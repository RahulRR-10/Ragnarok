import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../models/user.dart' as app_user;

class FirebaseAuthService {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;

  FirebaseAuthService({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignin,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignin ??
            GoogleSignIn(
              scopes: [
                'email',
                'profile',
              ],
            );

  app_user.User? _userFromFirebase(User? firebaseUser) {
    if (firebaseUser == null) {
      return null;
    }
    return app_user.User(
      uid: firebaseUser.uid,
      email: firebaseUser.email,
      displayName: firebaseUser.displayName,
      photoUrl: firebaseUser.photoURL,
    );
  }

  Stream<app_user.User?> get onAuthStateChanged {
    return _firebaseAuth.authStateChanges().map(_userFromFirebase);
  }

  Future<app_user.User?> signInWithEmailAndPassword(
      String email, String password) async {
    try {
      final authResult = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _userFromFirebase(authResult.user);
    } catch (e) {
      print('Error signing in with email and password: $e');
      rethrow;
    }
  }

  Future<app_user.User?> createUserWithEmailAndPassword(
      String email, String password) async {
    try {
      final authResult = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return _userFromFirebase(authResult.user);
    } catch (e) {
      print('Error creating user with email and password: $e');
      rethrow;
    }
  }

  Future<app_user.User?> signInAnonymously() async {
    try {
      final authResult = await _firebaseAuth.signInAnonymously();
      return _userFromFirebase(authResult.user);
    } catch (e) {
      print('Error signing in anonymously: $e');
      rethrow;
    }
  }

  Future<app_user.User?> signInWithGoogle() async {
    try {
      // For web, we'll use a different approach
      if (const bool.fromEnvironment('dart.library.html')) {
        // Use Firebase Auth's built-in Google sign-in for web
        final provider = GoogleAuthProvider();

        // Check if we're returning from a redirect
        final result = await _firebaseAuth.getRedirectResult();
        if (result.user != null) {
          // We're returning from a redirect with a user
          return _userFromFirebase(result.user);
        }

        // If no redirect result, initiate the redirect flow
        await _firebaseAuth.signInWithRedirect(provider);

        // Return null to indicate we're in the redirect flow
        // The auth state listener will handle navigation
        return null;
      } else {
        // For mobile platforms, use the Google Sign-In plugin
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

        if (googleUser == null) {
          throw Exception('Google Sign In was cancelled');
        }

        // Obtain the auth details from the request
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        // Create a new credential
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        // Sign in to Firebase with the Google credential
        final UserCredential authResult =
            await _firebaseAuth.signInWithCredential(credential);
        return _userFromFirebase(authResult.user);
      }
    } catch (e) {
      print('Error signing in with Google: $e');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await Future.wait([
        _firebaseAuth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }

  app_user.User? get currentUser {
    return _userFromFirebase(_firebaseAuth.currentUser);
  }

  // Helper method to detect if we're on a mobile device
  bool _isMobileDevice() {
    // This is a simple check that works for most cases
    // For more accurate detection, you might need a platform-specific implementation
    return const bool.fromEnvironment('dart.library.html') &&
        (const bool.fromEnvironment('dart.library.io') ||
            const bool.fromEnvironment('dart.library.html'));
  }
}
