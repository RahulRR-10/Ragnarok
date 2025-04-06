# BeeFlow Progress Synchronization Troubleshooting

If your progress (XP, level, achievements) isn't being saved to Firebase after cloning the project, follow these steps to fix the issue:

## 1. Check Firebase Rules

The most common issue is incorrect Firebase database rules. Make sure your Firebase Realtime Database has the following rules:

```json
{
  "rules": {
    "users": {
      "$userId": {
        ".read": "$userId === auth.uid",
        ".write": "$userId === auth.uid",

        "tasks": {
          "$taskId": {
            ".validate": "newData.hasChild('userId')",
            "userId": {
              ".validate": "newData.val() === auth.uid"
            },
            "isCompleted": {
              ".validate": "!newData.exists() || newData.isBoolean()"
            },
            "difficulty": {
              ".validate": "!newData.exists() || (newData.isString() &&
                          (newData.val() === 'easy' ||
                           newData.val() === 'medium' ||
                           newData.val() === 'hard' ||
                           newData.val() === 'epic'))"
            },
            "subtasks": {
              "$subtaskId": {
              }
            }
          }
        },

        "progress": {
          ".read": "$userId === auth.uid",
          ".write": "$userId === auth.uid"
        },

        "test_permissions": {
          ".write": "$userId === auth.uid",
          ".read": "$userId === auth.uid"
        }
      }
    }
  }
}
```

The key addition is the **"progress"** node which was missing in the original rules.

## 2. Check Firebase Authentication

1. Make sure you're properly signed in:

   - Check the user icon/status in the app
   - Sign out and sign back in to refresh the authentication token
   - Ensure your Firebase project has authentication enabled

2. Verify your auth methods are set up:
   - Go to Firebase Console > Authentication > Sign-in methods
   - Ensure Email/Password authentication is enabled

## 3. Test Firebase Connection

Add this code at the beginning of the `_saveUserStats()` method in `task_provider.dart` for debugging:

```dart
// Test Firebase connection
try {
  final userId = _taskService.currentUserId;
  if (userId == null) {
    debugPrint('ERROR: No user ID found when saving progress');
    return;
  }

  final testRef = FirebaseDatabase.instance
      .ref()
      .child('users')
      .child(userId)
      .child('test_permissions');

  await testRef.set({'test': DateTime.now().toString()});
  debugPrint('Test write successful - Firebase is working');
} catch (e) {
  debugPrint('Firebase test write failed: $e');
}
```

## 4. Force Save Progress

Add a button in the settings or debug screen to manually save progress:

```dart
ElevatedButton(
  onPressed: () async {
    try {
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      await taskProvider._saveUserStats(); // You may need to make this method public
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Progress manually saved to Firebase')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving progress: $e')),
      );
    }
  },
  child: const Text('Force Save Progress'),
)
```

## 5. Check Firebase Config Files

Ensure you have the correct Firebase configuration files:

- **Android**: Verify `google-services.json` is in the `android/app/` directory
- **iOS**: Verify `GoogleService-Info.plist` is in the `ios/Runner/` directory

## 6. Check Network Connectivity

- Make sure your device has a working internet connection
- Try on WiFi instead of cellular data
- Check if there's a firewall blocking Firebase connections

## 7. Update Flutter Firebase Packages

Run:

```bash
flutter pub upgrade firebase_core firebase_database firebase_auth
```

## 8. Clear App Data and Reinstall

As a last resort:

- Uninstall the app
- Clear cache/data
- Reinstall and sign in again

## Still Having Issues?

If you're still facing problems after trying these steps, collect debugging information:

1. Enable verbose logging in the app
2. Check the Firebase console for errors in the Crashlytics section
3. Contact the BeeFlow team with screenshots and error logs
