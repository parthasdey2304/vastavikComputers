import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/responsive_wrapper.dart';

class PracticeScreen extends StatelessWidget {
  const PracticeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text('Practice & Quizzes', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
          bottom: const TabBar(
            labelColor: AppTheme.primary,
            unselectedLabelColor: AppTheme.textSecondary,
            indicatorColor: AppTheme.primary,
            tabs: [
              Tab(text: 'MCQs'),
              Tab(text: 'Coding'),
              Tab(text: 'PYQs'),
            ],
          ),
        ),
        body: ResponsiveWrapper(
          child: TabBarView(
          children: [
            _buildMCQTab(context),
            _buildCodingTab(),
            _buildPYQsTab(),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildMCQTab(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildQuizCard(context, 'Core Java Basics', 'java'),
        _buildQuizCard(context, 'Python Data Structures', 'python'),
        _buildQuizCard(context, 'C Pointers & Memory', 'c'),
      ],
    );
  }

  Widget _buildQuizCard(BuildContext context, String title, String subjectId) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.surface),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text('AI Powered', style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              const Icon(Icons.auto_awesome, color: AppTheme.primary, size: 20),
            ],
          ),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          const SizedBox(height: 4),
          const Text('Generate custom MCQs', style: TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                context.push('/quiz-setup?topic=${Uri.encodeComponent(title)}');
              },
              child: const Text('Start Quiz'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodingTab() {
    final challenges = [
      {'title': 'Reverse a String', 'difficulty': 'Easy', 'tags': 'Strings'},
      {'title': 'Find Max in Array', 'difficulty': 'Easy', 'tags': 'Arrays'},
      {'title': 'Implement a Stack', 'difficulty': 'Medium', 'tags': 'Data Structures'},
      {'title': 'Dijkstra Shortest Path', 'difficulty': 'Hard', 'tags': 'Graphs'},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: challenges.length,
      itemBuilder: (context, index) {
        final c = challenges[index];
        final isHard = c['difficulty'] == 'Hard';
        final diffColor = isHard ? Colors.red : (c['difficulty'] == 'Medium' ? Colors.orange : Colors.green);
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppTheme.surface)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(c['tags']!, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                  Text(c['difficulty']!, style: TextStyle(color: diffColor, fontWeight: FontWeight.bold, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 8),
              Text(c['title']!, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    context.push('/editor', extra: c);
                  }, 
                  child: const Text('Solve Challenge')
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPYQsTab() {
    final papers = [
      {'title': 'ICSE Computer Applications', 'year': '2023', 'board': 'ICSE'},
      {'title': 'CBSE Computer Science', 'year': '2023', 'board': 'CBSE'},
      {'title': 'ICSE Computer Applications', 'year': '2022', 'board': 'ICSE'},
    ];

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: papers.length,
      itemBuilder: (context, index) {
        final p = papers[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppTheme.surface)),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppTheme.primary.withAlpha(20), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.picture_as_pdf_rounded, color: AppTheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p['title']!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textPrimary)),
                    const SizedBox(height: 4),
                    Text('${p['board']} • ${p['year']}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              TextButton(onPressed: () {}, child: const Text('View Paper')),
            ],
          ),
        );
      },
    );
  }
}
