import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:ui';

import 'package:unipast/features/browse/question_service.dart';
import 'package:unipast/features/payment/payment_service.dart';
import 'package:unipast/features/auth/profile_service.dart';
import 'package:unipast/features/home/course_service.dart';
import 'package:unipast/features/home/course_model.dart';
import 'package:unipast/core/ui_helpers.dart';
import 'package:unipast/core/god_mind_theme.dart';

class BrowseScreen extends ConsumerStatefulWidget {
  const BrowseScreen({super.key});

  @override
  ConsumerState<BrowseScreen> createState() => _BrowseScreenState();
}

class _BrowseScreenState extends ConsumerState<BrowseScreen> {
  Course? _selectedCourse;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GMTheme.bg,
      body: Stack(
        children: [
          const AnimatedNeuralBg(),
          Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _selectedCourse == null
                    ? _ProgrammeCourseList(
                        key: const ValueKey('courses'),
                        onSelect: (course) => setState(() => _selectedCourse = course),
                      )
                      : _CoursePastQuestions(
                          key: const ValueKey('questions'),
                          course: _selectedCourse!,
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 120, // To avoid safe area overlap, you might usually use SafeArea or intrinsic height
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top, left: 16, right: 16, bottom: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [GMTheme.bg.withAlpha(200), Colors.transparent],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Row(
            children: [
              if (_selectedCourse != null)
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: GMTheme.text),
                  onPressed: () => setState(() => _selectedCourse = null),
                ),
              Expanded(
                child: Text(
                  _selectedCourse == null ? 'Library' : _selectedCourse!.title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.orbitron(
                    color: GMTheme.text,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
              if (_selectedCourse != null) const SizedBox(width: 48), // Balance for centering
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgrammeCourseList extends ConsumerWidget {
  final Function(Course) onSelect;
  const _ProgrammeCourseList({super.key, required this.onSelect});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(myProfileProvider);

    return profileAsync.when(
      data: (profile) {
        if (profile == null ||
            profile.universityId.isEmpty ||
            profile.facultyId.isEmpty ||
            profile.programmeId.isEmpty) {
          return Center(
            child: _GlassEmptyState(
              icon: Icons.manage_accounts_rounded,
              title: 'Complete Your Profile',
              subtitle: 'Please update your academic details in settings to see your courses here.',
              actionLabel: 'Go to Profile',
              onAction: () => context.go('/profile/edit'),
            ),
          );
        }

        final coursesAsync = ref.watch(programmeCoursesProvider);

        return coursesAsync.when(
          data: (courses) {
            if (courses.isEmpty) {
              return Center(
                child: _GlassEmptyState(
                  icon: Icons.library_books_rounded,
                  title: 'No Courses Found',
                  subtitle: 'No courses are currently available for your programme in our database.',
                  actionLabel: 'Refresh',
                  onAction: () => ref.invalidate(programmeCoursesProvider),
                ),
              );
            }

            return ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 120),
              itemCount: courses.length,
              itemBuilder: (context, index) {
                final course = courses[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _GodMindCourseCard(course: course, onTap: () => onSelect(course)),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: GMTheme.primary)),
          error: (e, s) => Center(child: Text('Error: $e', style: GoogleFonts.inter(color: GMTheme.danger))),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: GMTheme.primary)),
      error: (e, s) => Center(child: Text('Error: $e', style: GoogleFonts.inter(color: GMTheme.danger))),
    );
  }
}

class _CoursePastQuestions extends ConsumerWidget {
  final Course course;

  const _CoursePastQuestions({super.key, required this.course});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questionsAsync = ref.watch(questionsByCourseProvider(course.id));

    return questionsAsync.when(
      data: (questions) {
        if (questions.isEmpty) {
          return const Center(
            child: _GlassEmptyState(
              icon: Icons.folder_off_rounded,
              title: 'No Past Questions Yet',
              subtitle: 'Check back later or contact your campus rep.',
            ),
          );
        }

        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(left: 20, right: 20, bottom: 120),
          itemCount: questions.length,
          itemBuilder: (context, index) {
            final q = questions[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _GodMindQuestionCard(
                year: q.year,
                title: q.title ?? 'Regular Exam',
                onTap: () async {
                  final sub = ref.read(mySubscriptionProvider).value;
                  final profile = ref.read(myProfileProvider).value;
                  final userName = profile?.fullName ?? 'Student';

                  if (sub != null && sub.isActive) {
                    showLoadingOverlay(context, message: 'Decrypting File...');
                    try {
                      final url = await ref.read(questionServiceProvider).getSignedUrl(q.pdfUrl);
                      hideLoadingOverlay();
                      if (context.mounted) {
                        context.push('/pdf-viewer', extra: {
                          'url': url,
                          'userName': userName,
                          'title': q.title ?? 'Past Question',
                          'id': q.id,
                        });
                      }
                    } catch (e) {
                      hideLoadingOverlay();
                      if (context.mounted) showErrorSnackbar(context, 'Access Denied');
                    }
                  } else {
                    context.push('/paywall', extra: {'url': q.pdfUrl, 'userName': userName});
                  }
                },
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: GMTheme.primary)),
      error: (e, s) => Center(child: Text('Error: $e', style: GoogleFonts.inter(color: GMTheme.danger))),
    );
  }
}

// Custom Glass UI Elements
class _GodMindCourseCard extends StatelessWidget {
  final Course course;
  final VoidCallback onTap;

  const _GodMindCourseCard({required this.course, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: GMTheme.glassBox,
        child: Row(
          children: [
            Container(
              width: 54, height: 54,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [GMTheme.primary.withAlpha(40), GMTheme.primary.withAlpha(10)],
                  radius: 1.0,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: GMTheme.primary.withAlpha(50)),
                boxShadow: [BoxShadow(color: GMTheme.primary.withAlpha(20), blurRadius: 15)],
              ),
              child: const Icon(Icons.book_rounded, color: GMTheme.primary, size: 26),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.code,
                    style: GoogleFonts.orbitron(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: GMTheme.accent,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    course.title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: GMTheme.text,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: GMTheme.textMuted, size: 28),
          ],
        ),
      ),
    );
  }
}

class _GodMindQuestionCard extends StatelessWidget {
  final int year;
  final String title;
  final VoidCallback onTap;

  const _GodMindQuestionCard({required this.year, required this.title, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: GMTheme.surface.withAlpha(230),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: GMTheme.secondary.withAlpha(40)),
          boxShadow: [BoxShadow(color: Colors.black.withAlpha(80), blurRadius: 20, offset: const Offset(0, 10))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: GMTheme.secondary.withAlpha(20),
                shape: BoxShape.circle,
                border: Border.all(color: GMTheme.secondary.withAlpha(60)),
              ),
              child: const Icon(Icons.picture_as_pdf_rounded, color: GMTheme.secondary, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Year $year',
                    style: GoogleFonts.orbitron(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: GMTheme.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: GMTheme.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: GMTheme.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.rocket_launch_rounded, color: GMTheme.primary, size: 20),
            )
          ],
        ),
      ),
    );
  }
}

class _GlassEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _GlassEmptyState({required this.icon, required this.title, required this.subtitle, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(32),
      decoration: GMTheme.glassBox,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: GMTheme.primary.withAlpha(10),
              shape: BoxShape.circle,
              border: Border.all(color: GMTheme.primary.withAlpha(30)),
            ),
            child: Icon(icon, color: GMTheme.primary, size: 48),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.orbitron(fontSize: 18, fontWeight: FontWeight.bold, color: GMTheme.text),
          ),
          const SizedBox(height: 12),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 14, color: GMTheme.textMuted, height: 1.5),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: GMTheme.primary.withAlpha(20),
                foregroundColor: GMTheme.primary,
                elevation: 0,
                side: BorderSide(color: GMTheme.primary.withAlpha(50)),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(actionLabel!, style: GoogleFonts.inter(fontWeight: FontWeight.bold, letterSpacing: 1)),
            ),
          ]
        ],
      ),
    );
  }
}
