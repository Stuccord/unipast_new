import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shimmer/shimmer.dart';
import 'package:unipast/core/theme.dart';
import 'package:unipast/features/viewer/ai_explanation_service.dart';

class AIDocSummarySheet extends ConsumerStatefulWidget {
  final String documentText;

  const AIDocSummarySheet({super.key, required this.documentText});

  @override
  ConsumerState<AIDocSummarySheet> createState() => _AIDocSummarySheetState();
}

class _AIDocSummarySheetState extends ConsumerState<AIDocSummarySheet> {
  late Future<String> _summaryFuture;

  @override
  void initState() {
    super.initState();
    _loadSummary();
  }

  void _loadSummary() {
    setState(() {
      _summaryFuture = ref
          .read(aiExplanationServiceProvider)
          .summarizeDocument(widget.documentText);
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
                      color: Colors.orange.withAlpha(isDark ? 40 : 25),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.summarize_rounded,
                      color: Colors.orange,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Document Summary',
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
              future: _summaryFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingShimmer(isDark);
                }

                if (snapshot.hasError) {
                  return _buildErrorState(snapshot.error.toString());
                }

                final summary = snapshot.data ?? 'No summary found.';

                return SingleChildScrollView(
                  child: Column(
                    children: [
                      MarkdownBody(
                        data: summary,
                        styleSheet: MarkdownStyleSheet(
                          p: TextStyle(
                            fontSize: 16,
                            height: 1.5,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                          h1: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          h2: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _loadSummary,
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Regenerate Summary'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryTeal,
                            foregroundColor: Colors.white,
                          ),
                        ),
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
          5,
          (index) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
              height: index == 0 ? 30 : 20,
              width: index % 2 == 0 ? double.infinity : 250,
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
          const Text('Failed to generate summary', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          ElevatedButton(onPressed: _loadSummary, child: const Text('Try Again')),
        ],
      ),
    );
  }
}
