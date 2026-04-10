import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unipast/features/offline/offline_service.dart';
import 'package:unipast/features/payment/payment_service.dart';
import 'package:unipast/features/auth/profile_service.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:unipast/core/theme.dart';

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Offline Content',
            style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: cachedAsync.when(
        data: (items) => items.isEmpty
            ? _EmptyOfflineState(isDark: isDark)
            : ListView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: _OfflineItemCard(item: item, isDark: isDark),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _OfflineItemCard extends ConsumerWidget {
  final dynamic item;
  final bool isDark;

  const _OfflineItemCard({required this.item, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: InkWell(
        onTap: () {
          final sub = ref.read(mySubscriptionProvider).value;
          final profile = ref.read(myProfileProvider).value;
          final userName = profile?.fullName ?? 'University Student';

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
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Thumbnail/Icon Placeholder
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.primaryTeal.withAlpha(isDark ? 30 : 15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.picture_as_pdf_outlined,
                    color: AppTheme.primaryTeal, size: 28),
              ),
              const SizedBox(width: 16),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Saved on ${DateFormat.yMMMd().format(item.downloadedAt)}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isDark ? Colors.white38 : Colors.black45,
                      ),
                    ),
                    if (item.expiresAt != null) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.timer_outlined, size: 12, color: Colors.orange.shade300),
                          const SizedBox(width: 4),
                          Text(
                            'Expires ${DateFormat.yMMMd().format(item.expiresAt!)}',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: Colors.orange.shade300,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Action Icon
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withAlpha(20),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.offline_pin_rounded,
                    color: Colors.green, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyOfflineState extends StatelessWidget {
  final bool isDark;
  const _EmptyOfflineState({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cloud_off_rounded,
            size: 80,
            color: isDark ? Colors.white10 : Colors.black.withAlpha(10),
          ),
          const SizedBox(height: 24),
          Text(
            'No physical copies yet?',
            style: GoogleFonts.playfairDisplay(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Download past questions to access them even without an internet connection.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isDark ? Colors.white24 : Colors.black26,
              ),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => context.go('/browse'),
            icon: const Icon(Icons.search_rounded),
            label: const Text('Browse Questions'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryTeal,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
