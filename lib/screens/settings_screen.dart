import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Consumer<SettingsProvider>(
        builder: (context, settingsProvider, child) {
          final settings = settingsProvider.settings;

          return ListView(
            children: [
              ListTile(
                title: const Text('Theme'),
                subtitle: Text(settings.theme.capitalize()),
                trailing: DropdownButton<String>(
                  value: settings.theme,
                  items: const [
                    DropdownMenuItem(value: 'system', child: Text('System')),
                    DropdownMenuItem(value: 'light', child: Text('Light')),
                    DropdownMenuItem(value: 'dark', child: Text('Dark')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      settingsProvider.updateTheme(value);
                    }
                  },
                ),
              ),
              const Divider(),
              ListTile(
                title: const Text('Work Duration'),
                subtitle: Text('${settings.workDuration} minutes'),
                trailing: DropdownButton<int>(
                  value: settings.workDuration,
                  items:
                      [15, 25, 30, 45, 60].map((duration) {
                        return DropdownMenuItem(
                          value: duration,
                          child: Text('$duration min'),
                        );
                      }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      settingsProvider.updateWorkDuration(value);
                    }
                  },
                ),
              ),
              ListTile(
                title: const Text('Short Break Duration'),
                subtitle: Text('${settings.shortBreakDuration} minutes'),
                trailing: DropdownButton<int>(
                  value: settings.shortBreakDuration,
                  items:
                      [5, 10, 15].map((duration) {
                        return DropdownMenuItem(
                          value: duration,
                          child: Text('$duration min'),
                        );
                      }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      settingsProvider.updateShortBreakDuration(value);
                    }
                  },
                ),
              ),
              ListTile(
                title: const Text('Long Break Duration'),
                subtitle: Text('${settings.longBreakDuration} minutes'),
                trailing: DropdownButton<int>(
                  value: settings.longBreakDuration,
                  items:
                      [15, 20, 25, 30].map((duration) {
                        return DropdownMenuItem(
                          value: duration,
                          child: Text('$duration min'),
                        );
                      }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      settingsProvider.updateLongBreakDuration(value);
                    }
                  },
                ),
              ),
              const Divider(),
              SwitchListTile(
                title: const Text('Mute Notifications'),
                subtitle: const Text('During focus mode'),
                value: settings.muteNotifications,
                onChanged: (value) {
                  settingsProvider.toggleNotifications(value);
                },
              ),
              SwitchListTile(
                title: const Text('White Noise'),
                subtitle: const Text('Play during focus mode'),
                value: settings.playWhiteNoise,
                onChanged: (value) {
                  settingsProvider.toggleWhiteNoise(value);
                },
              ),
              if (settings.playWhiteNoise) ...[
                ListTile(
                  title: const Text('White Noise Type'),
                  subtitle: Text(settings.whiteNoiseType.capitalize()),
                  trailing: DropdownButton<String>(
                    value: settings.whiteNoiseType,
                    items: const [
                      DropdownMenuItem(value: 'rain', child: Text('Rain')),
                      DropdownMenuItem(value: 'waves', child: Text('Waves')),
                      DropdownMenuItem(value: 'forest', child: Text('Forest')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        settingsProvider.updateWhiteNoiseType(value);
                      }
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      const Icon(Icons.volume_down),
                      Expanded(
                        child: Slider(
                          value: settings.whiteNoiseVolume,
                          onChanged: (value) {
                            settingsProvider.updateWhiteNoiseVolume(value);
                          },
                        ),
                      ),
                      const Icon(Icons.volume_up),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
