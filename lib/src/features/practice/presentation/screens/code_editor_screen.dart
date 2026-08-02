import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/services/code_execution_service.dart';

class CodeEditorScreen extends StatefulWidget {
  final Map<String, dynamic> challenge;
  const CodeEditorScreen({super.key, required this.challenge});

  @override
  State<CodeEditorScreen> createState() => _CodeEditorScreenState();
}

class _CodeEditorScreenState extends State<CodeEditorScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _quickNoteController = TextEditingController();
  final CodeExecutionService _executionService = CodeExecutionService();

  String _selectedLanguage = 'python';

  double? _editorFontSizeNullable;
  double get _editorFontSize => _editorFontSizeNullable ?? 14.0;
  set _editorFontSize(double val) => _editorFontSizeNullable = val;

  bool _isOutputVisible = false;
  bool _isRunning = false;
  String _outputResult = '';
  int _outputExitCode = 0;
  double _executionTime = 0.0;

  // Notes list: each entry has 'id' (Firestore doc id) and 'content'
  final List<Map<String, String>> _notesList = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 1);
    
    // Default boilerplate
    _codeController.text = '''def solve():
    # Write your code here
    pass

print("Execution started...")
solve()
''';
  }

  @override
  void dispose() {
    _tabController.dispose();
    _codeController.dispose();
    _notesController.dispose();
    _quickNoteController.dispose();
    super.dispose();
  }

  void _updateBoilerplate(String lang) {
    const boilerplates = {
      'python':     'print("Hello, World!")',
      'java':       'public class Main {\n  public static void main(String[] args) {\n    System.out.println("Hello, World!");\n  }\n}',
      'c':          '#include <stdio.h>\nint main() {\n  printf("Hello, World!\\n");\n  return 0;\n}',
      'c++':        '#include <iostream>\nint main() {\n  std::cout << "Hello, World!" << std::endl;\n  return 0;\n}',
      'javascript': 'console.log("Hello, World!");',
      'sqlite3':    'SELECT "Hello, World!";',
    };
    _codeController.text = boilerplates[lang] ?? '';
  }

  void _runCode() async {
    setState(() {
      _isOutputVisible = true;
      _isRunning = true;
      _outputResult = 'Running...';
    });

    final stopwatch = Stopwatch()..start();
    try {
      final result = await _executionService.executeCode(_selectedLanguage, '', _codeController.text);
      stopwatch.stop();
      
      if (!mounted) return;

      setState(() {
        _isRunning = false;
        _executionTime = stopwatch.elapsedMilliseconds / 1000.0;
        if (result['success'] == true) {
          _outputResult = result['output'];
          _outputExitCode = 0;
        } else {
          // Show the actual compiler/runtime error output
          final errOutput = result['output'] ?? result['error'] ?? 'Unknown error';
          _outputResult = errOutput;
          _outputExitCode = -1;
        }
      });
    } catch (e) {
      stopwatch.stop();
      if (!mounted) return;
      
      setState(() {
        _isRunning = false;
        if (e.toString().contains('INTERNET_REQUIRED')) {
          _outputResult = 'Error: Internet connection is required to run this code.';
          _showOfflineWarning();
        } else {
          _outputResult = 'Error: $e';
        }
        _outputExitCode = -1;
      });
    }
  }

  void _showOfflineWarning() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2430),
        title: const Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.redAccent),
            SizedBox(width: 12),
            Text('No Internet', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          'Internet connection is required to run this code on the remote server.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK', style: TextStyle(color: Color(0xFF4ADE80))),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Very dark slate
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Row(
          children: [
            Icon(Icons.terminal, color: Color(0xFF4ADE80)),
            SizedBox(width: 8),
            Text('Editor', style: TextStyle(color: Color(0xFF4ADE80), fontWeight: FontWeight.bold, fontSize: 24)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white70), 
            onPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: const Color(0xFF1E293B),
                builder: (context) => StatefulBuilder(
                  builder: (context, setModalState) {
                    return Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Editor Settings', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              const Text('Font Size', style: TextStyle(color: Colors.white70, fontSize: 16)),
                              Expanded(
                                child: Slider(
                                  value: _editorFontSize,
                                  min: 10.0,
                                  max: 30.0,
                                  divisions: 20,
                                  activeColor: const Color(0xFF4ADE80),
                                  label: _editorFontSize.round().toString(),
                                  onChanged: (val) {
                                    setModalState(() => _editorFontSize = val);
                                    setState(() => _editorFontSize = val);
                                  },
                                ),
                              ),
                              Text('${_editorFontSize.round()}px', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    );
                  }
                ),
              );
            }
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF0EA5E9),
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          tabs: const [
            Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.help_outline, size: 18), SizedBox(width: 8), Text('Question')])),
            Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.code, size: 18), SizedBox(width: 8), Text('Code')])),
            Tab(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.description_outlined, size: 18), SizedBox(width: 8), Text('Notes')])),
          ],
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [
              _buildQuestionTab(),
              _buildCodeTab(),
              _buildNotesTab(),
            ],
          ),
          
          // Output Panel overlay
          if (_isOutputVisible)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildOutputPanel(),
            ),
        ],
      ),
    );
  }

  Widget _buildQuestionTab() {
    final title = widget.challenge['title'] ?? 'Challenge';
    final difficulty = widget.challenge['difficulty'] ?? 'Easy';
    final diffColor = difficulty == 'Hard' ? Colors.redAccent : (difficulty == 'Medium' ? Colors.orangeAccent : const Color(0xFF4ADE80));
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: diffColor.withAlpha(30), borderRadius: BorderRadius.circular(4)),
                child: Text(difficulty, style: TextStyle(color: diffColor, fontWeight: FontWeight.bold, fontSize: 13)),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.thumb_up_alt_outlined, color: Colors.white54, size: 16),
              const SizedBox(width: 4),
              const Text('45.2K', style: TextStyle(color: Colors.white54, fontSize: 13)),
              const SizedBox(width: 16),
              const Icon(Icons.thumb_down_alt_outlined, color: Colors.white54, size: 16),
              const SizedBox(width: 4),
              const Text('1.4K', style: TextStyle(color: Colors.white54, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Solve the problem exactly as specified. Read the inputs carefully.', style: TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white12)),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Example 1:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
                SizedBox(height: 12),
                Text('Input: nums = [2,7,11,15], target = 9', style: TextStyle(fontFamily: 'monospace', color: Color(0xFF93C5FD))),
                SizedBox(height: 8),
                Text('Output: [0,1]', style: TextStyle(fontFamily: 'monospace', color: Color(0xFF93C5FD))),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildCodeTab() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: const Color(0xFF1E293B),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(color: const Color(0xFF0F172A), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.white12)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedLanguage,
                    dropdownColor: const Color(0xFF1E293B),
                    icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white54),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    items: const [
                      DropdownMenuItem(value: 'python', child: Text('Python 3.10')),
                      DropdownMenuItem(value: 'java', child: Text('Java')),
                      DropdownMenuItem(value: 'c', child: Text('C')),
                      DropdownMenuItem(value: 'c++', child: Text('C++')),
                      DropdownMenuItem(value: 'javascript', child: Text('JavaScript')),
                      DropdownMenuItem(value: 'sqlite3', child: Text('SQL')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _selectedLanguage = val);
                        _updateBoilerplate(val);
                      }
                    },
                  ),
                ),
              ),
              const Spacer(),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _isRunning ? null : _runCode,
                icon: _isRunning ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0F172A))) : const Icon(Icons.play_arrow, color: Color(0xFF0F172A)),
                label: Text(_isRunning ? 'RUNNING' : 'RUN', style: const TextStyle(color: Color(0xFF0F172A), fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4ADE80),
                  disabledBackgroundColor: const Color(0xFF4ADE80).withOpacity(0.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Container(
            color: const Color(0xFF0F172A),
            child: SingleChildScrollView(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Line numbers
                  Container(
                    width: 40,
                    padding: const EdgeInsets.only(top: 16, right: 8),
                    color: const Color(0xFF0F172A),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(
                        '\n'.allMatches(_codeController.text).length + 1, 
                        (index) => Text('${index + 1}', style: GoogleFonts.firaCode(color: Colors.white24, fontSize: _editorFontSize, height: 1.5))
                      ),
                    ),
                  ),
                  // Editor
                  Expanded(
                    child: Stack(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.only(top: 8, left: 8, bottom: 80, right: 8),
                          child: HighlightView(
                            _codeController.text.isEmpty ? ' ' : _codeController.text,
                            language: _selectedLanguage == 'sqlite3' ? 'sql' : _selectedLanguage,
                            theme: {...atomOneDarkTheme, 'root': TextStyle(backgroundColor: Colors.transparent, color: atomOneDarkTheme['root']?.color)},
                            padding: EdgeInsets.zero,
                            textStyle: GoogleFonts.firaCode(fontSize: _editorFontSize, height: 1.5),
                          ),
                        ),
                        TextField(
                          controller: _codeController,
                          maxLines: null,
                          onChanged: (_) => setState(() {}),
                          cursorColor: Colors.white,
                          textAlignVertical: TextAlignVertical.top,
                          style: GoogleFonts.firaCode(color: Colors.transparent, fontSize: _editorFontSize, height: 1.5),
                          decoration: const InputDecoration(
                            filled: true,
                            fillColor: Colors.transparent,
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.only(top: 8, left: 8, bottom: 80, right: 8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNotesTab() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Algorithm Implementation Ideas', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF93C5FD))),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(4), border: Border.all(color: const Color(0xFF0EA5E9))),
                child: const Text('#graph-traversal', style: TextStyle(color: Color(0xFF93C5FD), fontSize: 12)),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(4), border: Border.all(color: const Color(0xFF4ADE80))),
                child: const Text('#optimization', style: TextStyle(color: Color(0xFF4ADE80), fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
              child: _notesList.isEmpty
                ? const Center(child: Text('No notes yet. Add one below!', style: TextStyle(color: Colors.white30)))
                : ListView.builder(
                    itemCount: _notesList.length,
                    itemBuilder: (context, index) {
                      final note = _notesList[index];
                      return Dismissible(
                        key: Key(note['id']!),
                        background: Container(color: Colors.red.withOpacity(0.3), alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 16), child: const Icon(Icons.delete, color: Colors.red)),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) => _deleteNote(note['id']!, index),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                          child: Row(
                            children: [
                              const Text('• ', style: TextStyle(color: Color(0xFF4ADE80), fontSize: 16)),
                              Expanded(child: Text(note['content']!, style: const TextStyle(color: Colors.white70, fontSize: 15))),
                              IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18), onPressed: () => _deleteNote(note['id']!, index)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _quickNoteController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Add a quick note...',
                      hintStyle: TextStyle(color: Colors.white30),
                      border: InputBorder.none,
                      filled: true,
                      fillColor: Colors.transparent,
                      isDense: true,
                    ),
                    onSubmitted: (_) => _saveQuickNote(),
                  ),
                ),
                GestureDetector(
                  onTap: _saveQuickNote,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: const BoxDecoration(color: Color(0xFF0EA5E9), shape: BoxShape.circle),
                    child: const Icon(Icons.send, color: Colors.white, size: 16),
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Future<void> _saveQuickNote() async {
    if (_quickNoteController.text.trim().isEmpty) return;
    final text = _quickNoteController.text.trim();
    try {
      final docRef = await FirebaseFirestore.instance.collection('notes').add({
        'content': text,
        'challengeId': widget.challenge['id'] ?? 'unknown',
        'timestamp': FieldValue.serverTimestamp(),
      });
      setState(() {
        _notesList.add({'id': docRef.id, 'content': text});
        _quickNoteController.clear();
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Note saved!')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  Future<void> _deleteNote(String docId, int index) async {
    try {
      await FirebaseFirestore.instance.collection('notes').doc(docId).delete();
      setState(() => _notesList.removeAt(index));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }

  Widget _buildOutputPanel() {
    final isSuccess = _outputExitCode == 0;
    
    return Container(
      decoration: const BoxDecoration(
        color: Colors.black,
        border: Border(top: BorderSide(color: Colors.white12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Panel Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: const Color(0xFF1E293B),
            child: Row(
              children: [
                const Icon(Icons.terminal, color: Color(0xFF93C5FD), size: 16),
                const SizedBox(width: 8),
                const Text('OUTPUT', style: TextStyle(color: Color(0xFF93C5FD), fontWeight: FontWeight.bold, letterSpacing: 1)),
                const Spacer(),
                if (_isRunning)
                  const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF4ADE80)))
                else
                  Row(
                    children: [
                      Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: isSuccess ? const Color(0xFF4ADE80) : Colors.redAccent)),
                      const SizedBox(width: 6),
                      Text(isSuccess ? 'Ready' : 'Failed', style: TextStyle(color: isSuccess ? const Color(0xFF4ADE80) : Colors.redAccent)),
                    ],
                  ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () => setState(() => _isOutputVisible = false),
                  child: const Icon(Icons.close, color: Colors.white54, size: 20),
                ),
              ],
            ),
          ),
          // Output Body
          Container(
            padding: const EdgeInsets.all(16),
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.3),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('> Execution result:', style: TextStyle(color: Colors.white54, fontFamily: 'monospace')),
                  const SizedBox(height: 12),
                  Text(_outputResult, style: TextStyle(color: isSuccess ? const Color(0xFF4ADE80) : Colors.redAccent, fontFamily: 'monospace', fontSize: 14)),
                  const SizedBox(height: 24),
                  if (!_isRunning)
                    Text('⏱ Process exited with code $_outputExitCode in ${_executionTime.toStringAsFixed(3)}s', style: const TextStyle(color: Colors.white30, fontFamily: 'monospace', fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
