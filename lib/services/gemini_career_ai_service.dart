import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/application.dart';
import '../models/career_extraction.dart';
import 'career_ai_service.dart';
import 'mock_career_ai_service.dart';

class GeminiCareerAIService implements CareerAIService {
  static const String prefKey = 'gemini_api_key';
  static const String userClearedKey = 'gemini_key_cleared_by_user';
  static const MethodChannel _platformChannel =
      MethodChannel('com.example.career_copilot/config');

  final SharedPreferences? _prefs;
  String _platformDefaultKey = '';
  String _apiKey = '';
  GenerativeModel? _model;
  final MockCareerAIService _fallbackService = MockCareerAIService();

  GeminiCareerAIService({SharedPreferences? prefs, String? platformDefaultKey})
      : _prefs = prefs,
        _platformDefaultKey = platformDefaultKey ?? '' {
    _init();
  }

  void _init() {
    final bool userCleared = _prefs?.getBool(userClearedKey) ?? false;
    if (userCleared) {
      _apiKey = '';
    } else {
      // 1. Check SharedPreferences for user-provided custom key
      final savedKey = _prefs?.getString(prefKey);
      if (savedKey != null && savedKey.trim().isNotEmpty) {
        _apiKey = savedKey.trim();
      } else {
        // 2. Check platform default key, --dart-define or ApiConfig default
        final def = defaultKey;
        if (def.isNotEmpty) {
          _apiKey = def;
        }
      }
    }
    _initModel();
  }

