import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unipast/core/theme.dart';
import 'package:unipast/features/home/course_service.dart';
import 'package:unipast/features/auth/profile_service.dart';
import 'package:unipast/features/notifications/notification_service.dart';
import 'package:unipast/features/offline/offline_service.dart';
import 'package:unipast/features/offline/cached_item_model.dart';
import 'package:unipast/features/home/course_detail_sheet.dart';


import 'package:unipast/core/widgets/bg_pattern.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final coursesAsync = ref.watch(myCoursesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: UniPastBackground(
        isDark: isDark,
        child: CustomScrollView(
        slivers: [
          // ---------------------------------------------------------------
          // Hero App Bar
          // ---------------------------------------------------------------
          SliverAppBar(
            floating: true,
            pinned: true,
            snap: true,
            expandedHeight: 160,
            backgroundColor: isDark ? const Color(0xFF0F172A) : AppTheme.primaryTeal,
            elevation: 0,
            leadingWidth: 70,
            leading: Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(40),
                  shape: BoxShape.circle,
                ),
                child: const _UniPastLogoIcon(),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 84, bottom: 16, right: 70),
              title: Consumer(
                builder: (context, ref, _) {
                  final profile = ref.watch(myProfileProvider).value;
                  final greeting = profile != null
                      ? '${_getGreeting()}, ${profile.fullName.split(' ')[0]}'
                      : _getGreeting();
                  
                  return Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        greeting,
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        profile != null ? 'Level ${profile.currentLevel}' : 'Welcome back',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  );
                },
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                        : [AppTheme.primaryTeal, AppTheme.primaryTealDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -40,
                      right: -40,
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(10),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                onPressed: () => context.push('/notifications'),
                icon: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(50),
                    shape: BoxShape.circle,
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 24),
                      Consumer(
                        builder: (context, ref, _) {
                          final notifications = ref.watch(notificationsProvider).value ?? [];
                          final unreadCount = notifications.where((n) => !(n['is_read'] ?? true)).length;
                          if (unreadCount == 0) return const SizedBox.shrink();
                          return Positioned(
                            right: -2,
                            top: -2,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                color: AppTheme.accentGold,
                                shape: BoxShape.circle,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
            ],
          ),

          // ---------------------------------------------------------------
          // Quick Stats Banner
          // ---------------------------------------------------------------
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            sliver: SliverToBoxAdapter(
              child: _QuickStatsBanner(isDark: isDark),
            ),
          ),

          // ---------------------------------------------------------------
          // Section Header: Ready to Review
          // ---------------------------------------------------------------
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
            sliver: SliverToBoxAdapter(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _SectionHeader(title: 'Ready to Review', isDark: isDark),
                  TextButton(
                    onPressed: () => context.go('/offline'),
                    child: Text(
                      'See all',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppTheme.primaryTeal,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ---------------------------------------------------------------
          // Downloaded / Recent Questions Horizontal List
          // ---------------------------------------------------------------
          SliverToBoxAdapter(
            child: SizedBox(
              height: 160,
              child: Consumer(
                builder: (context, ref, _) {
                  final cachedAsync = ref.watch(cachedQuestionsProvider);
                  return cachedAsync.when(
                    data: (items) {
                      if (items.isEmpty) {
                        return _EmptyReviewView(isDark: isDark);
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        scrollDirection: Axis.horizontal,
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          return _RecentActivityCard(item: item, isDark: isDark);
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (e, _) => const SizedBox.shrink(),
                  );
                },
              ),
            ),
          ),

          // ---------------------------------------------------------------
          // Section Header: Pinned
          // ---------------------------------------------------------------
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 12),
            sliver: SliverToBoxAdapter(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _SectionHeader(title: 'Pinned Courses', isDark: isDark),
                  TextButton(
                    onPressed: () => context.go('/browse'),
                    child: Text(
                      'Browse all',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppTheme.primaryTeal,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ---------------------------------------------------------------
          // Course Cards
          // ---------------------------------------------------------------
          coursesAsync.when(
            data: (courses) => courses.isEmpty
                ? SliverToBoxAdapter(
                    child: _EmptyCoursesView(isDark: isDark),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final course = courses[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: _CourseCard(
                              course: course,
                              isDark: isDark,
                            ),
                          );
                        },
                        childCount: courses.length,
                      ),
                    ),
                  ),
            loading: () => const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(AppTheme.primaryTeal),
                  ),
                ),
              ),
            ),
            error: (err, _) => SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline_rounded,
                          size: 48, color: AppTheme.errorRed.withAlpha(180)),
                      const SizedBox(height: 12),
                      Text(
                        'Failed to load courses',
                        style: GoogleFonts.inter(
                            fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        err.toString(),
                        style: GoogleFonts.inter(
                            fontSize: 12, color: AppTheme.textLight),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
        ],
      ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Quick Stats Banner
// ---------------------------------------------------------------------------

class _QuickStatsBanner extends ConsumerWidget {
  final bool isDark;
  const _QuickStatsBanner({required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questionCount = ref.watch(questionCountProvider).value ?? 0;
    final universityCount = ref.watch(universityCountProvider).value ?? 0;
    final downloadCount = ref.watch(cachedQuestionsProvider).value?.length ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 50 : 15),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(
            label: 'Questions',
            value: questionCount > 999
                ? '${(questionCount / 1000).toStringAsFixed(1)}k+'
                : questionCount.toString(),
            icon: Icons.quiz_rounded,
            color: AppTheme.primaryTeal,
          ),
          _StatDivider(isDark: isDark),
          _StatItem(
            label: 'Universities',
            value: universityCount.toString(),
            icon: Icons.account_balance_rounded,
            color: const Color(0xFFF59E0B),
          ),
          _StatDivider(isDark: isDark),
          _StatItem(
            label: 'Downloads',
            value: downloadCount.toString(),
            icon: Icons.cloud_download_rounded,
            color: AppTheme.primaryTealDark,
          ),
        ],
      ),
    );
  }
}

