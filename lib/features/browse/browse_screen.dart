import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unipast/features/browse/question_service.dart';
import 'package:unipast/features/payment/payment_service.dart';
import 'package:unipast/features/auth/profile_service.dart';
import 'package:unipast/features/home/course_service.dart';
import 'package:unipast/features/home/course_model.dart';
import 'package:go_router/go_router.dart';
import 'package:unipast/core/ui_helpers.dart';

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
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(
          _selectedCourse == null ? 'My Courses' : _selectedCourse!.title,
          style:
              Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 20),
        ),
        leading: _selectedCourse != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                onPressed: () {
                  setState(() => _selectedCourse = null);
                },
              )
            : null,
        centerTitle: true,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _selectedCourse == null
            ? _MyCourseList(
                key: const ValueKey('courses'),
                onSelect: (course) => setState(() => _selectedCourse = course),
              )
            : _CoursePastQuestions(
                key: const ValueKey('questions'),
                course: _selectedCourse!,
              ),
      ),
    );
  }
}

class _MyCourseList extends ConsumerWidget {
  final Function(Course) onSelect;
  const _MyCourseList({super.key, required this.onSelect});

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
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.school_outlined, size: 64, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    'Complete Your Profile',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Please update your academic details in settings to see your courses here.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        final myCoursesAsync = ref.watch(myCoursesProvider);

        return myCoursesAsync.when(
          data: (courses) {
            if (courses.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.library_books_outlined,
                          size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      Text(
                        'No Courses Found',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'No courses are currently available for Level ${profile.currentLevel}, Semester ${profile.currentSemester}.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: courses.length,
              itemBuilder: (context, index) {
                final course = courses[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    elevation: 2,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      leading: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withAlpha(20),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.menu_book,
                            color: Theme.of(context).colorScheme.primary),
                      ),
                      title: Text(course.code,
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      subtitle: Text(course.title,
                          style: Theme.of(context).textTheme.bodyMedium),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => onSelect(course),
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, s) => Center(child: Text('Error loading courses: $e')),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error loading profile: $e')),
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
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.folder_off_outlined,
                    size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text(
                  'No Past Questions Yet',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Check back later or contact your campus rep.',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: questions.length,
          itemBuilder: (context, index) {
            final q = questions[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Card(
                elevation: 4,
                shadowColor:
                    Theme.of(context).colorScheme.primary.withAlpha(20),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.secondary.withAlpha(20),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.picture_as_pdf,
                        color: Theme.of(context).colorScheme.secondary),
                  ),
                  title: Text('Year ${q.year}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Regular Exam Question Paper'),
                  trailing: Icon(Icons.open_in_new,
                      size: 20, color: Theme.of(context).colorScheme.primary),
                  onTap: () async {
                    final sub = ref.read(mySubscriptionProvider).value;
                    final profile = ref.read(myProfileProvider).value;
                    final userName = profile?.fullName ?? 'University Student';

                    if (sub != null && sub.isActive) {
                      showLoadingOverlay(context, message: 'Opening PDF...');
                      try {
                        final url = await ref
                            .read(questionServiceProvider)
                            .getSignedUrl(q.pdfUrl);
                        hideLoadingOverlay();
                        if (context.mounted) {
                          context.push('/pdf-viewer', extra: {
                            'url': url,
                            'userName': userName,
                          });
                        }
                      } catch (e) {
                        hideLoadingOverlay();
                        if (context.mounted) {
                          showErrorSnackbar(context, 'Failed to open PDF');
                        }
                      }
                    } else {
                      context.push('/paywall', extra: {
                        'url': q.pdfUrl,
                        'userName': userName,
                      });
                    }
                  },
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }
}
