import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:unipast/features/offline/offline_service.dart';
import 'package:unipast/features/payment/payment_service.dart';
import 'package:unipast/features/auth/profile_service.dart';
import 'package:unipast/core/god_mind_theme.dart';

class OfflineScreen extends ConsumerStatefulWidget {
  const OfflineScreen({super.key});

  @override
  ConsumerState<OfflineScreen> createState() => _OfflineScreenState();
}

class _OfflineScreenState extends ConsumerState<OfflineScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final service = ref.read(offlineServiceProvider);
      if (service != null) {
        service.clearExpired().then((_) {
          ref.invalidate(cachedQuestionsProvider);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cachedAsync = ref.watch(cachedQuestionsProvider);

    return Scaffold(
      backgroundColor: GMTheme.bg,
      body: Stack(
        children: [
          const AnimatedNeuralBg(),
          Column(
            children: [
              _buildAppBar(context),
              Expanded(
                child: cachedAsync.when(
                  data: (items) => items.isEmpty
                      ? const _EmptyOfflineState()
                      : ListView.builder(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.only(left: 20, right: 20, top: 16, bottom: 120),
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: _OfflineGodMindCard(item: item),
                            );
                          },
                        ),
                  loading: () => const Center(child: CircularProgressIndicator(color: GMTheme.primary)),
                  error: (e, s) => Center(child: Text('Error: $e', style: GoogleFonts.inter(color: GMTheme.danger))),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
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
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Offline Contents',
                style: GoogleFonts.orbitron(
                  color: GMTheme.text,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OfflineGodMindCard extends ConsumerWidget {
  final dynamic item;

  const _OfflineGodMindCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () {
        final sub = ref.read(mySubscriptionProvider).value;
        final profile = ref.read(myProfileProvider).value;
        final userName = profile?.fullName ?? 'Student';

        if (sub != null && sub.isActive) {
          context.push(
            '/pdf-viewer',
            extra: {
              'url': item.filePath,
              'userName': userName,
              'isLocal': true,
            },
          );
        } else {
          context.push('/paywall', extra: {
            'url': item.filePath,
            'userName': userName,
            'isLocal': true,
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: GMTheme.glassBox,
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [GMTheme.accent.withAlpha(40), GMTheme.accent.withAlpha(10)],
                  radius: 1.0,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: GMTheme.accent.withAlpha(50)),
                boxShadow: [BoxShadow(color: GMTheme.accent.withAlpha(20), blurRadius: 15)],
              ),
              child: const Icon(Icons.download_done_rounded, color: GMTheme.accent, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: GMTheme.text,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Saved: ${DateFormat.yMMMd().format(item.downloadedAt)}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: GMTheme.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (item.expiresAt != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.timer_outlined, size: 12, color: GMTheme.danger),
                        const SizedBox(width: 4),
                        Text(
                          'Expires ${DateFormat.yMMMd().format(item.expiresAt!)}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: GMTheme.danger,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: GMTheme.primary.withAlpha(20),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.offline_pin_rounded, color: GMTheme.primary, size: 24),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyOfflineState extends StatelessWidget {
  const _EmptyOfflineState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(32),
        decoration: GMTheme.glassBox,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: GMTheme.textMuted.withAlpha(20),
                shape: BoxShape.circle,
                border: Border.all(color: GMTheme.textMuted.withAlpha(30)),
              ),
              child: const Icon(Icons.cloud_off_rounded, color: GMTheme.textMuted, size: 56),
            ),
            const SizedBox(height: 24),
            Text(
              'No physical copies yet?',
              style: GoogleFonts.orbitron(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: GMTheme.text,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Download past questions to access them even without an internet connection.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: GMTheme.textMuted,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => context.go('/browse'),
              icon: const Icon(Icons.search_rounded),
              label: const Text('Browse Questions'),
              style: ElevatedButton.styleFrom(
                backgroundColor: GMTheme.primary.withAlpha(20),
                foregroundColor: GMTheme.primary,
                elevation: 0,
                side: BorderSide(color: GMTheme.primary.withAlpha(50)),
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                textStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
