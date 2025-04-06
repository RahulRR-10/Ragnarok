import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/task_provider.dart';
import '../models/task.dart';
import 'main_screen.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  Future<void> _refreshData() async {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    await taskProvider.refreshProgressFromFirebase();

    // Show feedback
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Progress data refreshed'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    // Refresh data when screen loads
    Future.microtask(() async {
      final taskProvider = Provider.of<TaskProvider>(context, listen: false);
      await taskProvider.refreshProgressFromFirebase();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // This ensures progress data is refreshed whenever the screen becomes visible
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    taskProvider.refreshProgressFromFirebase();
  }

  @override
  Widget build(BuildContext context) {
    return NavigationWrapper(
      initialIndex: 2,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.deepPurple.shade300,
                Colors.deepPurple.shade600,
              ],
            ),
          ),
          child: Consumer<TaskProvider>(
            builder: (context, taskProvider, child) {
              final totalXP = taskProvider.totalXP;
              final currentLevel = taskProvider.currentLevel;
              final levelTitle = taskProvider.getLevelTitle(currentLevel);
              final levelProgress = taskProvider.getLevelProgress();
              final xpToNextLevel = taskProvider.getXPToNextLevel();
              final todayXP = taskProvider.getTodayXP();
              final achievements = taskProvider.checkAchievements();
              final streak = taskProvider.streak;

              return SafeArea(
                child: taskProvider.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        key: _refreshIndicatorKey,
                        onRefresh: _refreshData,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
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
                                  context, totalXP, todayXP, streak),
                              const SizedBox(height: 24),
                              _buildAchievements(context, achievements),
                              const SizedBox(height: 24),
                              _buildRecentTasks(context, taskProvider.tasks),
                            ],
                          ),
                        ),
                      ),
              );
            },
          ),
        ),
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
                color: Colors.amber[300],
              ),
        ),
        Row(
          children: [
            // Force refresh button with improved feedback
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Force Refresh Progress',
              onPressed: () {
                _refreshIndicatorKey.currentState?.show();
              },
            ),
          ],
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
                            color: Colors.amber[300],
                          ),
                    ),
                    Text(
                      'Level $currentLevel',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.amber[300],
                          ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber[100],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.star,
                    color: Colors.amber[700],
                    size: 32,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.amber[100],
              valueColor: AlwaysStoppedAnimation<Color>(
                Colors.amber[700]!,
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
                        color: Colors.amber[300],
                      ),
                ),
                Text(
                  '${(progress * 100).round()}%',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.amber[700],
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
    // Special formatting for streak display
    String streakDisplay;
    if (streak <= 0) {
      streakDisplay = "Start today!";
    } else if (streak == 1) {
      streakDisplay = "1 day";
    } else {
      streakDisplay = "$streak days";
    }

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
          _formatXP(totalXP),
          Icons.star,
          Colors.amber[300]!,
        ),
        _buildStatCard(
          context,
          'Today\'s XP',
          _formatXP(todayXP),
          Icons.today,
          Colors.amber[300]!,
        ),
        _buildStatCard(
          context,
          'Streak',
          streakDisplay,
          Icons.local_fire_department,
          Colors.amber[300]!,
        ),
      ],
    );
  }

  String _formatXP(int xp) {
    if (xp >= 1000) {
      final thousands = (xp / 1000).toStringAsFixed(1);
      return '${thousands}k';
    }
    return xp.toString();
  }

  Widget _buildStatCard(BuildContext context, String title, String value,
      IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: color,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                  ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievements(
      BuildContext context, Map<String, bool> achievements) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Achievements',
            style: TextStyle(
              color: Colors.amber[300],
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.2,
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
                          Expanded(
                            child: Text(
                              data['title'] as String,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
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
                      size: 24,
                      color: isUnlocked ? Colors.amber[700] : Colors.grey,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data['title'] as String,
                      style: TextStyle(
                        color:
                            isUnlocked ? Colors.amber[900] : Colors.grey[600],
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
      case 'xp_master':
        return {
          'icon': Icons.workspace_premium,
          'title': 'XP Master',
          'unlockCondition': 'Unlocks after earning 1000 total XP',
        };
      case 'quick_completer':
        return {
          'icon': Icons.timer,
          'title': 'Quick Completer',
          'unlockCondition':
              'Unlocks after completing 3 tasks in quick succession',
        };
      case 'consistent_planner':
        return {
          'icon': Icons.psychology,
          'title': 'Consistent Planner',
          'unlockCondition': 'Unlocks after using AI breakdown on 5 tasks',
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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            'Recent Tasks',
            style: TextStyle(
              color: Colors.amber[300],
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: recentTasks.length,
          itemBuilder: (context, index) {
            final task = recentTasks[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ListTile(
                leading: Icon(
                  Icons.check_circle,
                  color: Colors.amber[300],
                  size: 24,
                ),
                title: Text(
                  task.title,
                  style: TextStyle(
                    decoration: TextDecoration.lineThrough,
                    color: Colors.amber[300],
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${task.xpEarned} XP earned',
                  style: TextStyle(
                    color: Colors.amber[300],
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
