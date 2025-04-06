import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

class FirebaseUtils {
  static Future<bool> checkDatabasePermissions() async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final currentUser = auth.currentUser;

    if (currentUser == null) {
      debugPrint('FirebaseUtils: User is not authenticated');
      return false;
    }

    try {
      // Try to write to a test path
      final testRef = FirebaseDatabase.instance
          .ref()
          .child('users')
          .child(currentUser.uid)
          .child('test_permissions');

      await testRef.set({
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'test': 'Permission check'
      });

      // If successful, clean up the test node
      await testRef.remove();

      debugPrint('FirebaseUtils: Database permissions check passed');
      return true;
    } catch (e) {
      debugPrint('FirebaseUtils: Database permissions check failed: $e');
      return false;
    }
  }

  static Future<void> reauthenticateIfNeeded() async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    final currentUser = auth.currentUser;

    if (currentUser != null) {
      try {
        // Check how long since the token was last refreshed
        final tokenResult = await currentUser.getIdTokenResult();
        final tokenTimestamp = tokenResult.authTime != null
            ? tokenResult.authTime!.millisecondsSinceEpoch
            : 0;
        final now = DateTime.now().millisecondsSinceEpoch;

        // If token is older than 45 minutes, refresh it
        if (now - tokenTimestamp > 45 * 60 * 1000) {
          debugPrint('FirebaseUtils: Token is old, refreshing...');
          await currentUser.getIdToken(true);
          debugPrint('FirebaseUtils: Token refreshed successfully');
        }
      } catch (e) {
        debugPrint('FirebaseUtils: Error refreshing token: $e');
      }
    }
  }
}
