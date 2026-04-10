import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unipast/core/theme.dart';

class UniPastSplashScreen extends StatefulWidget {
  final String? errorMessage;
  final VoidCallback? onRetry;

  const UniPastSplashScreen({
    super.key,
    this.errorMessage,
    this.onRetry,
  });

  @override
  State<UniPastSplashScreen> createState() => _UniPastSplashScreenState();
}

class _UniPastSplashScreenState extends State<UniPastSplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _logoController;
  late final AnimationController _tiltController;
  late final AnimationController _glowController;
  
  late final Animation<double> _scaleAnimation;
  late final Animation<double> _tiltAnimation;
  late final Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    
    // Logo Pulsing
    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeInOut),
    );

    // 3D Tilt Loop
    _tiltController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _tiltAnimation = Tween<double>(begin: -0.1, end: 0.1).animate(
      CurvedAnimation(parent: _tiltController, curve: Curves.easeInOut),
    );

    // Background Glow Animation
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _tiltController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        children: [
          // 1. Premium Gradient Background
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? AppTheme.bgDark : AppTheme.bgLight,
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                      : [const Color(0xFF0F766E), const Color(0xFF134E4A)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),

          // 2. Animated Ambient Glows (3D depth)
          AnimatedBuilder(
            animation: _glowAnimation,
            builder: (context, _) {
              return Stack(
                children: [
                  _PositionedGlow(
                    top: -100 + (50 * _glowAnimation.value),
                    left: -100 + (30 * _glowAnimation.value),
                    color: AppTheme.accentGold.withAlpha(isDark ? 30 : 50),
                    size: 400,
                  ),
                  _PositionedGlow(
                    bottom: -50 + (40 * _glowAnimation.value),
                    right: -50 - (20 * _glowAnimation.value),
                    color: AppTheme.primaryTeal.withAlpha(isDark ? 40 : 60),
                    size: 350,
                  ),
                ],
              );
            },
          ),

          // 3. Main Content
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  
                  // 3D Tilted Logo Card
                  AnimatedBuilder(
                    animation: _tiltAnimation,
                    builder: (context, child) {
                      return Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.001) // perspective
                          ..rotateX(_tiltAnimation.value)
                          ..rotateY(_tiltAnimation.value * 2),
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: child,
                        ),
                      );
                    },
                    child: Hero(
                      tag: 'app_logo',
                      child: Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(36),
                          gradient: LinearGradient(
                            colors: [
                              AppTheme.accentGold,
                              AppTheme.accentGold.withAlpha(150),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withAlpha(80),
                              blurRadius: 40,
                              offset: const Offset(10, 20),
                            ),
                            BoxShadow(
                              color: AppTheme.accentGold.withAlpha(100),
                              blurRadius: 20,
                              offset: const Offset(-5, -5),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            // Glass Highlight
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(36),
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.white.withAlpha(100),
                                      Colors.transparent,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                ),
                              ),
                            ),
                            Center(
                              child: Text(
                                'UP',
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 52,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 2,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black.withAlpha(50),
                                      offset: const Offset(4, 4),
                                      blurRadius: 10,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 48),
                  
                  // Text Content with 3D shadowing
                  Text(
                    'UniPast',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 4,
                      shadows: [
                        Shadow(
                          color: Colors.black.withAlpha(100),
                          offset: const Offset(0, 5),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _GlassBadge(
                    child: Text(
                      'Past Questions • Future Success',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withAlpha(220),
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 60),

                  // Loading OR Error State
                  if (widget.errorMessage != null) 
                    _ErrorDisplay(
                      message: widget.errorMessage!,
                      onRetry: widget.onRetry,
                    )
                  else 
                    const _PremiumLoadingIndicator(),
                    
                  const Spacer(),
                  
                  Text(
                    'BUILDING THE FUTURE OF LEARNING',
                    style: GoogleFonts.inter(
                      color: Colors.white38,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 3,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PositionedGlow extends StatelessWidget {
  final double? top, left, bottom, right;
  final Color color;
  final double size;

  const _PositionedGlow({
    this.top, this.left, this.bottom, this.right,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top, left: left, bottom: bottom, right: right,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color,
              blurRadius: 100,
              spreadRadius: 50,
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassBadge extends StatelessWidget {
  final Widget child;
  const _GlassBadge({required this.child});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(30),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(20),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Colors.white.withAlpha(30)),
          ),
          child: child,
        ),
      ),
    );
  }
}

class _PremiumLoadingIndicator extends StatelessWidget {
  const _PremiumLoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
                AppTheme.accentGold.withAlpha(200)),
          ),
        ),
      ],
    );
  }
}

class _ErrorDisplay extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const _ErrorDisplay({required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: _GlassBadge(
        child: Column(
          children: [
            const Icon(Icons.warning_amber_rounded, color: AppTheme.accentGold, size: 28),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: onRetry,
                style: TextButton.styleFrom(
                  backgroundColor: AppTheme.accentGold,
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: Text(
                  'RETRY SYSTEM',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
