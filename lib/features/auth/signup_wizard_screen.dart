import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unipast/core/theme.dart';
import 'package:unipast/core/ui_helpers.dart';
import 'package:unipast/features/auth/signup_notifier.dart';
import 'package:unipast/features/browse/browse_service.dart';

// ---------------------------------------------------------------------------
// Constants & Data
// ---------------------------------------------------------------------------

const _kTotalSteps = 5; // 0..4

const _stepTitles = [
  'Create Account',
  'Your Identity',
  'Your University',
  'Faculty & Programme',
  'Level & Semester',
];

const _stepSubtitles = [
  'Secure credentials to get started',
  'Tell us who you are',
  'Find your campus',
  'Choose your study path',
  'Select your academic stage',
];



// Gradient definitions per step
const List<List<Color>> _stepGradients = [
  [Color(0xFF0F172A), Color(0xFF0A6C5F)], // navy to teal
  [Color(0xFF0A6C5F), Color(0xFF064D43)], // teal to dark teal
  [Color(0xFF064D43), Color(0xFF042F2E)], // darker
  [Color(0xFF0A6C5F), Color(0xFF0F172A)], // teal back to navy
  [Color(0xFFD4A017), Color(0xFFB45309)], // success => Gold
];

// ---------------------------------------------------------------------------
// Main Widget
// ---------------------------------------------------------------------------

class SignupWizardScreen extends ConsumerStatefulWidget {
  const SignupWizardScreen({super.key});

  @override
  ConsumerState<SignupWizardScreen> createState() => _SignupWizardScreenState();
}

