import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';

// Screens
import 'screens/main_screen.dart';
import 'screens/focus_mode_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/progress_screen.dart';
import 'screens/task_list_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/video_splash_screen.dart';

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

  // Check authentication state
  final auth = FirebaseAuth.instance;
  debugPrint(
      'Current auth state: ${auth.currentUser != null ? 'Logged in' : 'Not logged in'}');
  if (auth.currentUser != null) {
    debugPrint('User ID: ${auth.currentUser!.uid}');
  }

  // Only enable persistence for non-web platforms
  if (!kIsWeb) {
    FirebaseDatabase.instance.setPersistenceEnabled(true);
  }

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
        debugShowCheckedModeBanner: false,
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
          '/video_splash': (context) => SplashScreen(
                onSplashEnd: () {
                  Navigator.pushReplacementNamed(context, '/main');
                },
              ),
        },
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  late SharedPreferences _prefs;
  bool _initialized = false;
  bool _videoSplashShown = false;

  @override
  void initState() {
    super.initState();
    _initPrefs();
  }

  Future<void> _initPrefs() async {
    _prefs = await SharedPreferences.getInstance();
    setState(() {
      _initialized = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('AuthWrapper building');

    if (!_initialized) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // Add more detailed debugging
        debugPrint('Auth state connection: ${snapshot.connectionState}');
        debugPrint('Auth state has error: ${snapshot.hasError}');
        if (snapshot.hasError) {
          debugPrint('Auth state error: ${snapshot.error}');
        }
        debugPrint('Auth state has data: ${snapshot.hasData}');
        debugPrint('User is authenticated: ${snapshot.data != null}');

        final freshLogin = _prefs.getBool('fresh_login') ?? false;
        debugPrint('Fresh login flag: $freshLogin');

        // Track if video splash has been shown
        if (_videoSplashShown) {
          debugPrint('Video splash already shown this session');
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          // Show loading spinner while waiting for auth state
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // If the user is authenticated, show video splash then main screen
        if (snapshot.connectionState == ConnectionState.active) {
          final user = snapshot.data;
          if (user != null) {
            // Check for fresh login flag or if video splash hasn't been shown yet
            if (freshLogin && !_videoSplashShown) {
              debugPrint(
                  'User is authenticated, showing video splash (fresh login)');
              // Reset the flag
              _prefs.setBool('fresh_login', false);
              // Mark that we're showing the video splash
              _videoSplashShown = true;
              return SplashScreen(
                onSplashEnd: () {
                  Navigator.pushReplacementNamed(context, '/main');
                },
              );
            } else {
              debugPrint(
                  'User is authenticated, showing main screen (not fresh login or splash already shown)');
              return const MainScreen();
            }
          } else {
            // Reset the video splash shown flag when logged out
            _videoSplashShown = false;
            debugPrint('User is not authenticated, showing login screen');
          }
        }

        // Otherwise, show the login screen
        return const LoginScreen();
      },
    );
  }
}
