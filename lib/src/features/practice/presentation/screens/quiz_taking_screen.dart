import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/responsive_wrapper.dart';
import '../../data/services/quiz_export_service.dart';

class QuizTakingScreen extends StatefulWidget {
  final String topic;
  final List<Map<String, dynamic>> quizData;

  const QuizTakingScreen({super.key, required this.topic, required this.quizData});

  @override
  State<QuizTakingScreen> createState() => _QuizTakingScreenState();
}

class _QuizTakingScreenState extends State<QuizTakingScreen> {
  int _currentIndex = 0;
  final Map<int, int> _userAnswers = {};
  bool _isSubmitted = false;

  void _submitQuiz() {
    setState(() {
      _isSubmitted = true;
    });
  }

  Future<void> _downloadQuestionScript() async {
    try {
      await QuizExportService.exportQuestionScript(widget.topic, widget.quizData);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Question script downloaded!')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Download failed: $e')));
    }
  }

  Future<void> _downloadAnswerScript() async {
    try {
      await QuizExportService.exportAnswerScript(widget.topic, widget.quizData);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Answer script downloaded!')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Download failed: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isSubmitted) return _buildResultScreen();

    final currentQ = widget.quizData[_currentIndex];
    final options = currentQ['options'] as List<dynamic>;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text('${widget.topic} (${_currentIndex + 1}/${widget.quizData.length})', style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16)),
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppTheme.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: ResponsiveWrapper(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LinearProgressIndicator(
                  value: (_currentIndex + 1) / widget.quizData.length,
                  backgroundColor: AppTheme.surface,
                  valueColor: const AlwaysStoppedAnimation(AppTheme.primary),
                ),
                const SizedBox(height: 32),
                Text('Q${_currentIndex + 1}. ${currentQ['question']}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                const SizedBox(height: 32),
                Expanded(
                  child: ListView.builder(
                    itemCount: options.length,
                    itemBuilder: (context, idx) {
                      final isSelected = _userAnswers[_currentIndex] == idx;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _userAnswers[_currentIndex] = idx;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.primary.withAlpha(20) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isSelected ? AppTheme.primary : AppTheme.surface, width: 2),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected ? AppTheme.primary : AppTheme.surface,
                                ),
                                child: Center(
                                  child: Text(String.fromCharCode(65 + idx), style: TextStyle(color: isSelected ? Colors.white : AppTheme.textPrimary, fontWeight: FontWeight.bold)),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(child: Text(options[idx], style: const TextStyle(fontSize: 16))),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_currentIndex > 0)
                      TextButton(onPressed: () => setState(() => _currentIndex--), child: const Text('Previous')),
                    if (_currentIndex == 0) const SizedBox(),
                    
                    if (_currentIndex < widget.quizData.length - 1)
                      ElevatedButton(onPressed: () => setState(() => _currentIndex++), child: const Text('Next')),
                    if (_currentIndex == widget.quizData.length - 1)
                      ElevatedButton(
                        onPressed: _userAnswers.length == widget.quizData.length ? _submitQuiz : null,
                        style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent),
                        child: const Text('Submit Quiz'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultScreen() {
    int score = 0;
    for (int i = 0; i < widget.quizData.length; i++) {
      if (_userAnswers[i] == widget.quizData[i]['correctAnswerIndex']) {
        score++;
      }
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Quiz Results', style: TextStyle(color: AppTheme.textPrimary)),
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppTheme.textPrimary),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: SafeArea(
        child: ResponsiveWrapper(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Icon(Icons.emoji_events, size: 80, color: Colors.amber),
                const SizedBox(height: 16),
                Text('You scored $score out of ${widget.quizData.length}', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                const SizedBox(height: 32),
                
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.download),
                    label: const Text('Download Question Script (PDF)'),
                    onPressed: _downloadQuestionScript,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.download),
                    label: const Text('Download Answer Script (PDF)'),
                    onPressed: _downloadAnswerScript,
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.accent),
                  ),
                ),
                const SizedBox(height: 48),

                const Text('Review Answers', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ...widget.quizData.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final q = entry.value;
                  final userAns = _userAnswers[idx];
                  final correctAns = q['correctAnswerIndex'];
                  final isCorrect = userAns == correctAns;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.surface)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(isCorrect ? Icons.check_circle : Icons.cancel, color: isCorrect ? Colors.green : Colors.red),
                            const SizedBox(width: 8),
                            Expanded(child: Text('Q${idx + 1}. ${q['question']}', style: const TextStyle(fontWeight: FontWeight.bold))),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text('Your Answer: ${q['options'][userAns]}', style: TextStyle(color: isCorrect ? Colors.green : Colors.red)),
                        if (!isCorrect)
                          Text('Correct Answer: ${q['options'][correctAns]}', style: const TextStyle(color: Colors.green)),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: AppTheme.primary.withAlpha(20), borderRadius: BorderRadius.circular(8)),
                          child: Text('Explanation: ${q['explanation']}', style: const TextStyle(fontStyle: FontStyle.italic, fontSize: 13)),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
