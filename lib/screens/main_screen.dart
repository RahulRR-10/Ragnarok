import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:animate_do/animate_do.dart';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
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

class _NavigationWrapperState extends State<NavigationWrapper> with SingleTickerProviderStateMixin {
  late AnimationController _iconWiggleController;
  late int _selectedIndex;
  double _bookmarkTop = 0.3; // Default position at 30% from top
  double _bookmarkRight = 0;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _iconWiggleController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 800),
  )..repeat(reverse: true);

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

// Enum for icon position - moved outside the method to class level
enum IconPosition { left, right }

class _MainScreenState extends State<MainScreen> with TickerProviderStateMixin {
  final List<String> _quotes = [
    "Don't worry, you got this, keep going! 🌟",
    "Let's take it easy, just one step at a time! 🐿️",
    "Always bee-lieve in yourself! Buzz Buzz🐝",
    "Small progress is still progress, keep at it! 🚀",
    "Stay in motion through the commotion ✨",
  ];
  bool _hovering = false;
  late AnimationController _iconWiggleController;
  String _currentQuote = "Stay in motion through the commotion ✨";
  Timer? _quoteTimer;
  late AnimationController _quoteAnimationController;
  int _currentQuoteIndex = 0;
  
  // Animation controllers for button fade effects
  late List<AnimationController> _buttonAnimationControllers;
  late List<Animation<double>> _buttonOpacities;
  late AnimationController _beePulseController;
  late Animation<double> _beeScaleAnimation;

  @override
  void initState() {
    super.initState();
    _iconWiggleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    // Set up quote animation controller - shorter duration for fade transitions
    _quoteAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    
    // Start the timer to change quotes every 8 seconds
    _startQuoteTimer();
    
    // Set up button animations
    _buttonAnimationControllers = List.generate(
      3,
      (index) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 100),
      ),
    );
    
    _buttonOpacities = _buttonAnimationControllers.map((controller) {
      return Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: controller,
          curve: Curves.easeIn,
        ),
      );
    }).toList();
    _beePulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _beeScaleAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
    CurvedAnimation(
      parent: _beePulseController,
      curve: Curves.easeInOut,
      ),
    );

  // Start pulsing AFTER bounce animation ends
  Future.delayed(const Duration(milliseconds: 800), () {
    if (mounted) {
      _beePulseController.repeat(reverse: true);
    }
    });

    // Start button animations with staggered delay
    Future.delayed(const Duration(milliseconds: 100), () {
      _buttonAnimationControllers[0].forward();
    });
    
    Future.delayed(const Duration(milliseconds: 300), () {
      _buttonAnimationControllers[1].forward();
    });
    
    Future.delayed(const Duration(milliseconds: 500), () {
      _buttonAnimationControllers[2].forward();
    });
  }

  @override
  void dispose() {
    _quoteTimer?.cancel();
    _quoteAnimationController.dispose();
    for (var controller in _buttonAnimationControllers) {
      controller.dispose();
    }
    _beePulseController.dispose();
    _iconWiggleController.dispose();
    super.dispose();
    

  }

  void _startQuoteTimer() {
     // Start the animation loop
  _runQuoteAnimationLoop();
  }

 void _runQuoteAnimationLoop() async {
  while (mounted) {
    // Fade out
    await _quoteAnimationController.forward();

    setState(() {
      _currentQuoteIndex = (_currentQuoteIndex + 1) % _quotes.length;
      _currentQuote = _quotes[_currentQuoteIndex];
    });

    // Fade in
    await _quoteAnimationController.reverse();

    // Wait before starting the next change
    await Future.delayed(const Duration(seconds: 5));
  }
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
          Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ElevatedButton.icon(
        icon: Icon(
          Icons.logout_rounded,
          color: Colors.deepPurple.shade800,
          size: 18,
        ),
        label: Text(
          'Logout',
          style: TextStyle(
            color: Colors.deepPurple.shade800,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.amber.shade300,
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        onPressed: () async {
          try {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Logout'),
                content: const Text('Are you sure you want to logout?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Logout'),
                  ),
                ],
              ),
            );

            if (confirm == true) {
              await FirebaseAuth.instance.signOut();
              if (mounted) {
                Navigator.pushReplacementNamed(context, '/login');
              }
            }
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error logging out: $e')),
            );
          }
        },
      ),
    ),
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
                  child: ScaleTransition(
                    scale: _beeScaleAnimation,
                    child: Icon(
                      Icons.emoji_nature,
                      size: 100,
                      color: Colors.amber[300],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Interactive Quote with Background that fades
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
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
                  onEnter: (_) => _runQuoteAnimationLoop(),
                  child: AnimatedBuilder(
                    animation: _quoteAnimationController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: 1.0 - _quoteAnimationController.value,
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
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 50),
              // Quick Actions Grid with Enhanced Cards and alternating icon positions
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 1,
                  mainAxisSpacing: 20,
                  childAspectRatio: 2.5,
                  children: [
                    // First button - icon on left
                    FadeTransition(
                      opacity: _buttonOpacities[0],
                      child: _buildQuickActionCard(
                        context,
                        "My Tasks",
                        "assets/images/tasks.png",
                       const Color.fromARGB(255, 185, 158, 233),
                        () => Navigator.pushNamed(context, '/tasks'),
                        iconPosition: IconPosition.left,
                      ),
                    ),
                    // Second button - icon on right
                    FadeTransition(
                      opacity: _buttonOpacities[1],
                      child: _buildQuickActionCard(
                        context,
                        "Focus Mode",
                        "assets/images/focus.png",
                        const Color(0xFFAD88AD),
                        () => Navigator.pushNamed(context, '/focus'),
                        iconPosition: IconPosition.left,
                      ),
                    ),
                    // Third button - icon on left
                    FadeTransition(
                      opacity: _buttonOpacities[2],
                      child: _buildQuickActionCard(
                        context,
                        "Your Progress",
                        "assets/images/progress.png",
                        const Color(0xFF8A748A),
                        () => Navigator.pushNamed(context, '/progress'),
                        iconPosition: IconPosition.left,
                      ),
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
  String iconPath,
  Color color,
  VoidCallback onTap, {
  required IconPosition iconPosition,
}) {
  final iconWidget = MouseRegion(
    onEnter: (_) {
      setState(() {
        _hovering = true;
      });
      },
    onExit: (_) {
      setState(() {
          _hovering = false;
        });
    },
    child: AnimatedBuilder(
      animation: _iconWiggleController,
      builder: (context, child) {
        return Transform.rotate(
         angle: _hovering ? sin(_iconWiggleController.value * 2 * pi) * 0.05 : 0,
          child: child,
        );
     },
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        shape: BoxShape.circle,
      ),
      child: Image.asset(
        iconPath,         // <== This will come from your function parameter
        width: 76,
        height: 76,
      ),
    ),
  ),
);

  final textWidget = Text(
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
  );

  return MouseRegion(
    cursor: SystemMouseCursors.click,
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        duration: const Duration(milliseconds: 100),
        scale: 1.0,
        child: Card(
          elevation: 10,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  color.withOpacity(0.85),
                  color,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: iconPosition == IconPosition.left
                  ? MainAxisAlignment.start
                  : MainAxisAlignment.spaceBetween,
              children: iconPosition == IconPosition.left
                  ? [
                      iconWidget,
                      const SizedBox(width: 20),
                      textWidget,
                    ]
                  : [
                      textWidget,
                      iconWidget,
                    ],
            ),
          ),
        ),
      ),
    ),
  );
}

}