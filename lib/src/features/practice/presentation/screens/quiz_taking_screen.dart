import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/responsive_wrapper.dart';
import '../../data/services/quiz_export_service.dart';

/// A normalised quiz question shape that works both with admin-created papers
/// (`correctIndex`) and legacy AI-generated quizzes (`correctAnswerIndex`).
class _QuizQuestion {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String? explanation;

  const _QuizQuestion({
    required this.question,
    required this.options,
    required this.correctIndex,
    this.explanation,
  });

  factory _QuizQuestion.fromMap(Map<String, dynamic> map) {
    final optionsRaw = map['options'];
    final options = optionsRaw is List
        ? optionsRaw.map((e) => e.toString()).toList()
        : <String>[];

    final correctRaw = map['correctIndex'] ?? map['correctAnswerIndex'];
    final correctIndex = correctRaw is int
        ? correctRaw
        : (int.tryParse(correctRaw?.toString() ?? '') ?? 0).clamp(0, options.length - 1);

    return _QuizQuestion(
      question: map['question']?.toString() ?? '',
      options: options,
      correctIndex: correctIndex < 0 ? 0 : correctIndex,
      explanation: map['explanation']?.toString(),
    );
  }
}

class QuizTakingScreen extends StatefulWidget {
  final String topic;
  final List<Map<String, dynamic>> quizData;

  const QuizTakingScreen({super.key, required this.topic, required this.quizData});

  @override
  State<QuizTakingScreen> createState() => _QuizTakingScreenState();
}

class _QuizTakingScreenState extends State<QuizTakingScreen> {
  late final List<_QuizQuestion> _questions;
  final Map<int, int> _userAnswers = {};
  int _currentIndex = 0;
  bool _isSubmitted = false;
  int _seconds = 0;
  late final Stopwatch _stopwatch;
  late final Duration tick;

  @override
  void initState() {
    super.initState();
    _questions =
        widget.quizData.map(_QuizQuestion.fromMap).toList(growable: false);
    _stopwatch = Stopwatch()..start();
    tick = const Duration(seconds: 1);
    Future.doWhile(() async {
      await Future.delayed(tick);
      if (!mounted || _isSubmitted) return false;
      setState(() => _seconds = _stopwatch.elapsed.inSeconds);
      return true;
    });
  }

  int get _score {
    int s = 0;
    for (int i = 0; i < _questions.length; i++) {
      if (_userAnswers[i] == _questions[i].correctIndex) s++;
    }
    return s;
  }

  double get _accuracy =>
      _questions.isEmpty ? 0 : _score / _questions.length;

