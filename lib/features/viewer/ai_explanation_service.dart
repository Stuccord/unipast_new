import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final aiExplanationServiceProvider = Provider<AIExplanationService>((ref) {
  final apiKey = dotenv.get('GEMINI_API_KEY', fallback: '');
  return AIExplanationService(apiKey);
});

class AIExplanationService {
  final String _apiKey;
  late final GenerativeModel _model;

  AIExplanationService(this._apiKey) {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: _apiKey,
    );
  }

  Future<String> explainQuestion(String questionText) async {
    if (_apiKey.isEmpty || _apiKey == 'YOUR_KEY_HERE') {
      return '⚠️ **Gemini API Key missing.** Please add your API key to the .env file to enable AI explanations.';
    }

    final prompt = [
      Content.text(
        "You are an expert Ghanaian university tutor. Explain the question clearly and helpfully.\n\n"
        "Rules:\n"
        "- If theory question: Give word-for-word, structured explanation with key points in bullet form.\n"
        "- If maths/calculation question: Give step-by-step solution with clear reasoning, use LaTeX for equations where possible.\n"
        "- Always use simple English suitable for Level 100-400 students.\n"
        "- End with a short tip for exam success.\n\n"
        "Question: $questionText"
      )
    ];

    try {
      final response = await _model.generateContent(prompt);
      return response.text ?? 'I could not generate an explanation. Please try again.';
    } catch (e) {
      return '❌ **Error**: Failed to connect to AI service. Ensure you have internet and a valid API key. Details: $e';
    }
  }

  Future<String> summarizeDocument(String documentText) async {
    if (_apiKey.isEmpty || _apiKey == 'YOUR_KEY_HERE') {
      return '⚠️ **Gemini API Key missing.**';
    }

    final prompt = [
      Content.text(
        "You are an expert Ghanaian university tutor. Provide a concise, professional summary of this document.\n\n"
        "Format your response with these sections:\n"
        "1. **Overview**: (1-2 sentences on what this document is about)\n"
        "2. **Key Topics**: (Bullet points of main areas covered)\n"
        "3. **Exam Focus**: (What students should prioritize for marks)\n"
        "4. **Key Formula/Terms**: (List if applicable, else say 'N/A')\n\n"
        "Document Content: $documentText"
      )
    ];

    try {
      final response = await _model.generateContent(prompt);
      return response.text ?? 'I could not generate a summary.';
    } catch (e) {
      return '❌ **Error**: $e';
    }
  }

  Future<String> generateQuiz(String documentText) async {
    if (_apiKey.isEmpty || _apiKey == 'YOUR_KEY_HERE') {
      return 'ERROR: MISSING_KEY';
    }

    final prompt = [
      Content.text(
        "Generate a 5-question multiple choice quiz based ONLY on the following content.\n\n"
        "Document Content: $documentText\n\n"
        "Output MUST be a valid JSON array of objects with exactly this structure:\n"
        "[\n"
        "  {\n"
        "    \"question\": \"Question text?\",\n"
        "    \"options\": [\"Option A\", \"Option B\", \"Option C\", \"Option D\"],\n"
        "    \"answerIndex\": 0,\n"
        "    \"explanation\": \"Brief explanation of why this is correct.\"\n"
        "  }\n"
        "]\n\n"
        "Rules:\n"
        "- Exactly 5 questions.\n"
        "- answerIndex must be 0-3.\n"
        "- No preamble or extra text, just JSON."
      )
    ];

    try {
      final response = await _model.generateContent(prompt);
      // Strip any markdown code blocks if AI included them
      final text = response.text?.replaceAll('```json', '').replaceAll('```', '').trim() ?? '';
      return text;
    } catch (e) {
      return 'ERROR: $e';
    }
  }

  Future<String> askCustomQuestion(String documentText, String userQuestion) async {
    if (_apiKey.isEmpty || _apiKey == 'YOUR_KEY_HERE') {
      return '⚠️ **Gemini API Key missing.**';
    }

    final prompt = [
      Content.text(
        "You are an expert Ghanaian university tutor helping a student understand a document.\n\n"
        "Document Context: $documentText\n\n"
        "The student is asking: \"$userQuestion\"\n\n"
        "Instructions:\n"
        "- Provide a deep, clear, and accurate answer based on the document's context.\n"
        "- Explain complex concepts simply but thoroughly.\n"
        "- Use the Ghanaian tutoring persona (encouraging, clear, and structured).\n"
        "- Use Markdown for better readability (bold key terms, use lists).\n"
        "- If the answer isn't in the document, use your external knowledge but mention it's outside the provided text."
      )
    ];

    try {
      final response = await _model.generateContent(prompt);
      return response.text ?? 'I could not generate an answer. Please try rephrasing.';
    } catch (e) {
      return '❌ **Error**: $e';
    }
  }

  /// Generates a mind map / topic breakdown for the God Mind screen.
  Future<List<MindNode>> generateMindMap(String documentText) async {
    if (_apiKey.isEmpty || _apiKey == 'YOUR_KEY_HERE') {
      return [MindNode(topic: 'API Key Missing', icon: '⚠️', summary: 'Add GEMINI_API_KEY to .env', subtopics: [])];
    }

    final prompt = [
      Content.text(
        "Analyze this university exam document and extract the core knowledge structure.\n\n"
        "Document: $documentText\n\n"
        "Return ONLY a valid JSON array (no markdown, no preamble) with exactly 5-7 topic nodes:\n"
        "[\n"
        "  {\n"
        "    \"topic\": \"Topic Name (short, 2-4 words)\",\n"
        "    \"icon\": \"single emoji representing the topic\",\n"
        "    \"summary\": \"one sentence description (max 12 words)\",\n"
        "    \"subtopics\": [\"key term 1\", \"key term 2\", \"key term 3\"]\n"
        "  }\n"
        "]\n"
        "Ensure the output is pure JSON only."
      )
    ];

    try {
      final response = await _model.generateContent(prompt);
      final text = response.text
          ?.replaceAll('```json', '')
          .replaceAll('```', '')
          .trim() ?? '[]';
      final List<dynamic> data = jsonDecode(text);
      return data.map((e) => MindNode.fromJson(e)).toList();
    } catch (e) {
      return [
        MindNode(topic: 'Parse Error', icon: '❌', summary: 'Could not generate mind map', subtopics: [e.toString()]),
      ];
    }
  }
}

class MindNode {
  final String topic;
  final String icon;
  final String summary;
  final List<String> subtopics;

  MindNode({
    required this.topic,
    required this.icon,
    required this.summary,
    required this.subtopics,
  });

  factory MindNode.fromJson(Map<String, dynamic> json) {
    return MindNode(
      topic: json['topic'] ?? 'Unknown',
      icon: json['icon'] ?? '📚',
      summary: json['summary'] ?? '',
      subtopics: List<String>.from(json['subtopics'] ?? []),
    );
  }
}

