
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/chat_message.dart';
import '../theme/app_theme.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/jarvis_orb.dart';
import '../services/voice_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, this.selectedAI = "Auto Mode"});

  final String selectedAI;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  static const String _historyKey = 'jarvis_chat_history';

  static const String _welcomeMessage =
      "JARVIS core online. Voice input is being connected. "
      "Claude AI is not connected yet.";

  final List<ChatMessage> _messages = [
    ChatMessage(
      text: _welcomeMessage,
      isUser: false,
    ),
  ];

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final VoiceService _voiceService = VoiceService();

  bool _isListening = false;
  bool _isSending = false;
  String _language = 'English';

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _saveMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final history = _messages
          .map((message) => message.toJson())
          .toList();

      await prefs.setString(
        _historyKey,
        jsonEncode(history),
      );
    } catch (error) {
      debugPrint('Chat history save error: $error');
    }
  }

  Future<void> _loadMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final savedHistory = prefs.getString(_historyKey);

      if (savedHistory == null) return;

      final decoded = jsonDecode(savedHistory);

      if (decoded is! List) return;

      final loadedMessages = decoded
          .whereType<Map>()
          .map(
            (item) => ChatMessage.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList();

      if (!mounted) return;

      if (loadedMessages.isEmpty) return;

      setState(() {
        _messages
          ..clear()
          ..addAll(loadedMessages);
      });

      _scrollToBottom();
    } catch (error) {
      debugPrint('Chat history load error: $error');
    }
  }

  Future<void> _clearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.panelColor,
        title: const Text(
          'Clear Chat History?',
          style: TextStyle(color: AppTheme.primaryBlue),
        ),
        content: const Text(
          'Do you want to delete all saved messages?',
          style: TextStyle(color: AppTheme.textColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_historyKey);

      if (!mounted) return;

      setState(() {
        _messages
          ..clear()
          ..add(
            ChatMessage(
              text: _welcomeMessage,
              isUser: false,
            ),
          );
      });

      _scrollToBottom();
    } catch (error) {
      debugPrint('Clear history error: $error');
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();

    if (text.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
      _messages.add(
        ChatMessage(text: text, isUser: true),
      );
    });

    _controller.clear();
    _scrollToBottom();

    await _saveMessages();

    await _voiceService.stopListening();

    if (mounted) {
      setState(() => _isListening = false);
    }

    String reply;

    try {
      final response = await http
          .post(
            Uri.parse(
              'https://jarvis-assistant-t0ih.onrender.com/chat',
            ),
            headers: {
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'message': text,
              'provider': widget.selectedAI,
            }),
          )
          .timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        reply = data is Map && data['reply'] != null
            ? data['reply'].toString()
            : 'JARVIS received an invalid reply.';
      } else {
        reply = 'Backend error: ${response.statusCode}';
      }
    } catch (error) {
      reply =
          'Could not connect to JARVIS server. Please check your internet.';
    }

    if (!mounted) return;

    setState(() {
      _isSending = false;
      _messages.add(
        ChatMessage(text: reply, isUser: false),
      );
    });

    _scrollToBottom();

    await _saveMessages();

    await _voiceService.speak(
      reply,
      locale: _language == 'English' ? 'en-US' : 'mr-IN',
    );
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _onMicPressed() async {
    if (_isListening) {
      await _voiceService.stopListening();

      if (mounted) {
        setState(() => _isListening = false);
      }

      return;
    }

    setState(() => _isListening = true);

    try {
      await _voiceService.startListening(
        locale: _language == 'English' ? 'en-US' : 'mr-IN',
        onListeningChanged: (listening) {
          if (mounted) {
            setState(() => _isListening = listening);
          }
        },
        onResult: (recognizedText) {
          if (!mounted) return;

          setState(() {
            _controller.value = TextEditingValue(
              text: recognizedText,
              selection: TextSelection.collapsed(
                offset: recognizedText.length,
              ),
            );

            if (recognizedText.isNotEmpty) {
              _scrollToBottom();
            }
          });
        },
      );
    } catch (error) {
      if (!mounted) return;

      setState(() => _isListening = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppTheme.panelColor,
          content: Text(
            'Voice error: $error',
            style: const TextStyle(
              color: AppTheme.primaryBlue,
            ),
          ),
        ),
      );
    }
  }

  void _toggleLanguage() {
    setState(() {
      _language = _language == 'English' ? 'Marathi' : 'English';
    });
  }

  @override
  void dispose() {
    _voiceService.stopListening();
    _voiceService.stopSpeaking();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: const Text(
          'JARVIS CHAT',
          style: TextStyle(letterSpacing: 2),
        ),
        actions: [
          IconButton(
            tooltip: 'Clear Chat History',
            onPressed: _clearHistory,
            icon: const Icon(
              Icons.delete_outline,
              color: AppTheme.primaryBlue,
            ),
          ),
          TextButton(
            onPressed: _toggleLanguage,
            child: Text(
              _language == 'English' ? 'EN' : 'मर',
              style: const TextStyle(
                color: AppTheme.primaryBlue,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: JarvisOrb(
              size: 90,
              isListening: _isListening,
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _messages.length + (_isSending ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          "JARVIS is thinking...",
                          style: TextStyle(
                            color: AppTheme.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ChatBubble(
                  message: _messages[index],
                );
              },
            ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: const BoxDecoration(
        color: AppTheme.panelColor,
        border: Border(
          top: BorderSide(
            color: AppTheme.deepBlue,
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            _MicButton(
              isListening: _isListening,
              onPressed: _onMicPressed,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: _controller,
                style: const TextStyle(
                  color: AppTheme.textColor,
                ),
                decoration: InputDecoration(
                  hintText: _language == 'English'
                      ? 'Type a message...'
                      : 'संदेश टाइप करा...',
                  hintStyle: const TextStyle(
                    color: AppTheme.mutedTextColor,
                  ),
                  filled: true,
                  fillColor: AppTheme.deepBlue.withOpacity(0.3),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _sendMessage,
              icon: const Icon(
                Icons.send_rounded,
                color: AppTheme.primaryBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MicButton extends StatelessWidget {
  final bool isListening;
  final VoidCallback onPressed;

  const _MicButton({
    required this.isListening,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isListening
              ? AppTheme.primaryBlue.withOpacity(0.25)
              : AppTheme.deepBlue.withOpacity(0.4),
          border: Border.all(
            color: isListening
                ? AppTheme.primaryBlue
                : AppTheme.secondaryBlue,
            width: 1.5,
          ),
        ),
        child: Icon(
          isListening ? Icons.mic : Icons.mic_none,
          color: isListening
              ? AppTheme.primaryBlue
              : AppTheme.secondaryBlue,
        ),
      ),
    );
  }
}

