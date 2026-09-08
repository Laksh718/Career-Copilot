/// API Configuration
/// Pass your Gemini API key securely at build or run time:
///   flutter run --dart-define-from-file=secrets/api_keys.json
///   flutter run --dart-define=GEMINI_API_KEY=your_key_here
///
/// Alternatively, users can configure and change their API key directly
/// inside the application at runtime via Chat header or Profile settings.
class ApiConfig {
  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: '',
  );
}