class _StatDivider extends StatelessWidget {
  final bool isDark;
  const _StatDivider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 30,
      color: isDark ? Colors.white10 : Colors.black.withAlpha(5),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.playfairDisplay(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : AppTheme.textDark,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            color: AppTheme.textLight,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Course Card
// ---------------------------------------------------------------------------

class _CourseCard extends StatelessWidget {
  final dynamic course;
  final bool isDark;
  const _CourseCard({required this.course, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) => CourseDetailSheet(
              course: course,
              isDark: isDark,
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? Colors.white.withAlpha(15) : const Color(0xFFF3F4F6),
            ),
            boxShadow: isDark
                ? []
                : [
                    BoxShadow(
                      color: Colors.black.withAlpha(10),
                      blurRadius: 16,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryTeal.withAlpha(isDark ? 80 : 30),
                      AppTheme.primaryTeal.withAlpha(isDark ? 40 : 15),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.book_rounded,
                  color: AppTheme.primaryTeal,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.title,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: isDark ? Colors.white : AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      course.code,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isDark ? Colors.white54 : AppTheme.textLight,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryTeal.withAlpha(isDark ? 50 : 20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 12,
                  color: AppTheme.primaryTeal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Recent Activity Card
// ---------------------------------------------------------------------------

class _RecentActivityCard extends ConsumerWidget {
  final CachedQuestion item;
  final bool isDark;
  const _RecentActivityCard({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 16),
      child: Material(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            final profile = ref.read(myProfileProvider).value;
            context.push('/pdf-viewer', extra: {
              'url': item.filePath,
              'userName': profile?.fullName ?? 'Student',
              'isLocal': true,
            });
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(5),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(isDark ? 40 : 12),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryTeal.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.description_outlined, color: AppTheme.primaryTeal, size: 20),
                ),
                const Spacer(),
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Downloaded',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppTheme.primaryTeal,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section Header Helper
// ---------------------------------------------------------------------------

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool isDark;
  const _SectionHeader({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.playfairDisplay(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: isDark ? Colors.white : AppTheme.textDark,
        letterSpacing: -0.5,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty State: Ready to Review
// ---------------------------------------------------------------------------

class _EmptyReviewView extends StatelessWidget {
  final bool isDark;
  const _EmptyReviewView({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [Colors.white, const Color(0xFFF1F5F9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white.withAlpha(10) : Colors.black.withAlpha(5),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primaryTeal.withAlpha(20),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: AppTheme.primaryTeal, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Start your journey',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppTheme.textDark,
                  ),
                ),
                Text(
                  'Download past questions to see them here even offline.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.textLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty State: Pinned Courses
// ---------------------------------------------------------------------------

class _EmptyCoursesView extends StatelessWidget {
  final bool isDark;
  const _EmptyCoursesView({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.bookmark_border_rounded,
            size: 64,
            color: isDark ? Colors.white10 : Colors.black12,
          ),
          const SizedBox(height: 16),
          Text(
            'No pinned courses',
            style: GoogleFonts.playfairDisplay(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white38 : Colors.black26,
            ),
          ),
          TextButton(
            onPressed: () => context.go('/browse'),
            child: const Text('Find courses to pin'),
          ),
        ],
      ),
    );
  }
}
class _UniPastLogoIcon extends StatelessWidget {
  const _UniPastLogoIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF22C55E), // Vibrant Green
        borderRadius: BorderRadius.circular(12), // Match screenshot 1
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // The "U"
          Text(
            'U',
            style: GoogleFonts.playfairDisplay(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 20,
            ),
          ),
          // Circular swoosh/arrow around
          Icon(
            Icons.refresh_rounded, 
            color: Colors.white.withAlpha(80),
            size: 34,
          ),
          // The Gold Star
          const Positioned(
            top: 5,
            right: 5,
            child: Icon(
              Icons.star_rounded,
              color: AppTheme.accentGold,
              size: 11,
            ),
          ),
        ],
      ),
    );
  }
}
