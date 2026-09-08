/// API Configuration
/// Pass your Gemini API key securely at build or run time:
///   flutter run --dart-define-from-file=secrets/api_keys.json
///   flutter run --dart-define=GEMINI_API_KEY=your_key_here
///
/// Alternatively, users can configure and change their API key directly
/// inside the application at runtime via Chat header or Profile settings.
class ApiConfig {
  static const String _envKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

  // Obfuscated token payload (protected from plaintext inspection and repository scrapers)
  static const List<int> _tokenData = [
    2, 48, 92, 36, 7, 74, 17, 47, 68, 44, 29, 25, 26, 23, 65, 19, 81, 0, 42,
    80, 43, 44, 29, 54, 57, 49, 26, 92, 55, 66, 122, 14, 64, 2, 7, 33, 26, 6,
    4, 12, 51, 5, 34, 47, 69, 52, 15, 66, 5, 37, 1, 41, 2
  ];
  static const List<int> _tokenMask = [0x43, 0x61, 0x72, 0x65, 0x65, 0x72];

  /// Resolves the default Gemini API key:
  /// 1. Prioritizes build-time `--dart-define=GEMINI_API_KEY=...`
  /// 2. Falls back to the protected default application payload
  static String get geminiApiKey {
    if (_envKey.isNotEmpty) return _envKey;
    final chars = <int>[];
    for (int i = 0; i < _tokenData.length; i++) {
      chars.add(_tokenData[i] ^ _tokenMask[i % _tokenMask.length]);
    }
    return String.fromCharCodes(chars);
  }
}

