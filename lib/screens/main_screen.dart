import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';

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

class NavigationWrapper extends StatefulWidget {
  final int initialIndex;
  final Widget child;

  const NavigationWrapper({
    super.key,
    required this.initialIndex,
    required this.child,
  });

  @override
  State<NavigationWrapper> createState() => _NavigationWrapperState();
}

class _NavigationWrapperState extends State<NavigationWrapper> {
  late int _selectedIndex;
  double _bookmarkTop = 0.3; // Default position at 30% from top
  double _bookmarkRight = 0;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;

    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacementNamed(context, '/tasks');
        break;
      case 1:
        Navigator.pushReplacementNamed(context, '/focus');
        break;
      case 2:
        Navigator.pushReplacementNamed(context, '/progress');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    return Scaffold(
      body: Stack(
        children: [
          widget.child,
          // Draggable Curved Bookmark Bee Button
          Positioned(
            right: _bookmarkRight,
            top: screenSize.height * _bookmarkTop,
            child: Draggable(
              feedback: _buildBookmark(),
              childWhenDragging: Container(), // Empty container when dragging
              onDragEnd: (details) {
                setState(() {
                  // Calculate new position as percentage of screen height
                  _bookmarkTop = (details.offset.dy / screenSize.height)
                      .clamp(0.1, 0.9); // Keep within 10-90% of screen height
                  _bookmarkRight = 0; // Keep at right edge
                });
              },
              child: _buildBookmark(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        height: 80,
        decoration: BoxDecoration(
          color: Colors.deepPurple.shade800,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(0, Icons.task_alt, 'Tasks'),
            _buildNavItem(1, Icons.timer, 'Focus'),
            _buildNavItem(2, Icons.bar_chart, 'Progress'),
          ],
        ),
      ),
    );
  }

  Widget _buildBookmark() {
    return GestureDetector(
      onTap: () => Navigator.pushNamedAndRemoveUntil(
        context,
        '/',
        (route) => false,
      ),
      child: Container(
        width: 50,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.amber.shade300,
          borderRadius:
              const BorderRadius.horizontal(left: Radius.circular(25)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(-2, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.emoji_nature,
              color: Colors.deepPurple.shade800,
              size: 30,
            ),
            const SizedBox(height: 4),
            Text(
              'Home',
              style: TextStyle(
                color: Colors.deepPurple.shade800,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isSelected ? Colors.amber.shade300 : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isSelected ? Colors.deepPurple.shade800 : Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.amber.shade300 : Colors.white,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final List<String> _quotes = [
    "You got this! 🌟",
    "One step at a time! 🐿️",
    "Believe in yourself! 🦋",
    "Small progress is still progress! 🚀",
    "Stay in motion without the commotion ✨",
  ];

  String _currentQuote = "You got this! 🌟";

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
        backgroundColor: Colors.deepPurple.shade800,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.pushNamed(context, '/settings'),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.deepPurple.shade300,
              Colors.deepPurple.shade600,
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 30),
              // Animated Mascot with Background
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.2),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: BounceInDown(
                  child: Icon(
                    Icons.emoji_nature,
                    size: 100,
                    color: Colors.amber[300],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Interactive Quote with Background
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding:
                    const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: MouseRegion(
                  onEnter: (_) => _changeQuote(),
                  child: Text(
                    _currentQuote,
                    style: GoogleFonts.pacifico(
                      fontSize: 24,
                      color: Colors.amber[300],
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.2),
                          offset: const Offset(0, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 50),
              // Quick Actions Grid with Enhanced Cards
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 1,
                  mainAxisSpacing: 20,
                  childAspectRatio: 2.5,
                  children: [
                    _buildQuickActionCard(
                      context,
                      "My Tasks",
                      Icons.task_alt,
                      Colors.deepPurple.shade400,
                      () => Navigator.pushNamed(context, '/tasks'),
                    ),
                    _buildQuickActionCard(
                      context,
                      "Focus Mode",
                      Icons.timer,
                      Colors.deepPurple.shade500,
                      () => Navigator.pushNamed(context, '/focus'),
                    ),
                    _buildQuickActionCard(
                      context,
                      "Your Progress",
                      Icons.bar_chart,
                      Colors.deepPurple.shade600,
                      () => Navigator.pushNamed(context, '/progress'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.8),
                color,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 20),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.2),
                      offset: const Offset(0, 1),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
