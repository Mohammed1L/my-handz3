import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/search_utils.dart';


class Reindexer {
  final FirebaseFirestore _db;
  final int batchSize;
  final int readPageSize;

  Reindexer({
    FirebaseFirestore? firestore,
    this.batchSize = 250,
    this.readPageSize = 500,
  }) : _db = firestore ?? FirebaseFirestore.instance;

  Future<void> reindexAllProviders({bool onlyMissingKeywords = false}) async {
    print('=== reindexAllProviders started ===');
    Query query = _db.collection('providers').orderBy(FieldPath.documentId);

    DocumentSnapshot? lastDoc;
    int totalUpdated = 0;
    int page = 0;

    while (true) {
      Query pageQuery = query.limit(readPageSize);
      if (lastDoc != null) pageQuery = pageQuery.startAfterDocument(lastDoc);

      final snapshot = await pageQuery.get();
      if (snapshot.docs.isEmpty) break;

      page++;
      print('Processing page $page (${snapshot.docs.length} docs)...');

      // process in chunks for batch writes
      for (int i = 0; i < snapshot.docs.length; i += batchSize) {
        final chunk = snapshot.docs.skip(i).take(batchSize).toList();
        final batch = _db.batch();

        for (final doc in chunk) {
          final data = doc.data() as Map<String, dynamic>? ?? {};
          final existingKeywords = (data['keywords'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [];

          if (onlyMissingKeywords && existingKeywords.isNotEmpty) {
            // skip
            continue;
          }

          final name = (data['name'] ?? '').toString();
          final category = (data['category'] ?? '').toString();
          final services = (data['services'] as List<dynamic>?)
              ?.map((s) {
            if (s is Map) return s['name']?.toString() ?? '';
            return s?.toString() ?? '';
          })
              .where((s) => s.isNotEmpty)
              .toList() ??
              [];

          final combined = StringBuffer()..write(name)..write(' ')..write(category);
          for (final s in services.take(8)) {
            combined.write(' ');
            combined.write(s);
          }

          final keywords = generateKeywords(
            combined.toString(),
            prefixLimit: 12,
            maxTokens: 120,
          );

          batch.update(doc.reference, {'keywords': keywords});
        }

        await _commitWithRetries(batch);
        totalUpdated += chunk.length;
        print('Committed chunk of ${chunk.length} docs. Total updated ~ $totalUpdated');
      }

      lastDoc = snapshot.docs.last;
      await Future<void>.delayed(const Duration(milliseconds: 250));
    }

    print('=== reindexAllProviders completed. Approx updated: $totalUpdated ===');
  }

  Future<void> _commitWithRetries(WriteBatch batch, {int retries = 3}) async {
    int attempts = 0;
    while (true) {
      attempts++;
      try {
        await batch.commit();
        return;
      } catch (e) {
        if (attempts >= retries) {
          rethrow;
        }
        final backoff = Duration(milliseconds: 200 * attempts);
        print('Batch commit failed (attempt $attempts). Retrying after $backoff. Error: $e');
        await Future.delayed(backoff);
      }
    }
  }
}
