# 🐝 BeeFlow: Task Management for ADHD

<div align="center">
  <img src="assets/images/beeflow_logo.png" alt="BeeFlow Logo" width="200"/>
  
  <h3><i>Stay in motion through the commotion</i></h3>
  
  [![Flutter](https://img.shields.io/badge/Flutter-3.19.0-blue.svg)](https://flutter.dev)
  [![Dart](https://img.shields.io/badge/Dart-3.3.0-blue.svg)](https://dart.dev)
  [![Firebase](https://img.shields.io/badge/Firebase-Latest-orange.svg)](https://firebase.google.com)
  [![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
</div>

## Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Screenshots](#screenshots)
- [Architecture](#architecture)
- [Installation](#installation)
- [Usage](#usage)
- [Contributing](#contributing)
- [License](#license)
- [Privacy](#privacy)
- [Support](#support)
- [Acknowledgments](#acknowledgments)

## Overview

BeeFlow is a productivity application specifically designed for individuals with ADHD. It combines intuitive task management, gamification, and AI-powered features to help users overcome executive dysfunction and achieve their goals.

**Key Problems Solved:**

- Task initiation difficulty
- Sustaining attention and focus
- Breaking down complex tasks
- Maintaining motivation
- Tracking progress effectively

## Features

### Task Management

- **Intuitive Task Creation**: Simple UI for quick task entry
- **AI-Powered Breakdown**: Automatically divides complex tasks into manageable steps
- **Priority Setting**: Highlight urgent tasks with visual indicators
- **Voice Input**: Hands-free task creation with speech-to-text capability

### Focus Mode

- **Pomodoro Timer**: Built-in 25/5 minute work/break cycle
- **Distraction-Free Interface**: Clean design to maintain attention
- **Background Sounds**: White noise, nature sounds, and more to enhance focus
- **Subtask Tracking**: Complete steps in sequence for consistent progress

### Gamification System

- **XP Rewards**: Experience points for completed tasks based on difficulty
- **Level Progression**: Advance through 10 levels with unique titles
- **Achievement Badges**: Unlock 10+ achievements for reaching milestones
- **Streak System**: Daily streaks with multipliers for consistent usage

### Progress Tracking

- **Visual Statistics**: Track productivity metrics with intuitive visualizations
- **Achievement Gallery**: Display unlocked badges and accomplishments
- **Recent Activity**: Review recently completed tasks and earned XP
- **Streak Counter**: Monitor and maintain daily usage streaks

## Screenshots

<div align="center">
  <img src="assets/screenshots/task_list.png" alt="Task List" width="200"/>
  <img src="assets/screenshots/focus_mode.png" alt="Focus Mode" width="200"/>
  <img src="assets/screenshots/progress.png" alt="Progress Screen" width="200"/>
</div>

## Architecture

BeeFlow is built with a clean architecture approach, separating UI, business logic, and data layers:

### Technology Stack

- **Frontend**: Flutter (3.19.0+)
- **State Management**: Provider pattern
- **Backend**: Firebase (Authentication, Realtime Database)
- **AI Integration**: Google Gemini API
- **Local Storage**: Shared Preferences
- **Authentication**: Firebase Auth

### Code Structure

```
lib/
├── main.dart              # Application entry point
├── config/                # Configuration files
├── models/                # Data models
├── providers/             # State management
├── screens/               # UI screens
├── services/              # Firebase and API services
├── utils/                 # Helper utilities
└── widgets/               # Reusable UI components
```

## Installation

### Prerequisites

- Flutter SDK (3.19.0 or higher)
- Dart SDK (3.3.0 or higher)
- Firebase account
- Google Gemini API key

### Setup Instructions

1. **Clone the repository**

   ```bash
   git clone https://github.com/yourusername/beeflow.git
   cd beeflow
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Configure Firebase**

   - Create a Firebase project
   - Add Android/iOS apps to your Firebase project
   - Download and add the google-services.json/GoogleService-Info.plist
   - Follow Firebase setup instructions for each platform

4. **Set up Gemini API**

   - Obtain a Gemini API key from Google AI Studio
   - Create a file at `lib/config/gemini_config.dart` with:
     ```dart
     class GeminiConfig {
       static const String apiKey = 'YOUR_API_KEY';
       static const String endpoint = 'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent';
     }
     ```

5. **Run the application**
   ```bash
   flutter run
   ```

## Usage

### Task Management

1. Tap the "+" button to create a new task
2. Enter a task title and optionally enable AI breakdown
3. Mark tasks as complete by using the "Quick Complete" button or in Focus Mode

### Focus Mode

1. Select a task to focus on from your task list
2. Use the timer controls to start, pause, or reset the focus session
3. Check off subtasks as you complete them
4. Enjoy background sounds to enhance concentration

### Progress Tracking

1. Navigate to the Progress screen to view your achievements
2. Track your XP, level, and streak
3. View your unlocked achievements
4. Monitor your recently completed tasks

## Contributing

We welcome contributions to BeeFlow! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Commit your changes (`git commit -m 'Add some amazing feature'`)
5. Push to the branch (`git push origin feature/amazing-feature`)
6. Open a Pull Request

Please ensure your code follows the project's style and includes appropriate tests.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Privacy

BeeFlow respects user privacy and data security:

- All user data is stored securely in Firebase with appropriate authentication
- Voice input is processed locally when possible
- Task data is associated with user accounts and not shared with third parties
- Users can delete their data at any time through the settings

See our [Privacy Policy](PRIVACY.md) for complete details.

## Support

For support, feature requests, or bug reports:

- Open an issue on GitHub
- Contact us at support@beeflow.app
- Join our [Discord community](https://discord.gg/beeflow)

## Acknowledgments

- The Flutter and Dart teams for the amazing framework
- Firebase for robust backend services
- Google Gemini for AI capabilities
- The ADHD community for inspiration and feedback
- All contributors who have helped improve BeeFlow

---

<div align="center">
  <p>Made with ❤️ by BeeFlow Team</p>
  <p>© 2023-2024 BeeFlow</p>
</div>
