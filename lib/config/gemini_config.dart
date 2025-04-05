class GeminiConfig {
  static const String apiKey = 'AIzaSyCh0vbpS56JzS5NhRegT1gbYUmBJy_YMPY';
  static const String model = 'gemini-2.0-flash';
  static const String endpoint =
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent';
  static const Duration requestTimeout = Duration(seconds: 60);
}
