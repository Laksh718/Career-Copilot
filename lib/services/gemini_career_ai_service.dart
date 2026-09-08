import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import '../models/application.dart';
import '../models/career_extraction.dart';
import 'career_ai_service.dart';
import 'mock_career_ai_service.dart';

class GeminiCareerAIService implements CareerAIService {
  static const String prefKey = 'gemini_api_key';

  final SharedPreferences? _prefs;
  String _apiKey = '';
  GenerativeModel? _model;
  GenerativeModel? _fallbackModel;
  final MockCareerAIService _fallbackService = MockCareerAIService();

  GeminiCareerAIService({SharedPreferences? prefs}) : _prefs = prefs {
    _init();
  }

  void _init() {
    // 1. Check SharedPreferences
    final savedKey = _prefs?.getString(prefKey);
    if (savedKey != null && savedKey.trim().isNotEmpty) {
      _apiKey = savedKey.trim();
    } else {
      // 2. Check --dart-define
      const envKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
      if (envKey.isNotEmpty) {
        _apiKey = envKey.trim();
      } else {
        // 3. Fallback to ApiConfig
        _apiKey = ApiConfig.geminiApiKey.trim();
      }
    }
    _initModel();
  }

  void _initModel() {
    if (_apiKey.isNotEmpty) {
      _model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: _apiKey,
      );
      _fallbackModel = GenerativeModel(
        model: 'gemini-pro',
        apiKey: _apiKey,
      );
    } else {
      _model = null;
      _fallbackModel = null;
    }
  }

  /// Helper to generate content with gemini-1.5-flash, falling back to gemini-pro if unsupported
  Future<GenerateContentResponse> _generateContentWithFallback(
    List<Content> contents, {
    GenerationConfig? generationConfig,
  }) async {
    final primary = _model;
    if (primary == null) {
      throw StateError('Gemini API key is not configured');
    }
    try {
      return await primary.generateContent(contents, generationConfig: generationConfig);
    } catch (e) {
      final errStr = e.toString().toLowerCase();
      if (_fallbackModel != null &&
          (errStr.contains('not found') ||
              errStr.contains('404') ||
              errStr.contains('unsupported') ||
              errStr.contains('model'))) {
        try {
          return await _fallbackModel!.generateContent(contents, generationConfig: generationConfig);
        } catch (_) {
          rethrow;
        }
      }
      rethrow;
    }
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
    if (str.contains('SocketException') || str.contains('Network') || str.contains('Failed to fetch') || str.contains('XMLHttpRequest')) {
      return 'Network connection error';
    }
    return str.replaceAll(RegExp(r'^[A-Za-z0-9_]+Exception:\s*'), '').trim();
  }

  /// Whether real Gemini AI model is currently initialized
  bool get isConfigured => _model != null && _apiKey.isNotEmpty;

  /// Current configured API key (masked or raw)
  String get apiKey => _apiKey;

  /// Update the Gemini API key dynamically
  Future<void> setApiKey(String key) async {
    _apiKey = key.trim();
    if (_prefs != null) {
      await _prefs.setString(prefKey, _apiKey);
    }
    _initModel();
  }

  /// Remove saved API key and revert to fallback
  Future<void> clearApiKey() async {
    _apiKey = '';
    if (_prefs != null) {
      await _prefs.remove(prefKey);
    }
    _model = null;
    _fallbackModel = null;
  }

  /// Test a given API key or the current key with a minimal request
  Future<String?> testConnection([String? candidateKey]) async {
    final keyToTest = (candidateKey != null && candidateKey.trim().isNotEmpty)
        ? candidateKey.trim()
        : _apiKey;

    if (keyToTest.isEmpty) {
      return 'API key is empty. Please enter a valid Gemini API key.';
    }

    try {
      final testModel = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: keyToTest,
      );
      try {
        final res = await testModel.generateContent([Content.text('Respond with "OK"')]);
        if (res.text != null && res.text!.isNotEmpty) {
          return null; // Success! null means no error
        }
      } catch (e) {
        // Fallback test with gemini-pro
        final testPro = GenerativeModel(
          model: 'gemini-pro',
          apiKey: keyToTest,
        );
        final res = await testPro.generateContent([Content.text('Respond with "OK"')]);
        if (res.text != null && res.text!.isNotEmpty) {
          return null;
        }
      }
      return 'Received empty response from Gemini API.';
    } catch (e) {
      return _formatUserFriendlyError(e);
    }
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
