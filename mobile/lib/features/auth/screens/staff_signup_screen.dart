import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/auth/user_profile.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glow_badge.dart';
import '../../../core/widgets/primary_button.dart';

const _roleLabels = {
  'property_manager': 'Property Manager',
  'operations_manager': 'Operations Manager',
  'driver': 'Worker / Driver',
};

/// Staff signup via [staff_invites] + [register_staff_with_invite] RPC.
class StaffSignupScreen extends StatefulWidget {
  const StaffSignupScreen({super.key});

  @override
  State<StaffSignupScreen> createState() => _StaffSignupScreenState();
}

class _StaffSignupScreenState extends State<StaffSignupScreen> {
  final _codeController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _verifyingCode = false;
  bool _obscurePassword = true;
  String? _error;

  String? _inviteId;
  String? _previewRole;
  String? _previewProperty;

  @override
  void dispose() {
    _codeController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();
    if (code.isEmpty) {
      setState(() {
        _inviteId = null;
        _previewRole = null;
        _previewProperty = null;
      });
      return;
    }

    setState(() {
      _verifyingCode = true;
      _error = null;
    });

    try {
      final result = await Supabase.instance.client.rpc(
        'verify_staff_invite_code',
        params: {'p_invite_code': code.toUpperCase()},
      );

      if (result is! List || result.isEmpty) {
        setState(() {
          _inviteId = null;
          _previewRole = null;
          _previewProperty = null;
          _error = 'Could not verify code';
        });
        return;
      }

      final row = result.first is Map
          ? Map<String, dynamic>.from(result.first as Map)
          : <String, dynamic>{};

      final valid = row['is_valid'] == true;
      if (!valid) {
        setState(() {
          _inviteId = null;
          _previewRole = null;
          _previewProperty = null;
          _error = row['message']?.toString() ?? 'Invalid invite code';
        });
        return;
      }

      final roleKey = row['target_role']?.toString();
      setState(() {
        _inviteId = row['invite_id']?.toString();
        _previewRole = _roleLabels[roleKey] ?? roleKey;
        _previewProperty = row['property_name']?.toString();
        _error = null;
      });
    } catch (e) {
      setState(() {
        _inviteId = null;
        _previewRole = null;
        _previewProperty = null;
        _error = 'Verify failed: $e';
      });
    } finally {
      if (mounted) setState(() => _verifyingCode = false);
    }
  }

  Future<void> _signUp() async {
    if (_inviteId == null) {
      await _verifyCode();
      if (_inviteId == null) {
        setState(() => _error ??= 'Enter a valid staff invite code first.');
        return;
      }
    }

    final allFilled = _emailController.text.trim().isNotEmpty &&
        _passwordController.text.trim().isNotEmpty &&
        _firstNameController.text.trim().isNotEmpty &&
        _lastNameController.text.trim().isNotEmpty;
    if (!allFilled) {
      setState(() => _error = 'Please fill in all fields.');
      return;
    }
    if (_passwordController.text.trim().length < 6) {
      setState(() => _error = 'Password must be at least 6 characters.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final authResponse = await Supabase.instance.client.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (authResponse.user == null) {
        setState(() => _error = 'Account creation failed. Please try again.');
        return;
      }

      final userId = authResponse.user!.id;
      await Supabase.instance.client.rpc('register_staff_with_invite', params: {
        'p_invite_id': _inviteId,
        'p_user_id': userId,
        'p_email': _emailController.text.trim(),
        'p_first_name': _firstNameController.text.trim(),
        'p_last_name': _lastNameController.text.trim(),
      });

      final role = await fetchUserRole(userId);
      if (role == null) {
        setState(() => _error =
            'Account created but profile is still syncing. Sign in again in a moment.');
        return;
      }

      if (!mounted) return;
      final client = Supabase.instance.client;
      if (client.auth.currentSession != null) {
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        Navigator.of(context).pop();
      }
    } catch (e) {
      String msg = e.toString();
      if (msg.contains('User already registered')) {
        msg = 'Email already registered. Sign in or use a different email.';
      }
      setState(() => _error = msg);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface1,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Staff Sign Up',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
            fontSize: 17,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new,
              size: 18, color: AppColors.textSecondary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.manager.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: AppColors.manager.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.badge_outlined,
                      color: AppColors.manager, size: 22),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'Use the invite code from your super admin. It sets your role and property automatically.',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _label('STAFF INVITE CODE'),
            const SizedBox(height: 8),
            TextField(
              controller: _codeController,
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(
                  color: AppColors.textPrimary, letterSpacing: 1.2),
              onChanged: (_) {
                setState(() {
                  _inviteId = null;
                  _previewRole = null;
                  _previewProperty = null;
                });
              },
              onSubmitted: (_) => _verifyCode(),
              decoration: InputDecoration(
                hintText: 'e.g. STAFF8X2K',
                hintStyle: GoogleFonts.inter(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.surface2,
                suffixIcon: _verifyingCode
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : IconButton(
                        icon: const Icon(Icons.check_circle_outline),
                        onPressed: _verifyCode,
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
              ),
            ),
            if (_previewRole != null) ...[
              const SizedBox(height: 12),
              GlowBadge(
                label:
                    '$_previewRole${_previewProperty != null ? ' · $_previewProperty' : ''}',
                accent: AppColors.manager,
                showDot: true,
              ),
            ],
            const SizedBox(height: 24),
            _label('YOUR INFORMATION'),
            const SizedBox(height: 10),
            _field(_firstNameController, 'First Name'),
            const SizedBox(height: 12),
            _field(_lastNameController, 'Last Name'),
            const SizedBox(height: 12),
            _field(_emailController, 'Email',
                keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 12),
            _field(
              _passwordController,
              'Password',
              obscure: _obscurePassword,
              suffix: IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: AppColors.textMuted,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _obscurePassword = !_obscurePassword),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 16),
              GlowBadge(
                label: _error!,
                accent: AppColors.error,
                showDot: false,
              ),
            ],
            const SizedBox(height: 24),
            PrimaryButton(
              label: _isLoading ? 'Creating Account…' : 'Create Staff Account',
              accent: AppColors.manager,
              onPressed: _isLoading ? null : _signUp,
              isLoading: _isLoading,
              icon: Icons.person_add_outlined,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Already have an account? Sign In',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: AppColors.textSecondary,
        ),
      );

  Widget _field(
    TextEditingController controller,
    String label, {
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffix,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13),
        filled: true,
        fillColor: AppColors.surface2,
        suffixIcon: suffix,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
      ),
    );
  }
}
