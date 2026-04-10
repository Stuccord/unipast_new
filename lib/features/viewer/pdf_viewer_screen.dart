import 'dart:io';
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:unipast/features/auth/stats_service.dart';
import 'package:unipast/features/viewer/ai_explanation_sheet.dart';
import 'package:unipast/features/viewer/ai_summary_sheet.dart';
import 'package:unipast/features/viewer/ai_quiz_screen.dart';
import 'package:unipast/features/viewer/ai_ask_tutor_sheet.dart';
import 'package:unipast/core/theme.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:unipast/core/security_service.dart';
import 'package:unipast/features/offline/offline_service.dart';
import 'package:unipast/features/admin/activity_service.dart';

class PdfViewerScreen extends ConsumerStatefulWidget {
  final String pdfUrl;
  final String userName;
  final String questionId;
  final bool isLocal;

  const PdfViewerScreen({
    super.key,
    required this.pdfUrl,
    required this.userName,
    required this.questionId,
    this.isLocal = false,
  });

  @override
  ConsumerState<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends ConsumerState<PdfViewerScreen> {
  final PdfViewerController _pdfViewerController = PdfViewerController();
  bool _showTools = false;

  @override
  void initState() {
    super.initState();
    _recordView();
    _secureScreen();
  }

  Future<void> _secureScreen() async {
    if (!kIsWeb && Platform.isAndroid) {
      await SecurityService.enableScreenshotProtection(true);
    }
  }

  @override
  void dispose() {
    if (!kIsWeb && Platform.isAndroid) {
      SecurityService.enableScreenshotProtection(false);
    }
    super.dispose();
  }

  void _recordView() {
    StatsService().recordView(widget.questionId);
    ref.read(activityServiceProvider).recordActivity(
          eventType: 'view',
          description: 'Viewed document: ${widget.questionId}',
          metadata: {'question_id': widget.questionId},
        );
  }

  /// Shows a dialog for the user to paste/type the question or document text,
  /// then launches the appropriate AI tool. This approach is more reliable
  /// than OCR and works for all PDF types including scanned images.
  Future<void> _handleStudyTool(String tool) async {
    setState(() => _showTools = false);

    final TextEditingController textController = TextEditingController();
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(_toolIcon(tool), color: _toolColor(tool)),
            const SizedBox(width: 10),
            Text(_toolTitle(tool), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Copy and paste the question or document text below for best results.',
              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              maxLines: 6,
              decoration: InputDecoration(
                hintText: 'Paste question / document text here...',
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _toolColor(tool),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(_toolTitle(tool)),
          ),
        ],
      ),
    );

    if (confirmed != true || textController.text.trim().isEmpty) return;
    final text = textController.text.trim();
    if (!mounted) return;

