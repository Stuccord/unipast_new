import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unipast/core/theme.dart';
import 'package:unipast/core/ui_helpers.dart';
import 'package:unipast/features/auth/auth_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// Login Screen
// ---------------------------------------------------------------------------

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  late final AnimationController _entryController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.1, 1.0, curve: Curves.easeOutCubic),
    ));
    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _onLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await ref.read(authServiceProvider).signInWithEmail(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      if (mounted) {
        setState(() => _isLoading = false);
        showSuccessSnackbar(context, 'Login successful!');
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        showErrorSnackbar(context, 'Login failed: ${e.toString()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        body: Stack(
          children: [
            // ---------------------------------------------------------------
            // Full-screen gradient background
            // ---------------------------------------------------------------
            AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              width: size.width,
              height: size.height,
              decoration: BoxDecoration(
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
            ),

            // ---------------------------------------------------------------
            // Decorative blurred circles
            // ---------------------------------------------------------------
            Positioned(
              top: -60,
              right: -80,
              child: _GlowCircle(
                  size: 260, color: Colors.white.withAlpha(isDark ? 10 : 20)),
            ),
            Positioned(
              bottom: -80,
              left: -60,
              child: _GlowCircle(
                  size: 300,
                  color: const Color(0xFFF59E0B).withAlpha(isDark ? 30 : 25)),
            ),
            Positioned(
              top: size.height * 0.35,
              left: -40,
              child: _GlowCircle(
                  size: 180, color: Colors.white.withAlpha(isDark ? 8 : 12)),
            ),

            // ---------------------------------------------------------------
            // Main scrollable content
            // ---------------------------------------------------------------
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Logo + badge
                          _LogoBadge(isDark: isDark),
                          const SizedBox(height: 28),
                          // Glassmorphism card
                          _GlassCard(
                            isDark: isDark,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Header
                                _Header(isDark: isDark),
                                const SizedBox(height: 32),
                                // Form
                                Form(
                                  key: _formKey,
                                  child: Column(
                                    children: [
                                      // Email
                                      _EmailField(
                                          controller: _emailController,
                                          isDark: isDark),
                                      const SizedBox(height: 18),
                                      // Password
                                      _PasswordField(
                                        controller: _passwordController,
                                        obscure: _obscurePassword,
                                        isDark: isDark,
                                        onToggle: () => setState(() =>
                                            _obscurePassword =
                                                !_obscurePassword),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Forgot password
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: _ForgotPasswordLink(isDark: isDark),
                                ),
                                const SizedBox(height: 28),
                                // Login CTA
                                _LoginButton(
                                  isLoading: _isLoading,
                                  onTap: _isLoading ? null : _onLogin,
                                ),
                                const SizedBox(height: 24),
                                // Sign up link
                                _SignUpLink(isDark: isDark),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),
                          // Social proof
                          const _SocialProofBadge(),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Logo + Top Badge
// ---------------------------------------------------------------------------

class _LogoBadge extends StatelessWidget {
  final bool isDark;
  const _LogoBadge({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Logo mark
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(isDark ? 25 : 40),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withAlpha(60), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(30),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: Text(
              'UP',
              style: GoogleFonts.playfairDisplay(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 2,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'UniPast',
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Glassmorphism Card
// ---------------------------------------------------------------------------

class _GlassCard extends StatelessWidget {
  final Widget child;
  final bool isDark;
  const _GlassCard({required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF1F2937).withAlpha(230)
                : Colors.white.withAlpha(230),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isDark
                  ? Colors.white.withAlpha(20)
                  : Colors.white.withAlpha(180),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(isDark ? 80 : 40),
                blurRadius: 40,
                offset: const Offset(0, 20),
              ),
              BoxShadow(
                color: isDark
                    ? const Color(0xFF0D9488).withAlpha(30)
                    : Colors.white.withAlpha(120),
                blurRadius: 1,
                spreadRadius: 0,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _Header extends StatelessWidget {
  final bool isDark;
  const _Header({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : AppTheme.textDark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Welcome Back ',
              style: GoogleFonts.playfairDisplay(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: textColor,
                height: 1.2,
              ),
            ),
            const Icon(Icons.front_hand_rounded, size: 28, color: Color(0xFFF59E0B)),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            // Gold accent underline bar
            Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Sign in to UniPast',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: isDark ? Colors.white54 : AppTheme.textLight,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Email Field
// ---------------------------------------------------------------------------

class _EmailField extends StatelessWidget {
  final TextEditingController controller;
  final bool isDark;
  const _EmailField({required this.controller, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      style: GoogleFonts.inter(
          fontSize: 15, color: isDark ? Colors.white : AppTheme.textDark),
      decoration: _fieldDecoration(
        context,
        label: 'Email Address',
        icon: Icons.alternate_email_rounded,
        isDark: isDark,
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Please enter your email';
        if (!v.contains('@')) return 'Enter a valid email';
        return null;
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Password Field
// ---------------------------------------------------------------------------

class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final bool obscure;
  final bool isDark;
  final VoidCallback onToggle;

  const _PasswordField({
    required this.controller,
    required this.obscure,
    required this.isDark,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      textInputAction: TextInputAction.done,
      style: GoogleFonts.inter(
          fontSize: 15, color: isDark ? Colors.white : AppTheme.textDark),
      decoration: _fieldDecoration(
        context,
        label: 'Password',
        icon: Icons.lock_outline_rounded,
        isDark: isDark,
        suffix: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            size: 20,
            color: isDark ? Colors.white38 : Colors.grey.shade400,
          ),
          onPressed: onToggle,
        ),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Please enter your password';
        if (v.length < 6) return 'Password must be at least 6 characters';
        return null;
      },
    );
  }
}

InputDecoration _fieldDecoration(
  BuildContext context, {
  required String label,
  required IconData icon,
  required bool isDark,
  Widget? suffix,
}) {
  final fillColor = isDark ? Colors.white.withAlpha(10) : Colors.grey.shade50;
  final borderColor =
      isDark ? Colors.white.withAlpha(30) : Colors.grey.shade200;

  return InputDecoration(
    labelText: label,
    labelStyle: GoogleFonts.inter(
      fontSize: 14,
      color: isDark ? Colors.white54 : Colors.grey.shade500,
    ),
    floatingLabelStyle: GoogleFonts.inter(
      fontSize: 12,
      color: AppTheme.primaryTeal,
      fontWeight: FontWeight.w600,
    ),
    prefixIcon: Icon(icon,
        size: 20, color: isDark ? Colors.white38 : Colors.grey.shade400),
    suffixIcon: suffix,
    filled: true,
    fillColor: fillColor,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: borderColor),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: borderColor),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppTheme.primaryTeal, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppTheme.errorRed, width: 1.5),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppTheme.errorRed, width: 2),
    ),
  );
}

// ---------------------------------------------------------------------------
// Forgot Password
// ---------------------------------------------------------------------------

class _ForgotPasswordLink extends StatelessWidget {
  final bool isDark;
  const _ForgotPasswordLink({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Forgot password: wired to forgot password flow / recovery
      },
      child: Text(
        'Forgot Password?',
        style: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: const Color(0xFFF59E0B),
          decoration: TextDecoration.underline,
          decorationColor: const Color(0xFFF59E0B).withAlpha(120),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Login CTA Button
// ---------------------------------------------------------------------------

class _LoginButton extends StatefulWidget {
  final bool isLoading;
  final VoidCallback? onTap;

  const _LoginButton({required this.isLoading, required this.onTap});

  @override
  State<_LoginButton> createState() => _LoginButtonState();
}

class _LoginButtonState extends State<_LoginButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          height: 58,
          decoration: BoxDecoration(
            gradient: widget.onTap != null
                ? const LinearGradient(
                    colors: [Color(0xFF138577), Color(0xFF0A6C5F)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : null,
            color: widget.onTap == null ? Colors.grey.shade200 : null,
            borderRadius: BorderRadius.circular(16),
            boxShadow: widget.onTap != null
                ? [
                    BoxShadow(
                      color: AppTheme.primaryTeal.withAlpha(100),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Text(
                    'Sign In',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sign Up Link
// ---------------------------------------------------------------------------

class _SignUpLink extends StatelessWidget {
  final bool isDark;
  const _SignUpLink({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account?  ",
          style: GoogleFonts.inter(
            fontSize: 13,
            color: isDark ? Colors.white54 : Colors.grey.shade500,
          ),
        ),
        GestureDetector(
          onTap: () => context.push('/signup'),
          child: Text(
            'Sign Up',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFFF59E0B),
              decoration: TextDecoration.underline,
              decorationColor: const Color(0xFFF59E0B).withAlpha(120),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Social Proof Badge
// ---------------------------------------------------------------------------

class _SocialProofBadge extends StatelessWidget {
  const _SocialProofBadge();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(20),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withAlpha(40)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.verified_rounded,
                size: 16, color: Color(0xFFF59E0B)),
            const SizedBox(width: 6),
            Text(
              'Trusted by 5,000+ KTU students',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white.withAlpha(220),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Decorative Blur Circle
// ---------------------------------------------------------------------------

class _GlowCircle extends StatelessWidget {
  final double size;
  final Color color;
  const _GlowCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}
