import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class Achievement {
  final String title;
  final String description;
  final String unlockCondition;
  final IconData icon;
  final Color color;
  bool isUnlocked;

  Achievement({
    required this.title,
    required this.description,
    required this.unlockCondition,
    required this.icon,
    required this.color,
    this.isUnlocked = false,
  });
}

class AchievementsScreen extends StatelessWidget {
  final List<Achievement> achievements = [
    Achievement(
      title: 'First Task',
      description: 'Complete your first task',
      unlockCondition: 'Unlocks after completing 1 task',
      icon: Icons.star,
      color: Colors.amber,
    ),
    Achievement(
      title: 'Streak Master',
      description: 'Maintain a 7-day streak',
      unlockCondition: 'Unlocks after maintaining a 7-day streak',
      icon: Icons.local_fire_department,
      color: Colors.orange,
    ),
    Achievement(
      title: 'Subtask Star',
      description: 'Complete 10 subtasks',
      unlockCondition: 'Unlocks after completing 10 subtasks',
      icon: Icons.check_circle_outline,
      color: Colors.blue,
    ),
    Achievement(
      title: 'AI Friend',
      description: 'Use AI breakdown on 5 tasks',
      unlockCondition: 'Unlocks after using AI breakdown on 5 tasks',
      icon: Icons.psychology,
      color: Colors.purple,
    ),
    Achievement(
      title: 'Speed Demon',
      description: 'Complete 3 tasks in the same session',
      unlockCondition: 'Unlocks after completing 3 tasks in the same session',
      icon: Icons.speed,
      color: Colors.red,
    ),
    Achievement(
      title: 'Task Master',
      description: 'Complete 50 total tasks',
      unlockCondition: 'Unlocks after completing 50 total tasks',
      icon: Icons.emoji_events,
      color: Colors.green,
    ),
    Achievement(
      title: 'Epic Warrior',
      description: 'Complete 10 epic difficulty tasks',
      unlockCondition: 'Unlocks after completing 10 epic difficulty tasks',
      icon: Icons.military_tech,
      color: Colors.deepPurple,
    ),
    Achievement(
      title: 'Daily Champion',
      description: 'Complete 5 tasks in a single day',
      unlockCondition: 'Unlocks after completing 5 tasks in a single day',
      icon: Icons.calendar_today,
      color: Colors.teal,
    ),
  ];

  AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Achievements',
          style: GoogleFonts.poppins(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black,
              Colors.grey[900]!,
            ],
          ),
        ),
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: achievements.length,
          itemBuilder: (context, index) {
            final achievement = achievements[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              color: Colors.grey[800],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: InkWell(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: Colors.grey[800],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                      title: Row(
                        children: [
                          Icon(
                            achievement.icon,
                            color: achievement.color,
                            size: 32,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            achievement.title,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            achievement.description,
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[700],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: Colors.amber[300],
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    achievement.unlockCondition,
                                    style: GoogleFonts.poppins(
                                      color: Colors.amber[300],
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(
                            'Close',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: achievement.color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          achievement.icon,
                          color: achievement.color,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              achievement.title,
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              achievement.description,
                              style: GoogleFonts.poppins(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: Colors.white54,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
