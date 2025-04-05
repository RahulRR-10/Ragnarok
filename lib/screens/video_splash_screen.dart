import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:async';
import 'main_screen.dart';

class VideoSplashScreen extends StatefulWidget {
  const VideoSplashScreen({super.key});

  @override
  State<VideoSplashScreen> createState() => _VideoSplashScreenState();
}

class _VideoSplashScreenState extends State<VideoSplashScreen>
    with WidgetsBindingObserver {
  // Video setup
  VideoPlayerController? _controller;
  bool _videoInitialized = false;
  bool _videoError = false;
  String _errorMessage = '';
  bool _readyToShowVideo = false;

  // Animation controllers
  bool _showLogo = true;
  bool _transitionStarted = false;

  // Timing flags
  bool _minTimeElapsed = false;
  bool _videoCompleted = false;
  DateTime _startTime = DateTime.now();

  // Navigation safety flag - prevents other navigation while splash screen is showing
  static bool _isNavigatingToMainScreen = false;

  // Store timers so we can cancel them
  Timer? _minimumDurationTimer;
  Timer? _forcedTransitionTimer;
  Timer? _videoTimeoutTimer;
  Timer? _transitionDelayTimer;

  // This value ensures we always display the splash for at least 15 seconds
  final Duration _minimumDuration = const Duration(seconds: 15);

  // Force a full length display time (9 seconds) regardless of video state
  final Duration _forceFullDuration = const Duration(seconds: 9);

  @override
  void initState() {
    super.initState();

    // Add observer to detect app lifecycle changes
    WidgetsBinding.instance.addObserver(this);

    debugPrint('🎬 SPLASH: Initializing splash screen...');

    // Keep screen on during video
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    // Set a guaranteed minimum display time
    _startMinimumDisplayTimer();

    // Also set a forced transition timer as a fallback
    _startForcedTransitionTimer();

    // Reset the navigation safety flag
    _isNavigatingToMainScreen = false;

    // Force any previous controllers to dispose
    _checkAssetExists().then((exists) {
      if (exists) {
        debugPrint('✅ SPLASH: Video asset found, initializing player');
        _initializeVideo();
      } else {
        debugPrint('❌ SPLASH: Video asset not found!');
        setState(() {
          _videoError = true;
          _errorMessage = 'Video file not found';
        });
      }
    });
  }

  void _startForcedTransitionTimer() {
    _forcedTransitionTimer?.cancel();
    _forcedTransitionTimer = Timer(_forceFullDuration, () {
      if (!mounted) return;

      debugPrint('⏱️ SPLASH: Forced full display time elapsed');

      // If we haven't navigated away yet, force completion
      if (!_videoCompleted && !_transitionStarted) {
        debugPrint('⚠️ SPLASH: Forcing completion after full display time');
        setState(() {
          _videoCompleted = true;
        });
        _checkForTransition();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    debugPrint('🔄 SPLASH: Dependencies changed');
  }

  @override
  void didUpdateWidget(VideoSplashScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    debugPrint('🔄 SPLASH: Widget updated');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('📱 SPLASH: App lifecycle changed to $state');

    // Handle app going to background/foreground
    if (state == AppLifecycleState.paused) {
      _controller?.pause();
    } else if (state == AppLifecycleState.resumed) {
      _controller?.play();
    }
  }

  Future<bool> _checkAssetExists() async {
    try {
      debugPrint('🔍 SPLASH: Checking if video asset exists');
      final manifestContent = await rootBundle.loadString('AssetManifest.json');

      // Check if the asset path is in the manifest
      final videoExists = manifestContent.contains('assets/videos/intro.mp4');
      debugPrint('🔍 SPLASH: Video exists in manifest: $videoExists');

      return videoExists;
    } catch (e) {
      debugPrint('❌ SPLASH: Error checking asset existence: $e');
      return false;
    }
  }

  void _startMinimumDisplayTimer() {
    _minimumDurationTimer?.cancel();
    _minimumDurationTimer = Timer(_minimumDuration, () {
      if (!mounted) return;

      debugPrint('⏱️ SPLASH: Minimum display time elapsed');

      setState(() {
        _minTimeElapsed = true;
      });

      // After minimum time, check if we should transition
      _checkForTransition();
    });
  }

  void _initializeVideo() {
    try {
      debugPrint('🎬 SPLASH: Creating video controller');

      // Dispose any existing controller
      if (_controller != null) {
        _controller!.dispose();
        _controller = null;
      }

      // Use a hardcoded asset path
      const videoPath = 'assets/videos/intro.mp4';
      debugPrint('🎬 SPLASH: Loading video from: $videoPath');

      // Initialize controller with asset
      _controller = VideoPlayerController.asset(videoPath);

      // Set a timeout in case the video loading hangs
      _videoTimeoutTimer?.cancel();
      _videoTimeoutTimer = Timer(const Duration(seconds: 5), () {
        if (!_videoInitialized && mounted && !_videoError) {
          debugPrint('⚠️ SPLASH: Video initialization timed out');

          setState(() {
            _showLogo = true;
            _videoError = true;
            _errorMessage = 'Video initialization timed out';
          });

          // Try to flush controller
          _controller?.dispose();

          // If min time already passed, we can transition now
          _checkForTransition();
        }
      });

      // Start initialization process
      _controller!.initialize().then((_) {
        // If no longer mounted, abort
        if (!mounted) {
          debugPrint(
              '⚠️ SPLASH: Widget no longer mounted after initialization');
          return;
        }

        // Log video details
        final aspectRatio = _controller!.value.aspectRatio;
        final videoDuration = _controller!.value.duration;
        final videoSize = _controller!.value.size;

        debugPrint('✅ SPLASH: Video initialized successfully');
        debugPrint('📏 SPLASH: Video size: $videoSize');
        debugPrint(
            '⏱️ SPLASH: Video duration: ${videoDuration.inSeconds}.${videoDuration.inMilliseconds % 1000} seconds');
        debugPrint('📐 SPLASH: Video aspect ratio: $aspectRatio');

        // On success, remember video is initialized
        setState(() {
          _videoInitialized = true;
        });

        // If video is valid, show it and start playing
        if (videoDuration.inSeconds > 1) {
          // First, set position to zero before we create any frames
          _controller!.seekTo(Duration.zero);
          _controller!.pause();

          // Prepare the video
          _controller!.setVolume(1.0);
          _controller!.setLooping(false);

          // Add a listener to track video position
          _controller!.addListener(_videoListener);

          // Wait a moment to ensure the seek completes
          Future.delayed(const Duration(milliseconds: 300), () {
            if (!mounted || _controller == null) return;

            debugPrint('▶️ SPLASH: Starting video from position zero');

            // Verify we're at the beginning
            final position = _controller!.value.position;
            debugPrint(
                '🔍 SPLASH: Initial position before play: ${position.inMilliseconds}ms');

            if (position.inMilliseconds > 10) {
              // If not at beginning, try seeking again
              debugPrint('⚠️ SPLASH: Not at beginning, seeking again');
              _controller!.seekTo(Duration.zero);
            }

            // Start playing
            _controller!.play().then((_) {
              debugPrint('▶️ SPLASH: Video playback started');

              // Wait a longer time to ensure playback has actually started
              Future.delayed(const Duration(milliseconds: 500), () {
                if (mounted && _controller != null) {
                  // Verify we're playing from the beginning
                  final currentPosition = _controller!.value.position;
                  debugPrint(
                      '🔍 SPLASH: Position after play delay: ${currentPosition.inMilliseconds}ms');

                  if (currentPosition.inMilliseconds < 700) {
                    // Only if we're in the proper beginning range of the video, reveal it
                    setState(() {
                      _readyToShowVideo = true;
                      _showLogo = false;
                    });
                    debugPrint(
                        '✅ SPLASH: Video revealed at ${currentPosition.inMilliseconds}ms');
                  } else {
                    // If somehow we're far into the video, show error
                    debugPrint(
                        '❌ SPLASH: Video not playing from beginning: ${currentPosition.inMilliseconds}ms');
                    setState(() {
                      _videoError = true;
                      _errorMessage = 'Video playback position incorrect';
                    });
                  }
                }
              });
            }).catchError((e) {
              debugPrint('❌ SPLASH: Error starting playback: $e');
            });
          });
        } else {
          debugPrint('⚠️ SPLASH: Video too short, using fallback');
          setState(() {
            _videoError = true;
            _errorMessage = 'Video too short';
          });
          _checkForTransition();
        }
      }).catchError((error) {
        if (!mounted) return;

        debugPrint('❌ SPLASH: Error loading video: $error');
        setState(() {
          _videoError = true;
          _errorMessage = 'Failed to load video: $error';
        });

        // Try to clean up
        _controller?.dispose();
        _controller = null;

        _checkForTransition();
      });
    } catch (e) {
      if (!mounted) return;

      debugPrint('💥 SPLASH: Video controller creation failed: $e');
      setState(() {
        _videoError = true;
        _errorMessage = 'Controller error: $e';
      });

      _checkForTransition();
    }
  }

  void _videoListener() {
    if (_controller == null) return;

    // Log position every second for debugging
    final position = _controller!.value.position;
    if (position.inSeconds % 1 == 0 && position.inMilliseconds > 0) {
      final duration = _controller!.value.duration;
      final progress = position.inMilliseconds / duration.inMilliseconds;
      debugPrint(
          '🎬 SPLASH: Video at ${position.inSeconds}s/${duration.inSeconds}s (${(progress * 100).toStringAsFixed(0)}%)');
    }

    // Check if video has finished
    if (_controller!.value.position >=
        _controller!.value.duration - const Duration(milliseconds: 200)) {
      debugPrint('🏁 SPLASH: Video completed');
      setState(() {
        _videoCompleted = true;
      });
      _checkForTransition();
    }
  }

  void _checkForTransition() {
    // Only proceed if we haven't started transitioning yet
    if (_transitionStarted) {
      debugPrint('⏯️ SPLASH: Transition already in progress, skipping');
      return;
    }

    // Check if navigation is already in progress
    if (_isNavigatingToMainScreen) {
      debugPrint('⏯️ SPLASH: Navigation to main screen already in progress');
      return;
    }

    // Only transition if minimum time has passed AND video has completed
    if (_minTimeElapsed && (_videoCompleted || _videoError)) {
      debugPrint(
          '🔄 SPLASH: Conditions met for transition: minTime=$_minTimeElapsed, videoCompleted=$_videoCompleted, videoError=$_videoError');

      // Mark that we've started the transition process
      setState(() {
        _transitionStarted = true;
      });

      // Set the static flag to prevent double navigation
      _isNavigatingToMainScreen = true;

      // Transition after a short delay to ensure smooth animation
      _transitionDelayTimer?.cancel();
      _transitionDelayTimer =
          Timer(const Duration(milliseconds: 800), _navigateToMainScreen);
    } else {
      // Log what conditions are missing
      final now = DateTime.now();
      final elapsed = now.difference(_startTime);

      if (!_minTimeElapsed) {
        final remaining = _minimumDuration - elapsed;
        debugPrint(
            '⏳ SPLASH: Waiting for minimum time: ${remaining.inSeconds}.${remaining.inMilliseconds % 1000}s remaining');
      }

      if (!_videoCompleted && !_videoError) {
        debugPrint('⏳ SPLASH: Waiting for video to complete');
      }
    }
  }

  void _navigateToMainScreen() {
    if (!mounted) return;

    // Check again if navigation is in progress (double safety)
    if (!_isNavigatingToMainScreen) {
      debugPrint('⚠️ SPLASH: Navigation flag not set, aborting navigation');
      return;
    }

    debugPrint('🏠 SPLASH: Navigating to main screen');

    // Cancel all timers before navigation
    _cancelAllTimers();

    // Restore system UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    // Use a simpler navigation without the black fade
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const MainScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 800),
      ),
    );
  }

  void _cancelAllTimers() {
    debugPrint('🧹 SPLASH: Cancelling all timers');
    _minimumDurationTimer?.cancel();
    _forcedTransitionTimer?.cancel();
    _videoTimeoutTimer?.cancel();
    _transitionDelayTimer?.cancel();

    // Reset static flag
    _isNavigatingToMainScreen = false;
  }

  @override
  void dispose() {
    debugPrint('🧹 SPLASH: Disposing resources');

    // Cancel all timers
    _cancelAllTimers();

    // Remove lifecycle observer
    WidgetsBinding.instance.removeObserver(this);

    // Clean up video resources
    if (_controller != null) {
      _controller!.removeListener(_videoListener);
      _controller!.dispose();
      _controller = null;
    }

    // Restore system UI mode
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // Prevent back button from exiting the splash screen
      onWillPop: () async => false,
      child: Scaffold(
        backgroundColor: const Color(0xFF9675CE),
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Solid background as base layer
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF9675CE),
              ),
            ),

            // Video layer - only shown if properly loaded and ready to show
            if (_videoInitialized && _controller != null)
              AnimatedOpacity(
                opacity: _readyToShowVideo ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Center(
                  child: AspectRatio(
                    aspectRatio: _controller!.value.aspectRatio,
                    child: Stack(
                      children: [
                        // The video
                        VideoPlayer(_controller!),

                        // Black overlay that fades out when video is ready
                        AnimatedOpacity(
                          opacity: _readyToShowVideo ? 0.0 : 1.0,
                          duration: const Duration(milliseconds: 300),
                          child: Container(
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Logo and title overlay - always visible until video is ready
            if (_showLogo || _videoError)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Animated bee icon
                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0.8, end: 1.0),
                      duration: const Duration(seconds: 2),
                      curve: Curves.easeInOut,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Icon(
                            Icons.emoji_nature,
                            color: Colors.amber.shade300,
                            size: 120,
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.5),
                                blurRadius: 15,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                        );
                      },
                      child: Icon(
                        Icons.emoji_nature,
                        color: Colors.amber.shade300,
                        size: 120,
                      ),
                    ),
                    const SizedBox(height: 30),
                    Text(
                      'BeeFlow',
                      style: TextStyle(
                        color: Colors.amber.shade300,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'stay in motion through the commotion',
                      style: TextStyle(
                        color: Colors.amber.shade300,
                        fontSize: 18,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 50),
                    // Show error message if there's an error
                    if (_videoError && _errorMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Text(
                          _errorMessage,
                          style: TextStyle(
                            color: Colors.amber.shade200,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    // Pulsing indicator
                    _buildPulsingIndicator(),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Create a pulsing loading indicator
  Widget _buildPulsingIndicator() {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.8, end: 1.2),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            width: 15,
            height: 15,
            decoration: BoxDecoration(
              color: Colors.amber.shade300,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.amber.shade300.withOpacity(0.5),
                  blurRadius: 10,
                  spreadRadius: 5,
                ),
              ],
            ),
          ),
        );
      },
      child: Container(),
    );
  }
}
