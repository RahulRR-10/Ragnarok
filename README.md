# ADHD Task Manager

A Flutter application designed to help people with ADHD manage their tasks more effectively. The app features a gamified task management system with XP rewards, AI-powered task breakdown, and a user-friendly interface.

## Features

- 🎯 Task Management

  - Create and organize tasks
  - Set task difficulty and estimated duration
  - Add subtasks manually or use AI breakdown
  - Track task completion

- 🎮 Gamification

  - XP system based on task difficulty and completion
  - Level progression with unique titles
  - Streak system for daily task completion
  - Achievement system

- 🤖 AI Integration

  - AI-powered task breakdown
  - Smart subtask generation
  - Personalized task suggestions

- 📊 Progress Tracking
  - Visual progress indicators
  - Achievement tracking
  - Daily and weekly statistics
  - XP and level progress

## Getting Started

### Prerequisites

- Flutter SDK
- Dart SDK
- Azure OpenAI API credentials (for AI features)

### Installation

1. Clone the repository:

```bash
git clone https://github.com/yourusername/adhd_task_manager.git
```

2. Navigate to the project directory:

```bash
cd adhd_task_manager
```

3. Install dependencies:

```bash
flutter pub get
```

4. Configure your Azure OpenAI credentials in `lib/config/openai_config.dart`

5. Run the app:

```bash
flutter run
```

## Configuration

### Azure OpenAI Setup

1. Create an Azure OpenAI resource
2. Update the following in `lib/config/openai_config.dart`:
   - `apiKey`: Your Azure OpenAI API key
   - `endpoint`: Your Azure OpenAI endpoint
   - `deploymentName`: Your model deployment name

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.
