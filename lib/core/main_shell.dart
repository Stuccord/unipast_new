import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unipast/core/theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:unipast/core/connectivity_provider.dart';

// ---------------------------------------------------------------------------
// Shell Scaffold – wraps the 4 main tabs with the premium bottom nav
// ---------------------------------------------------------------------------

class MainShell extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell>
    with TickerProviderStateMixin {
  late final List<AnimationController> _iconControllers;
  late final List<Animation<double>> _scaleAnims;

  static const _navItems = [
    _NavItem(
      icon: Icons.home_outlined,
      activeIcon: Icons.home_rounded,
      label: 'Home',
    ),
    _NavItem(
      icon: Icons.search_rounded,
      activeIcon: Icons.search_rounded,
      label: 'Browse',
    ),
    _NavItem(
      icon: Icons.file_download_outlined,
      activeIcon: Icons.file_download_rounded,
      label: 'Offline',
    ),
    _NavItem(
      icon: Icons.person_outline_rounded,
      activeIcon: Icons.person_rounded,
      label: 'Profile',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _iconControllers = List.generate(
      _navItems.length,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 250),
      ),
    );
    _scaleAnims = _iconControllers.map((ctrl) {
      return TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.3), weight: 50),
        TweenSequenceItem(tween: Tween(begin: 1.3, end: 1.0), weight: 50),
      ]).animate(CurvedAnimation(parent: ctrl, curve: Curves.easeOut));
    }).toList();
    // Fire the initial animation for tab 0
    _iconControllers[0].forward();
  }

  @override
  void dispose() {
    for (final c in _iconControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _onTabTap(int index) {
    if (index == widget.navigationShell.currentIndex) return;
    _iconControllers[index].forward(from: 0);
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentIndex = widget.navigationShell.currentIndex;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: isDark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark.copyWith(
              systemNavigationBarColor:
                  isDark ? const Color(0xFF1A2332) : Colors.white,
            ),
      child: Scaffold(
        body: Column(
          children: [
            const _ConnectivityBanner(),
            Expanded(child: widget.navigationShell),
          ],
        ),
        bottomNavigationBar: _PremiumNavBar(
          currentIndex: currentIndex,
          items: _navItems,
          scaleAnims: _scaleAnims,
          onTap: _onTabTap,
          isDark: isDark,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Premium Nav Bar
// ---------------------------------------------------------------------------

class _PremiumNavBar extends StatelessWidget {
  final int currentIndex;
  final List<_NavItem> items;
  final List<Animation<double>> scaleAnims;
  final ValueChanged<int> onTap;
  final bool isDark;

  const _PremiumNavBar({
    required this.currentIndex,
    required this.items,
    required this.scaleAnims,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF1A2332) : Colors.white;
    final surfaceTint = isDark ? Colors.white.withAlpha(6) : Colors.transparent;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withAlpha(80)
                : Colors.black.withAlpha(20),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 68,
          color: surfaceTint,
          child: Row(
            children: List.generate(items.length, (i) {
              final item = items[i];
              final isActive = i == currentIndex;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onTap(i),
                  behavior: HitTestBehavior.opaque,
                  child: _NavBarItem(
                    item: item,
                    isActive: isActive,
                    scaleAnim: scaleAnims[i],
                    isDark: isDark,
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  final _NavItem item;
  final bool isActive;
  final Animation<double> scaleAnim;
  final bool isDark;

  const _NavBarItem({
    required this.item,
    required this.isActive,
    required this.scaleAnim,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = AppTheme.primaryTeal;
    final inactiveColor = isDark ? Colors.white38 : Colors.grey.shade400;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Icon with active pill indicator
        Stack(
          alignment: Alignment.topRight,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              decoration: BoxDecoration(
                color: isActive
                    ? AppTheme.primaryTeal.withAlpha(isDark ? 40 : 25)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: AnimatedBuilder(
                animation: scaleAnim,
                builder: (context, child) => Transform.scale(
                  scale: isActive ? scaleAnim.value : 1.0,
                  child: child,
                ),
                child: Icon(
                  isActive ? item.activeIcon : item.icon,
                  color: isActive ? activeColor : inactiveColor,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        // Label
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: GoogleFonts.inter(
            fontSize: 10,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
            color: isActive ? activeColor : inactiveColor,
          ),
          child: Text(item.label),
        ),
        // Active indicator dot
        const SizedBox(height: 2),
        AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: isActive ? 4 : 0,
          height: isActive ? 4 : 0,
          decoration: BoxDecoration(
            color: isActive ? activeColor : Colors.transparent,
            shape: BoxShape.circle,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Data class
// ---------------------------------------------------------------------------

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class _ConnectivityBanner extends ConsumerWidget {
  const _ConnectivityBanner();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(connectivityProvider);
    final isDisconnected = status == ConnectivityStatus.isDisconnected;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: isDisconnected ? 40 : 0,
      width: double.infinity,
      color: Colors.red.shade600,
      child: isDisconnected
          ? const Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wifi_off_rounded, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'No Internet Connection - Using Offline Mode',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
