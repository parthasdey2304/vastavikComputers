import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/interactive_quiz_widget.dart';
import '../../../../core/widgets/responsive_wrapper.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage(this.text, this.isUser, {DateTime? timestamp})
      : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'isUser': isUser,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory ChatMessage.fromMap(Map<String, dynamic> map) {
    return ChatMessage(
      map['text'] ?? '',
      map['isUser'] ?? false,
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _textScrollController = ScrollController();
  final ScrollController _chatScrollController = ScrollController();
  
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  ChatSession? _chatSession;
  bool _showScrollToBottom = false;
  
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _previousText = '';
  
  String? _currentChatId;

  @override
  void initState() {
    super.initState();
    _messages = [
      ChatMessage('Hello! I am Vastavik Bot. How can I assist you today?', false)
    ];
    _chatScrollController.addListener(() {
      if (_chatScrollController.hasClients) {
        final maxScroll = _chatScrollController.position.maxScrollExtent;
        final currentScroll = _chatScrollController.offset;
        final shouldShow = maxScroll - currentScroll > 200;
        if (_showScrollToBottom != shouldShow) {
          setState(() {
            _showScrollToBottom = shouldShow;
          });
        }
      }
    });
  }

  void _scrollToBottom() {
    if (_chatScrollController.hasClients) {
      _chatScrollController.animateTo(
        _chatScrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _toggleListening() async {
    if (_speechToText.isListening) {
      await _speechToText.stop();
      setState(() {});
    } else {
      if (!_speechEnabled) {
        _speechEnabled = await _speechToText.initialize(
          onStatus: (status) => setState(() {}),
          onError: (errorNotification) => setState(() {}),
        );
        if (!_speechEnabled) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Speech recognition not available.')));
          }
          return;
        }
      }
      
      _previousText = _controller.text;
      await _speechToText.listen(onResult: _onSpeechResult);
      setState(() {});
    }
  }

  void _onSpeechResult(result) {
    setState(() {
      final newText = _previousText.isEmpty ? result.recognizedWords : '$_previousText ${result.recognizedWords}';
      _controller.text = newText;
      _controller.selection = TextSelection.fromPosition(TextPosition(offset: _controller.text.length));
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_textScrollController.hasClients) {
        _textScrollController.animateTo(
          _textScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
        );
      }
    });
  }

  GenerativeModel _getModel() {
    final apiKey = AppConfig.geminiApiKey;
    if (apiKey.isEmpty) {
      throw Exception('API Key not found. Please provide GEMINI_API_KEY as a build argument.');
    }
    return GenerativeModel(
      model: 'gemini-3.5-flash',
      apiKey: apiKey,
      systemInstruction: Content.system('You are Vastavik Bot, an AI coding assistant powered by the Kimi K3, designed for kids in ICSE schools. Keep your explanations simple, educational, and age-appropriate. If asked what model or version you are running, you must strictly state that you are Kimi K3.\n\nCRITICAL INSTRUCTION: If the user asks for a quiz, you MUST output the quiz ONLY as a JSON block wrapped in ```json ... ``` with the structure: {"type": "quiz", "title": "Quiz Title", "questions": [{"question": "...", "options": ["A", "B", "C", "D"], "answerIndex": 0}]}. If the user asks for a question paper, you MUST output ONLY a JSON block wrapped in ```json ... ``` with the structure: {"type": "questionPaper", "title": "Paper Title", "subject": "Subject Name", "durationMinutes": 60, "instructions": "Answer all questions.", "questions": [{"question": "...", "options": ["A", "B", "C", "D"], "answerIndex": 0}]}. Do not add any text before or after the JSON block.'),
    );
  }

  Future<void> _saveMessageToFirestore(ChatMessage msg) async {
    final user = ref.read(authStateChangesProvider).value;
    if (user == null) return;
    
    final firestore = FirebaseFirestore.instance;
    final chatRef = firestore.collection('users').doc(user.uid).collection('ai_chats');

    if (_currentChatId == null) {
      // Create new chat
      final doc = await chatRef.add({
        'title': msg.text.length > 30 ? '${msg.text.substring(0, 30)}...' : msg.text,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'messages': [_messages.first.toMap(), msg.toMap()],
      });
      _currentChatId = doc.id;
    } else {
      // Update existing
      await chatRef.doc(_currentChatId).update({
        'updatedAt': FieldValue.serverTimestamp(),
        'messages': FieldValue.arrayUnion([msg.toMap()])
      });
    }
  }

  Future<void> _sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    
    final userMsg = ChatMessage(text, true);
    setState(() {
      _messages.add(userMsg);
      _isLoading = true;
    });
    _controller.clear();
    
    await _saveMessageToFirestore(userMsg);

    try {
      if (_chatSession == null) {
        final model = _getModel();
        _chatSession = model.startChat();
      }
      
      final content = Content.text(text);
      final response = await _chatSession!.sendMessage(content);
      
      final botMsg = ChatMessage(response.text ?? 'No response', false);
      setState(() {
        _messages.add(botMsg);
      });
      await _saveMessageToFirestore(botMsg);
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage('Gemini AI Error: Make sure your API key is correct and valid.\n\nDetails: $e', false));
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToBottom();
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _createNewChat() {
    setState(() {
      _currentChatId = null;
      _chatSession = null;
      _messages = [
        ChatMessage('Hello! I am Vastavik Bot. How can I assist you today?', false)
      ];
    });
    Navigator.pop(context); // close drawer
  }

  void _loadChat(String id, List<ChatMessage> history) {
    setState(() {
      _currentChatId = id;
      _messages = history;
      
      final model = _getModel();
      List<Content> apiHistory = [];
      for (var msg in history) {
        if (msg.isUser) {
          apiHistory.add(Content.text(msg.text));
        } else {
          apiHistory.add(Content.model([TextPart(msg.text)]));
        }
      }
      _chatSession = model.startChat(history: apiHistory);
    });
    Navigator.pop(context); // close drawer
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  Widget _buildDrawer() {
    final user = ref.watch(authStateChangesProvider).value;
    if (user == null) {
      return Drawer(child: Center(child: Text('Please log in.')));
    }
    
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: AppTheme.primary),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.smart_toy, color: Colors.white, size: 40),
                  SizedBox(height: 8),
                  Text('Vastavik Bot Chats', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.add, color: AppTheme.primary),
            title: Text('New Chat', style: TextStyle(fontWeight: FontWeight.bold)),
            onTap: _createNewChat,
          ),
          Divider(),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('ai_chats')
                  .orderBy('updatedAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Center(child: Text('Error loading chats'));
                if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
                
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) return Center(child: Text('No previous chats.'));
                
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final title = data['title'] ?? 'Chat #${docs.length - index}';
                    final isSelected = doc.id == _currentChatId;
                    
                    return ListTile(
                      selected: isSelected,
                      selectedTileColor: AppTheme.primary.withAlpha(20),
                      leading: Icon(Icons.chat_bubble_outline, color: isSelected ? AppTheme.primary : Colors.grey),
                      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                      onTap: () {
                        final rawMessages = (data['messages'] as List?) ?? [];
                        final messages = rawMessages
                            .map((m) => ChatMessage.fromMap(m as Map<String, dynamic>))
                            .toList();
                        _loadChat(doc.id, messages);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBackground,
      drawer: _buildDrawer(),
      appBar: AppBar(
        backgroundColor: context.appSurface,
        elevation: context.isDark ? 0 : 1,
        title: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Icon(Icons.smart_toy, color: AppTheme.primary),
              SizedBox(width: 8),
              Text('Vastavik Bot', style: TextStyle(color: context.appTextPrimary, fontWeight: FontWeight.bold)),
              SizedBox(width: 16),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: AppTheme.accent.withAlpha(30), borderRadius: BorderRadius.circular(8)),
                child: Text('Kimi K3', style: TextStyle(color: AppTheme.accent, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
      body: ResponsiveWrapper(
        child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                ListView.builder(
                  controller: _chatScrollController,
                  padding: EdgeInsets.all(20),
                  itemCount: _messages.length + (_isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (_isLoading && index == _messages.length) {
                      return Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: _buildBotMessage(context, '*Developing...*'),
                      );
                    }
                    final msg = _messages[index];
                    return Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: msg.isUser ? _buildUserMessage(context, msg.text) : _buildBotMessage(context, msg.text),
                    );
                  },
                ),
                if (_showScrollToBottom)
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: FloatingActionButton(
                      mini: true,
                      onPressed: _scrollToBottom,
                      backgroundColor: context.appSurface,
                      foregroundColor: AppTheme.primary,
                      elevation: 4,
                      child: Icon(Icons.keyboard_arrow_down),
                    ),
                  ),
              ],
            ),
          ),
          _buildQuickActions(),
          _buildMessageInput(),
        ],
        ),
      ),
    );
  }

  Widget _buildBotMessage(BuildContext context, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 16,
          backgroundColor: AppTheme.primary,
          child: Icon(Icons.smart_toy, size: 16, color: Colors.white),
        ),
        SizedBox(width: 12),
        Flexible(
          child: Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: context.appSurface,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: MarkdownBody(
              data: text,
              builders: {
                'code': CodeElementBuilder(context),
              },
              styleSheet: MarkdownStyleSheet(
                p: TextStyle(color: context.appTextPrimary),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserMessage(BuildContext context, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Flexible(
          child: Container(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Text(text, style: TextStyle(color: Colors.white)),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return SizedBox(
      height: 50,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 20),
        children: [
          _buildChip('Explain Code', () => _sendMessage('Can you explain this code snippet?')),
          SizedBox(width: 8),
          _buildChip('Generate Quiz', () => _sendMessage('Generate 3 MCQs about Java OOP concepts with 4 options each.')),
          SizedBox(width: 8),
          _buildChip('Find Bug', () => _sendMessage('Help me find a bug in my Flutter code.')),
        ],
      ),
    );
  }

  Widget _buildChip(String label, VoidCallback onTap) {
    return ActionChip(
      label: Text(label, style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.bold, fontSize: 12)),
      backgroundColor: AppTheme.primary.withAlpha(20),
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onPressed: onTap,
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.appSurface,
        boxShadow: [BoxShadow(color: Color(0x05000000), blurRadius: 10, offset: Offset(0, -4))],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: context.appSurface, borderRadius: BorderRadius.circular(24)),
                child: Scrollbar(
                  controller: _textScrollController,
                  child: TextField(
                    controller: _controller,
                    scrollController: _textScrollController,
                    minLines: 1,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: 'Ask anything...',
                      border: InputBorder.none,
                    ),
                    onSubmitted: _sendMessage,
                  ),
                ),
              ),
            ),
            SizedBox(width: 8),
            CircleAvatar(
              radius: 24,
              backgroundColor: _speechToText.isListening ? Colors.red.withAlpha(50) : AppTheme.primary.withAlpha(20),
              child: IconButton(
                icon: Icon(
                  _speechToText.isListening ? Icons.mic_off : Icons.mic,
                  color: _speechToText.isListening ? Colors.red : AppTheme.primary,
                ),
                onPressed: _toggleListening,
              ),
            ),
            SizedBox(width: 8),
            CircleAvatar(
              radius: 24,
              backgroundColor: AppTheme.primary,
              child: IconButton(
                icon: Icon(Icons.send, color: Colors.white),
                onPressed: () => _sendMessage(_controller.text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CodeElementBuilder extends MarkdownElementBuilder {
  final BuildContext context;
  CodeElementBuilder(this.context);

  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    final codeText = element.textContent;
    final isBlock = codeText.contains('\n');

    if (isBlock) {
      try {
        final decoded = jsonDecode(codeText);
        if (decoded is Map<String, dynamic> && 
            (decoded['type'] == 'quiz' || decoded['type'] == 'questionPaper')) {
          return InteractiveQuizWidget(quizData: decoded);
        }
      } catch (e) {
        // Not a JSON quiz, just render as normal code block
      }
    }

    if (!isBlock) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(codeText, style: TextStyle(fontFamily: 'monospace', fontSize: 13)),
      );
    }

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(vertical: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.only(top: 24.0),
            child: SelectableText(
              codeText,
              style: TextStyle(fontFamily: 'monospace', fontSize: 13, color: Colors.black87),
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            child: InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: codeText));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Code copied to clipboard!'), duration: Duration(seconds: 1)),
                );
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.copy, size: 14, color: Colors.grey),
                  SizedBox(width: 4),
                  Text('Copy', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
