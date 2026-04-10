import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unipast/core/theme.dart';
import 'package:unipast/core/app.dart';

// ---------------------------------------------------------------------------
// Global UI Helpers – toasts, loading overlay, success banners
// ---------------------------------------------------------------------------

/// Shows a styled error snackbar.
void showErrorSnackbar(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      _buildSnackBar(
        context,
        message: message,
        icon: Icons.error_outline_rounded,
        backgroundColor: const Color(0xFFEF4444),
      ),
    );
}

/// Shows a styled success snackbar.
void showSuccessSnackbar(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      _buildSnackBar(
        context,
        message: message,
        icon: Icons.check_circle_outline_rounded,
        backgroundColor: AppTheme.successGreen,
      ),
    );
}

/// Shows a styled info snackbar (primary teal).
void showInfoSnackbar(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      _buildSnackBar(
        context,
        message: message,
        icon: Icons.info_outline_rounded,
        backgroundColor: AppTheme.primaryTeal,
      ),
    );
}

/// Shows a styled error snackbar globally (no context needed).
void showGlobalErrorSnackbar(String message) {
  scaffoldMessengerKey.currentState?.showSnackBar(
    _buildGlobalSnackBar(
      message: message,
      icon: Icons.error_outline_rounded,
      backgroundColor: const Color(0xFFEF4444),
    ),
  );
}

/// Shows a styled success snackbar globally.
void showGlobalSuccessSnackbar(String message) {
  scaffoldMessengerKey.currentState?.showSnackBar(
    _buildGlobalSnackBar(
      message: message,
      icon: Icons.check_circle_outline_rounded,
      backgroundColor: AppTheme.successGreen,
    ),
  );
}

SnackBar _buildGlobalSnackBar({
  required String message,
  required IconData icon,
  required Color backgroundColor,
}) {
  return SnackBar(
    behavior: SnackBarBehavior.floating,
    backgroundColor: Colors.transparent,
    elevation: 0,
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    content: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withAlpha(80),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

SnackBar _buildSnackBar(
  BuildContext context, {
  required String message,
  required IconData icon,
  required Color backgroundColor,
}) {
  return SnackBar(
    behavior: SnackBarBehavior.floating,
    backgroundColor: Colors.transparent,
    elevation: 0,
    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    content: Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withAlpha(80),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Loading Overlay
// ---------------------------------------------------------------------------

/// Shows a full-screen frosted loading overlay.
///
/// Call [hideLoadingOverlay] to dismiss.
OverlayEntry? _loadingEntry;

void showLoadingOverlay(BuildContext context, {String message = 'Loading...'}) {
  _loadingEntry = OverlayEntry(
    builder: (_) => _LoadingOverlay(message: message),
  );
  Overlay.of(context).insert(_loadingEntry!);
}

void hideLoadingOverlay() {
  _loadingEntry?.remove();
  _loadingEntry = null;
}

class _LoadingOverlay extends StatelessWidget {
  final String message;
  const _LoadingOverlay({required this.message});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withAlpha(120),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1A2332)
                : Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(60),
                blurRadius: 32,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 44,
                height: 44,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(AppTheme.primaryTeal),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
