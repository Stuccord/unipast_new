import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:unipast/core/theme.dart';
import 'package:unipast/core/ui_helpers.dart';
import 'package:unipast/features/home/course_model.dart';
import 'package:unipast/features/browse/question_service.dart';
import 'package:unipast/features/payment/payment_service.dart';
import 'package:unipast/features/auth/profile_service.dart';

class CourseDetailSheet extends ConsumerWidget {
  final Course course;
  final bool isDark;

  const CourseDetailSheet({
    super.key,
    required this.course,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questionsAsync = ref.watch(questionsByCourseProvider(course.id));

    return Container(
      padding: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryTeal.withAlpha(isDark ? 50 : 20),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.auto_stories_rounded, color: AppTheme.primaryTeal),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.code,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppTheme.textDark,
                        ),
                      ),
                      Text(
                        course.title,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: AppTheme.textLight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: isDark ? Colors.white10 : Colors.black.withAlpha(5),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          const Divider(height: 1),
          
          // Questions List
          Flexible(
            child: questionsAsync.when(
              data: (questions) {
                if (questions.isEmpty) {
                  return _EmptyQuestionsView(isDark: isDark);
                }
                return ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                  itemCount: questions.length,
                  itemBuilder: (context, index) {
                    final q = questions[index];
                    return _QuestionItem(
                      question: q,
                      isDark: isDark,
                      onTap: () async {
                        final sub = ref.read(mySubscriptionProvider).value;
                        final profile = ref.read(myProfileProvider).value;
                        final userName = profile?.fullName ?? 'Student';

                        if (sub != null && sub.isActive) {
                          showLoadingOverlay(context, message: 'Opening Paper...');
                          try {
                            final url = await ref
                                .read(questionServiceProvider)
                                .getSignedUrl(q.pdfUrl);
                            hideLoadingOverlay();
                            if (context.mounted) {
                              Navigator.pop(context); // Close sheet
                              context.push('/pdf-viewer', extra: {
                                'url': url,
                                'userName': userName,
                                'title': q.title ?? 'Past Question',
                                'id': q.id,
                              });
                            }
                          } catch (e) {
                            hideLoadingOverlay();
                            if (context.mounted) {
                              showErrorSnackbar(context, 'Failed to open PDF');
                            }
                          }
                        } else {
                          Navigator.pop(context); // Close sheet
                          context.push('/paywall', extra: {
                            'url': q.pdfUrl,
                            'userName': userName,
                          });
                        }
                      },
                    );
                  },
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(60),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              ),
              error: (err, _) => Padding(
                padding: const EdgeInsets.all(40),
                child: Center(child: Text('Error: $err')),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionItem extends StatelessWidget {
  final dynamic question;
  final bool isDark;
  final VoidCallback onTap;

  const _QuestionItem({
    required this.question,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: isDark ? Colors.white.withAlpha(5) : Colors.black.withAlpha(5),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.accentGold.withAlpha(20),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.picture_as_pdf_rounded, 
                    color: AppTheme.accentGold, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Year ${question.year}',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: isDark ? Colors.white : AppTheme.textDark,
                        ),
                      ),
                      Text(
                        question.title ?? 'Past Question Paper',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppTheme.textLight,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, 
                  color: isDark ? Colors.white24 : Colors.black26),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyQuestionsView extends StatelessWidget {
  final bool isDark;
  const _EmptyQuestionsView({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Column(
        children: [
          Icon(Icons.folder_open_rounded, 
            size: 48, color: isDark ? Colors.white10 : Colors.black.withAlpha(10)),
          const SizedBox(height: 16),
          Text(
            'No questions found',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : AppTheme.textDark.withAlpha(150),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'We are still uploading papers for this course.',
            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
