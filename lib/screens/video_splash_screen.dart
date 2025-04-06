import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onSplashEnd;

  const SplashScreen({Key? key, required this.onSplashEnd}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  static const Duration splashDuration = Duration(seconds: 3);
  late final List<AnimationController> _dotControllers;
  late final List<Animation<double>> _dotAnimations;

  @override
  void initState() {
    super.initState();
    _startTimeout();
    _initDotAnimations();
  }

  void _startTimeout() {
    Future.delayed(splashDuration, () {
      if (mounted) {
        widget.onSplashEnd();
      }
    });
  }

  void _initDotAnimations() {
    _dotControllers = List.generate(3, (index) {
      return AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 700),
      )..repeat(reverse: true);
    });

    _dotAnimations = _dotControllers.map((controller) {
      return Tween<double>(begin: 0.8, end: 1.4).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
    }).toList();

    // Stagger start times
    for (int i = 0; i < _dotControllers.length; i++) {
      Future.delayed(Duration(milliseconds: 1000 * i), () {
        if (mounted) _dotControllers[i].forward();
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _dotControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Widget _buildAnimatedDot(int index) {
    return ScaleTransition(
      scale: _dotAnimations[index],
      child: Container(
        width: 15,
        height: 15,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFFFEE483),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFEE483).withOpacity(0.5),
              blurRadius: 8,
              spreadRadius: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDotsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) => _buildAnimatedDot(index)),
    );
  }

  Widget _buildFallbackLogo() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedScale(
          scale: 1.0,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeOutBack,
          child: Image.asset(
            'assets/images/logo.jpg',
            width: 550,
            height: 200,
          ),
        ),
        const SizedBox(height: 3),
        _buildDotsRow(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    timeDilation = 1.0;
    return Scaffold(
      backgroundColor: Colors.deepPurple.shade300,
      body: SafeArea(
        child: Center(child: _buildFallbackLogo()),
      ),
    );
  }
}
