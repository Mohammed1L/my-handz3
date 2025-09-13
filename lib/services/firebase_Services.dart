import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Create a new booking request
  Future<void> createBookingRequest({
    required String service,
    required String date,
    required String time,
    required String address,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception("User not logged in");
    }

    await _firestore.collection('requests').add({
      'userId': user.uid,
      'service': service,
      'date': date,
      'time': time,
      'address': address,
      'status': 'pending',
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  /// Get all available services (if you use static services from Firestore)
  Future<List<Map<String, dynamic>>> getAllServices() async {
    final snapshot = await _firestore.collection('services').get();
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  /// Get all bookings (map-based) for the current user
  Future<List<Map<String, dynamic>>> getMyBookings() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not logged in");

    final snapshot = await _firestore
        .collection('requests')
        .where('userId', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true)
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  /// Get bookings as snapshots (for detail + ID access)
  Future<QuerySnapshot<Map<String, dynamic>>> getMyBookingsSnapshot() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not logged in");

    return await _firestore
        .collection('requests')
        .where('userId', isEqualTo: user.uid)
        .orderBy('timestamp', descending: true)
        .get();
  }

  /// Get the current user ID
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  /// Sign out user
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// (Optional) Add a test provider to Firestore
  Future<void> addProvider() async {
    await _firestore.collection('providers').doc('sparkle_clean').set({
      'name': 'SparkleClean',
      'category': 'cleaning',
      'rating': 4.5,
      'location': 'Riyadh',
      'image': 'https://link-to-image.com/image.jpg',
      'services': [
        {'name': 'Deep Cleaning', 'price': 100},
        {'name': 'Regular Cleaning', 'price': 70},
      ],
    });
  }
}

/// Admin service helper for adding providers
class FirebaseAdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> addProvider({
    required String id,
    required String name,
    required String category,
    required String imageUrl,
    required List<Map<String, dynamic>> services,
    double rating = 4.5,
    String location = "Unknown",
  }) async {
    await _firestore.collection('providers').doc(id).set({
      'name': name,
      'category': category,
      'rating': rating,
      'location': location,
      'image': imageUrl,
      'services': services,
    });
  }
}
