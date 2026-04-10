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
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: isDark ? AppTheme.bgDark : AppTheme.bgLight,
          // Removed missing watermark asset to prevent rendering crash.
          // image: const AssetImage('assets/images/watermark.png'), 
          // opacity: isDark ? 0.05 : 0.03, 
          // repeat: ImageRepeat.repeat,
          gradient: isDark
              ? const LinearGradient(
                  colors: [
                    Color(0xFF0F172A),
                    Color(0xFF070B14),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : const LinearGradient(
                  colors: [
                    Color(0xFF0A6C5F),
                    Color(0xFF064D43),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Logo Glow
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: AppTheme.accentGold.withAlpha(isDark ? 30 : 255),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(isDark ? 80 : 40),
                        blurRadius: 40,
                        offset: const Offset(0, 15),
                      ),
                    ],
                    border: Border.all(
                      color: isDark ? AppTheme.accentGold.withAlpha(100) : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      'UP',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        color: isDark ? AppTheme.accentGold : Colors.white,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'UniPast',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppTheme.accentGold,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Past Questions • Future Success',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white70,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 32),

              // Loading OR Error State
              if (widget.errorMessage != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.red.withAlpha(200),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.errorMessage!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                if (widget.onRetry != null)
                  ElevatedButton.icon(
                    onPressed: widget.onRetry,
                    icon: const Icon(Icons.refresh, color: Colors.white),
                    label: Text(
                      'Retry',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withAlpha(40),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  )
              ] else ...[
                const SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ],
              const Spacer(),
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Text(
                  'Powered by KTU',
                  style: GoogleFonts.inter(
                    color: Colors.white54,
                    fontSize: 12,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
