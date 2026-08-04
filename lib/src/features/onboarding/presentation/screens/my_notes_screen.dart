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
        title: Text('New Note'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleController, decoration: InputDecoration(hintText: 'Title')),
            SizedBox(height: 12),
            TextField(controller: contentController, decoration: InputDecoration(hintText: 'Content'), maxLines: 4),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
            child: Text('Save', style: TextStyle(color: Colors.white)),
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
      backgroundColor: context.appBackground,
      appBar: AppBar(
        backgroundColor: context.appSurface,
        elevation: context.isDark ? 0 : 1,
        title: Text('My Notes', style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.bold)),
        iconTheme: IconThemeData(color: context.appTextPrimary),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addNote,
        backgroundColor: AppTheme.primary,
        child: Icon(Icons.add, color: Colors.white),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _notes.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.note_add_outlined, size: 64, color: context.appTextSecondary),
                      SizedBox(height: 16),
                      Text('No notes yet!', style: TextStyle(fontSize: 18, color: context.appTextSecondary)),
                      SizedBox(height: 4),
                      Text('Tap + to create your first note.', style: TextStyle(color: context.appTextSecondary)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: _notes.length,
                  itemBuilder: (context, index) {
                    final note = _notes[index];
                    return Card(
                      margin: EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      child: ListTile(
                        contentPadding: EdgeInsets.all(16),
                        title: Text(note['title'] ?? '', style: TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(note['content'] ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.delete_outline, color: Colors.red),
                          onPressed: () => _deleteNote(note['id']),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
