import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:unipast/core/theme.dart';
import 'package:unipast/features/viewer/ai_explanation_service.dart';

class AIAskTutorSheet extends ConsumerStatefulWidget {
  final String documentText;

  const AIAskTutorSheet({super.key, required this.documentText});

  @override
  ConsumerState<AIAskTutorSheet> createState() => _AIAskTutorSheetState();
}

class _AIAskTutorSheetState extends ConsumerState<AIAskTutorSheet> {
  final TextEditingController _questionController = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  @override
  void dispose() {
    _questionController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final question = _questionController.text.trim();
    if (question.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'text': question});
      _questionController.clear();
      _isLoading = true;
    });

    try {
      final answer = await ref
          .read(aiExplanationServiceProvider)
          .askCustomQuestion(widget.documentText, question);

      if (!mounted) return;

      setState(() {
        _messages.add({'role': 'assistant', 'text': answer});
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _messages.add({
          'role': 'assistant',
          'text': '❌ **Error**: Failed to get answer. Please check your internet or API key.'
        });
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + bottomPadding),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1F2C) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.withAlpha(isDark ? 40 : 25),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.psychology_alt_rounded,
                      color: Colors.blue,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Ask AI Tutor',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const Divider(height: 32),

          // Message List
          if (_messages.isEmpty && !_isLoading)
            _buildEmptyState(isDark)
          else
            Flexible(
              child: SingleChildScrollView(
                reverse: true,
                child: Column(
                  children: [
                    ..._messages.map((msg) => _buildMessageBubble(msg, isDark)),
                    if (_isLoading) _buildLoadingShimmer(isDark),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Input Field
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _questionController,
                  decoration: InputDecoration(
                    hintText: 'Ask your question here...',
                    filled: true,
                    fillColor: isDark ? Colors.white10 : Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              const SizedBox(width: 12),
              IconButton.filled(
                onPressed: _isLoading ? null : _sendMessage,
                icon: const Icon(Icons.send_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: AppTheme.primaryTeal,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            Icon(Icons.chat_bubble_outline_rounded, size: 48, color: Colors.blue.withAlpha(100)),
            const SizedBox(height: 16),
            Text(
              'What would you like to know?',
              style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white70 : Colors.black54),
            ),
            const SizedBox(height: 4),
            const Text(
              'I have read this document and can help explain it.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, String> msg, bool isDark) {
    final isUser = msg['role'] == 'user';
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            const CircleAvatar(
              radius: 14,
              backgroundColor: Colors.blue,
              child: Icon(Icons.smart_toy_rounded, size: 16, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isUser 
                    ? AppTheme.primaryTeal 
                    : (isDark ? Colors.white10 : Colors.grey.shade100),
                borderRadius: BorderRadius.circular(20).copyWith(
                  bottomRight: isUser ? const Radius.circular(0) : null,
                  bottomLeft: !isUser ? const Radius.circular(0) : null,
                ),
              ),
              child: MarkdownBody(
                data: msg['text']!,
                selectable: true,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(
                    fontSize: 15,
                    color: isUser ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                  ),
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            const CircleAvatar(
              radius: 14,
              backgroundColor: Colors.grey,
              child: Icon(Icons.person_rounded, size: 16, color: Colors.white),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingShimmer(bool isDark) {
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.white10 : Colors.grey.shade300,
      highlightColor: isDark ? Colors.white24 : Colors.grey.shade100,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(radius: 14, backgroundColor: Colors.white),
          const SizedBox(width: 8),
          Container(
            height: 60,
            width: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ],
      ),
    );
  }
}
