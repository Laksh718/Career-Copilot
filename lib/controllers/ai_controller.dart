import 'package:flutter/foundation.dart';
import '../services/career_ai_service.dart';
import '../services/gemini_career_ai_service.dart';
import '../models/career_extraction.dart';
import '../models/application.dart';

class AIController extends ChangeNotifier {
  final CareerAIService _aiService;
  
  bool _isAnalyzing = false;
  bool get isAnalyzing => _isAnalyzing;

  AIController(this._aiService);

  bool get isGeminiService => _aiService is GeminiCareerAIService;

  bool get isGeminiActive {
    final service = _aiService;
    if (service is GeminiCareerAIService) {
      return service.isConfigured;
    }
    return false;
  }

  String get currentApiKey {
    final service = _aiService;
    if (service is GeminiCareerAIService) {
      return service.apiKey;
    }
    return '';
  }

  bool get hasEnvironmentKey {
    final service = _aiService;
    if (service is GeminiCareerAIService) {
      return service.hasEnvironmentKey;
    }
    return false;
  }

  bool get isDefaultKey {
    final service = _aiService;
    if (service is GeminiCareerAIService) {
      return service.isDefaultKey;
    }
    return false;
  }

  Future<void> updateApiKey(String key) async {
    final service = _aiService;
    if (service is GeminiCareerAIService) {
      await service.setApiKey(key);
      notifyListeners();
    }
  }

  Future<void> clearApiKey() async {
    final service = _aiService;
    if (service is GeminiCareerAIService) {
      await service.clearApiKey();
      notifyListeners();
    }
  }

  Future<void> restoreDefaultKey() async {
    final service = _aiService;
    if (service is GeminiCareerAIService) {
      await service.restoreDefaultKey();
      notifyListeners();
    }
  }

  Future<void> loadPlatformDefaultKeyIfAvailable() async {
    final service = _aiService;
    if (service is GeminiCareerAIService) {
      await service.loadPlatformDefaultKeyIfAvailable();
      notifyListeners();
    }
  }

  Future<String?> testApiKey([String? testKey]) async {
    final service = _aiService;
    if (service is GeminiCareerAIService) {
      return await service.testConnection(testKey);
    }
    return 'Gemini service is not active.';
  }

  Future<CareerExtraction> analyzeMessage(String message) async {
    _isAnalyzing = true;
    notifyListeners();

    try {
      final extraction = await _aiService.analyzeMessage(message);
      return extraction;
    } finally {
      _isAnalyzing = false;
      notifyListeners();
    }
  }

  Future<String> chatWithCareerCoach(String userMessage, List<Application> applications) async {
    return await _aiService.chatWithCareerCoach(userMessage, applications);
  }
}
