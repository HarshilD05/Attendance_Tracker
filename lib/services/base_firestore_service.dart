import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

abstract class BaseFirestoreService {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final FirebaseAuth auth = FirebaseAuth.instance;

  /// Get current authenticated user's ID
  String? get currentUserId => auth.currentUser?.uid;

  /// Get current authenticated user
  User? get currentUser => auth.currentUser;

  /// Ensure user is authenticated before performing operations
  void ensureAuthenticated() {
    if (currentUserId == null) {
      throw Exception('User not authenticated');
    }
  }

  /// Get a reference to a collection
  CollectionReference getCollection(String path) {
    return firestore.collection(path);
  }

  /// Get a reference to a document
  DocumentReference getDocument(String path) {
    return firestore.doc(path);
  }

  /// Execute a batch operation
  Future<void> executeBatch(Function(WriteBatch batch) operations) async {
    final batch = firestore.batch();
    operations(batch);
    await batch.commit();
  }

  /// Handle common Firestore errors
  String handleFirestoreError(dynamic error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'You do not have permission to perform this action';
        case 'not-found':
          return 'The requested document was not found';
        case 'already-exists':
          return 'The document already exists';
        case 'unavailable':
          return 'Service is currently unavailable. Please try again later';
        case 'deadline-exceeded':
          return 'Request timed out. Please try again';
        default:
          return 'An error occurred: ${error.message}';
      }
    }
    return 'An unexpected error occurred: $error';
  }
}
