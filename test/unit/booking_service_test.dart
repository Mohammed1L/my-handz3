import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';

class BookingRepo {
  final FakeFirebaseFirestore db;
  final MockFirebaseAuth auth;

  BookingRepo(this.db, this.auth);

  Future<void> createBooking({
    required String service,
    required String date,
    required String time,
    required String address,
  }) async {
    final user = await auth.currentUser!;
    await db.collection('requests').add({
      'userId': user.uid,
      'service': service,
      'date': date,
      'time': time,
      'address': address,
      'status': 'pending',
      'timestamp': DateTime.now(),
    });
  }
}

void main() {
  test('createBooking writes a pending request with userId', () async {
    // TODO: inject fake auth and fake firestore, or refactor repo
  }, skip: true);
}