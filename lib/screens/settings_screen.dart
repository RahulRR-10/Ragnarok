import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/settings_provider.dart';
import '../models/settings.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/firebase_auth_service.dart';
import 'main_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return NavigationWrapper(
      initialIndex: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
          backgroundColor: Colors.deepPurple.shade800,
          foregroundColor: Colors.white,
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.amber.shade300,
            labelColor: Colors.amber.shade300,
            unselectedLabelColor: Colors.white70,
            tabs: const [
              Tab(icon: Icon(Icons.palette), text: 'Appearance'),
              Tab(icon: Icon(Icons.timer), text: 'Focus'),
              Tab(icon: Icon(Icons.account_circle), text: 'Account'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.help_outline),
              onPressed: () {
                // Show help dialog
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Help & Support'),
                    content: const SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Need help with BeeFlow?',
                              style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(height: 8),
                          Text('• Email: support@beeflow.app'),
                          Text('• Visit: help.beeflow.app'),
                          Text('• Discord: discord.gg/beeflow'),
                          SizedBox(height: 16),
                          Text('App Version: 1.0.0'),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        body: Consumer<SettingsProvider>(
          builder: (context, settingsProvider, child) {
            final settings = settingsProvider.settings;

            return TabBarView(
              controller: _tabController,
              children: [
                // Appearance Tab
                _buildAppearanceTab(context, settings, settingsProvider),

                // Focus Tab
                _buildFocusTab(context, settings, settingsProvider),

                // Account Tab
                _buildAccountTab(context),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAppearanceTab(BuildContext context, Settings settings,
      SettingsProvider settingsProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Theme selection with visual preview
          _buildSectionHeader('Theme'),
          _buildThemeSelector(settings, settingsProvider),
          const SizedBox(height: 24),

          // App colors
          _buildSectionHeader('Colors'),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Primary Color',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            const Text('Deep Purple'),
                          ],
                        ),
                      ),
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.deepPurple,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Accent Color',
                                style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            const Text('Amber'),
                          ],
                        ),
                      ),
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.amber.shade300,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Font size and more
          _buildSectionHeader('Text'),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Font Size'),
                  subtitle: const Text('Medium'),
                  trailing: DropdownButton<String>(
                    value: 'medium',
                    underline: Container(),
                    items: const [
                      DropdownMenuItem(value: 'small', child: Text('Small')),
                      DropdownMenuItem(value: 'medium', child: Text('Medium')),
                      DropdownMenuItem(value: 'large', child: Text('Large')),
                    ],
                    onChanged: (value) {
                      // TODO: Implement font size change
                    },
                  ),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Bold Text'),
                  value: false,
                  onChanged: (value) {
                    // TODO: Implement bold text toggle
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Animation settings
          _buildSectionHeader('Animations'),
          Card(
            child: SwitchListTile(
              title: const Text('Confetti Animations'),
              subtitle: const Text('Show celebration animations'),
              value: true,
              onChanged: (value) {
                // TODO: Implement animation toggle
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFocusTab(BuildContext context, Settings settings,
      SettingsProvider settingsProvider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Focus Timer
          _buildSectionHeader('Pomodoro Timer'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.work, color: Colors.deepPurple),
                  title: const Text('Work Duration'),
                  subtitle: Text('${settings.workDuration} minutes'),
                  trailing: DropdownButton<int>(
                    value: settings.workDuration,
                    underline: Container(),
                    items: [15, 25, 30, 45, 60].map((duration) {
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
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.coffee, color: Colors.amber),
                  title: const Text('Short Break Duration'),
                  subtitle: Text('${settings.shortBreakDuration} minutes'),
                  trailing: DropdownButton<int>(
                    value: settings.shortBreakDuration,
                    underline: Container(),
                    items: [5, 10, 15].map((duration) {
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
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.weekend, color: Colors.green),
                  title: const Text('Long Break Duration'),
                  subtitle: Text('${settings.longBreakDuration} minutes'),
                  trailing: DropdownButton<int>(
                    value: settings.longBreakDuration,
                    underline: Container(),
                    items: [15, 20, 25, 30].map((duration) {
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
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Auto-Start Breaks'),
                  subtitle: const Text(
                      'Automatically start breaks after work sessions'),
                  value: false,
                  onChanged: (value) {
                    // TODO: Implement auto-start breaks
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Notifications
          _buildSectionHeader('Notifications'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Mute Notifications'),
                  subtitle: const Text('During focus mode'),
                  value: settings.muteNotifications,
                  onChanged: (value) {
                    settingsProvider.toggleNotifications(value);
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Timer Alert'),
                  subtitle: const Text('Sound alert when timer ends'),
                  value: true,
                  onChanged: (value) {
                    // TODO: Implement timer alert
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Sound Settings
          _buildSectionHeader('Sound'),
          Card(
            child: Column(
              children: [
                ExpansionTile(
                  title: const Text('White Noise'),
                  leading: Icon(
                    settings.playWhiteNoise
                        ? Icons.volume_up
                        : Icons.volume_off,
                    color: settings.playWhiteNoise
                        ? Colors.deepPurple
                        : Colors.grey,
                  ),
                  trailing: Switch(
                    value: settings.playWhiteNoise,
                    activeColor: Colors.deepPurple,
                    onChanged: (value) {
                      settingsProvider.toggleWhiteNoise(value);
                    },
                  ),
                  children: settings.playWhiteNoise
                      ? [
                          ListTile(
                            title: const Text('Sound Type'),
                            trailing: DropdownButton<String>(
                              value: settings.whiteNoiseType,
                              underline: Container(),
                              items: const [
                                DropdownMenuItem(
                                    value: 'rain', child: Text('Rain')),
                                DropdownMenuItem(
                                    value: 'waves', child: Text('Waves')),
                                DropdownMenuItem(
                                    value: 'forest', child: Text('Forest')),
                                DropdownMenuItem(
                                    value: 'cafe', child: Text('Cafe')),
                                DropdownMenuItem(
                                    value: 'fire', child: Text('Fireplace')),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  settingsProvider.updateWhiteNoiseType(value);
                                }
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: Row(
                              children: [
                                const Icon(Icons.volume_down, size: 20),
                                Expanded(
                                  child: Slider(
                                    value: settings.whiteNoiseVolume,
                                    onChanged: (value) {
                                      settingsProvider
                                          .updateWhiteNoiseVolume(value);
                                    },
                                    activeColor: Colors.deepPurple,
                                  ),
                                ),
                                const Icon(Icons.volume_up, size: 20),
                              ],
                            ),
                          ),
                        ]
                      : [],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountTab(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Card
          Card(
            margin: const EdgeInsets.only(bottom: 24),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.amber.shade300,
                    child: Text(
                      user?.displayName?.isNotEmpty == true
                          ? user!.displayName![0].toUpperCase()
                          : (user?.email?.isNotEmpty == true
                              ? user!.email![0].toUpperCase()
                              : 'B'),
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple.shade900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.displayName ?? 'BeeFlow User',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    user?.email ?? '',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit Profile'),
                    onPressed: () {
                      // TODO: Navigate to profile editing screen
                    },
                  ),
                ],
              ),
            ),
          ),

          // Account Settings
          _buildSectionHeader('Account Settings'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.sync, color: Colors.deepPurple),
                  title: const Text('Data Sync'),
                  subtitle: const Text('Sync your data across devices'),
                  trailing: Switch(
                    value: true,
                    activeColor: Colors.deepPurple,
                    onChanged: (value) {
                      // TODO: Implement data sync toggle
                    },
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.backup, color: Colors.deepPurple),
                  title: const Text('Backup Data'),
                  subtitle: const Text('Create a cloud backup of your data'),
                  onTap: () {
                    // TODO: Implement backup functionality
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Backup started')),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.restore, color: Colors.deepPurple),
                  title: const Text('Restore Data'),
                  subtitle: const Text('Restore from a cloud backup'),
                  onTap: () {
                    // TODO: Implement restore functionality
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Restore Data'),
                        content: const Text(
                            'This will replace your current data with your last backup. Continue?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('Restore completed')),
                              );
                            },
                            child: const Text('Restore'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // App Settings
          _buildSectionHeader('API Keys'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Gemini API Key',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Enter your Gemini API key to enable AI-powered task breakdowns.',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'API Key',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.save),
                        onPressed: () {
                          // TODO: Save API key
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('API key saved')),
                          );
                        },
                      ),
                    ),
                    obscureText: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Danger Zone
          _buildSectionHeader('Danger Zone', color: Colors.red),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.delete_forever, color: Colors.red),
                  title: const Text('Clear All Data'),
                  subtitle: const Text('Delete all your tasks and settings'),
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Clear All Data'),
                        content: const Text(
                            'This will permanently delete all your tasks and settings. This action cannot be undone.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            onPressed: () {
                              // TODO: Implement data clearing
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text('All data cleared')),
                              );
                            },
                            child: const Text('Clear Data'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.red),
                  title: const Text('Logout'),
                  subtitle: const Text('Sign out of your account'),
                  onTap: () async {
                    final confirmed = await showDialog<bool>(
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
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Logout'),
                          ),
                        ],
                      ),
                    );

                    if (confirmed == true && context.mounted) {
                      try {
                        await FirebaseAuth.instance.signOut();
                        Navigator.pushReplacementNamed(context, '/login');
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error logging out: $e')),
                          );
                        }
                      }
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),

          // App Info
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade300,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.emoji_nature,
                    size: 30,
                    color: Colors.deepPurple.shade900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text('BeeFlow v1.0.0'),
                Text(
                  '© 2024 BeeFlow',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, {Color color = Colors.deepPurple}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _buildThemeSelector(
      Settings settings, SettingsProvider settingsProvider) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildThemeOption(
              title: 'Light',
              icon: Icons.light_mode,
              isSelected: settings.theme == 'light',
              onTap: () => settingsProvider.updateTheme('light'),
              preview: Container(
                width: 50,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 30,
                      height: 10,
                      color: Colors.deepPurple,
                    ),
                    const SizedBox(height: 5),
                    Container(
                      width: 30,
                      height: 30,
                      color: Colors.grey.shade200,
                    ),
                  ],
                ),
              ),
            ),
            _buildThemeOption(
              title: 'Dark',
              icon: Icons.dark_mode,
              isSelected: settings.theme == 'dark',
              onTap: () => settingsProvider.updateTheme('dark'),
              preview: Container(
                width: 50,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 30,
                      height: 10,
                      color: Colors.deepPurple.shade300,
                    ),
                    const SizedBox(height: 5),
                    Container(
                      width: 30,
                      height: 30,
                      color: Colors.grey.shade800,
                    ),
                  ],
                ),
              ),
            ),
            _buildThemeOption(
              title: 'System',
              icon: Icons.auto_awesome,
              isSelected: settings.theme == 'system',
              onTap: () => settingsProvider.updateTheme('system'),
              preview: Container(
                width: 50,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: LinearGradient(
                    colors: [Colors.white, Colors.grey.shade900],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Icon(
                    Icons.devices,
                    color: Colors.amber.shade300,
                    size: 24,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
    required Widget preview,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          preview,
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.deepPurple : null,
            ),
          ),
          Icon(
            Icons.check_circle,
            color: isSelected ? Colors.deepPurple : Colors.transparent,
            size: 16,
          ),
        ],
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
