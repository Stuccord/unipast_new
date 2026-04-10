import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:confetti/confetti.dart';
import 'package:unipast/core/theme.dart';
import 'package:unipast/features/viewer/ai_explanation_service.dart';

class AIQuizScreen extends ConsumerStatefulWidget {
  final String documentText;

  const AIQuizScreen({super.key, required this.documentText});

  @override
  ConsumerState<AIQuizScreen> createState() => _AIQuizScreenState();
}

class _AIQuizScreenState extends ConsumerState<AIQuizScreen> {
  late Future<List<QuizQuestion>> _quizFuture;
  late ConfettiController _confettiController;
  
  int _currentIndex = 0;
  int _score = 0;
  bool _isFinished = false;
  int? _selectedOption;
  bool _hasAnswered = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _loadQuiz();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _loadQuiz() {
    setState(() {
      _quizFuture = _fetchQuiz();
      _currentIndex = 0;
      _score = 0;
      _isFinished = false;
      _selectedOption = null;
      _hasAnswered = false;
    });
  }

  Future<List<QuizQuestion>> _fetchQuiz() async {
    final rawJson = await ref.read(aiExplanationServiceProvider).generateQuiz(widget.documentText);
    
    if (rawJson.startsWith('ERROR')) {
      throw Exception(rawJson);
    }

    try {
      final List<dynamic> data = jsonDecode(rawJson);
      return data.map((item) => QuizQuestion.fromJson(item)).toList();
    } catch (e) {
      throw Exception('Failed to parse quiz: $e');
    }
  }

  void _handleAnswer(int index, int correctIndex) {
    if (_hasAnswered) return;
    
    setState(() {
      _selectedOption = index;
      _hasAnswered = true;
      if (index == correctIndex) {
        _score++;
      }
    });

    // Short delay before moving to next question (or showing results)
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      if (_currentIndex < 4) {
        setState(() {
          _currentIndex++;
          _selectedOption = null;
          _hasAnswered = false;
        });
      } else {
        setState(() {
          _isFinished = true;
        });
        if (_score >= 3) {
          _confettiController.play();
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.bgDark : AppTheme.bgLight,
      appBar: AppBar(
        title: const Text('AI Revision Quiz'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          FutureBuilder<List<QuizQuestion>>(
            future: _quizFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: AppTheme.primaryTeal),
                      SizedBox(height: 24),
                      Text('AI is reading the document...', style: TextStyle(fontWeight: FontWeight.w500)),
                      Text('Generating questions just for you', style: TextStyle(color: Colors.grey, fontSize: 12)),
                    ],
                  ),
                );
              }

              if (snapshot.hasError) {
                return _buildErrorState(snapshot.error.toString());
              }

              final quiz = snapshot.data!;
              
              if (_isFinished) {
                return _buildScoreSummary(quiz.length, isDark);
              }

              final question = quiz[_currentIndex];

              return Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Progress Indicator
                    LinearProgressIndicator(
                      value: (_currentIndex + 1) / quiz.length,
                      backgroundColor: isDark ? Colors.white10 : Colors.black12,
                      color: AppTheme.primaryTeal,
                      minHeight: 8,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Question ${_currentIndex + 1} of ${quiz.length}',
                      style: const TextStyle(color: AppTheme.primaryTeal, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      question.question,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 32),
                    ...List.generate(question.options.length, (index) {
                      final isSelected = _selectedOption == index;
                      final isCorrect = index == question.answerIndex;
                      
                      Color cardColor = isDark ? const Color(0xFF1F2937) : Colors.white;
                      Color borderColor = Colors.transparent;
                      
                      if (_hasAnswered) {
                        if (isCorrect) {
                          cardColor = Colors.green.withAlpha(isDark ? 40 : 20);
                          borderColor = Colors.green;
                        } else if (isSelected) {
                          cardColor = Colors.red.withAlpha(isDark ? 40 : 20);
                          borderColor = Colors.red;
                        }
                      } else if (isSelected) {
                        borderColor = AppTheme.primaryTeal;
                      }

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: InkWell(
                          onTap: () => _handleAnswer(index, question.answerIndex),
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: borderColor, width: 2),
                              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white10 : Colors.black12,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Center(
                                    child: Text(
                                      String.fromCharCode(65 + index),
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    question.options[index],
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                                if (_hasAnswered && isCorrect)
                                  const Icon(Icons.check_circle, color: Colors.green),
                                if (_hasAnswered && isSelected && !isCorrect)
                                  const Icon(Icons.cancel, color: Colors.red),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                    
                    if (_hasAnswered) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryTeal.withAlpha(15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: AppTheme.primaryTeal, size: 20),
                            const SizedBox(width: 12),
                            Expanded(child: Text(question.explanation, style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic))),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
          
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
              colors: const [Colors.green, Colors.blue, Colors.pink, Colors.orange, Colors.purple],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreSummary(int total, bool isDark) {
    String message = 'Good job!';
    IconData icon = Icons.emoji_events_rounded;
    Color color = Colors.orange;

    if (_score == total) {
      message = 'Perfect Score! 🍫';
      color = AppTheme.primaryTeal;
    } else if (_score < 3) {
      message = 'Keep Studying!';
      icon = Icons.menu_book_rounded;
      color = Colors.grey;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 80, color: color),
            const SizedBox(height: 24),
            Text(
              message,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'You scored $_score out of $total',
              style: TextStyle(fontSize: 18, color: isDark ? Colors.white70 : Colors.black54),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryTeal,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Back to PDF'),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _loadQuiz,
              child: const Text('Try New Questions'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            const Text('Quiz Generation Failed', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(error, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 32),
            ElevatedButton(onPressed: _loadQuiz, child: const Text('Try Again')),
          ],
        ),
      ),
    );
  }
}

class QuizQuestion {
  final String question;
  final List<String> options;
  final int answerIndex;
  final String explanation;

  QuizQuestion({
    required this.question,
    required this.options,
    required this.answerIndex,
    required this.explanation,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      question: json['question'] ?? 'Unknown Question',
      options: List<String>.from(json['options'] ?? []),
      answerIndex: json['answerIndex'] ?? 0,
      explanation: json['explanation'] ?? '',
    );
  }
}