  String get _elapsedLabel {
    final m = _seconds ~/ 60;
    final s = _seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _next() => setState(() => _currentIndex++);
  void _prev() => setState(() => _currentIndex--);

  void _submit() {
    _stopwatch.stop();
    setState(() => _isSubmitted = true);
  }

  Future<void> _export(bool answers) async {
    try {
      if (answers) {
        await QuizExportService.exportAnswerScript(
            widget.topic, widget.quizData);
      } else {
        await QuizExportService.exportQuestionScript(
            widget.topic, widget.quizData);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF downloaded!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Download failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isSubmitted) return _buildResultScreen();
    return _buildQuizScreen();
  }

  // ----- Quiz taking UI -----
  Widget _buildQuizScreen() {
    final q = _questions[_currentIndex];
    final total = _questions.length;
    final selected = _userAnswers[_currentIndex];

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appSurface,
        elevation: context.isDark ? 0 : 1,
        title: Text(
          widget.topic,
          style: TextStyle(color: context.appTextPrimary),
        ),
        leading: IconButton(
          icon: Icon(Icons.close, color: context.appTextPrimary),
          onPressed: () => context.pop(),
        ),
        actions: [
          Center(
            child: Container(
              margin: EdgeInsets.only(right: 16),
              padding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: context.appSurface,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.timer_outlined,
                      color: AppTheme.primary, size: 16),
                  SizedBox(width: 4),
                  Text(
                    _elapsedLabel,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ResponsiveWrapper(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // progress + question counter
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: (_currentIndex + 1) / total,
                          backgroundColor: context.appSurface,
                          valueColor: const AlwaysStoppedAnimation(
                              AppTheme.primary),
                          minHeight: 8,
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      '${_currentIndex + 1}/$total',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: context.appTextPrimary,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 28),

                // question card
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: context.appSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Text(
                    'Q${_currentIndex + 1}.  ${q.question}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: context.appTextPrimary,
                      height: 1.4,
                    ),
                  ),
                ),
                SizedBox(height: 24),

                // options
                Expanded(
                  child: ListView.separated(
                    itemCount: q.options.length,
                    separatorBuilder: (_, _) => SizedBox(height: 12),
                    itemBuilder: (context, idx) {
                      final isSelected = selected == idx;
                      final letter = String.fromCharCode(65 + idx);
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _userAnswers[_currentIndex] = idx),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.primary.withAlpha(18)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.primary
                                  : Colors.grey.shade300,
                              width: 2,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected
                                      ? AppTheme.primary
                                      : context.appSurface,
                                ),
                                child: Center(
                                  child: Text(
                                    letter,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : context.appTextPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  q.options[idx],
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 16),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: _currentIndex > 0 ? _prev : null,
                      child: Text('Previous'),
                    ),
                    if (_currentIndex < total - 1)
                      ElevatedButton(
                        onPressed: _next,
                        child: Text('Next'),
                      ),
                    if (_currentIndex == total - 1)
                      ElevatedButton(
                        onPressed: _userAnswers.length == total ? _submit : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.accent,
                        ),
                        child: Text('Submit Quiz'),
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

  // ----- Result UI: score card + per-question colour-coding -----
  Widget _buildResultScreen() {
    final total = _questions.length;
    final correct = _score;
    final wrong = total - correct;
    final pct = (_accuracy * 100).round();
    final passed = _accuracy >= 0.5;

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appSurface,
        title: Text('Quiz Results',
            style: TextStyle(color: context.appTextPrimary)),
        leading: IconButton(
          icon: Icon(Icons.close, color: context.appTextPrimary),
          onPressed: () => context.go('/home'),
        ),
      ),
      body: SafeArea(
        child: ResponsiveWrapper(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Score card
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: passed
                          ? const [Color(0xFF16A34A), Color(0xFF22C55E)]
                          : const [Color(0xFFEF4444), Color(0xFFF97316)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: (passed ? Colors.green : Colors.orange)
                            .withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Icon(
                        passed ? Icons.emoji_events : Icons.refresh,
                        size: 64,
                        color: context.appSurface,
                      ),
                      SizedBox(height: 12),
                      Text(
                        passed ? 'Great job!' : 'Keep practicing!',
                        style: TextStyle(
                          color: context.appSurface,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _ScoreChip(label: 'Score', value: '$correct / $total'),
                          _ScoreChip(label: 'Accuracy', value: '$pct%'),
                          _ScoreChip(label: 'Time', value: _elapsedLabel),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 32),

                // Summary badges
                Row(
                  children: [
                    Expanded(
                      child: _SummaryChip(
                        icon: Icons.check_circle,
                        label: 'Correct',
                        count: correct,
                        color: Colors.green,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _SummaryChip(
                        icon: Icons.cancel,
                        label: 'Wrong',
                        count: wrong,
                        color: Colors.red,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _SummaryChip(
                        icon: Icons.help_outline,
                        label: 'Unanswered',
                        count: total - _userAnswers.length,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 32),

                Text(
                  'Review Answers',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: context.appTextPrimary,
                  ),
                ),
                SizedBox(height: 16),

                ...List.generate(total, (i) {
                  final q = _questions[i];
                  final userAns = _userAnswers[i];
                  final isCorrect =
                      userAns != null && userAns == q.correctIndex;
                  final skipped = userAns == null;

                  return Container(
                    margin: EdgeInsets.only(bottom: 14),
                    padding: EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: context.appSurface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: skipped
                            ? Colors.orange
                            : (isCorrect ? Colors.green : Colors.red),
                        width: 1.4,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              skipped
                                  ? Icons.help_outline
                                  : (isCorrect
                                      ? Icons.check_circle
                                      : Icons.cancel),
                              color: skipped
                                  ? Colors.orange
                                  : (isCorrect ? Colors.green : Colors.red),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'Q${i + 1}. ${q.question}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: context.appTextPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 14),
                        if (!skipped)
                          _AnswerRow(
                            letter:
                                String.fromCharCode(65 + userAns),
                            text: q.options[userAns],
                            isCorrect: isCorrect,
                          ),
                        _AnswerRow(
                          letter: String.fromCharCode(65 + q.correctIndex),
                          text: q.options[q.correctIndex],
                          isCorrect: true,
                          showAsKey: true,
                        ),
                        if (q.explanation != null &&
                            q.explanation!.isNotEmpty) ...[
                          SizedBox(height: 10),
                          Container(
                            padding: EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withAlpha(18),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'Explanation: ${q.explanation}',
                              style: TextStyle(
                                  fontStyle: FontStyle.italic, fontSize: 13, color: context.appTextSecondary),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }),

                SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.download),
                    label: Text('Download Question Script (PDF)'),
                    onPressed: () => _export(false),
                  ),
                ),
                SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.download),
                    label: Text('Download Answer Script (PDF)'),
                    onPressed: () => _export(true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.accent,
                    ),
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

class _ScoreChip extends StatelessWidget {
  final String label;
  final String value;
  const _ScoreChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              color: context.appSurface,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _SummaryChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;
  const _SummaryChip({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: color.withAlpha(18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(120)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          SizedBox(height: 6),
          Text(
            '$count',
            style: TextStyle(
                fontWeight: FontWeight.bold, color: color, fontSize: 18),
          ),
          Text(
            label,
            style: TextStyle(color: context.appTextSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _AnswerRow extends StatelessWidget {
  final String letter;
  final String text;
  final bool isCorrect;
  final bool showAsKey;

  const _AnswerRow({
    required this.letter,
    required this.text,
    required this.isCorrect,
    this.showAsKey = false,
  });

  @override
  Widget build(BuildContext context) {
    final bg = showAsKey
        ? Colors.green.withAlpha(20)
        : (isCorrect ? Colors.green.withAlpha(20) : Colors.red.withAlpha(20));
    final border = showAsKey
        ? Colors.green
        : (isCorrect ? Colors.green : Colors.red);
    final textColor = showAsKey
        ? Colors.green
        : (isCorrect ? Colors.green : Colors.red);

    return Container(
      margin: EdgeInsets.only(bottom: 6),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border.withAlpha(140)),
      ),
      child: Row(
        children: [
          Text(
            showAsKey ? 'Correct Answer: ' : 'Your Answer: ',
            style: TextStyle(
                fontSize: 12, color: context.appTextSecondary),
          ),
          Text(
            '$letter. ',
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(text, style: TextStyle(color: textColor)),
          ),
        ],
      ),
    );
  }
}
