class XPConfig {
  // Base XP values
  static const int baseTaskXP = 100;
  static const int baseSubtaskXP = 30;
  static const int subtaskXP = 50;

  // Streak multipliers
  static const double dailyStreakMultiplier = 0.1; // +10% per day streak
  static const int maxStreakMultiplier = 3; // Cap at 3x

  // Time-based multipliers
  static const double sameSessionMultiplier =
      1.5; // Completing tasks in the same session
  static const double earlyCompletionMultiplier =
      1.25; // Completing before due date

  // Special bonuses
  static const int allSubtasksBonus = 50; // Bonus for completing all subtasks
  static const int aiBreakdownBonus = 25; // Bonus for using AI breakdown
  static const int perfectWeekBonus = 300; // Completing tasks 7 days in a row

  // Level thresholds
  static const int xpPerLevel = 200;
  static const List<String> levelTitles = [
    'Beginner',
    'Task Tackler',
    'Focus Finder',
    'Productivity Pro',
    'ADHD Champion',
    'Master Organizer',
    'Task Wizard'
  ];

  // XP thresholds for levels
  static const List<int> levelThresholds = [
    0, // Level 1
    1000, // Level 2
    2500, // Level 3
    5000, // Level 4
    10000, // Level 5
    20000, // Level 6
    35000, // Level 7
    50000, // Level 8
    75000, // Level 9
    100000, // Level 10
  ];

  // Achievement thresholds
  static const Map<String, int> achievementThresholds = {
    'first_task': 1, // Complete first task
    'streak_master': 7, // 7-day streak
    'subtask_star': 10, // Complete 10 subtasks
    'ai_friend': 5, // Use AI breakdown 5 times
    'speed_demon': 3, // Complete 3 tasks in one session
    'task_master': 50, // Complete 50 tasks
    'epic_warrior': 10, // Complete 10 epic tasks
    'daily_champion': 5, // Complete 5 tasks in one day
  };
}
