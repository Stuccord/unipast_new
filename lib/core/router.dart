import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:unipast/core/main_shell.dart';
import 'package:unipast/features/auth/login_screen.dart';
import 'package:unipast/features/auth/signup_wizard_screen.dart';
import 'package:unipast/features/home/home_screen.dart';
import 'package:unipast/features/browse/browse_screen.dart';
import 'package:unipast/features/viewer/pdf_viewer_screen.dart';
import 'package:unipast/features/auth/profile_screen.dart';
import 'package:unipast/features/auth/edit_profile_screen.dart';
import 'package:unipast/features/admin/admin_dashboard_screen.dart';

import 'package:unipast/features/admin/admin_management_screen.dart';
import 'package:unipast/features/offline/offline_screen.dart';
import 'package:unipast/features/payment/paywall_screen.dart';
import 'package:unipast/features/notifications/notification_screen.dart';
import 'package:unipast/features/auth/auth_service.dart';
import 'package:unipast/features/auth/profile_service.dart';

// Provides a listenableNotifier to trigger router redirects
final routerNotifierProvider = ChangeNotifierProvider((ref) {
  return RouterNotifier(ref);
});

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen(authStateChangesProvider, (_, __) => notifyListeners());
    _ref.listen(myProfileProvider, (_, __) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  // Use read here so the GoRouter instance is stable and not recreated.
  // The refreshListenable already triggers internal GoRouter refreshes.
  final notifier = ref.read(routerNotifierProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: notifier,
    redirect: (context, state) {
      final isLoggedIn = ref.read(authServiceProvider).currentUser != null;
      final matchedLocation = state.matchedLocation;

      final isAuthRoute =
          matchedLocation == '/login' || matchedLocation == '/signup';

      // If not logged in at all, gate to the login screen.
      if (!isLoggedIn) {
        if (!isAuthRoute) {
          return '/login';
        }
        return null;
      }

      // If logged in, check the auth stream for transient loading states.
      final authState = ref.read(authStateChangesProvider);
      if (authState.isLoading ||
          authState.isReloading ||
          authState.isRefreshing) {
        debugPrint('[ROUTER] Auth state loading...');
        return null;
      }

      // If logged in, check profile
      final profileAsync = ref.read(myProfileProvider);

      // If profile is still loading/refreshing, don't redirect yet.
      if (profileAsync.isLoading ||
          profileAsync.isReloading ||
          profileAsync.isRefreshing) {
        debugPrint('[ROUTER] Profile loading...');
        return null;
      }

      // If the profile fetch errored out, do NOT redirect to signup.
      if (profileAsync.hasError) {
        debugPrint('[ROUTER] Profile fetch error: ${profileAsync.error}');
        return null;
      }

      if (profileAsync.hasValue) {
        final profile = profileAsync.value;
        debugPrint(
            '   - Profile Record: ${profile != null ? 'EXISTS' : 'NULL'}');

        // If logged in and at an auth route (login/signup), and we have a
        // profile record, send them to home.
        if (isAuthRoute && profile != null) {
          debugPrint(
              '   👉 Already has profile, redirecting from $matchedLocation to /');
          return '/';
        }

        // We only redirect to /signup if the profile is genuinely missing
        // AND we are not already there.
        if (profile == null && matchedLocation != '/signup') {
          debugPrint('[ROUTER] No profile record found, redirecting to /signup');
          return '/signup';
        }
      }

      return null;
    },
    routes: [
      // -----------------------------------------------------------------
      // Auth routes (no nav bar)
      // -----------------------------------------------------------------
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupWizardScreen(),
      ),
      GoRoute(
        path: '/paywall',
        builder: (context, state) => const PaywallScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationScreen(),
      ),
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/manage',
        builder: (context, state) {
          final extra = state.extra as Map<String, String>?;
          return AdminManagementScreen(
            title: extra?['title'] ?? 'Management',
            mode: extra?['mode'] ?? 'universities',
          );
        },
      ),
      // -----------------------------------------------------------------
      // PDF Viewer (full-screen, no nav bar)
      // -----------------------------------------------------------------
      GoRoute(
        path: '/pdf-viewer',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return PdfViewerScreen(
            pdfUrl: extra?['url'] ?? '',
            userName: extra?['userName'] ?? 'User',
            questionId: extra?['id'] ?? 'unknown',
          );
        },
      ),
      // -----------------------------------------------------------------
      // Main tabs (wrapped in MainShell with premium bottom nav)
      // -----------------------------------------------------------------
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => MainShell(
          navigationShell: navigationShell,
        ),
        branches: [
          // Tab 0 – Home
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          // Tab 1 – Browse
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/browse',
                builder: (context, state) => const BrowseScreen(),
              ),
            ],
          ),
          // Tab 2 – Offline
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/offline',
                builder: (context, state) => const OfflineScreen(),
              ),
            ],
          ),
          // Tab 3 – Profile
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
                routes: [
                  GoRoute(
                    path: 'edit',
                    builder: (context, state) => const EditProfileScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
