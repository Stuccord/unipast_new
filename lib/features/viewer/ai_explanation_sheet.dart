import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:unipast/core/theme.dart';
import 'package:unipast/features/viewer/ai_explanation_service.dart';

class AIExplanationSheet extends ConsumerStatefulWidget {
  final String questionText;

  const AIExplanationSheet({super.key, required this.questionText});

  @override
  ConsumerState<AIExplanationSheet> createState() => _AIExplanationSheetState();
}

class _AIExplanationSheetState extends ConsumerState<AIExplanationSheet> {
  late Future<String> _explanationFuture;

  @override
  void initState() {
    super.initState();
    _loadExplanation();
  }

  void _loadExplanation() {
    setState(() {
      _explanationFuture = ref
          .read(aiExplanationServiceProvider)
          .explainQuestion(widget.questionText);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
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
                      color: AppTheme.primaryTeal.withAlpha(isDark ? 40 : 25),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: AppTheme.primaryTeal,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'AI Explanation',
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

          // Content
          Flexible(
            child: FutureBuilder<String>(
              future: _explanationFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingShimmer(isDark);
                }

                if (snapshot.hasError) {
                  return _buildErrorState(snapshot.error.toString());
                }

                final explanation = snapshot.data ?? 'No explanation found.';

                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MarkdownBody(
                        data: explanation,
                        selectable: true,
                        styleSheet: MarkdownStyleSheet(
                          p: TextStyle(
                            fontSize: 16,
                            height: 1.5,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                          h1: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          h2: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          code: TextStyle(
                            backgroundColor: isDark ? Colors.white10 : Colors.black12,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // Footer Actions
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: explanation));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Copied to clipboard')),
                                );
                              },
                              icon: const Icon(Icons.copy_rounded, size: 18),
                              label: const Text('Copy Results'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isDark ? Colors.white10 : Colors.grey.shade100,
                                foregroundColor: isDark ? Colors.white : Colors.black87,
                                elevation: 0,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _loadExplanation,
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              label: const Text('Regenerate'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingShimmer(bool isDark) {
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.white10 : Colors.grey.shade300,
      highlightColor: isDark ? Colors.white24 : Colors.grey.shade100,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(
          6,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              height: index == 0 ? 24 : 16,
              width: index % 2 == 0 ? double.infinity : 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline_rounded, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          const Text(
            'Failed to load explanation',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadExplanation,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}
