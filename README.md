# 🐝 BeeFlow: ADHD Task Manager

<div align="center">
  <img src="assets/beeflow_logo.png" alt="BeeFlow Logo" width="200"/>
  
  <h3><i>stay in motion through the commotion</i></h3>
  
  [![Flutter](https://img.shields.io/badge/Flutter-3.19.0-blue.svg)](https://flutter.dev)
  [![Dart](https://img.shields.io/badge/Dart-3.3.0-blue.svg)](https://dart.dev)
  [![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
</div>

## 🌟 Transform Your Productivity Journey

BeeFlow is an innovative task management application specifically designed for individuals with ADHD. With its intuitive interface, gamification features, and AI-powered task breakdowns, BeeFlow helps users stay focused and accomplish their goals.

## ✨ Key Features

### 🎯 Smart Task Management

- **Create & Organize**: Easily add tasks with titles, difficulty levels, and priorities
- **Subtask Breakdown**: Break down complex tasks into manageable steps
- **AI-Powered Analysis**: Get intelligent task breakdowns and difficulty assessments
- **Focus Mode**: Dedicated screen for concentrating on one task at a time

### 🏆 Gamification System

- **XP Rewards**: Earn experience points for completing tasks and subtasks
- **Level Progression**: Advance through levels with unique titles (Novice → Immortal)
- **Streak System**: Maintain daily streaks for bonus rewards
- **Achievements**: Unlock badges for reaching milestones

### 📊 Progress Tracking

- **Visual Stats**: Track your productivity with beautiful charts and indicators
- **Daily Insights**: See your daily XP earnings and completion rates
- **Achievement Gallery**: View all your unlocked achievements
- **Recent Activity**: Review your recently completed tasks

### 🐝 Friendly Interface

- **Bee-themed design**: Engaging yellow and purple color scheme with bee mascot
- **Intuitive navigation**: Simple bottom navigation bar with three main sections
- **Draggable bookmark**: Quick access to home from any screen

### 🧠 AI-Powered Task Breakdown

- **Task analysis**: Automatically breaks down tasks into manageable subtasks
- **Difficulty assessment**: AI evaluates and assigns appropriate difficulty levels
- **XP calculation**: Customized experience points based on task complexity

### 🎤 Voice Input

- **Speech-to-text**: Create tasks using voice commands
- **Real-time transcription**: See your spoken words converted to text instantly
- **Hands-free operation**: Perfect for when typing is inconvenient

### ⏱️ Focus Mode

- **Pomodoro timer**: Built-in 25/5 minute work/break cycle
- **Subtask tracking**: Check off subtasks as you complete them
- **Distraction-free interface**: Clean design to maintain focus

### 🏆 Progress Tracking

- **XP system**: Earn experience points for completing tasks
- **Level progression**: Watch your productivity level increase over time
- **Achievement badges**: Unlock achievements for consistent performance

## 🚀 Getting Started

### Prerequisites

- Flutter SDK (3.19.0 or higher)
- Dart SDK (3.3.0 or higher)
- Gemini API key (for AI features)

### Installation

1. **Clone the repository**

   ```bash
   git clone https://github.com/yourusername/beeflow.git
   ```

2. **Navigate to the project directory**

   ```bash
   cd beeflow
   ```

3. **Install dependencies**

   ```bash
   flutter pub get
   ```

4. **Configure your Gemini API key**

   - Open `lib/config/gemini_config.dart`
   - Replace `apiKey` with your Gemini API key

5. **Run the app**
   ```bash
   flutter run
   ```

## 🧩 How It Works

### Task Creation

1. Add a new task with a title and optional priority
2. Choose to use AI breakdown for automatic subtask generation
3. Set difficulty level (Easy, Medium, Hard, Epic)

### Task Completion

1. Complete subtasks one by one
2. Earn XP based on task difficulty and completion speed
3. Maintain streaks for bonus multipliers
4. Unlock achievements as you progress

### Focus Mode

1. Select a task to focus on
2. Use the Pomodoro timer to maintain concentration
3. Complete subtasks during focused work sessions
4. Return to the task list with a sense of accomplishment

### Focus Screen

1. Select a task to focus on
2. Use the Pomodoro timer to maintain concentration
3. Complete subtasks during focused work sessions
4. Return to the task list with a sense of accomplishment

## 🛠️ Built With

- [Flutter](https://flutter.dev/) - UI framework
- [Provider](https://pub.dev/packages/provider) - State management
- [Shared Preferences](https://pub.dev/packages/shared_preferences) - Local storage
- [Gemini API](https://ai.google.dev/) - AI task breakdown
- [Confetti](https://pub.dev/packages/confetti) - Celebration effects

## 📱 Screenshots

<div align="center">
  <img src="assets/screenshot_task_list.png" alt="Task List" width="200"/>
  <img src="assets/screenshot_focus.png" alt="Focus Mode" width="200"/>
  <img src="assets/screenshot_progress.png" alt="Progress Screen" width="200"/>
</div>

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Inspired by gamification principles in productivity apps
- Special thanks to the Flutter community for amazing packages
- Icon credits: [Material Icons](https://fonts.google.com/icons)

---

<div align="center">
  <p>Made with ❤️ for productivity enthusiasts</p>
</div>

## 📱 Screens

### Login & Registration

- Secure authentication with email/password or Google sign-in
- User profile creation with customizable settings
- Anonymous login option for quick access

### Home Screen

- Motivational quotes that change on hover
- Quick access cards to main app sections
- Animated bee mascot for friendly interaction
- Logout button for secure session management

### Task List Screen

- Complete overview of all your tasks
- Color-coded difficulty levels for quick recognition
- XP indicators showing task value
- "Add Task" button with AI breakdown option
- Voice input capability for hands-free task creation
- Task filtering and sorting options
- Quick-complete functionality for simple tasks

### Task Creation

- Simple task title input with optional voice recognition
- AI breakdown option to generate subtasks automatically
- Priority setting for urgent tasks
- Clean and straightforward interface

### Focus Screen

- Pomodoro timer with start, pause, and reset controls
- Subtask list with completion checkboxes
- Session counter for tracking productivity streaks
- Completion celebration with confetti animation
- Draggable bookmark for quick navigation

### Progress Screen

- XP and level visualization
- Daily, weekly, and monthly progress charts
- Achievement badges and unlocked rewards
- Productivity insights and trends

### Settings

- Theme customization options
- Notification preferences
- Account management
- Data backup and sync settings
- Help and support resources

## 📄 Privacy & Security

BeeFlow takes user privacy seriously. All task data is stored securely in Firebase with strict access rules. Speech recognition is performed locally on the device when possible, minimizing data transmission.

## 📄 Support

For support, feature requests, or bug reports, please open an issue on the repository or contact the development team.

---

_BeeFlow: Stay in motion without the commotion_ ✨
