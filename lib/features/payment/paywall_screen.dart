import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unipast/core/supabase_config.dart';
import 'package:unipast/core/theme.dart';
import 'package:unipast/core/ui_helpers.dart';
import 'package:unipast/features/payment/payment_service.dart';
import 'package:unipast/features/payment/payment_webview.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> with WidgetsBindingObserver {

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
      // Refresh subscription when user returns to app
      ref.invalidate(mySubscriptionProvider);
    }
  }

  void _onSubscribe() {
    final user = ref.read(supabaseClientProvider).auth.currentUser;
    if (user == null) {
      showErrorSnackbar(context, 'User not logged in');
      return;
    }
 
    final paymentFuture = ref.read(paymentServiceProvider).initializeTransaction(
          email: user.email ?? '',
          amountPesewas: 100, // GHS 1.00 (Testing Amount)
          userId: user.id,
        );
 
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (webViewContext) => PaymentWebView(
          initialFuture: paymentFuture,
          onFinish: (bool success, {String? reference}) async {
    // Capture ref-dependent values BEFORE pop() disposes the widget.
    final payService = ref.read(paymentServiceProvider);
    final userId = user.id;

    Navigator.of(webViewContext).pop(); 
    
    if (!success) return;

    try {
      if (userId.isNotEmpty && reference != null) {
        await payService.verifySubscription(reference, userId);
      }
      
      if (mounted) {
        showSuccessSnackbar(context, 'Payment successful! Updating account...');
      }
    } catch (e) {
      if (mounted) {
        showErrorSnackbar(context, 'Payment succeeded, but could not update account automatically.');
      }
    } finally {
      if (mounted) ref.invalidate(mySubscriptionProvider);
    }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // REACTIVE ACTIVATION: 
    // Listen for the subscription to become active (via webhook or client verify).
    // As soon as the Stream broadcasts the active sub, we close the paywall.
    ref.listen(mySubscriptionProvider, (previous, next) {
      next.whenData((sub) {
        if (sub != null && sub.isActive) {
          if (mounted) {
            context.pop(); // Close Paywall automatically
            showSuccessSnackbar(context, 'Premium features unlocked!');
          }
        }
      });
    });

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF042F2E), const Color(0xFF0F172A)]
                    : [AppTheme.primaryTeal, const Color(0xFF0D9488)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // Header / Close
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close_rounded,
                            color: Colors.white),
                        onPressed: () => context.pop(),
                      ),
                      const Spacer(),
                      Text(
                        'UniPast Premium',
                        style: GoogleFonts.playfairDisplay(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      const Spacer(),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 10),
                        // Crown icon with glow
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(20),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.accentGold.withAlpha(30),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.workspace_premium_rounded,
                              color: AppTheme.accentGold, size: 56),
                        ),
                        const SizedBox(height: 32),

                        Text(
                          'Unlock All Past Questions',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),

                        Text(
                          'Get full access to expert solutions and offline downloads for just ₵1/semester.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: Colors.white.withAlpha(180),
                            height: 1.5,
                          ),
                        ),

                        const SizedBox(height: 40),

                        // Benefits Card
                        _BenefitsList(isDark: isDark),

                        const SizedBox(height: 48),

                        // CTA Button
                        _SubscribeButton(
                          isProcessing: false,
                          onTap: _onSubscribe,
                        ),

                        const SizedBox(height: 20),
                        // MoMo Manual Approval Tip
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(20),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withAlpha(30)),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.info_outline_rounded, color: AppTheme.accentGold, size: 16),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Mobile Money Tip',
                                    style: GoogleFonts.inter(
                                      color: AppTheme.accentGold,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'If you don\'t see the payment prompt, dial *170# (MTN) or *110# (Telecel) to approve manually under My Wallet / Transactions.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),
                        TextButton(
                          onPressed: () {
                            showSuccessSnackbar(context, 'Checking for active subscription...');
                            ref.invalidate(mySubscriptionProvider);
                          },
                          child: Text(
                            'Paid already? Check Status',
                            style: GoogleFonts.inter(
                              color: AppTheme.accentGold.withAlpha(200),
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => context.pop(),
                          child: Text(
                            'Maybe Later',
                            style: GoogleFonts.inter(
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BenefitsList extends StatelessWidget {
  final bool isDark;
  const _BenefitsList({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(isDark ? 20 : 30),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withAlpha(40)),
      ),
      child: const Column(
        children: [
          _BenefitItem(text: 'Unlimited downloads'),
          _BenefitItem(text: 'Offline access to all solutions'),
          _BenefitItem(text: 'New uploads notifications'),
          _BenefitItem(text: 'Personalized recommendations'),
        ],
      ),
    );
  }
}

class _BenefitItem extends StatelessWidget {
  final String text;
  const _BenefitItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Color(0xFFF59E0B), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubscribeButton extends StatefulWidget {
  final bool isProcessing;
  final VoidCallback? onTap;

  const _SubscribeButton({required this.isProcessing, required this.onTap});

  @override
  State<_SubscribeButton> createState() => _SubscribeButtonState();
}

class _SubscribeButtonState extends State<_SubscribeButton> {
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) =>
          setState(() => _isProcessing = true), // For scale effect only
      onTapUp: (_) => setState(() => _isProcessing = false),
      onTapCancel: () => setState(() => _isProcessing = false),
      onTap: widget.onTap,
      child: TweenAnimationBuilder<double>(
        duration: const Duration(milliseconds: 150),
        tween: Tween(begin: 1.0, end: _isProcessing ? 0.96 : 1.0),
        builder: (context, scale, child) => Transform.scale(
          scale: scale,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 64,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.accentGold,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accentGold.withAlpha(100),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Center(
              child: widget.isProcessing
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    )
                  : Text(
                      'Subscribe Now – ₵1 / Semester',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