class _SignupWizardScreenState extends ConsumerState<SignupWizardScreen>
    with TickerProviderStateMixin {
  late final AnimationController _slideController;
  late final AnimationController _fadeController;
  late final ConfettiController _confettiController;

  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  // Synchronous guard against double-submission.
  // Unlike state.isLoading (which updates async), this is set/cleared
  // synchronously so rapid double-taps are blocked immediately.
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 4));
    _resetAnimations(forward: true);
    _slideController.forward();
    _fadeController.forward();
  }

  void _resetAnimations({required bool forward}) {
    _slideAnim = Tween<Offset>(
      begin: Offset(forward ? 0.15 : -0.15, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeIn),
    );
  }

  void _animateForward() {
    _slideController.reset();
    _fadeController.reset();
    _resetAnimations(forward: true);
    _slideController.forward();
    _fadeController.forward();
  }

  void _animateBack() {
    _slideController.reset();
    _fadeController.reset();
    _resetAnimations(forward: false);
    _slideController.forward();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _onNext(SignupNotifier notifier, SignupState state) async {
    final step = state.currentStep;

    // Synchronous guard — blocks a second tap before Riverpod state refreshes.
    if (_isSubmitting) return;

    if (step == 4) {
      _isSubmitting = true;
      try {
        await notifier.completeSignup(ref);
        _confettiController.play();
        // Redirect is now handled by the user clicking "Get Started" on the success step.
      } catch (e) {
        if (mounted) {
          // state.error is already formatted by the notifier
          final msg = ref.read(signupProvider).error ??
              'Signup failed. Please try again.';
          showErrorSnackbar(context, msg);
        }
      } finally {
        // Always release the lock so the user can try again after an error.
        if (mounted) setState(() => _isSubmitting = false);
      }
      return; // don't animate forward — success step handles its own UI
    }

    // Steps 0-3: just advance.
    _animateForward();
    notifier.nextStep();
  }

  void _onBack(SignupNotifier notifier, SignupState state) {
    _animateBack();
    notifier.previousStep();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(signupProvider);
    final notifier = ref.read(signupProvider.notifier);
    final step = state.currentStep;
    final gradient = _stepGradients[step.clamp(0, _stepGradients.length - 1)];
    final isSuccessStep = step >= _kTotalSteps;
    final isInteractiveStep = step < _kTotalSteps;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            // Background gradient
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            // Decorative circles
            Positioned(
              top: -80,
              right: -80,
              child: _DecorativeCircle(
                size: 280,
                color: Colors.white.withAlpha(18),
              ),
            ),
            Positioned(
              bottom: -100,
              left: -60,
              child: _DecorativeCircle(
                size: 320,
                color: Colors.white.withAlpha(12),
              ),
            ),
            // Main content
            SafeArea(
              child: Column(
                children: [
                  // Header
                  _WizardHeader(
                    step: step,
                    onBack: step > 0 && !isSuccessStep
                        ? () => _onBack(notifier, state)
                        : null,
                    isSuccessStep: isSuccessStep,
                  ),
                  // Progress stepper
                  if (isInteractiveStep) ...[
                    const SizedBox(height: 8),
                    _StepperDots(currentStep: step, totalSteps: _kTotalSteps),
                    const SizedBox(height: 4),
                    _ProgressBar(
                      progress: step / (_kTotalSteps - 1),
                    ),
                    const SizedBox(height: 20),
                  ],
                  // Step title
                  if (isInteractiveStep)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _stepTitles[step],
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _stepSubtitles[step],
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              color: Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (isInteractiveStep) const SizedBox(height: 20),
                  // Step card
                  Expanded(
                    child: FadeTransition(
                      opacity: _fadeAnim,
                      child: SlideTransition(
                        position: _slideAnim,
                        child: _StepCard(
                          step: step,
                          state: state,
                          notifier: notifier,
                          onNext: () => _onNext(notifier, state),
                          onBack: () => _onBack(notifier, state),
                          confettiController: _confettiController,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Confetti overlay
            Align(
              alignment: Alignment.topCenter,
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                shouldLoop: false,
                colors: const [
                  Color(0xFFF59E0B),
                  Color(0xFF10B981),
                  Color(0xFF006D77),
                  Colors.white,
                  Color(0xFFEC4899),
                ],
                numberOfParticles: 60,
                maxBlastForce: 40,
                minBlastForce: 10,
                emissionFrequency: 0.05,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _WizardHeader extends StatelessWidget {
  final int step;
  final VoidCallback? onBack;
  final bool isSuccessStep;

  const _WizardHeader(
      {required this.step, required this.onBack, required this.isSuccessStep});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          if (onBack != null)
            Material(
              color: Colors.white.withAlpha(30),
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: onBack,
                child: const Padding(
                  padding: EdgeInsets.all(10),
                  child: Icon(Icons.arrow_back_ios_new,
                      color: Colors.white, size: 18),
                ),
              ),
            )
          else
            const SizedBox(width: 40),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(30),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'UniPast',
              style: GoogleFonts.playfairDisplay(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const Spacer(),
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stepper Dots + Progress Bar
// ---------------------------------------------------------------------------

class _StepperDots extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const _StepperDots({required this.currentStep, required this.totalSteps});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(totalSteps, (i) {
          final isActive = i == currentStep;
          final isDone = i < currentStep;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: isActive ? 24 : 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              color: isDone || isActive
                  ? Colors.white
                  : Colors.white.withAlpha(80),
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double progress;
  const _ProgressBar({required this.progress});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: progress.clamp(0.0, 1.0),
          backgroundColor: Colors.white.withAlpha(40),
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          minHeight: 4,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Decorative Circle Widget
// ---------------------------------------------------------------------------

class _DecorativeCircle extends StatelessWidget {
  final double size;
  final Color color;
  const _DecorativeCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

// ---------------------------------------------------------------------------
// Step Card Container
// ---------------------------------------------------------------------------

class _StepCard extends StatelessWidget {
  final int step;
  final SignupState state;
  final SignupNotifier notifier;
  final VoidCallback onNext;
  final VoidCallback onBack;
  final ConfettiController confettiController;

  const _StepCard({
    required this.step,
    required this.state,
    required this.notifier,
    required this.onNext,
    required this.onBack,
    required this.confettiController,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (step == 5) {
      return _SuccessStep(confettiController: confettiController, email: state.email);
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2332) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(48),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: _buildStep(context),
      ),
    );
  }

  Widget _buildStep(BuildContext context) {
    switch (step) {
      case 0:
        return _Step0Credentials(
            state: state, notifier: notifier, onNext: onNext);
      case 1:
        return _Step1Identity(state: state, notifier: notifier, onNext: onNext);
      case 2:
        return _Step2University(
            state: state, notifier: notifier, onNext: onNext);
      case 3:
        return _Step3Faculty(state: state, notifier: notifier, onNext: onNext);
      case 4:
        return _Step4LevelSemester(
            state: state, notifier: notifier, onNext: onNext);
      default:
        return const SizedBox.shrink();
    }
  }
}

// ---------------------------------------------------------------------------
// Step 0 – Credentials (email / phone)
// ---------------------------------------------------------------------------

class _Step0Credentials extends StatefulWidget {
  final SignupState state;
  final SignupNotifier notifier;
  final VoidCallback onNext;

  const _Step0Credentials(
      {required this.state, required this.notifier, required this.onNext});

  @override
  State<_Step0Credentials> createState() => _Step0CredentialsState();
}

class _Step0CredentialsState extends State<_Step0Credentials> {
  bool _useEmail = true;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Email or Phone toggle
          Row(
            children: [
              _ToggleChip(
                label: 'Email',
                icon: Icons.email_outlined,
                isSelected: _useEmail,
                onTap: () => setState(() => _useEmail = true),
              ),
              const SizedBox(width: 8),
              _ToggleChip(
                label: 'Phone',
                icon: Icons.phone_outlined,
                isSelected: !_useEmail,
                onTap: () => setState(() => _useEmail = false),
              ),
            ],
          ),
          const SizedBox(height: 24),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _useEmail
                ? _buildField(
                    key: const ValueKey('email'),
                    label: 'Email Address',
                    icon: Icons.alternate_email,
                    keyboardType: TextInputType.emailAddress,
                    initialValue: widget.state.email,
                    onChanged: (val) => widget.notifier.updateAccountInfo(
                      email: val,
                      phone: widget.state.phone,
                      password: widget.state.password,
                    ),
                  )
                : _buildField(
                    key: const ValueKey('phone'),
                    label: 'Phone Number',
                    icon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    initialValue: widget.state.phone,
                    onChanged: (val) => widget.notifier.updateAccountInfo(
                      email: widget.state.email,
                      phone: val,
                      password: widget.state.password,
                    ),
                  ),
          ),
          const SizedBox(height: 32),
          _ContinueButton(
            onTap: (_useEmail
                    ? (widget.state.email.isNotEmpty &&
                        widget.state.email.contains('@'))
                    : (widget.state.phone.isNotEmpty &&
                        widget.state.phone.length >= 10))
                ? widget.onNext
                : null,
            label: 'Continue',
          ),
          const SizedBox(height: 16),
          Center(
            child: GestureDetector(
              onTap: () => context.go('/login'),
              child: RichText(
                text: TextSpan(
                  text: 'Already have an account?  ',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppTheme.textDark.withAlpha(180),
                  ),
                  children: [
                    TextSpan(
                      text: 'Sign in',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppTheme.primaryTeal,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildField({
    required Key key,
    required String label,
    required IconData icon,
    required TextInputType keyboardType,
    required String initialValue,
    required ValueChanged<String> onChanged,
  }) {
    return TextField(
      key: key,
      onChanged: onChanged,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step 1 – Name + Password (strength indicator)
// ---------------------------------------------------------------------------

class _Step1Identity extends StatefulWidget {
  final SignupState state;
  final SignupNotifier notifier;
  final VoidCallback onNext;

  const _Step1Identity(
      {required this.state, required this.notifier, required this.onNext});

  @override
  State<_Step1Identity> createState() => _Step1IdentityState();
}

class _Step1IdentityState extends State<_Step1Identity> {
  String _password = '';
  bool _obscure = true;

  int _strength(String p) {
    if (p.isEmpty) return 0;
    int score = 0;
    if (p.length >= 8) score++;
    if (p.contains(RegExp(r'[A-Z]'))) score++;
    if (p.contains(RegExp(r'[0-9]'))) score++;
    if (p.contains(RegExp(r'[!@#\$%^&*]'))) score++;
    return score;
  }

  Color _strengthColor(int s) {
    switch (s) {
      case 1:
        return const Color(0xFFEF4444);
      case 2:
        return const Color(0xFFF59E0B);
      case 3:
        return const Color(0xFF10B981);
      case 4:
        return const Color(0xFF059669);
      default:
        return Colors.grey.shade200;
    }
  }

  String _strengthLabel(int s) {
    switch (s) {
      case 1:
        return 'Weak';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Strong';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _strength(_password);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            onChanged: (val) =>
                widget.notifier.updatePersonalInfo(fullName: val),
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Full Name',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            onChanged: (val) {
              setState(() => _password = val);
              widget.notifier.updateAccountInfo(
                email: widget.state.email,
                phone: widget.state.phone,
                password: val,
              );
            },
            obscureText: _obscure,
            decoration: InputDecoration(
              labelText: 'Password',
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Strength bar
          if (_password.isNotEmpty) ...[
            Row(
              children: List.generate(4, (i) {
                return Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 5,
                    margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                    decoration: BoxDecoration(
                      color: i < s ? _strengthColor(s) : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 6),
            Text(
              _strengthLabel(s),
              style: GoogleFonts.inter(
                fontSize: 12,
                color: _strengthColor(s),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 8),
          // Hints
          _PasswordHint(
              text: 'At least 8 characters', met: _password.length >= 8),
          _PasswordHint(
              text: 'One uppercase letter',
              met: _password.contains(RegExp(r'[A-Z]'))),
          _PasswordHint(
              text: 'One number', met: _password.contains(RegExp(r'[0-9]'))),
          _PasswordHint(
              text: 'One special character',
              met: _password.contains(RegExp(r'[!@#\$%^&*]'))),
          const SizedBox(height: 28),
          _ContinueButton(
            isLoading: widget.state.isLoading,
            onTap: (widget.state.fullName.isNotEmpty && s >= 2)
                ? widget.onNext
                : null,
            label: 'Continue',
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _PasswordHint extends StatelessWidget {
  final String text;
  final bool met;
  const _PasswordHint({required this.text, required this.met});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(
            met ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 14,
            color: met ? const Color(0xFF10B981) : Colors.grey,
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.inter(
                fontSize: 12,
                color: met ? const Color(0xFF10B981) : Colors.grey),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step 2 – University Selection
// ---------------------------------------------------------------------------

class _Step2University extends ConsumerStatefulWidget {
  final SignupState state;
  final SignupNotifier notifier;
  final VoidCallback onNext;

  const _Step2University({
    required this.state,
    required this.notifier,
    required this.onNext,
  });

  @override
  ConsumerState<_Step2University> createState() => _Step2UniversityState();
}

class _Step2UniversityState extends ConsumerState<_Step2University> {
  String _activeCategory = 'All';
  String _search = '';
  String? _selectedId;

  @override
  Widget build(BuildContext context) {
    final universitiesAsync = ref.watch(universitiesProvider);

    return universitiesAsync.when(
      data: (unis) {
        final filtered = unis.where((u) {
          final matchCategory =
              _activeCategory == 'All' || u.category == _activeCategory;
          final matchSearch = _search.isEmpty ||
              u.name.toLowerCase().contains(_search.toLowerCase());
          return matchCategory && matchSearch;
        }).toList();

        final categories = [
          'All',
          ...unis.map((u) => u.category).toSet().toList()
        ];

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            children: [
              TextField(
                onChanged: (val) => setState(() => _search = val),
                decoration: InputDecoration(
                  labelText: 'Search university...',
                  prefixIcon: const Icon(Icons.search),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                height: 36,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final cat = categories[i];
                    final isActive = cat == _activeCategory;
                    return GestureDetector(
                      onTap: () => setState(() => _activeCategory = cat),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppTheme.primaryTeal
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isActive
                                ? AppTheme.primaryTeal
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Text(
                          cat,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color:
                                isActive ? Colors.white : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final uni = filtered[i];
                    final isSelected = _selectedId == uni.id;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedId = uni.id);
                        widget.notifier.updateAcademicInfo(universityId: uni.id);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppTheme.primaryTeal.withAlpha(20)
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.primaryTeal
                                : Colors.grey.shade200,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.primaryTeal
                                    : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Text(
                                  uni.name[0],
                                  style: GoogleFonts.playfairDisplay(
                                    fontWeight: FontWeight.bold,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.grey.shade600,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    uni.name,
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                  Text(
                                    uni.category,
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check_circle,
                                  color: AppTheme.primaryTeal, size: 20),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              _ContinueButton(
                isLoading: widget.state.isLoading,
                onTap: _selectedId != null ? widget.onNext : null,
                label: 'Continue',
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => const Center(child: Text('Error loading universities')),
    );
  }
}

// ---------------------------------------------------------------------------
// Step 3 – Faculty & Programme
// ---------------------------------------------------------------------------

class _Step3Faculty extends ConsumerStatefulWidget {
  final SignupState state;
  final SignupNotifier notifier;
  final VoidCallback onNext;

  const _Step3Faculty({
    required this.state,
    required this.notifier,
    required this.onNext,
  });

  @override
  ConsumerState<_Step3Faculty> createState() => _Step3FacultyState();
}

class _Step3FacultyState extends ConsumerState<_Step3Faculty> {
  String? _selectedFaculty;
  String? _selectedProgramme;

  @override
  Widget build(BuildContext context) {
    // If universityId is missing (shouldn't happen if they passed Step 2), we'd need to handle it.
    final universityId = widget.state.universityId;
    if (universityId == null) {
      return const Center(child: Text('Please select a university first'));
    }

    final facultiesAsync = ref.watch(facultiesProvider(universityId));

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select Faculty',
            style:
                GoogleFonts.playfairDisplay(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 110,
            child: facultiesAsync.when(
              data: (facs) => ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: facs.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  final f = facs[i];
                  final isSelected = _selectedFaculty == f.id;
                  return GestureDetector(
                    onTap: () => setState(() {
                      _selectedFaculty = f.id;
                      _selectedProgramme = null;
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 88,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.primaryTeal
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.primaryTeal
                              : Colors.grey.shade200,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.account_balance_rounded, // Generic icon for now
                            color: isSelected
                                ? Colors.white
                                : Colors.grey.shade600,
                            size: 26,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            f.name,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, s) => const Center(child: Text('Error')),
            ),
          ),
          if (_selectedFaculty != null) ...[
            const SizedBox(height: 20),
            Text(
              'Select Programme',
              style: GoogleFonts.playfairDisplay(
                  fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ref.watch(programmesProvider(_selectedFaculty!)).when(
                    data: (progs) => ListView.separated(
                      itemCount: progs.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 6),
                      itemBuilder: (context, i) {
                        final p = progs[i];
                        final isSelected = _selectedProgramme == p.id;
                        return GestureDetector(
                          onTap: () {
                            setState(() => _selectedProgramme = p.id);
                            widget.notifier.updateAcademicInfo(
                                programmeId: p.id, facultyId: _selectedFaculty);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppTheme.primaryTeal.withAlpha(18)
                                  : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.primaryTeal
                                    : Colors.grey.shade200,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    p.name,
                                    style: GoogleFonts.inter(
                                      fontSize: 13,
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                      color: isSelected
                                          ? AppTheme.primaryTeal
                                          : AppTheme.textDark,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(Icons.check_circle,
                                      color: AppTheme.primaryTeal, size: 18),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, s) => const Center(child: Text('Error')),
                  ),
            ),
          ],
          if (_selectedFaculty == null) const Spacer(),
          const SizedBox(height: 12),
          _ContinueButton(
            isLoading: widget.state.isLoading,
            onTap: (_selectedFaculty != null && _selectedProgramme != null)
                ? widget.onNext
                : null,
            label: 'Continue',
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step 4 – Level & Semester
// ---------------------------------------------------------------------------

class _Step4LevelSemester extends StatefulWidget {
  final SignupState state;
  final SignupNotifier notifier;
  final VoidCallback onNext;

  const _Step4LevelSemester(
      {required this.state, required this.notifier, required this.onNext});

  @override
  State<_Step4LevelSemester> createState() => _Step4LevelSemesterState();
}

class _Step4LevelSemesterState extends State<_Step4LevelSemester> {
  int? _level;
  int? _semester;

  final _levels = [100, 200, 300, 400];
  final _semesters = [1, 2];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Academic Level',
            style:
                GoogleFonts.playfairDisplay(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            children: _levels.map((lvl) {
              final isSelected = _level == lvl;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _level = lvl),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(
                              colors: [AppTheme.primaryTeal, Color(0xFF0D9488)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: isSelected ? null : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.primaryTeal
                            : Colors.grey.shade200,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppTheme.primaryTeal.withAlpha(80),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              )
                            ]
                          : [],
                    ),
                    child: Column(
                      children: [
                        Text(
                          '$lvl',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Colors.white
                                : Colors.grey.shade700,
                          ),
                        ),
                        Text(
                          'Level',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: isSelected ? Colors.white70 : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),
          Text(
            'Semester',
            style:
                GoogleFonts.playfairDisplay(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Row(
            children: _semesters.map((sem) {
              final isSelected = _semester == sem;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _semester = sem),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? const LinearGradient(
                              colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      color: isSelected ? null : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.accentGold
                            : Colors.grey.shade200,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppTheme.accentGold.withAlpha(80),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              )
                            ]
                          : [],
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Semester $sem',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? Colors.white
                                : Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 32),
          _ContinueButton(
            isLoading: widget.state.isLoading,
            onTap:
                (_level != null && _semester != null && !widget.state.isLoading)
                    ? () {
                        widget.notifier.updateAcademicInfo(
                          level: _level,
                          semester: _semester,
                        );
                        widget.onNext();
                      }
                    : null,
            label: 'Complete Signup',
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step 5 – Success / Payment CTA
// ---------------------------------------------------------------------------

class _SuccessStep extends ConsumerWidget {
  final ConfettiController confettiController;
  final String email;

  const _SuccessStep({required this.confettiController, required this.email});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF59E0B).withAlpha(80),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // Background glow
            Positioned(
              top: -40,
              right: -40,
              child: _DecorativeCircle(
                size: 200,
                color: Colors.white.withAlpha(20),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Crown icon
                  Center(
                    child: Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(50),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Icon(Icons.workspace_premium_rounded,
                            size: 48, color: Colors.white.withAlpha(200)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Welcome to UniPast!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your account is ready. You can now browse all past questions for free.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Colors.white.withAlpha(220),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Email verification notice
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(40),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: Colors.white.withAlpha(80), width: 1),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.mark_email_unread_rounded,
                            size: 28, color: Colors.white),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Check Your Email',
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'We sent a confirmation link to your inbox. Please verify your email to activate your account.',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Colors.white.withAlpha(210),
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton(
                      onPressed: () async {
                        try {
                          await ref.read(authServiceProvider).resendEmail(email);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Magic link resent! Check your inbox.'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: ${e.toString()}'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                      child: Text(
                        "Didn't receive it? Resend Link",
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Colors.white.withAlpha(200),
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // CTA button
                  GestureDetector(
                    onTap: () => context.go('/'),
                    child: Container(
                      height: 58,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(40),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'Get Started',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFD97706),
                          ),
                        ),
                      ),
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

// ---------------------------------------------------------------------------
// Shared Widgets
// ---------------------------------------------------------------------------

class _ToggleChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ToggleChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryTeal : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppTheme.primaryTeal : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16,
                color: isSelected ? Colors.white : Colors.grey.shade600),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContinueButton extends StatelessWidget {
  final VoidCallback? onTap;
  final String label;
  final bool isLoading;

  const _ContinueButton({
    required this.onTap,
    required this.label,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = onTap != null && !isLoading;
    return GestureDetector(
      onTap: isEnabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 56,
        decoration: BoxDecoration(
          gradient: isEnabled
              ? const LinearGradient(
                  colors: [AppTheme.primaryTeal, Color(0xFF0D9488)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
              : null,
          color: isEnabled ? null : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(14),
          boxShadow: isEnabled
              ? [
                  BoxShadow(
                    color: AppTheme.primaryTeal.withAlpha(90),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  label,
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isEnabled ? Colors.white : Colors.grey.shade400,
                  ),
                ),
        ),
      ),
    );
  }
}
