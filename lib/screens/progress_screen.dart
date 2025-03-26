import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../models/task.dart';
import 'main_screen.dart';

class ProgressScreen extends StatelessWidget {
  const ProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return NavigationWrapper(
      initialIndex: 2,
      child: Consumer<TaskProvider>(
        builder: (context, taskProvider, child) {
          final totalXP = taskProvider.totalXP;
          final currentLevel = taskProvider.currentLevel;
          final levelTitle = taskProvider.getLevelTitle(currentLevel);
          final levelProgress = taskProvider.getLevelProgress();
          final xpToNextLevel = taskProvider.getXPToNextLevel();
          final todayXP = taskProvider.getTodayXP();
          final achievements = taskProvider.checkAchievements();

          return Scaffold(
            body: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                  ],
                ),
              ),
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context),
                      const SizedBox(height: 24),
                      _buildLevelCard(context, levelTitle, currentLevel,
                          levelProgress, xpToNextLevel),
                      const SizedBox(height: 24),
                      _buildStatsGrid(
                          context, totalXP, todayXP, taskProvider.streak),
                      const SizedBox(height: 24),
                      _buildAchievements(context, achievements),
                      const SizedBox(height: 24),
                      _buildRecentTasks(context, taskProvider.tasks),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Progress',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () {
            // Refresh progress
          },
        ),
      ],
    );
  }

  Widget _buildLevelCard(
    BuildContext context,
    String levelTitle,
    int currentLevel,
    double progress,
    int xpToNextLevel,
  ) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      levelTitle,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                    ),
                    Text(
                      'Level $currentLevel',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.star,
                    color: Theme.of(context).colorScheme.primary,
                    size: 32,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: progress,
              backgroundColor:
                  Theme.of(context).colorScheme.primary.withOpacity(0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
              minHeight: 8,
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$xpToNextLevel XP to next level',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                ),
                Text(
                  '${(progress * 100).round()}%',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsGrid(
      BuildContext context, int totalXP, int todayXP, int streak) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: [
        _buildStatCard(
          context,
          'Total XP',
          totalXP.toString(),
          Icons.star,
          Theme.of(context).colorScheme.primary,
        ),
        _buildStatCard(
          context,
          'Today\'s XP',
          todayXP.toString(),
          Icons.today,
          Theme.of(context).colorScheme.secondary,
        ),
        _buildStatCard(
          context,
          'Streak',
          '$streak days',
          Icons.local_fire_department,
          Colors.orange,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievements(
      BuildContext context, Map<String, bool> achievements) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Achievements',
            style: TextStyle(
              color: Colors.amber[300],
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemCount: achievements.length,
          itemBuilder: (context, index) {
            final achievement = achievements.keys.elementAt(index);
            final isUnlocked = achievements[achievement]!;
            final data = _getAchievementData(achievement);

            return Card(
              color: isUnlocked ? Colors.amber[100] : Colors.grey[800],
              child: InkWell(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Row(
                        children: [
                          Icon(data['icon'] as IconData,
                              color:
                                  isUnlocked ? Colors.amber[700] : Colors.grey),
                          const SizedBox(width: 8),
                          Text(data['title'] as String),
                        ],
                      ),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isUnlocked
                                ? 'Congratulations! You\'ve unlocked this achievement!'
                                : 'Keep working to unlock this achievement.',
                            style: TextStyle(
                              color: isUnlocked
                                  ? Colors.amber[900]
                                  : Colors.grey[600],
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
                                    data['unlockCondition'] as String,
                                    style: TextStyle(
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
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      data['icon'] as IconData,
                      size: 32,
                      color: isUnlocked ? Colors.amber[700] : Colors.grey,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      data['title'] as String,
                      style: TextStyle(
                        color:
                            isUnlocked ? Colors.amber[900] : Colors.grey[600],
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Map<String, dynamic> _getAchievementData(String achievement) {
    switch (achievement) {
      case 'first_task':
        return {
          'icon': Icons.check_circle,
          'title': 'First Task',
          'unlockCondition': 'Unlocks after completing 1 task',
        };
      case 'streak_master':
        return {
          'icon': Icons.local_fire_department,
          'title': 'Streak Master',
          'unlockCondition': 'Unlocks after maintaining a 7-day streak',
        };
      case 'subtask_star':
        return {
          'icon': Icons.star,
          'title': 'Subtask Star',
          'unlockCondition': 'Unlocks after completing 10 subtasks',
        };
      case 'ai_friend':
        return {
          'icon': Icons.psychology,
          'title': 'AI Friend',
          'unlockCondition': 'Unlocks after using AI breakdown on 5 tasks',
        };
      case 'speed_demon':
        return {
          'icon': Icons.speed,
          'title': 'Speed Demon',
          'unlockCondition':
              'Unlocks after completing 3 tasks in the same session',
        };
      case 'task_master':
        return {
          'icon': Icons.emoji_events,
          'title': 'Task Master',
          'unlockCondition': 'Unlocks after completing 50 total tasks',
        };
      case 'epic_warrior':
        return {
          'icon': Icons.auto_awesome,
          'title': 'Epic Warrior',
          'unlockCondition':
              'Unlocks after completing 10 epic difficulty tasks',
        };
      case 'daily_champion':
        return {
          'icon': Icons.celebration,
          'title': 'Daily Champion',
          'unlockCondition': 'Unlocks after completing 5 tasks in a single day',
        };
      default:
        return {
          'icon': Icons.help,
          'title': 'Unknown',
          'unlockCondition': 'Unknown unlock condition',
        };
    }
  }

  Widget _buildRecentTasks(BuildContext context, List<Task> tasks) {
    final recentTasks =
        tasks.where((task) => task.isCompleted).take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Tasks',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: recentTasks.length,
          itemBuilder: (context, index) {
            final task = recentTasks[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: task.getDifficultyColor().withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    task.getDifficultyIcon(),
                    color: task.getDifficultyColor(),
                  ),
                ),
                title: Text(
                  task.title,
                  style: const TextStyle(
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                subtitle: Text(
                  '${task.xpEarned} XP',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
                trailing: Text(
                  '${task.completedAt?.day}/${task.completedAt?.month}/${task.completedAt?.year}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
