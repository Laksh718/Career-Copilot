import '../models/application.dart';
import '../models/career_extraction.dart';

abstract class CareerAIService {
  Future<CareerExtraction> analyzeMessage(String message);
  Future<String> summarizeOpportunity(Application application);
  Future<List<String>> generateInterviewQuestions(Application application);
  Future<String> draftReply(Application application);
  Future<String> explainRequirements(Application application);
  Future<String> chatWithCareerCoach(String userMessage, List<Application> applications);
}

