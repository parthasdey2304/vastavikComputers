import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/firestore_service.dart';

class MyNotesScreen extends StatefulWidget {
  const MyNotesScreen({super.key});

  @override
  State<MyNotesScreen> createState() => _MyNotesScreenState();
}

class _MyNotesScreenState extends State<MyNotesScreen> {
  final _firestoreService = FirestoreService();
  List<Map<String, dynamic>> _notes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final notes = await _firestoreService.getNotes(uid);
      if (mounted) {
        setState(() {
          _notes = notes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addNote() async {
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Note'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: const InputDecoration(hintText: 'Title')),
            const SizedBox(height: 12),
            TextField(controller: contentController, decoration: const InputDecoration(hintText: 'Content'), maxLines: 4),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (result == true && titleController.text.trim().isNotEmpty) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final noteId = DateTime.now().millisecondsSinceEpoch.toString();
      await _firestoreService.saveNote(uid, noteId, {
        'title': titleController.text.trim(),
        'content': contentController.text.trim(),
        'createdAt': DateTime.now().toIso8601String(),
      });
      _loadNotes();
    }
  }

  Future<void> _deleteNote(String noteId) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await _firestoreService.deleteNote(uid, noteId);
    _loadNotes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: const Text('My Notes', style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNote,
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notes.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.note_add_outlined, size: 64, color: AppTheme.textSecondary),
                      SizedBox(height: 16),
                      Text('No notes yet!', style: TextStyle(fontSize: 18, color: AppTheme.textSecondary)),
                      SizedBox(height: 4),
                      Text('Tap + to create your first note.', style: TextStyle(color: AppTheme.textSecondary)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _notes.length,
                  itemBuilder: (context, index) {
                    final note = _notes[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(note['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(note['content'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _deleteNote(note['id']),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
