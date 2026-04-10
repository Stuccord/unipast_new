import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unipast/core/router.dart';
import 'package:unipast/features/auth/auth_service.dart';
import 'package:unipast/features/auth/profile_service.dart';

// Fake implementations to satisfy the router dependencies without needing mockito
class FakeAuthService implements AuthService {
  final bool isLogged;
  FakeAuthService(this.isLogged);

  @override
  User? get currentUser => isLogged
      ? const User(
          id: '123',
          appMetadata: {},
          userMetadata: {},
          aud: 'authenticated',
          createdAt: '2024-01-01T00:00:00Z',
        )
      : null;

  @override
  Stream<AuthState> get authStateChanges => const Stream.empty();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets(
      'Router redirects to /signup when profile is null (missing from DB) after login',
      (tester) async {
    final container = ProviderContainer(
      overrides: [
        authServiceProvider.overrideWithValue(FakeAuthService(true)),
        authStateChangesProvider.overrideWith((ref) => Stream.value(AuthState(
            AuthChangeEvent.signedIn,
            Session(
              accessToken: 'token',
              tokenType: 'bearer',
              user: const User(
                id: '123',
                appMetadata: {},
                userMetadata: {},
                aud: 'authenticated',
                createdAt: '',
              ),
            )))),
        myProfileProvider.overrideWith((ref) => null),
      ],
    );

    await container.read(myProfileProvider.future);
    final router = container.read(routerProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );

    await tester.pumpAndSettle();

    final currentPath =
        router.routerDelegate.currentConfiguration.last.matchedLocation;

    // We expect it to be /signup because profile is null (missing from DB)
    expect(currentPath, '/signup');
  });

  testWidgets(
      'Router does NOT redirect to /signup when profile exists but is incomplete',
      (tester) async {
    final incompleteProfile = UserProfile(
      id: '123',
      fullName: 'Test',
      universityId: '',
      facultyId: '',
      programmeId: '', // Incomplete
      currentLevel: 100,
      currentSemester: 1,
    );

    final container = ProviderContainer(
      overrides: [
        authServiceProvider.overrideWithValue(FakeAuthService(true)),
        authStateChangesProvider.overrideWith((ref) => Stream.value(AuthState(
            AuthChangeEvent.signedIn,
            Session(
              accessToken: 'token',
              tokenType: 'bearer',
              user: const User(
                id: '123',
                appMetadata: {},
                userMetadata: {},
                aud: 'authenticated',
                createdAt: '',
              ),
            )))),
        myProfileProvider.overrideWith((ref) => incompleteProfile),
      ],
    );

    await container.read(myProfileProvider.future);
    final router = container.read(routerProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );

    await tester.pumpAndSettle();

    final currentPath =
        router.routerDelegate.currentConfiguration.last.matchedLocation;

    // Should NOT be redirected to signup anymore, even if incomplete
    expect(currentPath, '/');
  });

  testWidgets(
      'Router redirects from login to home when profile exists during loading',
      (tester) async {
    final profile = UserProfile(
      id: '123',
      fullName: 'Test',
      universityId: 'ktu',
      facultyId: 'it',
      programmeId: 'cs',
      currentLevel: 100,
      currentSemester: 1,
    );

    final container = ProviderContainer(
      overrides: [
        authServiceProvider.overrideWithValue(FakeAuthService(true)),
        authStateChangesProvider.overrideWith((ref) => Stream.value(AuthState(
            AuthChangeEvent.signedIn,
            Session(
              accessToken: 'token',
              tokenType: 'bearer',
              user: const User(
                id: '123',
                appMetadata: {},
                userMetadata: {},
                aud: 'authenticated',
                createdAt: '',
              ),
            )))),
        myProfileProvider.overrideWith((ref) => profile),
      ],
    );

    await container.read(myProfileProvider.future);
    final router = container.read(routerProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Mock reaching /login while logged in
    router.go('/login');
    await tester.pumpAndSettle();

    final currentPath =
        router.routerDelegate.currentConfiguration.last.matchedLocation;

    // Should be redirected to home
    expect(currentPath, '/');
  });

  testWidgets('Router stays on /signup when profile is null (no loop)',
      (tester) async {
    final container = ProviderContainer(
      overrides: [
        authServiceProvider.overrideWithValue(FakeAuthService(true)),
        authStateChangesProvider.overrideWith((ref) => Stream.value(AuthState(
            AuthChangeEvent.signedIn,
            Session(
              accessToken: 'token',
              tokenType: 'bearer',
              user: const User(
                id: '123',
                appMetadata: {},
                userMetadata: {},
                aud: 'authenticated',
                createdAt: '',
              ),
            )))),
        myProfileProvider.overrideWith((ref) => null),
      ],
    );

    await container.read(myProfileProvider.future);
    final router = container.read(routerProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Mock reaching /signup while profile matches "missing" (null)
    router.go('/signup');
    await tester.pumpAndSettle();

    final currentPath =
        router.routerDelegate.currentConfiguration.last.matchedLocation;

    // Should STAY on /signup (no redirect back to /)
    expect(currentPath, '/signup');
  });
}
