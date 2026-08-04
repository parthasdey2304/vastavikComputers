import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/responsive_wrapper.dart';
import '../../data/services/ai_quiz_service.dart';

class QuizSetupScreen extends StatefulWidget {
  final String topic;
  const QuizSetupScreen({super.key, required this.topic});

  @override
  State<QuizSetupScreen> createState() => _QuizSetupScreenState();
}

class _QuizSetupScreenState extends State<QuizSetupScreen> {
  int _selectedQuestions = 10;
  String _selectedDifficulty = 'Medium';
  bool _isGenerating = false;
  final AiQuizService _quizService = AiQuizService();

  void _generateQuiz() async {
    setState(() {
      _isGenerating = true;
    });

    try {
      final quizData = await _quizService.generateQuiz(widget.topic, _selectedQuestions, _selectedDifficulty);
      if (mounted) {
        context.push('/take-quiz', extra: {
          'topic': widget.topic,
          'quizData': quizData,
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error generating quiz: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appSurface,
        elevation: context.isDark ? 0 : 1,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.appTextPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text('AI Quiz Generator', style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: ResponsiveWrapper(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.auto_awesome, color: AppTheme.primary, size: 32),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Generate quiz for:\n${widget.topic}',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: context.appTextPrimary),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 32),
                
                Text('Number of Questions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.appTextPrimary)),
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [10, 20, 30].map((num) {
                    final isSelected = _selectedQuestions == num;
                    return ChoiceChip(
                      label: Text('$num', style: TextStyle(color: isSelected ? Colors.white : context.appTextPrimary, fontWeight: FontWeight.bold)),
                      selected: isSelected,
                      selectedColor: AppTheme.primary,
                      backgroundColor: context.appSurface,
                      onSelected: (val) {
                        if (val) setState(() => _selectedQuestions = num);
                      },
                    );
                  }).toList(),
                ),
                SizedBox(height: 24),

                Text('Difficulty', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.appTextPrimary)),
                SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: ['Easy', 'Medium', 'Hard'].map((diff) {
                    final isSelected = _selectedDifficulty == diff;
                    return ChoiceChip(
                      label: Text(diff, style: TextStyle(color: isSelected ? Colors.white : context.appTextPrimary, fontWeight: FontWeight.bold)),
                      selected: isSelected,
                      selectedColor: AppTheme.primary,
                      backgroundColor: context.appSurface,
                      onSelected: (val) {
                        if (val) setState(() => _selectedDifficulty = diff);
                      },
                    );
                  }).toList(),
                ),
                SizedBox(height: 48),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isGenerating ? null : _generateQuiz,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isGenerating 
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)),
                              SizedBox(width: 12),
                              Text('Generating Magic...', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                            ],
                          )
                        : Text('Generate AI Quiz', style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
