import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unipast/features/auth/profile_service.dart';
import 'package:unipast/features/auth/auth_service.dart';
import 'package:unipast/features/auth/stats_service.dart';
import 'package:unipast/features/payment/payment_service.dart';
import 'package:intl/intl.dart';
import 'package:unipast/core/lookup_data.dart';
import 'package:unipast/core/theme_provider.dart';
import 'package:unipast/core/theme.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Refresh subscription and profile stats when user returns to app
      ref.invalidate(mySubscriptionProvider);
      ref.invalidate(profileStatsProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(myProfileProvider);
    final subscriptionAsync = ref.watch(mySubscriptionProvider);
    final statsAsync = ref.watch(profileStatsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUser = ref.watch(authServiceProvider).currentUser;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('Profile not found'));
          }
          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // Premium Hero Header
              _ProfileSliverHeader(profile: profile, isDark: isDark),

              SliverToBoxAdapter(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Greeting
                      Text(
                        'Hello, ${profile.fullName.split(' ')[0]} – Your study hub',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Subscription Status Card
                      subscriptionAsync.when(
                        data: (sub) => _PremiumSubscriptionCard(
                          sub: sub,
                          isDark: isDark,
                        ),
                        loading: () => const _ShimmerCard(),
                        error: (e, s) => const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 32),

                      // Quick Stats
                      _QuickStatsRow(
                        isDark: isDark,
                        stats: statsAsync.valueOrNull ?? {
                          'viewed': '0',
                          'stored': '0',
                          'streaks': '0d',
                        },
                      ),
                      const SizedBox(height: 32),

                      // Personal Information Section
                      _SectionHeader(
                          title: 'Personal Information', isDark: isDark),
                      const SizedBox(height: 12),
                      _SettingsCard(
                        isDark: isDark,
                        children: [
                          _SettingsTile(
                            icon: Icons.school_outlined,
                            title: 'Academic Details',
                            subtitle:
                                '${LookupData.getProgrammeName(profile.programmeId)} • Level ${profile.currentLevel}',
                            onTap: () => context.push('/profile/edit'),
                          ),
                          _SettingsTile(
                            icon: Icons.email_outlined,
                            title: 'Email Address',
                            subtitle: currentUser?.email ?? 'Unavailable',
                            onTap: null,
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Settings & Preferences
                      _SectionHeader(title: 'App Settings', isDark: isDark),
                      const SizedBox(height: 12),
                      _SettingsCard(
                        isDark: isDark,
                        children: [
                          _SettingsTile(
                            icon: Icons.dark_mode_outlined,
                            title: 'Dark Mode',
                            trailing: Consumer(
                              builder: (context, ref, _) {
                                final themeMode = ref.watch(themeProvider);
                                return Switch.adaptive(
                                  value: themeMode == ThemeMode.dark ||
                                      (themeMode == ThemeMode.system &&
                                          Theme.of(context).brightness ==
                                              Brightness.dark),
                                  activeTrackColor:
                                      AppTheme.accentGold.withAlpha(100),
                                  activeThumbColor: AppTheme.accentGold,
                                  onChanged: (val) {
                                    ref
                                        .read(themeProvider.notifier)
                                        .toggleTheme(val);
                                  },
                                );
                              },
                            ),
                          ),
                          _SettingsTile(
                            icon: Icons.notifications_none_outlined,
                            title: 'Notifications',
                            onTap: () => context.push('/notifications'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // Admin Section (Only for Admins)
                      if (profile.isAdmin) ...[
                        _SectionHeader(title: 'Administration', isDark: isDark),
                        const SizedBox(height: 12),
                        _SettingsCard(
                          isDark: isDark,
                          children: [
                            _SettingsTile(
                              icon: Icons.admin_panel_settings_outlined,
                              title: 'Admin Dashboard',
                              subtitle: 'Manage platform content & users',
                              onTap: () => context.push('/admin'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                      ],

                      // Support & About
                      _SectionHeader(title: 'Support', isDark: isDark),
                      const SizedBox(height: 12),
                      _SettingsCard(
                        isDark: isDark,
                        children: [
                          _SettingsTile(
                            icon: Icons.help_outline_rounded,
                            title: 'Privacy & Terms',
                            onTap: () => launchUrl(
                              Uri.parse('https://unipast.com/privacy'),
                              mode: LaunchMode.externalApplication,
                            ),
                          ),
                          _SettingsTile(
                            icon: Icons.info_outline_rounded,
                            title: 'About UniPast',
                            onTap: () => showAboutDialog(
                              context: context,
                              applicationName: 'UniPast',
                              applicationVersion: '1.0.2',
                              applicationLegalese: '© 2026 UniPast. Made with care in Ghana.',
                              applicationIcon: const Icon(Icons.school, size: 48, color: AppTheme.primaryTeal),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 48),
                      Center(
                        child: TextButton.icon(
                          onPressed: () =>
                              ref.read(authServiceProvider).signOut(),
                          icon: const Icon(Icons.logout_rounded,
                              color: Colors.red),
                          label: Text(
                            'Log Out of Account',
                            style: GoogleFonts.inter(
                              color: Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Footer
                      Center(
                        child: Column(
                          children: [
                            Text(
                              'Version 1.0.2',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: isDark ? Colors.white24 : Colors.black26,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Made with ',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white38 : Colors.black38,
                                  ),
                                ),
                                const Icon(Icons.favorite, size: 12, color: Colors.red),
                                Text(
                                  ' in Ghana',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white38 : Colors.black38,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _ProfileSliverHeader extends StatelessWidget {
  final dynamic profile;
  final bool isDark;

  const _ProfileSliverHeader({required this.profile, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: AppTheme.primaryTeal,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppTheme.primaryTeal,
                AppTheme.primaryTeal.withAlpha(200),
                isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              ],
              stops: const [0.0, 0.4, 0.9],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              // Avatar with Border
              Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: AppTheme.primaryTeal.withAlpha(30),
                  child: const Icon(Icons.person,
                      size: 50, color: AppTheme.primaryTeal),
                ),
              ),
              const SizedBox(height: 16),
              // Name
              Text(
                profile.fullName,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              // Badges
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _Badge(
                      text: 'Level ${profile.currentLevel}',
                      color: AppTheme.accentGold),
                  const SizedBox(width: 8),
                  _Badge(
                      text: 'Sem ${profile.currentSemester}',
                      color: Colors.white24,
                      isBordered: true),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;
  final bool isBordered;

  const _Badge(
      {required this.text, required this.color, this.isBordered = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isBordered ? null : color,
        borderRadius: BorderRadius.circular(20),
        border: isBordered ? Border.all(color: Colors.white) : null,
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isBordered ? Colors.white : Colors.black87,
        ),
      ),
    );
  }
}

class _PremiumSubscriptionCard extends StatelessWidget {
  final dynamic sub;
  final bool isDark;

  const _PremiumSubscriptionCard({this.sub, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final bool isActive = sub != null && sub.isActive;

    return Card(
      elevation: 4,
      shadowColor: AppTheme.accentGold.withAlpha(50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: isActive
          ? (isDark ? const Color(0xFF1E293B) : Colors.white)
          : AppTheme.primaryTeal,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.accentGold.withAlpha(isActive ? 40 : 255),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.workspace_premium_rounded,
                    color: isActive ? AppTheme.accentGold : Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isActive ? 'Premium Access Active' : 'Go Premium Today',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isActive
                              ? (isDark ? Colors.white : Colors.black87)
                              : Colors.white,
                        ),
                      ),
                      Text(
                        isActive
                            ? 'Valid until ${DateFormat.yMMMd().format(sub.expiresAt)}'
                            : 'Unlock all past questions & solutions',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: isActive
                              ? (isDark ? Colors.white60 : Colors.black54)
                              : Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.push('/paywall'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentGold,
                foregroundColor: Colors.black87,
                elevation: 0,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(
                isActive ? 'Renew Subscription' : 'Upgrade – ₵1 / Sem',
                style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickStatsRow extends StatelessWidget {
  final bool isDark;
  final Map<String, String> stats;

  const _QuickStatsRow({required this.isDark, required this.stats});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: _StatCard(
                label: 'Viewed',
                value: stats['viewed'] ?? '0',
                icon: Icons.visibility_outlined,
                isDark: isDark)),
        const SizedBox(width: 12),
        Expanded(
            child: _StatCard(
                label: 'Stored',
                value: stats['stored'] ?? '0',
                icon: Icons.check_circle_outline_rounded,
                isDark: isDark)),
        const SizedBox(width: 12),
        Expanded(
            child: _StatCard(
                label: 'Streaks',
                value: stats['streaks'] ?? '0d',
                icon: Icons.local_fire_department_outlined,
                isDark: isDark)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isDark;

  const _StatCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? Colors.white10 : Colors.black.withAlpha(10)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: AppTheme.primaryTeal),
          const SizedBox(height: 8),
          Text(value,
              style: GoogleFonts.playfairDisplay(
                  fontSize: 18, fontWeight: FontWeight.bold)),
          Text(label,
              style: GoogleFonts.inter(
                  fontSize: 11,
                  color: isDark ? Colors.white38 : Colors.black38)),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool isDark;
  const _SectionHeader({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.playfairDisplay(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: isDark ? Colors.white70 : Colors.black87,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;
  final bool isDark;

  const _SettingsCard({required this.children, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: isDark ? Colors.white10 : Colors.black.withAlpha(5)),
      ),
      child: Column(children: children),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primaryTeal.withAlpha(20),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 22, color: AppTheme.primaryTeal),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
      subtitle: subtitle != null
          ? Text(subtitle!,
              style: GoogleFonts.inter(
                  fontSize: 12,
                  color: isDark ? Colors.white38 : Colors.black38))
          : null,
      trailing: trailing ??
          Icon(Icons.chevron_right_rounded,
              size: 20, color: isDark ? Colors.white12 : Colors.black12),
      onTap: onTap,
    );
  }
}

class _ShimmerCard extends StatelessWidget {
  const _ShimmerCard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.white10 : Colors.black.withAlpha(10),
      highlightColor: isDark ? Colors.white24 : Colors.black.withAlpha(5),
      child: Container(
        height: 150,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
      ),
    );
  }
}
