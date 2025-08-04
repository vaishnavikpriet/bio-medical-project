import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // FIXED: Initialize GoogleSignIn without any parameters.
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Stream to track user authentication state
  Stream<User?> get userStream => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Email & Password Sign Up
  Future<User?> signUpWithEmailAndPassword(
      String email,
      String password,
      ) async {
    try {
      UserCredential credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      debugPrint('SignUp Error: ${e.code}');
      throw _getAuthExceptionMessage(e.code);
    }
  }

  // Email & Password Sign In
  Future<User?> signInWithEmailAndPassword(
      String email,
      String password,
      ) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential.user;
    } on FirebaseAuthException catch (e) {
      debugPrint('Login Error: ${e.code}');
      throw _getAuthExceptionMessage(e.code);
    }
  }

  // UPDATED: The entire Google Sign-In flow is updated to the modern API.
  Future<User?> signInWithGoogle() async {
    try {
      // 1. Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // The user canceled the sign-in
        return null;
      }

      // 2. Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
      await googleUser.authentication;

      // 3. Create a new credential for Firebase
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // 4. Once signed in, return the UserCredential
      UserCredential userCredential =
      await _auth.signInWithCredential(credential);
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      debugPrint('Google SignIn Error: ${e.code} - ${e.message}');
      if (e.code == 'account-exists-with-different-credential') {
        throw 'An account already exists with a different sign-in method.';
      }
      throw 'Google sign-in failed. Please try again.';
    } catch (e) {
      debugPrint('Google SignIn Error: $e');
      throw 'An unknown error occurred while signing in with Google.';
    }
  }

  // Sign Out - Enhanced with complete cleanup
  Future<void> signOut() async {
    try {
      // FIXED: Check if a Google user is signed in before trying to sign out.
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
      // Always sign out from Firebase.
      await _auth.signOut();

      debugPrint('User signed out successfully');
    } catch (e) {
      debugPrint('SignOut Error: $e');
      throw 'Failed to sign out. Please try again.';
    }
  }

  // Password Reset
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      debugPrint('Password Reset Error: ${e.code}');
      throw _getAuthExceptionMessage(e.code);
    }
  }

  // Delete account permanently
  Future<void> deleteAccount() async {
    try {
      // Re-authentication might be required for this operation.
      // This implementation assumes the user has recently signed in.
      await _auth.currentUser?.delete();
      await signOut(); // Ensure complete cleanup
    } on FirebaseAuthException catch (e) {
      debugPrint('Account Deletion Error: ${e.code}');
      throw _getAuthExceptionMessage(e.code);
    }
  }

  // Helper method to convert Firebase error codes to user-friendly messages
  String _getAuthExceptionMessage(String code) {
    switch (code) {
      case 'weak-password':
        return 'The password provided is too weak. Use at least 6 characters.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'operation-not-allowed':
        return 'Email/password accounts are not enabled.';
      case 'user-disabled':
        return 'This account has been disabled. Contact support.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later or reset your password.';
      case 'requires-recent-login':
        return 'This operation requires recent authentication. Please log in again.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}