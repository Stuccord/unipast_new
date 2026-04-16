 
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unipast/core/god_mind_theme.dart';
import 'package:unipast/core/ui_helpers.dart';
import 'package:unipast/features/auth/auth_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// Login Screen - Premium Edition
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
      duration: const Duration(milliseconds: 1000),
    );
    _fadeAnim = CurvedAnimation(
      parent: _entryController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.15),
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
        showSuccessSnackbar(context, 'Neurolink Established. Welcome.');
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        showErrorSnackbar(context, 'Authentication failed: ${e.toString()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: GMTheme.bg,
        body: Stack(
          children: [
            // ---------------------------------------------------------------
            // Futuristic Neural Background
            // ---------------------------------------------------------------
            const AnimatedNeuralBg(),

            // ---------------------------------------------------------------
            // Main scrollable content
            // ---------------------------------------------------------------
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Logo
                          const UniPastLogoBadge(),
                          const SizedBox(height: 32),
                          
                          // Form Glass Container
                          Container(
                            padding: const EdgeInsets.all(32),
                            decoration: GMTheme.glassBox,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Heading
                                Text(
                                  'INITIALIZE\nCONNECTION',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.orbitron(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: GMTheme.text,
                                    letterSpacing: 2,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'Enter your credentials to access the UniPast platform.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: GMTheme.textMuted,
                                  ),
                                ),
                                const SizedBox(height: 40),

                                // Input Fields
                                Form(
                                  key: _formKey,
                                  child: Column(
                                    children: [
                                      _GodMindTextField(
                                        controller: _emailController,
                                        label: 'Neuro-Address (Email)',
                                        icon: Icons.alternate_email_rounded,
                                        keyboardType: TextInputType.emailAddress,
                                        validator: (v) {
                                          if (v == null || v.isEmpty) return 'Identification required';
                                          if (!v.contains('@')) return 'Invalid address structure';
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 20),
                                      _GodMindTextField(
                                        controller: _passwordController,
                                        label: 'Security Cipher (Password)',
                                        icon: Icons.lock_outline_rounded,
                                        obscure: _obscurePassword,
                                        onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
                                        validator: (v) {
                                          if (v == null || v.isEmpty) return 'Cipher required';
                                          if (v.length < 6) return 'Cipher must be at least 6 characters';
                                          return null;
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Forgot password
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: GestureDetector(
                                    onTap: () {},
                                    child: Text(
                                      'Lost cipher?',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: GMTheme.primary,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 32),

                                // Login CTA
                                _GodMindLoginButton(
                                  isLoading: _isLoading,
                                  onTap: _isLoading ? null : _onLogin,
                                ),
                                const SizedBox(height: 24),

                                // Sign up link
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Unregistered entity? ",
                                      style: GoogleFonts.inter(fontSize: 13, color: GMTheme.textMuted),
                                    ),
                                    GestureDetector(
                                      onTap: () => context.push('/signup'),
                                      child: Text(
                                        'Establish Access',
                                        style: GoogleFonts.inter(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: GMTheme.accent,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 32),
                          // Social proof
                          const _GodMindSocialProofBadge(),
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

class UniPastLogoBadge extends StatelessWidget {
  const UniPastLogoBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const UniPastCustomLogo(size: 80),
        const SizedBox(height: 16),
        Text(
          'UNIPAST',
          style: GoogleFonts.orbitron(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: GMTheme.text,
            letterSpacing: 4,
          ),
        ),
      ],
    );
  }
}

class UniPastCustomLogo extends StatelessWidget {
  final double size;
  const UniPastCustomLogo({this.size = 80, super.key});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: GMTheme.card,
        borderRadius: BorderRadius.circular(size * 0.25),
        border: Border.all(color: GMTheme.primary.withAlpha(150), width: 2),
        boxShadow: [
          BoxShadow(
            color: GMTheme.primary.withAlpha(50),
            blurRadius: size * 0.3,
            offset: Offset(0, size * 0.1),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // A stylized 'U' vector
          Positioned(
            bottom: size * 0.22,
            child: Container(
              width: size * 0.45,
              height: size * 0.42,
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: GMTheme.primary, width: size * 0.08),
                  right: BorderSide(color: GMTheme.primary, width: size * 0.08),
                  bottom: BorderSide(color: GMTheme.primary, width: size * 0.08),
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(size * 0.2),
                  bottomRight: Radius.circular(size * 0.2),
                ),
              ),
            ),
          ),
          // An accent dot representing future/past 'P' connection
          Positioned(
            top: size * 0.25,
            right: size * 0.27,
            child: Container(
              width: size * 0.12,
              height: size * 0.12,
              decoration: const BoxDecoration(
                color: GMTheme.accent,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Custom Text Field
// ---------------------------------------------------------------------------

class _GodMindTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool? obscure;
  final VoidCallback? onToggle;
  final TextInputType? keyboardType;
  final String? Function(String?) validator;

  const _GodMindTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscure,
    this.onToggle,
    this.keyboardType,
    required this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscure ?? false,
      keyboardType: keyboardType,
      textInputAction: obscure != null ? TextInputAction.done : TextInputAction.next,
      style: GoogleFonts.firaCode(fontSize: 15, color: GMTheme.text),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(fontSize: 14, color: GMTheme.textMuted),
        floatingLabelStyle: GoogleFonts.inter(fontSize: 12, color: GMTheme.primary, fontWeight: FontWeight.w600),
        prefixIcon: Icon(icon, size: 20, color: GMTheme.textMuted),
        suffixIcon: onToggle != null
            ? IconButton(
                icon: Icon(
                  obscure! ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  size: 20,
                  color: GMTheme.textMuted,
                ),
                onPressed: onToggle,
              )
            : null,
        filled: true,
        fillColor: GMTheme.surface.withAlpha(150),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: GMTheme.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: GMTheme.divider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: GMTheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: GMTheme.danger, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: GMTheme.danger, width: 2),
        ),
      ),
      validator: validator,
    );
  }
}

// ---------------------------------------------------------------------------
// Login CTA Button
// ---------------------------------------------------------------------------

class _GodMindLoginButton extends StatefulWidget {
  final bool isLoading;
  final VoidCallback? onTap;

  const _GodMindLoginButton({required this.isLoading, required this.onTap});

  @override
  State<_GodMindLoginButton> createState() => _GodMindLoginButtonState();
}

class _GodMindLoginButtonState extends State<_GodMindLoginButton> {
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
          height: 56,
          decoration: BoxDecoration(
            color: widget.onTap == null ? GMTheme.surface : GMTheme.primary.withAlpha(20),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: widget.onTap == null ? GMTheme.divider : GMTheme.primary.withAlpha(60), width: 2),
            boxShadow: widget.onTap != null ? [BoxShadow(color: GMTheme.primary.withAlpha(30), blurRadius: 20)] : null,
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(GMTheme.primary)),
                  )
                : Text(
                    'AUTHENTICATE',
                    style: GoogleFonts.orbitron(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: widget.onTap == null ? GMTheme.textMuted : GMTheme.primary,
                      letterSpacing: 2,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Social Proof Badge
// ---------------------------------------------------------------------------

class _GodMindSocialProofBadge extends StatelessWidget {
  const _GodMindSocialProofBadge();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: GMTheme.secondary.withAlpha(20),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: GMTheme.secondary.withAlpha(40)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.shield_rounded, size: 16, color: GMTheme.secondary),
            const SizedBox(width: 8),
            Text(
              'Trusted by 5,000+ Students',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: GMTheme.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
