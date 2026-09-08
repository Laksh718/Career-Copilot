import 'package:flutter/foundation.dart';
import '../services/career_ai_service.dart';
import '../models/career_extraction.dart';

import '../models/application.dart';

class AIController extends ChangeNotifier {
  final CareerAIService _aiService;
  
  bool _isAnalyzing = false;
  bool get isAnalyzing => _isAnalyzing;

  AIController(this._aiService);

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

