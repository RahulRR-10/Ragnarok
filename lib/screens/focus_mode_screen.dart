import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import '../models/settings.dart';
import '../providers/settings_provider.dart';
import '../providers/task_provider.dart';

class FocusModeScreen extends StatefulWidget {
  const FocusModeScreen({super.key});

  @override
  State<FocusModeScreen> createState() => _FocusModeScreenState();
}

class _FocusModeScreenState extends State<FocusModeScreen> {
  Timer? _timer;
  int _secondsRemaining = 25 * 60;
  bool _isRunning = false;
  bool _isBreak = false;
  int _completedSessions = 0;
  final AudioPlayer _audioPlayer = AudioPlayer();
  String _currentMode = 'Focus';

  @override
  void initState() {
    super.initState();
    _initializeAudio();
  }

  Future<void> _initializeAudio() async {
    await _audioPlayer.setAsset('assets/white_noise.mp3');
    await _audioPlayer.setLoopMode(LoopMode.one);
  }

  void _startTimer() {
    setState(() {
      _isRunning = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
        } else {
          _timer?.cancel();
          _isRunning = false;
          _completedSessions++;
          _onSessionComplete();
        }
      });
    });

    final settings =
        Provider.of<SettingsProvider>(context, listen: false).settings;
    if (settings.playWhiteNoise) {
      _audioPlayer.play();
    }
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
    });
    _audioPlayer.pause();
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _secondsRemaining = _isBreak ? 5 * 60 : 25 * 60;
      _isRunning = false;
    });
    _audioPlayer.pause();
  }

  void _onSessionComplete() {
    setState(() {
      _isBreak = !_isBreak;
      _secondsRemaining = _isBreak ? 5 * 60 : 25 * 60;
    });
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF2196F3),
              Color(0xFF1976D2),
            ],
          ),
        ),
        child: SafeArea(
          child: Consumer<SettingsProvider>(
            builder: (context, settingsProvider, child) {
              final settings = settingsProvider.settings;
              return Column(
                children: [
                  _buildHeader(),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildModeSelector(),
                          const SizedBox(height: 32),
                          _buildTimer(),
                          const SizedBox(height: 32),
                          _buildControls(),
                          const SizedBox(height: 32),
                          _buildSessionInfo(),
                          const SizedBox(height: 32),
                          _buildWhiteNoiseControls(settings),
                        ],
                      ),
                    ),
                  ),
                  _buildBottomNavigation(),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () {},
          ),
          const Expanded(
            child: Text(
              'Focus Mode',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildModeSelector() {
    return Card(
      elevation: 0,
      color: Colors.white.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildModeButton('Short Break', _isBreak),
            _buildModeButton('Focus', !_isBreak),
          ],
        ),
      ),
    );
  }

  Widget _buildModeButton(String mode, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: TextButton(
        onPressed: () {
          setState(() {
            _isBreak = mode == 'Short Break';
            _secondsRemaining = _isBreak ? 5 * 60 : 25 * 60;
          });
        },
        style: TextButton.styleFrom(
          backgroundColor: isSelected ? Colors.white.withOpacity(0.2) : null,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
        child: Text(
          mode,
          style: TextStyle(
            color: Colors.white,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildTimer() {
    return Column(
      children: [
        Text(
          _formatTime(_secondsRemaining),
          style: TextStyle(
            fontSize: 72,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isBreak ? 'Break Time' : 'Focus Time',
          style: TextStyle(
            fontSize: 20,
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(Icons.refresh, color: Colors.white, size: 32),
          onPressed: _resetTimer,
        ),
        const SizedBox(width: 24),
        FloatingActionButton(
          onPressed: _isRunning ? _pauseTimer : _startTimer,
          backgroundColor: Colors.white,
          child: Icon(
            _isRunning ? Icons.pause : Icons.play_arrow,
            color: Colors.blue[700],
            size: 32,
          ),
        ),
      ],
    );
  }

  Widget _buildSessionInfo() {
    return Card(
      elevation: 0,
      color: Colors.white.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Sessions Completed',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _completedSessions.toString(),
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWhiteNoiseControls(Settings settings) {
    return Card(
      elevation: 0,
      color: Colors.white.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'White Noise',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Switch(
                  value: settings.playWhiteNoise,
                  onChanged: (value) async {
                    await Provider.of<SettingsProvider>(context, listen: false)
                        .toggleWhiteNoise(value);
                    if (value && _isRunning) {
                      _audioPlayer.play();
                    } else {
                      _audioPlayer.pause();
                    }
                  },
                  activeColor: Colors.white,
                ),
              ],
            ),
            if (settings.playWhiteNoise) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.volume_down, color: Colors.white),
                  Expanded(
                    child: Slider(
                      value: settings.whiteNoiseVolume,
                      onChanged: (value) async {
                        await Provider.of<SettingsProvider>(context,
                                listen: false)
                            .updateWhiteNoiseVolume(value);
                        _audioPlayer.setVolume(value);
                      },
                      activeColor: Colors.white,
                    ),
                  ),
                  Icon(Icons.volume_up, color: Colors.white),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/progress');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                'View Progress',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/tasks');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.blue[700],
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text(
                'My Tasks',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
