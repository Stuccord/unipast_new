import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:unipast/features/auth/auth_service.dart';
import 'package:unipast/features/auth/profile_service.dart';

import 'package:unipast/features/admin/activity_service.dart';

class SignupState {
  final int currentStep;
  final String email;
  final String phone;
  final String password;
  final String fullName;
  final String? universityId;
  final String? facultyId;
  final String? programmeId;
  final int? level;
  final int? semester;
  final bool isLoading;
  final String? error;

  SignupState({
    this.currentStep = 0,
    this.email = '',
    this.phone = '',
    this.password = '',
    this.fullName = '',
    this.universityId,
    this.facultyId,
    this.programmeId,
    this.level,
    this.semester,
    this.isLoading = false,
    this.error,
  });

  SignupState copyWith({
    int? currentStep,
    String? email,
    String? phone,
    String? password,
    String? fullName,
    String? universityId,
    String? facultyId,
    String? programmeId,
    int? level,
    int? semester,
    bool? isLoading,
    String? error,
  }) {
    return SignupState(
      currentStep: currentStep ?? this.currentStep,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      password: password ?? this.password,
      fullName: fullName ?? this.fullName,
      universityId: universityId ?? this.universityId,
      facultyId: facultyId ?? this.facultyId,
      programmeId: programmeId ?? this.programmeId,
      level: level ?? this.level,
      semester: semester ?? this.semester,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class SignupNotifier extends StateNotifier<SignupState> {
  SignupNotifier() : super(SignupState());

  void nextStep() => state = state.copyWith(currentStep: state.currentStep + 1);
  void previousStep() =>
      state = state.copyWith(currentStep: state.currentStep - 1);

  void updateAccountInfo({
    required String email,
    required String phone,
    required String password,
  }) {
    state = state.copyWith(email: email, phone: phone, password: password);
  }

  void updatePersonalInfo({required String fullName}) {
    state = state.copyWith(fullName: fullName);
  }

  void updateAcademicInfo({
    String? universityId,
    String? facultyId,
    String? programmeId,
    int? level,
    int? semester,
  }) {
    state = state.copyWith(
      universityId: universityId,
      facultyId: facultyId,
      programmeId: programmeId,
      level: level,
      semester: semester,
    );
  }

  Future<void> completeSignup(WidgetRef ref) async {
    // 1. Debounce / Prevent double submission
    if (state.isLoading) {
      return;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      final authResponse = await ref.read(authServiceProvider).signUpWithEmail(
        email: state.email,
        password: state.password,
        phone: state.phone,
        metadata: {
          'full_name': state.fullName,
          'university_id': state.universityId,
          'faculty_id': state.facultyId,
          'programme_id': state.programmeId,
          'current_level': state.level,
          'current_semester': state.semester,
        },
      );

      if (authResponse.user != null) {
        // Log the signup activity
        await ref.read(activityServiceProvider).recordActivity(
              eventType: 'signup',
              description: 'New user joined: ${state.fullName}',
              userId: authResponse.user!.id,
              metadata: {'email': state.email},
            );

        // NOTE: Profile is now created automatically by a DB trigger
        // using the metadata we passed above. This avoids RLS violations.

        // Invalidate the cached profile so the router sees the newly created profile!
        ref.invalidate(myProfileProvider);

        // Move to success step (5)
        state = state.copyWith(currentStep: 5, isLoading: false);
      } else {
      }
      state = state.copyWith(isLoading: false);
    } catch (e) {

      String errorMessage = 'An unexpected error occurred. Please try again.';

      if (e is PostgrestException) {
        if (e.code == '42501') {
          errorMessage =
              'Database Access Denied (RLS Violation). Please ensure you have applied the SQL fixes from the implementation plan in your Supabase Dashboard.';
        } else {
          errorMessage = 'Database Error: ${e.message}';
        }
      } else if (e is AuthException) {
        if (e.message.toLowerCase().contains('rate limit') ||
            e.statusCode == '429') {
          errorMessage =
              'For security, please wait a minute before trying to sign up again.';
        } else {
          errorMessage = e.message;
        }
      } else {
        errorMessage = e.toString();
      }

      state = state.copyWith(isLoading: false, error: errorMessage);
      throw Exception(errorMessage);
    }
  }
}

final signupProvider = StateNotifierProvider<SignupNotifier, SignupState>((
  ref,
) {
  return SignupNotifier();
});
