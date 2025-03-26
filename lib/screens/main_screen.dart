import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';

import 'task_list_screen.dart';
import 'focus_mode_screen.dart';
import 'progress_screen.dart';
import 'settings_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Removes debug tag
      title: 'ADHD Task Manager',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple,
        fontFamily: GoogleFonts.poppins().fontFamily,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const TaskListScreen(),
    const FocusModeScreen(),
    const ProgressScreen(),
    const SettingsScreen(),
  ];

  final List<String> _quotes = [
    "You got this! 🌟",
    "One step at a time! 🐿️",
    "Believe in yourself! 🦋",
    "Small progress is still progress! 🚀",
    "Stay in motion without the commotion ✨",
  ];

  String _currentQuote = "You got this! 🌟";

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _changeQuote() {
    setState(() {
      _quotes.shuffle();
      _currentQuote = _quotes.first;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.deepPurple.shade300,
      appBar: AppBar(
        title: Text(
          "ADHD Task Manager",
          style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.deepPurple.shade600,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => _onItemTapped(3),
          ),
        ],
      ),
      body: _selectedIndex == 0
          ? Column(
              children: [
                const SizedBox(height: 20),
                // Animated Mascot using existing Flutter icons
                BounceInDown(
                  child: Icon(
                    Icons.emoji_nature, // 🦋 Dynamic butterfly icon
                    size: 80,
                    color: Colors.amberAccent.shade100,
                  ),
                ),
                const SizedBox(height: 10),
                // Hover-to-change quote
                MouseRegion(
                  onEnter: (_) => _changeQuote(),
                  child: Text(
                    _currentQuote,
                    style: GoogleFonts.pacifico(fontSize: 20, color: Colors.white),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Cloud Shape
                        Container(
                          width: 280,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(50),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.checklist,
                                size: 60,
                                color: Colors.deepPurple,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                "No tasks yet, add one to get started ✅",
                                style: GoogleFonts.poppins(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.deepPurple.shade700,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            )
          : _screens[_selectedIndex], // Other screens are clean
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(
              backgroundColor: Colors.amberAccent.shade200,
              shape: const CircleBorder(),
              onPressed: () {
                // TODO: Implement task-adding functionality
              },
              child: const Icon(Icons.add, size: 32, color: Colors.deepPurple),
            )
          : null, // Hide FAB on other screens
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.deepPurple.shade800,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
          child: NavigationBar(
            backgroundColor: Colors.deepPurple.shade800,
            selectedIndex: _selectedIndex,
            onDestinationSelected: _onItemTapped,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.task_alt, color: Colors.white),
                label: 'Tasks',
              ),
              NavigationDestination(
                icon: Icon(Icons.timer, color: Colors.white),
                label: 'Focus',
              ),
              NavigationDestination(
                icon: Icon(Icons.bar_chart, color: Colors.white),
                label: 'Progress',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings, color: Colors.white),
                label: 'Settings',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
