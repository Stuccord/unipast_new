import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:unipast/features/home/course_service.dart';
import 'package:unipast/features/auth/profile_service.dart';
import 'package:unipast/features/notifications/notification_service.dart';
import 'package:unipast/features/offline/offline_service.dart';
import 'package:unipast/features/offline/cached_item_model.dart';
import 'package:unipast/features/home/course_detail_sheet.dart';

// ─────────────────────────────────────────────
// GOD MIND THEME PALETTE
// ─────────────────────────────────────────────
class _GM {
  static const bg         = Color(0xFF05080F);
  static const surface    = Color(0xFF0D1526);
  static const card       = Color(0xFF111D35);
  static const divider    = Color(0xFF1E2F50);
  static const primary    = Color(0xFF00E5CC);
  static const secondary  = Color(0xFF7C3AED);
  static const accent     = Color(0xFFFFB800);
  static const text       = Color(0xFFE2EAF4);
  static const textMuted  = Color(0xFF7B8BAA);
  static const danger     = Color(0xFFFF4560);
}

// ─────────────────────────────────────────────
// HOME SCREEN ENTRY
// ─────────────────────────────────────────────
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with TickerProviderStateMixin {
  late final AnimationController _rotateCtrl;
  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _rotateCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 40))..repeat();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 3))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _rotateCtrl.dispose();
    _pulseCtrl.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning,';
    if (hour < 17) return 'Good Afternoon,';
    return 'Good Evening,';
  }

  @override
  Widget build(BuildContext context) {
    // Determine greeting data
    final profile = ref.watch(myProfileProvider).value;
    final name = profile?.fullName.split(' ').first ?? 'Student';
    final level = profile != null ? 'Level ${profile.currentLevel}' : 'Welcome to UniPast';

    return Scaffold(
      backgroundColor: _GM.bg,
      body: Stack(
        children: [
          // 1. Futuristic Animated Background
          _AnimatedNeuralBg(rotateCtrl: _rotateCtrl),

          // 2. Main Scroll Content
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildAppBar(name, level),
              _buildQuickStats(ref),
              _buildSectionHeader('Ready to Review', () => context.go('/offline')),
              _buildReadyToReview(ref),
              _buildSectionHeader('Pinned Courses', () => context.go('/browse')),
              _buildPinnedCourses(ref),
              const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // UI COMPONENTS
  // ─────────────────────────────────────────

  Widget _buildAppBar(String name, String level) {
    return SliverAppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      expandedHeight: 140,
      collapsedHeight: 80,
      floating: false,
      pinned: true,
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_GM.bg.withAlpha(200), Colors.transparent],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 24, bottom: 20, right: 24),
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getGreeting(),
                        style: GoogleFonts.inter(
                          color: _GM.textMuted,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        name,
                        style: GoogleFonts.orbitron(
                          color: _GM.primary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        level,
                        style: GoogleFonts.firaCode(
                          color: _GM.accent,
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  _buildNotificationBell(ref),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationBell(WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider).value ?? [];
    final unreadCount = notifications.where((n) => !(n['is_read'] ?? true)).length;

    return GestureDetector(
      onTap: () => context.push('/notifications'),
      child: AnimatedBuilder(
        animation: _pulseCtrl,
        builder: (context, child) {
          return Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _GM.card.withAlpha(180),
              border: Border.all(color: _GM.primary.withAlpha(50)),
              boxShadow: unreadCount > 0
                  ? [BoxShadow(color: _GM.primary.withAlpha((80 * _pulseCtrl.value).toInt()), blurRadius: 15 * _pulseCtrl.value)]
                  : [],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(Icons.notifications_none_rounded, color: _GM.text, size: 18),
                if (unreadCount > 0)
                  Positioned(
                    top: 6,
                    right: 8,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: _GM.accent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildQuickStats(WidgetRef ref) {
    final qc = ref.watch(questionCountProvider).value ?? 0;
    final uc = ref.watch(universityCountProvider).value ?? 0;
    final dc = ref.watch(cachedQuestionsProvider).value?.length ?? 0;

    final qStr = qc > 999 ? '${(qc / 1000).toStringAsFixed(1)}k+' : qc.toString();

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: _GM.card.withAlpha(180),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: _GM.divider),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(100),
                blurRadius: 30,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(val: qStr, label: 'Questions', icon: Icons.quiz_rounded, color: _GM.primary),
              _StatDivider(),
              _StatItem(val: uc.toString(), label: 'Varsities', icon: Icons.account_balance_rounded, color: _GM.secondary),
              _StatDivider(),
              _StatItem(val: dc.toString(), label: 'Downloads', icon: Icons.cloud_download_rounded, color: _GM.accent),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, VoidCallback onSeeAll) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      sliver: SliverToBoxAdapter(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                color: _GM.text,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            GestureDetector(
              onTap: onSeeAll,
              child: Text(
                'EXPLORE',
                style: GoogleFonts.orbitron(
                  color: _GM.primary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadyToReview(WidgetRef ref) {
    final asyncData = ref.watch(cachedQuestionsProvider);

    return SliverToBoxAdapter(
      child: SizedBox(
        height: 180,
        child: asyncData.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: _GM.primary),
          ),
          error: (e, _) => Center(
            child: Text('Error loading files', style: GoogleFonts.inter(color: _GM.danger)),
          ),
          data: (items) {
            if (items.isEmpty) {
              return _EmptyGlassCard(
                icon: Icons.auto_awesome_rounded,
                title: 'No documents yet',
                subtitle: 'Download past questions to see them here for offline access.',
                onTap: () => context.go('/browse'),
              );
            }
            return ListView.builder(
              physics: const BouncingScrollPhysics(),
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: items.length,
              itemBuilder: (ctx, i) => _RecentDocCard(item: items[i]),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPinnedCourses(WidgetRef ref) {
    final asyncData = ref.watch(myCoursesProvider);

    return asyncData.when(
      loading: () => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Center(child: CircularProgressIndicator(color: _GM.primary)),
        ),
      ),
      error: (e, _) => SliverToBoxAdapter(
        child: Center(
          child: Text('Error loading courses', style: GoogleFonts.inter(color: _GM.danger)),
        ),
      ),
      data: (courses) {
        if (courses.isEmpty) {
          return SliverToBoxAdapter(
            child: _EmptyGlassCard(
              icon: Icons.bookmark_border_rounded,
              title: 'No pinned courses',
              subtitle: 'Pin your favourite courses for quick access right here.',
              onTap: () => context.go('/browse'),
            ),
          );
        }
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _CourseGlassCard(course: courses[i]),
              ),
              childCount: courses.length,
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────
// CUSTOM GLASS WIDGETS
// ─────────────────────────────────────────

class _StatItem extends StatelessWidget {
  final String val;
  final String label;
  final IconData icon;
  final Color color;

  const _StatItem({required this.val, required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 10),
        Text(
          val,
          style: GoogleFonts.orbitron(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: _GM.text,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 10,
            color: _GM.textMuted,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 40,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.transparent, _GM.divider, Colors.transparent],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }
}

class _RecentDocCard extends ConsumerWidget {
  final CachedQuestion item;
  const _RecentDocCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        final profile = ref.read(myProfileProvider).value;
        context.push('/pdf-viewer', extra: {
          'url': item.filePath,
          'userName': profile?.fullName ?? 'Student',
          'isLocal': true,
        });
      },
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              _GM.card.withAlpha(200),
              _GM.surface.withAlpha(200),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _GM.primary.withAlpha(30)),
          boxShadow: [
            BoxShadow(
              color: _GM.primary.withAlpha(10),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _GM.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _GM.primary.withAlpha(50)),
              ),
              child: const Icon(Icons.description_outlined, color: _GM.primary, size: 24),
            ),
            const Spacer(),
            Text(
              item.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: _GM.text,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: _GM.primary, size: 12),
                const SizedBox(width: 4),
                Text(
                  'READY',
                  style: GoogleFonts.orbitron(
                    fontSize: 9,
                    color: _GM.primary,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CourseGlassCard extends StatelessWidget {
  final dynamic course;
  const _CourseGlassCard({required this.course});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => CourseDetailSheet(course: course, isDark: true),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: _GM.card.withAlpha(150),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _GM.divider),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(80),
              blurRadius: 20,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                gradient: const RadialGradient(
                  colors: [Color(0xFF1E3A5F), Color(0xFF112240)],
                  radius: 1.0,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _GM.secondary.withAlpha(80)),
                boxShadow: [
                  BoxShadow(color: _GM.secondary.withAlpha(30), blurRadius: 10),
                ],
              ),
              child: const Icon(Icons.book_rounded, color: _GM.text, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.title,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: _GM.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    course.code,
                    style: GoogleFonts.firaCode(
                      fontSize: 12,
                      color: _GM.secondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, color: _GM.textMuted, size: 16),
          ],
        ),
      ),
    );
  }
}

class _EmptyGlassCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _EmptyGlassCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: _GM.card.withAlpha(100),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: _GM.divider),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _GM.primary.withAlpha(15),
                shape: BoxShape.circle,
                border: Border.all(color: _GM.primary.withAlpha(30)),
              ),
              child: Icon(icon, color: _GM.primary, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: _GM.text,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: _GM.textMuted,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────
// ANIMATED NEURAL BACKGROUND
// ─────────────────────────────────────────

class _AnimatedNeuralBg extends StatelessWidget {
  final AnimationController rotateCtrl;
  const _AnimatedNeuralBg({required this.rotateCtrl});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: rotateCtrl,
      builder: (_, __) => CustomPaint(
        painter: _NeuralHomePainter(rotateCtrl.value),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _NeuralHomePainter extends CustomPainter {
  final double t;
  _NeuralHomePainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(1234);
    
    // Generate nodes across the screen
    final nodes = List.generate(24, (i) {
      final angle = (i / 24) * 2 * math.pi + t * math.pi * (i % 2 == 0 ? 1 : -1);
      final rX = size.width * (0.3 + 0.2 * rng.nextDouble());
      final rY = size.height * (0.3 + 0.3 * rng.nextDouble());
      
      return Offset(
        size.width / 2 + math.cos(angle) * rX,
        size.height / 2 + math.sin(angle) * rY,
      );
    });

    // Draw connections
    final linePaint = Paint()
      ..color = _GM.primary.withAlpha(8)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < nodes.length; i++) {
      for (int j = i + 1; j < nodes.length; j++) {
        final dist = (nodes[i] - nodes[j]).distance;
        if (dist < 200) {
          canvas.drawLine(nodes[i], nodes[j], linePaint);
        }
      }
    }

    // Draw glowing nodes
    for (final n in nodes) {
      final glow = Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10)
        ..color = _GM.primary.withAlpha(20);
      canvas.drawCircle(n, 8, glow);
      canvas.drawCircle(n, 2, Paint()..color = _GM.primary.withAlpha(60));
    }

    // Large ambient background glows
    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.1),
      250,
      Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 120)
        ..color = _GM.secondary.withAlpha(15),
    );

    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.7),
      300,
      Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 140)
        ..color = _GM.primary.withAlpha(10),
    );
  }

  @override
  bool shouldRepaint(_NeuralHomePainter old) => old.t != t;
}
