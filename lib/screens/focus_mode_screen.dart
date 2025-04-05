import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:async';
import 'package:just_audio/just_audio.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'main_screen.dart';

class FocusModeScreen extends StatefulWidget {
  const FocusModeScreen({super.key});

  @override
  State<FocusModeScreen> createState() => _FocusModeScreenState();
}

class _FocusModeScreenState extends State<FocusModeScreen>
    with SingleTickerProviderStateMixin {
  final audioPlayer = AudioPlayer();
  Timer? _timer;
  int _timeLeft = 0;
  bool _isRunning = false;
  bool _isTimerActive = false;
  String _selectedSound = 'none';
  double _volume = 0.5;
  int _selectedDuration = 25;
  final TextEditingController _customDurationController =
      TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  final Map<String, String> _soundAssets = {
    'white_noise': 'assets/audio/white_noise.mp3',
    'forest': 'assets/audio/forest.mp3',
    'ocean': 'assets/audio/ocean.mp3',
    'rain': 'assets/audio/rain.mp3',
  };

  @override
  void initState() {
    super.initState();
    _initializeAudio();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initializeAudio() async {
    await audioPlayer.setAsset('assets/white_noise.mp3');
    await audioPlayer.setLoopMode(LoopMode.one);
  }

  void _startTimer() {
    setState(() {
      _isTimerActive = true;
      _isRunning = true;
      if (_timeLeft == 0) {
        _timeLeft = _selectedDuration * 60;
      }
    });

    _animationController.forward();

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
        } else {
          _stopTimer();
          _showCompletionDialog();
        }
      });
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() {
      _isRunning = false;
      _isTimerActive = false;
      _timeLeft = 0;
    });
    _animationController.reverse();
  }

  void _resetTimer() {
    _timer?.cancel();
    setState(() {
      _timeLeft = _selectedDuration * 60;
      _isRunning = false;
    });
  }

  void _showCustomDurationPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Custom Duration',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple.shade800,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _customDurationController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      color: Colors.deepPurple.shade800,
                      fontWeight: FontWeight.w500,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter minutes',
                      hintStyle: TextStyle(
                        color: Colors.deepPurple.shade300,
                        fontSize: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    final duration =
                        int.tryParse(_customDurationController.text);
                    if (duration != null && duration > 0) {
                      setState(() {
                        _selectedDuration = duration;
                        _timeLeft = duration * 60;
                      });
                      Navigator.pop(context);
                      _startTimer();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade300,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 15,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: Text(
                    'Start',
                    style: TextStyle(
                      color: Colors.deepPurple.shade800,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Focus Session Complete!'),
        content: const Text('Great job staying focused! Take a short break.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _stopTimer();
            },
            child: const Text('Done'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _resetTimer();
              _startTimer();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber.shade300,
            ),
            child: Text(
              'Start New Session',
              style: TextStyle(color: Colors.deepPurple.shade800),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _playSound(String soundName) async {
    if (_selectedSound == soundName) {
      await audioPlayer.stop();
      setState(() {
        _selectedSound = 'none';
      });
    } else {
      final soundPath = _soundAssets[soundName];
      if (soundPath != null) {
        await audioPlayer.stop();
        await audioPlayer.setAsset(soundPath);
        await audioPlayer.setVolume(_volume);
        await audioPlayer.play();
        setState(() {
          _selectedSound = soundName;
        });
      }
    }
  }

  String _formatTime(int seconds) {
    int minutes = seconds ~/ 60;
    int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    audioPlayer.dispose();
    _customDurationController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NavigationWrapper(
      initialIndex: 1,
      child: Scaffold(
        appBar: _isTimerActive
            ? null
            : AppBar(
                title: const Text('Focus Mode'),
                backgroundColor: Colors.deepPurple.shade600,
              ),
        body: Stack(
          children: [
            if (!_isTimerActive)
              FadeTransition(
                opacity: _fadeAnimation,
                child: Container(
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
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.psychology,
                                  size: 40,
                                  color: Colors.amber.shade300,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  '"Focus on the journey, not the destination. Joy is found not in finishing an activity but in doing it."',
                                  style: GoogleFonts.lato(
                                    fontSize: 16,
                                    fontStyle: FontStyle.italic,
                                    color: const Color(0xFFFFD700),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  '- Greg Anderson',
                                  style: TextStyle(
                                    color: Color(0xFFFFD700),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildPresetTimers(),
                        const SizedBox(height: 24),
                        _buildSoundSelector(),
                        const SizedBox(height: 16),
                        _buildSpotifyWidget(),
                      ],
                    ),
                  ),
                ),
              ),
            if (_isTimerActive)
              Container(
                color: Colors.black,
                child: Center(
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.85,
                    height: MediaQuery.of(context).size.width * 0.85,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.deepPurple.shade600,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.deepPurple.shade200.withOpacity(0.5),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.85,
                          height: MediaQuery.of(context).size.width * 0.85,
                          child: CircularProgressIndicator(
                            value: _timeLeft / (_selectedDuration * 60),
                            strokeWidth: 8,
                            backgroundColor:
                                Colors.deepPurple.shade300.withOpacity(0.3),
                            color: Colors.amber.shade300,
                          ),
                        ),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _formatTime(_timeLeft),
                              style: GoogleFonts.robotoMono(
                                fontSize: 72,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Icon(
                              Icons.emoji_nature,
                              size: 40,
                              color: Colors.amber.shade300,
                            ),
                            const SizedBox(height: 30),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    _isRunning
                                        ? Icons.pause_circle
                                        : Icons.play_circle,
                                    size: 56,
                                    color: Colors.white,
                                  ),
                                  onPressed:
                                      _isRunning ? _pauseTimer : _startTimer,
                                ),
                                const SizedBox(width: 24),
                                IconButton(
                                  icon: const Icon(
                                    Icons.stop_circle,
                                    size: 56,
                                    color: Colors.white,
                                  ),
                                  onPressed: _stopTimer,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetTimers() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose Duration',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.amber[300],
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildTimeButton(5),
                _buildTimeButton(10),
                _buildTimeButton(25),
                _buildCustomTimeButton(),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeButton(int minutes) {
    final isSelected = minutes == _selectedDuration && !_isTimerActive;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDuration = minutes;
          _timeLeft = minutes * 60;
        });
        _startTimer();
      },
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: isSelected ? Colors.amber.shade300 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(15),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.amber.shade200.withOpacity(0.5),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$minutes',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? Colors.deepPurple.shade800
                    : Colors.grey.shade700,
              ),
            ),
            Text(
              'min',
              style: TextStyle(
                fontSize: 12,
                color: isSelected
                    ? Colors.deepPurple.shade800
                    : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomTimeButton() {
    return GestureDetector(
      onTap: _showCustomDurationPicker,
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add,
              size: 24,
              color: Colors.grey.shade700,
            ),
            Text(
              'Custom',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSoundSelector() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Background Sounds',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.amber[300],
              ),
            ),
            const SizedBox(height: 20),
            GridView.count(
              shrinkWrap: true,
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildSoundButton('white_noise', 'White Noise', Icons.waves),
                _buildSoundButton('forest', 'Forest', Icons.forest),
                _buildSoundButton('ocean', 'Ocean', Icons.water),
                _buildSoundButton('rain', 'Rain', Icons.water_drop),
              ],
            ),
            if (_selectedSound != 'none') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(
                    Icons.volume_down,
                    color: Colors.amber[300],
                  ),
                  Expanded(
                    child: Slider(
                      value: _volume,
                      onChanged: (value) {
                        setState(() {
                          _volume = value;
                          audioPlayer.setVolume(_volume);
                        });
                      },
                      activeColor: Colors.amber[300],
                    ),
                  ),
                  Icon(
                    Icons.volume_up,
                    color: Colors.amber[300],
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSoundButton(String soundName, String label, IconData icon) {
    final isSelected = soundName == _selectedSound;
    return GestureDetector(
      onTap: () => _playSound(soundName),
      child: Container(
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    Colors.amber.shade300,
                    Colors.amber.shade400,
                  ],
                )
              : LinearGradient(
                  colors: [
                    Colors.grey.shade100,
                    Colors.grey.shade200,
                  ],
                ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.amber.shade200.withOpacity(0.5),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: isSelected
                  ? Colors.deepPurple.shade800
                  : Colors.grey.shade700,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? Colors.deepPurple.shade800
                    : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpotifyWidget() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                FaIcon(
                  FontAwesomeIcons.spotify,
                  color: Colors.amber[300],
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'Spotify',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber[300],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: Implement Spotify integration
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Spotify integration coming soon!'),
                    ),
                  );
                },
                icon:
                    FaIcon(FontAwesomeIcons.spotify, color: Colors.amber[300]),
                label: Text(
                  'Connect Spotify',
                  style: TextStyle(color: Colors.amber[300]),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple.shade800,
                  foregroundColor: Colors.amber[300],
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
