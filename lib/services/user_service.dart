import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user.dart';
import 'base_firestore_service.dart';

class UserService extends BaseFirestoreService {
  static const String _collectionName = 'users';

  /// Get users collection reference
  CollectionReference get _usersCollection => getCollection(_collectionName);

  /// Create user document in Firestore
  Future<void> createUser({
    required String uid,
    required String email,
    String? displayName,
    String? photoURL,
  }) async {
    try {
      final appUser = AppUser.create(
        uid: uid,
        email: email,
        displayName: displayName,
        photoURL: photoURL,
      );

      await _usersCollection.doc(uid).set(appUser.toJson());
    } catch (e) {
      throw Exception('Failed to create user: ${handleFirestoreError(e)}');
    }
  }

  /// Get user document from Firestore
  Future<AppUser?> getUser(String uid) async {
    try {
      final doc = await _usersCollection.doc(uid).get();
      if (doc.exists) {
        return AppUser.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user: ${handleFirestoreError(e)}');
    }
  }

  /// Get current user document
  Future<AppUser?> getCurrentUser() async {
    ensureAuthenticated();
    return await getUser(currentUserId!);
  }

  /// Update user document
  Future<void> updateUser(AppUser user) async {
    try {
      await _usersCollection.doc(user.uid).update(user.toJson());
    } catch (e) {
      throw Exception('Failed to update user: ${handleFirestoreError(e)}');
    }
  }

  /// Update user profile information
  Future<void> updateUserProfile({
    String? displayName,
    String? photoURL,
  }) async {
    ensureAuthenticated();
    
    try {
      final currentUser = await getCurrentUser();
      if (currentUser == null) {
        throw Exception('User document not found');
      }

      final updatedUser = currentUser.copyWith(
        displayName: displayName,
        photoURL: photoURL,
      );

      await updateUser(updatedUser);
    } catch (e) {
      throw Exception('Failed to update profile: ${handleFirestoreError(e)}');
    }
  }

  /// Add semester ID to user's semester list
  Future<void> addSemesterToUser(String semesterId) async {
    ensureAuthenticated();
    
    try {
      final currentUser = await getCurrentUser();
      if (currentUser == null) {
        throw Exception('User document not found');
      }

      final updatedUser = currentUser.addSemester(semesterId);
      await updateUser(updatedUser);
    } catch (e) {
      throw Exception('Failed to add semester to user: ${handleFirestoreError(e)}');
    }
  }

  /// Remove semester ID from user's semester list
  Future<void> removeSemesterFromUser(String semesterId) async {
    ensureAuthenticated();
    
    try {
      final currentUser = await getCurrentUser();
      if (currentUser == null) {
        throw Exception('User document not found');
      }

      final updatedUser = currentUser.removeSemester(semesterId);
      await updateUser(updatedUser);
    } catch (e) {
      throw Exception('Failed to remove semester from user: ${handleFirestoreError(e)}');
    }
  }

  /// Check if user document exists
  Future<bool> userExists(String uid) async {
    try {
      final doc = await _usersCollection.doc(uid).get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  /// Create user document from Firebase Auth user
  Future<void> createUserFromAuth(User firebaseUser) async {
    try {
      // Check if user document already exists
      if (await userExists(firebaseUser.uid)) {
        return; // User already exists, no need to create
      }

      await createUser(
        uid: firebaseUser.uid,
        email: firebaseUser.email!,
        displayName: firebaseUser.displayName,
        photoURL: firebaseUser.photoURL,
      );
    } catch (e) {
      throw Exception('Failed to create user from auth: ${handleFirestoreError(e)}');
    }
  }

  /// Get user's semester IDs
  Future<List<String>> getUserSemesterIds() async {
    ensureAuthenticated();
    
    try {
      final currentUser = await getCurrentUser();
      return currentUser?.semesterIds ?? [];
    } catch (e) {
      throw Exception('Failed to get user semester IDs: ${handleFirestoreError(e)}');
    }
  }

  /// Listen to current user document changes
  Stream<AppUser?> getCurrentUserStream() {
    if (currentUserId == null) {
      return Stream.value(null);
    }

    return _usersCollection.doc(currentUserId).snapshots().map((doc) {
      if (doc.exists) {
        return AppUser.fromFirestore(doc);
      }
      return null;
    });
  }

  /// Delete user document (use with caution)
  Future<void> deleteUser(String uid) async {
    try {
      await _usersCollection.doc(uid).delete();
    } catch (e) {
      throw Exception('Failed to delete user: ${handleFirestoreError(e)}');
    }
  }

  /// Update user's last active timestamp
  Future<void> updateLastActive() async {
    ensureAuthenticated();
    
    try {
      await _usersCollection.doc(currentUserId).update({
        'updatedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      // Silently fail for last active updates
      print('Failed to update last active: $e');
    }
  }
}
