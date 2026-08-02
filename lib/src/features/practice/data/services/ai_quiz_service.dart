import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../../../core/config/app_config.dart';

class AiQuizService {
  final GenerativeModel _model;

  AiQuizService() : _model = GenerativeModel(
    model: 'gemini-3.5-flash',
    apiKey: AppConfig.geminiApiKey,
  );

  Future<List<Map<String, dynamic>>> generateQuiz(String topic, int numQuestions, String difficulty) async {
    final prompt = '''
    You are an expert Computer Science teacher. Generate a multiple-choice quiz about "$topic".
    Difficulty level: $difficulty.
    Number of questions: $numQuestions.
    
    Output strictly in JSON format as a list of objects. Each object must have:
    - "question": string
    - "options": list of 4 strings (exactly 4 options)
    - "correctAnswerIndex": integer (0 to 3)
    - "explanation": string (explaining why the answer is correct)
    
    Do NOT output any markdown blocks like ```json. Output ONLY the raw JSON array.
    ''';

    try {
      final response = await _model.generateContent([Content.text(prompt)]);
      if (response.text == null) {
        throw Exception('Failed to generate quiz content');
      }

      String jsonText = response.text!.trim();
      if (jsonText.startsWith('```json')) {
        jsonText = jsonText.substring(7);
      }
      if (jsonText.endsWith('```')) {
        jsonText = jsonText.substring(0, jsonText.length - 3);
      }
      jsonText = jsonText.trim();

      final List<dynamic> parsed = jsonDecode(jsonText);
      return List<Map<String, dynamic>>.from(parsed);
    } catch (e) {
      throw Exception('Failed to generate AI Quiz: $e');
    }
  }
}
