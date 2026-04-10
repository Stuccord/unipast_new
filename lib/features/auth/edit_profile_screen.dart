import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:unipast/core/theme.dart';
import 'package:unipast/features/auth/profile_service.dart';
import 'package:unipast/core/ui_helpers.dart';
import 'package:go_router/go_router.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late int _currentLevel;
  late int _currentSemester;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(myProfileProvider).value;
    _nameController = TextEditingController(text: profile?.fullName ?? '');
    
    int dbLevel = profile?.currentLevel ?? 100;
    if (![100, 200, 300, 400, 500, 600].contains(dbLevel)) {
      dbLevel = 100;
    }
    _currentLevel = dbLevel;

    int dbSem = profile?.currentSemester ?? 1;
    if (![1, 2].contains(dbSem)) {
      dbSem = 1;
    }
    _currentSemester = dbSem;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      await ref.read(profileServiceProvider).updateProfile({
        'full_name': _nameController.text,
        'current_level': _currentLevel,
        'current_semester': _currentSemester,
      });
      ref.invalidate(myProfileProvider);
      if (mounted) {
        showSuccessSnackbar(context, 'Profile updated successfully');
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        String msg = 'Failed to update profile';
        if (e is PostgrestException && e.code == '42501') {
          msg = 'Access Denied: RLS Policy violation on profiles table.';
        }
        showErrorSnackbar(context, msg);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Edit Profile',
            style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Personal Details',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Update your information to keep your study hub accurate.',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: isDark ? Colors.white38 : Colors.black45,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Full Name',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'Enter your full name',
                  prefixIcon: const Icon(Icons.person_outline),
                  fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                ),
                style: GoogleFonts.inter(fontSize: 16),
                validator: (val) => val == null || val.isEmpty
                    ? 'Please enter your name'
                    : null,
              ),
              const SizedBox(height: 32),
              Text(
                'Academic Stage',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Level',
                            style: GoogleFonts.inter(
                                fontSize: 12, color: Colors.grey)),
                        DropdownButtonFormField<int>(
                          initialValue: _currentLevel,
                          dropdownColor:
                              isDark ? const Color(0xFF1E293B) : Colors.white,
                          items: [100, 200, 300, 400, 500, 600].map((level) {
                            return DropdownMenuItem(
                              value: level,
                              child: Text('Level $level'),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _currentLevel = val);
                          },
                          decoration: InputDecoration(
                            fillColor: isDark
                                ? const Color(0xFF1E293B)
                                : Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Semester',
                            style: GoogleFonts.inter(
                                fontSize: 12, color: Colors.grey)),
                        DropdownButtonFormField<int>(
                          initialValue: _currentSemester,
                          dropdownColor:
                              isDark ? const Color(0xFF1E293B) : Colors.white,
                          items: [1, 2].map((sem) {
                            return DropdownMenuItem(
                              value: sem,
                              child: Text('Semester $sem'),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null)
                              setState(() => _currentSemester = val);
                          },
                          decoration: InputDecoration(
                            fillColor: isDark
                                ? const Color(0xFF1E293B)
                                : Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 48),
              ElevatedButton(
                onPressed: _isSaving ? null : _onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryTeal,
                  minimumSize: const Size(double.infinity, 60),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        'Save Changes',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
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