  /// Query Android platform MethodChannel to load default key if injected into resources
  Future<void> loadPlatformDefaultKeyIfAvailable() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    try {
      final key = await _platformChannel.invokeMethod<String>('getDefaultGeminiApiKey');
      if (key != null && key.trim().isNotEmpty) {
        _platformDefaultKey = key.trim();
        final bool userCleared = _prefs?.getBool(userClearedKey) ?? false;
        final savedKey = _prefs?.getString(prefKey);
        final hasSavedKey = savedKey != null && savedKey.trim().isNotEmpty;
        if (!userCleared && !hasSavedKey && _apiKey.isEmpty) {
          _apiKey = _platformDefaultKey;
          _initModel();
        }
      }
    } catch (e) {
      debugPrint('Error loading platform default Gemini API key: $e');
    }
  }

  static const List<String> candidateModels = [
    'gemini-2.5-flash',
    'gemini-3.5-flash',
    'gemini-1.5-flash',
    'gemini-pro',
  ];

  void _initModel() {
    if (_apiKey.isNotEmpty) {
      _model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: _apiKey,
      );
    } else {
      _model = null;
    }
  }

  /// Helper to generate content with gemini-2.5-flash, cascading to gemini-3.5-flash & legacy models
  Future<GenerateContentResponse> _generateContentWithFallback(
    List<Content> contents, {
    GenerationConfig? generationConfig,
  }) async {
    if (_apiKey.isEmpty) {
      throw StateError('Gemini API key is not configured');
    }
    Object? lastError;
    for (final modelName in candidateModels) {
      try {
        final model = GenerativeModel(
          model: modelName,
          apiKey: _apiKey,
        );
        return await model.generateContent(contents, generationConfig: generationConfig);
      } catch (e) {
        lastError = e;
        final errStr = e.toString().toLowerCase();
        if (errStr.contains('not found') ||
            errStr.contains('404') ||
            errStr.contains('unsupported') ||
            errStr.contains('no longer available') ||
            errStr.contains('model')) {
          continue;
        }
        rethrow;
      }
    }
    throw lastError ?? StateError('All Gemini candidate models failed');
  }

  String _formatUserFriendlyError(Object e) {
    final str = e.toString();
    if (str.contains('API_KEY_INVALID') || str.contains('API key not valid')) {
      return 'Invalid API key. Check your key at aistudio.google.com';
    }
    if (str.contains('RESOURCE_EXHAUSTED') || str.contains('429') || str.contains('quota')) {
      return 'Gemini rate limit / quota reached';
    }
    if (str.contains('PERMISSION_DENIED')) {
      return 'Permission denied for this API key';
    }
    if (str.contains('503') || str.contains('UNAVAILABLE') || str.contains('high demand')) {
      return 'Gemini is experiencing temporary high traffic. Please retry in a moment';
    }
    if (str.contains('SocketException') || str.contains('Network') || str.contains('Failed to fetch') || str.contains('XMLHttpRequest')) {
      return 'Network connection error';
    }
    return str.replaceAll(RegExp(r'^[A-Za-z0-9_]+Exception:\s*'), '').trim();
  }

  /// Whether real Gemini AI model is currently initialized
  bool get isConfigured => _model != null && _apiKey.isNotEmpty;

  /// Current configured API key (masked or raw)
  String get apiKey => _apiKey;

  /// Default API key from platform config, --dart-define, or ApiConfig
  String get defaultKey {
    if (_platformDefaultKey.isNotEmpty) return _platformDefaultKey;
    const envKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
    if (envKey.isNotEmpty) return envKey.trim();
    return ApiConfig.geminiApiKey.trim();
  }

  /// Whether a default key was configured at build, platform, or environment time
  bool get hasEnvironmentKey => defaultKey.isNotEmpty;

  /// Whether the currently active key is the default built-in/platform key
  bool get isDefaultKey {
    if (_apiKey.isEmpty) return false;
    final def = defaultKey;
    return def.isNotEmpty && _apiKey == def;
  }

  /// Update the Gemini API key dynamically with user-provided custom key
  Future<void> setApiKey(String key) async {
    final trimmed = key.trim();
    if (trimmed.isEmpty) {
      await clearApiKey();
      return;
    }
    _apiKey = trimmed;
    if (_prefs != null) {
      await _prefs.setBool(userClearedKey, false);
      await _prefs.setString(prefKey, _apiKey);
    }
    _initModel();
  }

  /// Remove saved API key and explicitly switch to offline fallback
  Future<void> clearApiKey() async {
    _apiKey = '';
    if (_prefs != null) {
      await _prefs.setBool(userClearedKey, true);
      await _prefs.remove(prefKey);
    }
    _model = null;
  }

  /// Restore the default built-in application key
  Future<void> restoreDefaultKey() async {
    if (_prefs != null) {
      await _prefs.setBool(userClearedKey, false);
      await _prefs.remove(prefKey);
    }
    _apiKey = defaultKey;
    _initModel();
  }

  /// Test a given API key or the current key with a minimal request
  Future<String?> testConnection([String? candidateKey]) async {
    final keyToTest = (candidateKey != null && candidateKey.trim().isNotEmpty)
        ? candidateKey.trim()
        : _apiKey;

    if (keyToTest.isEmpty) {
      return 'API key is empty. Please enter a valid Gemini API key.';
    }

    Object? lastError;
    for (final modelName in candidateModels) {
      try {
        final testModel = GenerativeModel(
          model: modelName,
          apiKey: keyToTest,
        );
        final res = await testModel.generateContent([Content.text('Respond with "OK"')]);
        if (res.text != null && res.text!.isNotEmpty) {
          return null; // Success!
        }
      } catch (e) {
        lastError = e;
        final errStr = e.toString().toLowerCase();
        if (errStr.contains('not found') ||
            errStr.contains('404') ||
            errStr.contains('unsupported') ||
            errStr.contains('no longer available') ||
            errStr.contains('model')) {
          continue;
        }
        return _formatUserFriendlyError(e);
      }
    }
    return lastError != null
        ? _formatUserFriendlyError(lastError)
        : 'Received empty response from Gemini API.';
  }

  @override
  Future<CareerExtraction> analyzeMessage(String message) async {
    final model = _model;
    if (model == null) {
      return _fallbackService.analyzeMessage(message);
    }

    final prompt = '''
You are an expert career assistant. Extract job application information from the following message.
Return the output STRICTLY as a valid JSON object matching this schema. If a field is not present, use null.
Do not wrap the JSON in markdown code blocks. Just return the raw JSON object.

Schema:
{
  "company": "String or null",
  "role": "String or null",
  "location": "String or null",
  "workMode": "String or null",
  "stipend": "String or null",
  "salary": "String or null",
  "deadline": "String (e.g. September 12, Tomorrow) or null",
  "interviewDate": "String (e.g. Monday, Oct 5) or null",
  "interviewTime": "String (e.g. 8:00 PM) or null",
  "applicationLink": "String or null",
  "requiredDocuments": ["String", "String"] or null,
  "eligibility": "String or null",
  "contactPerson": "String or null"
}

Message:
"$message"
''';

    try {
      final response = await _generateContentWithFallback([Content.text(prompt)]);
      
      String text = response.text ?? '{}';
      // Clean up potential markdown formatting if the model still includes it
      if (text.startsWith('```json')) {
        text = text.substring(7);
      }
      if (text.startsWith('```')) {
        text = text.substring(3);
      }
      if (text.endsWith('```')) {
        text = text.substring(0, text.length - 3);
      }
      text = text.trim();

      final json = jsonDecode(text) as Map<String, dynamic>;

      String? deadline = json['deadline'] as String?;
      String? interviewDate = json['interviewDate'] as String?;
      
      String status = 'Applied';
      String nextAction = 'Review details';
      if (interviewDate != null && interviewDate.isNotEmpty) {
        status = 'Interview';
        nextAction = 'Prepare for interview';
      } else if (deadline != null && deadline.isNotEmpty) {
        status = 'Action Required';
        nextAction = 'Submit application before deadline';
      }

      List<String>? docs;
      if (json['requiredDocuments'] != null) {
        docs = List<String>.from(json['requiredDocuments'] as List);
      }

      return CareerExtraction(
        company: json['company'] as String?,
        role: json['role'] as String?,
        location: json['location'] as String?,
        workMode: json['workMode'] as String?,
        stipend: json['stipend'] as String?,
        salary: json['salary'] as String?,
        deadline: deadline,
        interviewDate: interviewDate,
        interviewTime: json['interviewTime'] as String?,
        applicationLink: json['applicationLink'] as String?,
        requiredDocuments: docs,
        eligibility: json['eligibility'] as String?,
        contactPerson: json['contactPerson'] as String?,
        status: status,
        nextAction: nextAction,
      );
    } catch (e) {
      debugPrint('Falling back to local AI extractor: $e');
      return _fallbackService.analyzeMessage(message);
    }
  }

  @override
  Future<String> draftReply(Application application) async {
    final model = _model;
    if (model == null) return _fallbackService.draftReply(application);
    try {
      final prompt = 'Draft a short, professional email reply confirming receipt and interest for a ${application.role} position at ${application.company}. Keep it under 50 words.';
      final response = await _generateContentWithFallback([Content.text(prompt)]);
      return response.text ?? await _fallbackService.draftReply(application);
    } catch (e) {
      return _fallbackService.draftReply(application);
    }
  }

  @override
  Future<String> explainRequirements(Application application) async {
    final model = _model;
    if (model == null) return _fallbackService.explainRequirements(application);
    try {
      if (application.requiredDocuments.isEmpty) return "No documents required.";
      final prompt = 'Briefly explain the purpose of these required documents for a job application: ${application.requiredDocuments.map((e) => e.name).join(', ')}';
      final response = await _generateContentWithFallback([Content.text(prompt)]);
      return response.text ?? await _fallbackService.explainRequirements(application);
    } catch (e) {
      return _fallbackService.explainRequirements(application);
    }
  }

  @override
  Future<List<String>> generateInterviewQuestions(Application application) async {
    final model = _model;
    if (model == null) return _fallbackService.generateInterviewQuestions(application);
    try {
      final prompt = 'Generate 3 common interview questions for a ${application.role} at ${application.company}. Return them as a JSON list of strings without markdown blocks.';
      final response = await _generateContentWithFallback([Content.text(prompt)]);
      String text = response.text ?? '[]';
      text = text.replaceAll('```json', '').replaceAll('```', '').trim();
      List<dynamic> list = jsonDecode(text);
      return list.map((e) => e.toString()).toList();
    } catch (e) {
      return _fallbackService.generateInterviewQuestions(application);
    }
  }

  @override
  Future<String> summarizeOpportunity(Application application) async {
    final model = _model;
    if (model == null) return _fallbackService.summarizeOpportunity(application);
    try {
      final prompt = 'Write a 1-sentence summary of this opportunity: Role: ${application.role}, Company: ${application.company}, Deadline: ${application.deadline}';
      final response = await _generateContentWithFallback([Content.text(prompt)]);
      return response.text?.trim() ?? await _fallbackService.summarizeOpportunity(application);
    } catch (e) {
      return _fallbackService.summarizeOpportunity(application);
    }
  }

  @override
  Future<String> chatWithCareerCoach(String userMessage, List<Application> applications) async {
    final model = _model;
    if (model == null) return _fallbackService.chatWithCareerCoach(userMessage, applications);
    try {
      final appsContext = applications.map((a) {
        return '- ${a.company} (${a.role}) | Status: ${a.status.name}'
            '${a.interviewDate.isNotEmpty ? ' | Interview: ${a.interviewDate} ${a.interviewTime}' : ''}'
            '${a.deadline.isNotEmpty ? ' | Deadline: ${a.deadline}' : ''}'
            '${a.nextAction.isNotEmpty ? ' | Next: ${a.nextAction}' : ''}';
      }).join('\n');

      final prompt = '''
You are "Career Copilot", an elite, executive-level AI career advisor for college students and job seekers.
User's Tracked Applications:
${appsContext.isEmpty ? 'No applications currently tracked.' : appsContext}

User Query: "$userMessage"

Instructions:
1. Do NOT include conversational greetings or filler like "Sure!", "Here is what I found:", or "Hello Laksh".
2. Start directly with the first section header: ### SUMMARY.
3. Use the following structured section format (omit a section if not applicable):

### SUMMARY
A direct, punchy 1-2 sentence executive answer to the user's question.

### HIGHLIGHTS
• Key point 1 with specific details
• Key point 2
• Key point 3

### ACTION PLAN
1. First concrete step
2. Second concrete step

### TEMPLATE
(Include ONLY if the user asked to draft an email, message, questions, or script. Provide clean, professional copy.)

### PRO TIP
One high-leverage career or interview tip relevant to this topic.

Keep the response concise, punchy, well-structured, and easy to read on mobile.
''';

      final response = await _generateContentWithFallback([Content.text(prompt)]);
      final text = response.text?.trim();
      if (text != null && text.isNotEmpty) {
        return text;
      }
      return await _fallbackService.chatWithCareerCoach(userMessage, applications);
    } catch (e) {
      debugPrint('Gemini chat error, using fallback: $e');
      final fallbackReply = await _fallbackService.chatWithCareerCoach(userMessage, applications);
      final errorMsg = _formatUserFriendlyError(e);
      if (fallbackReply.startsWith('### SUMMARY\n')) {
        return fallbackReply.replaceFirst(
          '### SUMMARY\n',
          '### SUMMARY\n[Gemini: $errorMsg • Offline AI response below]\n\n',
        );
      }
      return "### SUMMARY\n[Gemini: $errorMsg • Offline AI response below]\n\n$fallbackReply";
    }
  }
}
