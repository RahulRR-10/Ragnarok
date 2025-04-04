import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/gemini_config.dart';
import '../models/task.dart';

class GeminiService {
  static Future<(List<String>, TaskDifficulty)> analyzeTask(
      String taskTitle) async {
    try {
      // The Flash model expects the API key as a query parameter
      final url =
          Uri.parse('${GeminiConfig.apiEndpoint}?key=${GeminiConfig.apiKey}');

      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {
                  'text':
                      '''You are an ADHD task coach. Break down this task: "$taskTitle" into small steps.

Provide:
1. A difficulty rating (clearly labeled as "Difficulty: EASY", "Difficulty: MEDIUM", "Difficulty: HARD", or "Difficulty: EPIC")
2. 3-4 very short, specific action steps (use 3-7 words per step)

Format your response exactly like this:
Difficulty: MEDIUM
1. Call dentist
2. Find insurance card
3. Schedule appointment
4. Set reminder'''
                }
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.1,
            'maxOutputTokens': 150,
            'topP': 0.8,
          }
        }),
      );

      if (response.statusCode == 429) {
        debugPrint('Rate limited by Gemini API');
        return (<String>[], TaskDifficulty.medium);
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        debugPrint('Gemini API response: $data');

        // Extract the generated text from the response
        final content =
            data['candidates'][0]['content']['parts'][0]['text'] as String;

        debugPrint('Generated content: $content');

        // Extract difficulty level
        TaskDifficulty difficulty = TaskDifficulty.medium;

        if (content.toLowerCase().contains('difficulty: easy')) {
          difficulty = TaskDifficulty.easy;
        } else if (content.toLowerCase().contains('difficulty: medium')) {
          difficulty = TaskDifficulty.medium;
        } else if (content.toLowerCase().contains('difficulty: hard')) {
          difficulty = TaskDifficulty.hard;
        } else if (content.toLowerCase().contains('difficulty: epic')) {
          difficulty = TaskDifficulty.epic;
        }

        // Extract steps - improved to better handle Flash model's output format
        final steps = content
            .split('\n')
            .where((step) => step.trim().isNotEmpty && step.contains('.'))
            .map((step) {
              // Remove any numbering (like "1. ")
              return step.replaceAll(RegExp(r'^\d+\.\s*'), '').trim();
            })
            .where((step) =>
                !step.toLowerCase().contains('difficulty:') &&
                step.length > 0 &&
                step.length <= 50)
            .take(4)
            .toList();

        // If we couldn't extract steps properly, try an alternative method
        if (steps.isEmpty) {
          // Look for lines that start with a number or have a bullet point
          final allLines = content
              .split('\n')
              .where((line) =>
                  line.trim().isNotEmpty &&
                  !line.toLowerCase().contains('difficulty:') &&
                  (RegExp(r'^\d+[\.\)]').hasMatch(line) || line.contains('• ')))
              .map((line) => line
                  .replaceAll(RegExp(r'^\d+[\.\)]\s*'), '')
                  .replaceAll('• ', '')
                  .trim())
              .toList();

          if (allLines.isNotEmpty) {
            return (allLines, difficulty);
          }

          // As a last resort, just take non-empty lines that aren't about difficulty
          final possibleSteps = content
              .split('\n')
              .where((line) =>
                  line.trim().isNotEmpty &&
                  !line.toLowerCase().contains('difficulty:'))
              .map((line) => line.trim())
              .take(4)
              .toList();

          if (possibleSteps.isNotEmpty) {
            return (possibleSteps, difficulty);
          }
        }

        return (steps, difficulty);
      }

      debugPrint('Gemini API error: ${response.statusCode} - ${response.body}');
      return (<String>[], TaskDifficulty.medium);
    } catch (e) {
      debugPrint('Error getting Gemini analysis: $e');
      return (<String>[], TaskDifficulty.medium);
    }
  }
}
