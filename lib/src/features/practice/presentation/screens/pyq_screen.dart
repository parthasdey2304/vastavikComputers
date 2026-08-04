import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/models/course.dart';
import '../../../../core/services/firestore_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/responsive_wrapper.dart';
import '../../../shared/presentation/screens/pdf_viewer_screen.dart';

final _papersStreamProvider = StreamProvider<List<QuestionPaperModel>>((ref) {
  return ref.watch(firestoreServiceProvider).streamQuestionPapers();
});

/// Past Year Questions listing. Reads the shared `questionPapers` collection,
/// but presents a clean PYQ-style list grouped by subject.
class PyqScreen extends ConsumerWidget {
  const PyqScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final papersAsync = ref.watch(_papersStreamProvider);

    return Scaffold(
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appSurface,
        elevation: context.isDark ? 0 : 1,
        title: Text(
          'Past Year Questions',
          style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.bold),
        ),
        iconTheme: IconThemeData(color: context.appTextPrimary),
      ),
      body: SafeArea(
        child: ResponsiveWrapper(
          child: papersAsync.when(
            loading: () => Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text('Failed to load PYQs:\n$e',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: context.appTextSecondary)),
              ),
            ),
            data: (papers) {
              final pyqs = papers.where((p) {
                // Treat all papers as potential PYQs; filter here if you add a 'isPyq' flag
                return p.subject.isNotEmpty;
              }).toList();

              if (pyqs.isEmpty) {
                return _emptyState(context);
              }

              // Group by subject
              final grouped = <String, List<QuestionPaperModel>>{};
              for (final p in pyqs) {
                grouped.putIfAbsent(p.subject, () => []).add(p);
              }
              final subjects = grouped.keys.toList()..sort();

              return ListView.builder(
                padding: EdgeInsets.all(20),
                itemCount: subjects.length,
                itemBuilder: (context, i) {
                  final subject = subjects[i];
                  final subjectPapers = grouped[subject]!;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(bottom: 8, top: 8),
                        child: Text(
                          subject,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: context.appTextPrimary,
                          ),
                        ),
                      ),
                      ...subjectPapers.map((p) => _PyqCard(paper: p)),
                      SizedBox(height: 12),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.article_outlined, size: 64, color: Colors.grey.shade400),
            SizedBox(height: 16),
            Text(
              'No PYQs available yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: context.appTextPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Admins can add Past Year Question papers from the Admin Dashboard.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

class _PyqCard extends ConsumerWidget {
  final QuestionPaperModel paper;
  const _PyqCard({required this.paper});

  Future<void> _openAttachment(BuildContext context, WidgetRef ref,
      Map<String, dynamic> attachment) async {
    final url = attachment['pdfUrl']?.toString() ?? '';
    final fileName = attachment['fileName']?.toString() ?? 'document.pdf';
    if (url.isEmpty) return;
    try {
      final bytes = await FirebaseStorage.instance.refFromURL(url).getData();
      if (bytes == null) return;
      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PdfViewerScreen(title: fileName, pdfBytes: bytes),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open PDF: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMcq = paper.type == 'mcq';
    final fs = ref.watch(firestoreServiceProvider);
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: context.appSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            leading: CircleAvatar(
              backgroundColor: (isMcq ? AppTheme.primary : AppTheme.accent).withAlpha(25),
              child: Icon(isMcq ? Icons.list_alt : Icons.code,
                  color: isMcq ? AppTheme.primary : AppTheme.accent),
            ),
            title: Text(paper.title,
                style: TextStyle(fontWeight: FontWeight.bold, color: context.appTextPrimary)),
            subtitle: Text(
              '${paper.questions.length} questions • ${paper.timeLimitMinutes} min',
              style: TextStyle(fontSize: 12, color: context.appTextSecondary),
            ),
            trailing: Icon(Icons.arrow_forward_ios, size: 16, color: context.appTextSecondary),
            onTap: () {
              // Route into the quiz taking flow for MCQ PYQs, or editor for coding
              if (isMcq) {
                context.push('/take-quiz', extra: {
                  'topic': paper.title,
                  'quizData': paper.questions,
                });
              } else {
                context.push('/editor', extra: {
                  'title': paper.title,
                  'challenge': paper.questions.isNotEmpty ? paper.questions.first : {},
                });
              }
            },
          ),
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: fs.streamPaperAttachments(paper.id),
            builder: (context, snap) {
              final attachments = snap.data ?? [];
              if (attachments.isEmpty) {
                return SizedBox.shrink();
              }
              return Padding(
                padding: EdgeInsets.fromLTRB(18, 0, 18, 14),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: attachments.map((att) {
                    final name = att['fileName']?.toString() ?? 'PDF';
                    return ActionChip(
                      avatar: Icon(Icons.picture_as_pdf, size: 18, color: Colors.red),
                      label: Text(name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 12)),
                      onPressed: () => _openAttachment(context, ref, att),
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
