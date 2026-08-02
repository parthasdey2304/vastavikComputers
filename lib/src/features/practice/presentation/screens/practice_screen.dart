import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

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
        body: TabBarView(
          children: [
            _buildMCQTab(),
            const Center(child: Text('Coding Challenges Coming Soon')),
            const Center(child: Text('Previous Year Questions')),
          ],
        ),
      ),
    );
  }

  Widget _buildMCQTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _buildQuizCard('Core Java Basics', '10 Questions', 'Medium'),
        _buildQuizCard('Python Data Structures', '15 Questions', 'Hard'),
        _buildQuizCard('C Pointers & Memory', '5 Questions', 'Easy'),
      ],
    );
  }

  Widget _buildQuizCard(String title, String subtitle, String difficulty) {
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
                  color: AppTheme.accent.withAlpha(30),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(difficulty, style: const TextStyle(color: AppTheme.accent, fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              const Icon(Icons.timer_outlined, color: AppTheme.textSecondary, size: 20),
            ],
          ),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              child: const Text('Start Quiz'),
            ),
          ),
        ],
      ),
    );
  }
}
