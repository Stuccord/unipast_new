import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import 'package:unipast/features/auth/profile_service.dart';
import 'package:unipast/features/auth/auth_service.dart';
import 'package:unipast/features/auth/stats_service.dart';
import 'package:unipast/features/payment/payment_service.dart';
import 'package:unipast/core/lookup_data.dart';
import 'package:share_plus/share_plus.dart';

import 'package:unipast/core/god_mind_theme.dart';

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
      ref.invalidate(mySubscriptionProvider);
      ref.invalidate(profileStatsProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(myProfileProvider);
    final subscriptionAsync = ref.watch(mySubscriptionProvider);
    final statsAsync = ref.watch(profileStatsProvider);
    final currentUser = ref.watch(authServiceProvider).currentUser;

    return Scaffold(
      backgroundColor: GMTheme.bg,
      body: Stack(
        children: [
          const AnimatedNeuralBg(),
          profileAsync.when(
            data: (profile) {
              if (profile == null) return const Center(child: Text('Profile not found', style: TextStyle(color: GMTheme.text)));
              
              return CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _GodMindProfileHeader(profile: profile),

                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          // Subscription Status Card
                          subscriptionAsync.when(
                            data: (sub) => _PremiumSubscriptionCard(sub: sub),
                            loading: () => const _GodMindShimmerCard(),
                            error: (e, s) => const SizedBox.shrink(),
                          ),
                          const SizedBox(height: 32),

                          // Quick Stats
                          _QuickStatsRow(
                            stats: statsAsync.valueOrNull ?? {
                              'viewed': '0',
                              'stored': '0',
                              'streaks': '0d',
                            },
                          ),
                          const SizedBox(height: 32),

                          // Personal Information Section
                          const _SectionTitle(title: 'Personal Information'),
                          const SizedBox(height: 16),
                          _GodMindSettingsCard(
                            children: [
                              _GodMindSettingsTile(
                                icon: Icons.school_rounded,
                                iconColor: GMTheme.primary,
                                title: 'Academic Details',
                                subtitle: '${LookupData.getProgrammeName(profile.programmeId)} • Level ${profile.currentLevel}',
                                onTap: () => context.push('/profile/edit'),
                              ),
                              _GodMindSettingsTile(
                                icon: Icons.email_rounded,
                                iconColor: GMTheme.secondary,
                                title: 'Email Address',
                                subtitle: currentUser?.email ?? 'Unavailable',
                                showArrow: false,
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),

                          // Settings & Preferences
                          const _SectionTitle(title: 'App Settings'),
                          const SizedBox(height: 16),
                          _GodMindSettingsCard(
                            children: [
                              _GodMindSettingsTile(
                                icon: Icons.sync_rounded,
                                iconColor: GMTheme.primary,
                                title: 'Smart Auto-Sync',
                                subtitle: 'Download new past questions on Wi-Fi',
                                trailing: Consumer(
                                  builder: (context, ref, _) {
                                    return Switch.adaptive(
                                      value: true,
                                      activeTrackColor: GMTheme.primary.withAlpha(100),
                                      activeThumbColor: GMTheme.primary,
                                      onChanged: (val) {
                                      },
                                    );
                                  },
                                ),
                              ),
                              _GodMindSettingsTile(
                                icon: Icons.notifications_none_rounded,
                                iconColor: GMTheme.accent,
                                title: 'Notifications',
                                onTap: () => context.push('/notifications'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),

                          // Admin Section or Student Resources
                          if (profile.isAdmin) ...[
                            const _SectionTitle(title: 'Administrative Center'),
                            const SizedBox(height: 16),
                            _GodMindSettingsCard(
                              children: [
                                _GodMindSettingsTile(
                                  icon: Icons.admin_panel_settings_rounded,
                                  iconColor: GMTheme.danger,
                                  title: 'God Mind Console',
                                  subtitle: 'Manage platform content & users',
                                  onTap: () => context.push('/admin'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                          ] else ...[
                            const _SectionTitle(title: 'Student Resources'),
                            const SizedBox(height: 16),
                            _GodMindSettingsCard(
                              children: [
                                _GodMindSettingsTile(
                                  icon: Icons.volunteer_activism_rounded,
                                  iconColor: GMTheme.primary,
                                  title: 'Request Material',
                                  subtitle: 'Can\'t find a past question? Request it',
                                  onTap: () => launchUrl(Uri.parse('mailto:support@unipast.app?subject=Past Question Request')),
                                ),
                                _GodMindSettingsTile(
                                  icon: Icons.share_rounded,
                                  iconColor: GMTheme.secondary,
                                  title: 'Share UniPast',
                                  subtitle: 'Help other students excel',
                                  onTap: () {
                                    SharePlus.instance.share(
                                      ShareParams(
                                        text: 'Ace your university exams with UniPast! 🚀 Get access to thousands of past questions and brilliant AI tools. Download now: https://unipast.app',
                                        subject: 'Check out UniPast!',
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                          ],

                          // Support & About
                          const _SectionTitle(title: 'Support'),
                          const SizedBox(height: 16),
                          _GodMindSettingsCard(
                            children: [
                              _GodMindSettingsTile(
                                icon: Icons.shield_rounded,
                                iconColor: GMTheme.textMuted,
                                title: 'Privacy & Terms',
                                onTap: () => launchUrl(
                                  Uri.parse('https://unipast.app/privacy'),
                                  mode: LaunchMode.externalApplication,
                                ),
                              ),
                              _GodMindSettingsTile(
                                icon: Icons.info_rounded,
                                iconColor: GMTheme.textMuted,
                                title: 'About UniPast',
                                onTap: () => showAboutDialog(
                                  context: context,
                                  applicationName: 'UniPast',
                                  applicationVersion: 'Premium Edition',
                                  applicationIcon: const Icon(Icons.rocket_launch_rounded, size: 48, color: GMTheme.primary),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 48),

                          // Logout Button
                          Center(
                            child: ElevatedButton.icon(
                              onPressed: () => ref.read(authServiceProvider).signOut(),
                              icon: const Icon(Icons.power_settings_new_rounded, color: Colors.white),
                              label: Text(
                                'Initiate Logout',
                                style: GoogleFonts.orbitron(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: GMTheme.danger.withAlpha(80),
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                side: BorderSide(color: GMTheme.danger.withAlpha(150)),
                              ),
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
            loading: () => const Center(child: CircularProgressIndicator(color: GMTheme.primary)),
            error: (e, s) => Center(child: Text('Error: $e', style: const TextStyle(color: GMTheme.danger))),
          ),
        ],
      ),
    );
  }
}

class _GodMindProfileHeader extends StatelessWidget {
  final dynamic profile;

  const _GodMindProfileHeader({required this.profile});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 320,
      pinned: true,
      backgroundColor: Colors.transparent,
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  GMTheme.primary.withAlpha(20),
                  GMTheme.bg.withAlpha(150),
                ],
              ),
            ),
            child: FlexibleSpaceBar(
              background: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 50),
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [GMTheme.primary.withAlpha(40), GMTheme.primary.withAlpha(10)],
                      ),
                      border: Border.all(color: GMTheme.primary.withAlpha(80), width: 2),
                      boxShadow: [BoxShadow(color: GMTheme.primary.withAlpha(40), blurRadius: 20)],
                    ),
                    child: const Icon(Icons.person_rounded, size: 50, color: GMTheme.primary),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    profile.fullName,
                    style: GoogleFonts.orbitron(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: GMTheme.text,
                      letterSpacing: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${LookupData.getProgrammeName(profile.programmeId)}',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: GMTheme.primary,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${LookupData.getUniversityName(profile.universityId)}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: GMTheme.textMuted,
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _GodMindBadge(text: 'LEVEL ${profile.currentLevel}', color: GMTheme.accent),
                      const SizedBox(width: 8),
                      _GodMindBadge(text: 'SEM ${profile.currentSemester}', color: GMTheme.secondary, isOutlined: true),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GodMindBadge extends StatelessWidget {
  final String text;
  final Color color;
  final bool isOutlined;

  const _GodMindBadge({required this.text, required this.color, this.isOutlined = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isOutlined ? Colors.transparent : color.withAlpha(20),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isOutlined ? GMTheme.textMuted.withAlpha(50) : color.withAlpha(60)),
      ),
      child: Text(
        text,
        style: GoogleFonts.firaCode(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isOutlined ? GMTheme.textMuted : color,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _PremiumSubscriptionCard extends StatelessWidget {
  final dynamic sub;

  const _PremiumSubscriptionCard({this.sub});

  @override
  Widget build(BuildContext context) {
    final bool isActive = sub != null && sub.isActive;
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isActive ? GMTheme.card.withAlpha(180) : GMTheme.accent.withAlpha(20),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isActive ? GMTheme.divider : GMTheme.accent.withAlpha(50)),
        boxShadow: isActive ? [] : [BoxShadow(color: GMTheme.accent.withAlpha(20), blurRadius: 20)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isActive ? GMTheme.accent.withAlpha(20) : GMTheme.accent.withAlpha(40),
                  shape: BoxShape.circle,
                  border: Border.all(color: GMTheme.accent.withAlpha(isActive ? 60 : 100)),
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: GMTheme.accent,
                  size: 32,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isActive ? 'UniPast Premium Access' : 'Ascend to UniPast Premium',
                      style: GoogleFonts.orbitron(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: GMTheme.text,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      isActive
                          ? 'Active until ${DateFormat.yMMMd().format(sub.expiresAt)}'
                          : 'Unlock all past questions & AI solutions',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: isActive ? GMTheme.primary : GMTheme.textMuted,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.push('/paywall'),
            style: ElevatedButton.styleFrom(
              backgroundColor: GMTheme.accent.withAlpha(isActive ? 20 : 100),
              foregroundColor: GMTheme.accent,
              elevation: 0,
              side: BorderSide(color: GMTheme.accent.withAlpha(60)),
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: Text(
              isActive ? 'Renew Alignment' : 'Upgrade – ₵1 / Sem',
              style: GoogleFonts.orbitron(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.5, color: isActive ? GMTheme.accent : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickStatsRow extends StatelessWidget {
  final Map<String, String> stats;

  const _QuickStatsRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: GMTheme.glassBox,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _GodMindStatCard(label: 'Viewed', value: stats['viewed'] ?? '0', icon: Icons.visibility_rounded, color: GMTheme.primary),
          _GodMindStatDivider(),
          _GodMindStatCard(label: 'Stored', value: stats['stored'] ?? '0', icon: Icons.save_rounded, color: GMTheme.secondary),
          _GodMindStatDivider(),
          _GodMindStatCard(label: 'Streaks', value: stats['streaks'] ?? '0d', icon: Icons.local_fire_department_rounded, color: GMTheme.accent),
        ],
      ),
    );
  }
}

class _GodMindStatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _GodMindStatCard({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 24, color: color),
        const SizedBox(height: 12),
        Text(value, style: GoogleFonts.orbitron(fontSize: 20, fontWeight: FontWeight.bold, color: GMTheme.text)),
        const SizedBox(height: 4),
        Text(label, style: GoogleFonts.inter(fontSize: 11, color: GMTheme.textMuted, fontWeight: FontWeight.bold, letterSpacing: 1)),
      ],
    );
  }
}

class _GodMindStatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 40,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.transparent, GMTheme.divider, Colors.transparent],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.orbitron(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: GMTheme.textMuted,
        letterSpacing: 2,
      ),
    );
  }
}

class _GodMindSettingsCard extends StatelessWidget {
  final List<Widget> children;

  const _GodMindSettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: GMTheme.glassBox,
      child: Column(children: children),
    );
  }
}

class _GodMindSettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool showArrow;

  const _GodMindSettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.showArrow = true,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: iconColor.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: iconColor.withAlpha(40)),
        ),
        child: Icon(icon, size: 22, color: iconColor),
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: GMTheme.text,
        ),
      ),
      subtitle: subtitle != null
          ? Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Text(subtitle!, style: GoogleFonts.inter(fontSize: 12, color: GMTheme.textMuted)),
            )
          : null,
      trailing: trailing ?? (showArrow ? const Icon(Icons.chevron_right_rounded, size: 20, color: GMTheme.textMuted) : null),
      onTap: onTap,
    );
  }
}

class _GodMindShimmerCard extends StatelessWidget {
  const _GodMindShimmerCard();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: GMTheme.card,
      highlightColor: GMTheme.surface,
      child: Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          color: GMTheme.card,
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    );
  }
}
