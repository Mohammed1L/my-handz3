import 'dart:async';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

Future<void> main() async {
  final db = FakeFirebaseFirestore();
  const total = 500;
  final sw = Stopwatch()..start();

  await Future.wait(List.generate(total, (i) async {
    await db.collection('requests').add({
      'userId': 'loadUser',
      'service': 'Cleaning $i',
      'date': '2025-09-25',
      'time': '10:00',
      'address': 'LatLng',
      'status': 'pending',
      'timestamp': DateTime.now(),
    });
  }));

  sw.stop();
  print('Wrote $total docs in ${sw.elapsedMilliseconds} ms '
      '(${(total/(sw.elapsedMilliseconds/1000)).toStringAsFixed(1)} ops/s)');
}



