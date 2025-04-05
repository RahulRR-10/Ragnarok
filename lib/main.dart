import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Screens
import 'screens/main_screen.dart';
import 'screens/focus_mode_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/progress_screen.dart';
import 'screens/task_list_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';

// Providers
import 'providers/task_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/progress_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: FirebaseOptions(
      apiKey: "AIzaSyDGB7GjIEYGwThlky6HPq-7RazZOBRMgoQ",
      authDomain: "beeflow-93ea2.firebaseapp.com",
      databaseURL: "https://beeflow-93ea2-default-rtdb.firebaseio.com",
      projectId: "beeflow-93ea2",
      storageBucket: "beeflow-93ea2.firebasestorage.app",
      messagingSenderId: "165353650541",
      appId: "1:165353650541:web:8411259ab7c4ee1f5a4264",
      measurementId: "G-DRYF5DQCEZ",
    ),
  );

  final prefs = await SharedPreferences.getInstance();

  // Initialize notifications
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initializationSettings = InitializationSettings(
    android: initializationSettingsAndroid,
  );
  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  runApp(MyApp(prefs: prefs));
}

class MyApp extends StatelessWidget {
  final SharedPreferences prefs;

  const MyApp({super.key, required this.prefs});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TaskProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider(prefs)),
        ChangeNotifierProvider(create: (_) => ProgressProvider()),
      ],
      child: MaterialApp(
        title: 'ADHD Task Manager',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF9575CD), // Lighter purple
            primary: const Color(0xFF9575CD),
            secondary: const Color(0xFFB39DDB),
            background: const Color(0xFFF3E5F5),
            brightness: Brightness.light,
          ),
          textTheme: GoogleFonts.poppinsTextTheme(),
          cardTheme: CardTheme(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF9575CD),
            primary: const Color(0xFF9575CD),
            secondary: const Color(0xFFB39DDB),
            background: const Color(0xFF311B92),
            brightness: Brightness.dark,
          ),
          textTheme: GoogleFonts.poppinsTextTheme(ThemeData.dark().textTheme),
          cardTheme: CardTheme(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          useMaterial3: true,
        ),
        home: const AuthWrapper(),
        routes: {
          '/login': (context) => const LoginScreen(),
          '/register': (context) => const RegisterScreen(),
          '/main': (context) => const MainScreen(),
          '/tasks': (context) => const TaskListScreen(),
          '/focus': (context) => const FocusModeScreen(),
          '/settings': (context) => const SettingsScreen(),
          '/progress': (context) => const ProgressScreen(),
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // If the user is authenticated, show the main screen
        if (snapshot.connectionState == ConnectionState.active) {
          final user = snapshot.data;
          if (user != null) {
            // User is authenticated, navigate to main screen
            // Use a post-frame callback to avoid navigation during build
            WidgetsBinding.instance.addPostFrameCallback((_) {
              // Check if we're not already on the main screen
              if (ModalRoute.of(context)?.settings.name != '/main') {
                Navigator.of(context).pushReplacementNamed('/main');
              }
            });
            return const MainScreen();
          }
        }

        // Otherwise, show the login screen
        return const LoginScreen();
      },
    );
  }
}
