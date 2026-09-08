/// API Configuration
/// You can optionally set your default Gemini API key here or pass it at build time
/// via: flutter build apk --dart-define=GEMINI_API_KEY=your_key_here
/// Alternatively, users can set their key directly in the app via Profile > AI Intelligence Settings.
class ApiConfig {
  static const String geminiApiKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
}
