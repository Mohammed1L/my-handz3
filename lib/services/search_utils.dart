import 'dart:convert';
import 'package:characters/characters.dart';

String normalize(String s) {
  s = s.toLowerCase();

  s = s.replaceAll(RegExp(r'[^\w\s\u0600-\u06FF]', multiLine: true), ' ');
  s = s.replaceAll(RegExp(r'\s+'), ' ').trim();

  const arabicDiacritics = '\u064B\u064C\u064D\u064E\u064F\u0650\u0651\u0652';
  final buffer = StringBuffer();
  for (final ch in s.characters) {
    if (!arabicDiacritics.contains(ch)) buffer.write(ch);
  }
  return buffer.toString();
}

List<String> generateKeywords(
    String text, {
      int prefixLimit = 12,
      int maxTokens = 120,
    }) {
  if (text.trim().isEmpty) return <String>[];

  final normalized = normalize(text); // use public normalize
  final words = normalized.split(' ').where((w) => w.isNotEmpty).toList();

  final Set<String> tokens = <String>{};

  for (final w in words) {
    final len = w.length;
    final limit = prefixLimit < len ? prefixLimit : len;
    for (int i = 1; i <= limit; i++) {
      tokens.add(w.substring(0, i));
    }
    tokens.add(w);
  }

  for (int start = 0; start < words.length; start++) {
    final buffer = StringBuffer();
    for (int end = start; end < words.length && (end - start) < 4; end++) {
      if (buffer.isNotEmpty) buffer.write(' ');
      buffer.write(words[end]);
      final combined = buffer.toString();
      final len = combined.length;
      final limit = prefixLimit < len ? prefixLimit : len;
      for (int i = 1; i <= limit; i++) {
        tokens.add(combined.substring(0, i));
      }
      tokens.add(combined);
    }
  }

  final list = tokens.toList();
  list.sort((a, b) {
    if (a.length != b.length) return a.length.compareTo(b.length);
    return a.compareTo(b);
  });

  if (list.length > maxTokens) return list.sublist(0, maxTokens);
  return list;
}
