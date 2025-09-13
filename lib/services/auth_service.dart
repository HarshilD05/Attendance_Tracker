import 'package:firebase_auth/firebase_auth.dart';
// import 'package:google_sign_in/google_sign_in.dart'; // Temporarily disabled
import 'user_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // final GoogleSignIn _googleSignIn = GoogleSignIn(); // Temporarily disabled
  final UserService _userService = UserService();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state changes stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Email & Password Sign In
  Future<UserCredential?> signInWithEmailPassword(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Check if email is verified for email/password users
      if (credential.user != null && !credential.user!.emailVerified) {
        // Check if user signed up with email/password (not Google)
        final isEmailPasswordUser = credential.user!.providerData
            .any((info) => info.providerId == 'password');
        
        if (isEmailPasswordUser) {
          throw 'Please verify your email before signing in. Check your inbox for verification link.';
        }
      }
      
      // Ensure user document exists in Firestore after successful sign-in
      if (credential.user != null && credential.user!.emailVerified) {
        await ensureUserDocumentExists();
      }
      
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Email & Password Sign Up
  Future<UserCredential?> signUpWithEmailPassword(String email, String password, String name) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Update display name and send email verification
      if (credential.user != null) {
        await credential.user!.updateDisplayName(name);
        await credential.user!.sendEmailVerification();
        
        // Note: We don't create the Firestore user document here
        // It will be created after email verification is confirmed
      }
      
      return credential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Google Sign In (temporarily disabled)
  Future<UserCredential?> signInWithGoogle() async {
    throw 'Google sign-in is currently unavailable. Please use email/password authentication.';
  }

  // Sign Out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw 'Error signing out: $e';
    }
  }

  // Reset Password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Delete Account
  Future<void> deleteAccount() async {
    try {
      await _auth.currentUser?.delete();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Send Email Verification
  Future<void> sendEmailVerification() async {
    try {
      await _auth.currentUser?.sendEmailVerification();
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Check if email is verified
  Future<bool> isEmailVerified() async {
    await _auth.currentUser?.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  // Create user document in Firestore after email verification
  Future<void> createUserDocumentIfVerified() async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Check if email is verified
    await user.reload();
    if (!user.emailVerified) return;

    try {
      // Check if user document already exists
      if (await _userService.userExists(user.uid)) {
        return; // User document already exists
      }

      // Create user document in Firestore
      await _userService.createUserFromAuth(user);
    } catch (e) {
      print('Error creating user document: $e');
      // Don't throw here to avoid breaking the auth flow
    }
  }

  // Ensure user document exists (call this after successful authentication)
  Future<void> ensureUserDocumentExists() async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Only create if user is verified and document doesn't exist
      if (user.emailVerified && !await _userService.userExists(user.uid)) {
        await _userService.createUserFromAuth(user);
      }
    } catch (e) {
      print('Error ensuring user document exists: $e');
    }
  }

  // Resend verification email
  Future<void> resendVerificationEmail() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    } else {
      throw 'No user found or email already verified';
    }
  }

  // Change Password
  Future<void> changePassword(String newPassword) async {
    try {
      await _auth.currentUser?.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Check if user signed up with email/password
  bool isEmailPasswordUser() {
    final user = _auth.currentUser;
    if (user == null) return false;
    
    return user.providerData.any((info) => info.providerId == 'password');
  }

  // Reload current user data
  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'invalid-credential':
        return 'Invalid login credentials.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many failed login attempts. Please try again later.';
      case 'operation-not-allowed':
        return 'This sign-in method is not enabled.';
      default:
        return 'Authentication error: ${e.message ?? "Unknown error"}';
    }
  }
}