    if (tool == 'Explain') {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => AIExplanationSheet(questionText: text),
      );
    } else if (tool == 'Summary') {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => AIDocSummarySheet(documentText: text),
      );
    } else if (tool == 'Quiz') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AIQuizScreen(documentText: text),
        ),
      );
    } else if (tool == 'AskTutor') {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => AIAskTutorSheet(documentText: text),
      );
    }
  }

  Future<void> _downloadForOffline(BuildContext context) async {
    if (widget.isLocal) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This file is already downloaded.')),
      );
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Encrypting and downloading with your license...'),
        duration: Duration(seconds: 2),
      ),
    );

    try {
      final offlineService = ref.read(offlineServiceProvider);
      if (offlineService == null) {
        throw Exception('Offline service is not available.');
      }

      await offlineService.downloadAndCache(
        questionId: widget.questionId,
        bucket: 'past_questions', // Assuming default bucket, might need to extract from URL if dynamic
        path: widget.pdfUrl.split('past_questions/').last, // Extract path
        title: 'Past Question', // Or ideally pass title down
        userName: widget.userName,
      );

      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: const Text('✅ Securely downloaded for offline use!'),
          backgroundColor: Colors.green.shade700,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text('❌ Download failed: $e'),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  String _toolTitle(String tool) {
    switch (tool) {
      case 'Explain': return 'AI Explain';
      case 'Summary': return 'AI Summary';
      case 'Quiz':    return 'AI Quiz';
      case 'AskTutor': return 'Ask Tutor';
      default: return 'AI Tool';
    }
  }

  IconData _toolIcon(String tool) {
    switch (tool) {
      case 'Explain': return Icons.auto_awesome_rounded;
      case 'Summary': return Icons.summarize_rounded;
      case 'Quiz':    return Icons.quiz_rounded;
      case 'AskTutor': return Icons.psychology_alt_rounded;
      default: return Icons.smart_toy_rounded;
    }
  }

  Color _toolColor(String tool) {
    switch (tool) {
      case 'Explain': return AppTheme.primaryTeal;
      case 'Summary': return Colors.orange;
      case 'Quiz':    return Colors.purple;
      case 'AskTutor': return Colors.blue;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text('Past Question'),
        backgroundColor: Colors.black.withAlpha(200),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.download_outlined),
            onPressed: () => _downloadForOffline(context),
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
               ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sharing is disabled for copyright protection.')),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          widget.isLocal
              ? SfPdfViewer.file(
                  File(widget.pdfUrl),
                  controller: _pdfViewerController,
                  enableTextSelection: false,
                  canShowPaginationDialog: true,
                )
              : SfPdfViewer.network(
                  widget.pdfUrl,
                  controller: _pdfViewerController,
                  enableTextSelection: false,
                  canShowPaginationDialog: true,
                ),
          // Watermark Overlay
          IgnorePointer(
            child: CustomPaint(
              size: Size.infinite,
              painter: WatermarkPainter(
                text: widget.userName,
                timestamp: DateTime.now().toString().substring(0, 16),
              ),
            ),
          ),
          // Study Tools Menu
          Positioned(
            bottom: 24,
            right: 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_showTools) ...[
                  _buildToolButton(
                    'Ask Tutor',
                    Icons.psychology_alt_rounded,
                    Colors.blue,
                    () => _handleStudyTool('AskTutor'),
                  ),
                  const SizedBox(height: 12),
                  _buildToolButton(
                    'AI Quiz',
                    Icons.quiz_rounded,
                    Colors.purple,
                    () => _handleStudyTool('Quiz'),
                  ),
                  const SizedBox(height: 12),
                  _buildToolButton(
                    'AI Summary',
                    Icons.summarize_rounded,
                    Colors.orange,
                    () => _handleStudyTool('Summary'),
                  ),
                  const SizedBox(height: 12),
                  _buildToolButton(
                    'AI Explain',
                    Icons.auto_awesome_rounded,
                    AppTheme.primaryTeal,
                    () => _handleStudyTool('Explain'),
                  ),
                  const SizedBox(height: 16),
                ],
                FloatingActionButton(
                  heroTag: 'study_tools',
                  onPressed: () => setState(() => _showTools = !_showTools),
                  backgroundColor: _showTools ? const Color(0xFFE11D48) : AppTheme.primaryTeal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  child: AnimatedRotation(
                    turns: _showTools ? 0.125 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(_showTools ? Icons.add : Icons.psychology_rounded),
                  ),
                ),
                const SizedBox(height: 16),
                FloatingActionButton.small(
                  heroTag: 'zoom_in',
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.textDark,
                  onPressed: () => _pdfViewerController.zoomLevel += 0.5,
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'zoom_out',
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  backgroundColor: Colors.white,
                  foregroundColor: AppTheme.textDark,
                  onPressed: () => _pdfViewerController.zoomLevel -= 0.5,
                  child: const Icon(Icons.remove),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton(String label, IconData icon, Color color, VoidCallback onTap) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withAlpha(20) : Colors.black.withAlpha(180),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(width: 12),
        FloatingActionButton(
          heroTag: label,
          onPressed: onTap,
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: Icon(icon, size: 22),
        ),
      ],
    );
  }
}

class WatermarkPainter extends CustomPainter {
  final String text;
  final String timestamp;

  WatermarkPainter({required this.text, required this.timestamp});

  @override
  void paint(Canvas canvas, Size size) {
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );

    const style = TextStyle(
      color: Color.fromRGBO(50, 50, 50, 0.12),
      fontSize: 18,
      fontWeight: FontWeight.bold,
    );

    textPainter.text = TextSpan(
      text: '$text\n$timestamp\nLICENSED COPY - DO NOT SHARE', 
      style: style
    );
    textPainter.layout();

    // Aggressive grid pattern for screenshot deterrence
    double x = 0;
    double y = 0;
    while (y < size.height + 200) {
      x = (y % 300 == 0) ? -50 : 50;
      while (x < size.width + 100) {
        canvas.save();
        canvas.translate(x, y);
        canvas.rotate(-0.6); // Steeper angle
        textPainter.paint(canvas, const Offset(0, 0));
        canvas.restore();
        x += 200; // Denser grid
      }
      y += 150; // Denser grid
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
