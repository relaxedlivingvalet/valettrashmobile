# RLV Brand Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Align all app screens with the official RLV brand sheet — color palette, typography, login screen layout with Apple/Google OAuth, and all five role dashboards updated to match their design mockups.

**Architecture:** Single-pass token update first (colors + fonts), then screen-by-screen redesign. All Supabase data queries are preserved unchanged; only presentation layer changes. Apple/Google OAuth is added via Supabase OAuth flow using existing `supabase_flutter` package — no new auth infrastructure required.

**Tech Stack:** Flutter 3.41.9, Dart, `google_fonts` (already installed), `sign_in_with_apple` (new), `google_sign_in` (new), Supabase Auth OAuth, `mobile/lib/core/theme/` token system.

---

## Color Tokens Reference (from brand sheet)

| Token | Hex | Maps to |
|---|---|---|
| background | `#0A0A0A` | App background |
| surface1 | `#1A1A1A` | Cards, nav bar |
| surface2 | `#3A3A3A` | Input fields, secondary surfaces |
| border | `#3A3A3A` | Dividers, card borders |
| borderSubtle | `#1A1A1A` | Subtle separators |
| textPrimary | `#FFFFFF` | Headings, primary text |
| textSecondary | `#6B6B6B` | Body, labels |
| textMuted | `#E5E5E5` | Placeholders, captions |
| rlvBlue | `#0A84FF` | Brand accent (replaces all per-role colors) |
| success | `#10B981` | Keep — "All Clear" status |
| warning | `#F59E0B` | Keep — in-progress banners |
| error | `#EF4444` | Keep — errors, violations |

**Note:** Per-role accents (emerald, amber, indigo, purple) are retired. All roles use `#0A84FF` as their accent to match the unified brand sheet.

---

## Run Commands

```powershell
# Run on web (fastest for visual verification)
cd C:\Users\e159305\Projects\valettrashmobile\mobile
& "C:\Users\e159305\Apps\flutter\bin\flutter.bat" run -d chrome --no-pub

# Check for compile errors without running
& "C:\Users\e159305\Apps\flutter\bin\flutter.bat" analyze --no-pub

# Install packages after pubspec.yaml changes
& "C:\Users\e159305\Apps\flutter\bin\flutter.bat" pub get
```

---

## Task 1: Color Tokens + Typography

**Files:**
- Modify: `mobile/lib/core/theme/app_colors.dart`
- Modify: `mobile/lib/core/theme/app_typography.dart`

- [ ] **Step 1: Update `app_colors.dart`**

Replace the entire file content:

```dart
import 'package:flutter/material.dart';

abstract final class AppColors {
  // ── Surfaces ─────────────────────────────────────────────────────────
  static const Color background   = Color(0xFF0A0A0A);
  static const Color surface1     = Color(0xFF1A1A1A);
  static const Color surface2     = Color(0xFF3A3A3A);
  static const Color border       = Color(0xFF3A3A3A);
  static const Color borderSubtle = Color(0xFF1A1A1A);

  // ── Text ─────────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF6B6B6B);
  static const Color textMuted     = Color(0xFFE5E5E5);

  // ── Brand ─────────────────────────────────────────────────────────────
  static const Color rlvBlue = Color(0xFF0A84FF);

  // ── Role accents (all unified to brand blue) ──────────────────────────
  static const Color resident = rlvBlue;
  static const Color worker   = rlvBlue;
  static const Color manager  = rlvBlue;
  static const Color owner    = rlvBlue;

  // ── Semantic ─────────────────────────────────────────────────────────
  static const Color success  = Color(0xFF10B981);
  static const Color warning  = Color(0xFFF59E0B);
  static const Color error    = Color(0xFFEF4444);
  static const Color info     = Color(0xFF0A84FF);
}

@immutable
class AppColorsScheme extends ThemeExtension<AppColorsScheme> {
  const AppColorsScheme({
    required this.background,
    required this.surface1,
    required this.surface2,
    required this.border,
    required this.borderSubtle,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
  });

  final Color background;
  final Color surface1;
  final Color surface2;
  final Color border;
  final Color borderSubtle;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;

  static const dark = AppColorsScheme(
    background:    Color(0xFF0A0A0A),
    surface1:      Color(0xFF1A1A1A),
    surface2:      Color(0xFF3A3A3A),
    border:        Color(0xFF3A3A3A),
    borderSubtle:  Color(0xFF1A1A1A),
    textPrimary:   Color(0xFFFFFFFF),
    textSecondary: Color(0xFF6B6B6B),
    textMuted:     Color(0xFFE5E5E5),
  );

  static const light = AppColorsScheme(
    background:    Color(0xFFF5F6FA),
    surface1:      Color(0xFFFFFFFF),
    surface2:      Color(0xFFF0F2F5),
    border:        Color(0xFFE3E7EF),
    borderSubtle:  Color(0xFFEEF0F5),
    textPrimary:   Color(0xFF0F1117),
    textSecondary: Color(0xFF4B5563),
    textMuted:     Color(0xFF9CA3AF),
  );

  @override
  AppColorsScheme copyWith({
    Color? background,
    Color? surface1,
    Color? surface2,
    Color? border,
    Color? borderSubtle,
    Color? textPrimary,
    Color? textSecondary,
    Color? textMuted,
  }) =>
      AppColorsScheme(
        background:    background    ?? this.background,
        surface1:      surface1      ?? this.surface1,
        surface2:      surface2      ?? this.surface2,
        border:        border        ?? this.border,
        borderSubtle:  borderSubtle  ?? this.borderSubtle,
        textPrimary:   textPrimary   ?? this.textPrimary,
        textSecondary: textSecondary ?? this.textSecondary,
        textMuted:     textMuted     ?? this.textMuted,
      );

  @override
  AppColorsScheme lerp(AppColorsScheme? other, double t) {
    if (other == null) return this;
    return AppColorsScheme(
      background:    Color.lerp(background,    other.background,    t)!,
      surface1:      Color.lerp(surface1,      other.surface1,      t)!,
      surface2:      Color.lerp(surface2,      other.surface2,      t)!,
      border:        Color.lerp(border,        other.border,        t)!,
      borderSubtle:  Color.lerp(borderSubtle,  other.borderSubtle,  t)!,
      textPrimary:   Color.lerp(textPrimary,   other.textPrimary,   t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textMuted:     Color.lerp(textMuted,     other.textMuted,     t)!,
    );
  }
}

extension AppColorsContext on BuildContext {
  AppColorsScheme get roleColors =>
      Theme.of(this).extension<AppColorsScheme>() ?? AppColorsScheme.dark;
}
```

- [ ] **Step 2: Update `app_typography.dart`** — switch from DM Sans to Montserrat (headings) + Inter (body). Both are available via the already-installed `google_fonts` package.

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

abstract final class AppTypography {
  static TextTheme get textTheme {
    final base = ThemeData.dark().textTheme;
    return base.copyWith(
      displayLarge: GoogleFonts.montserrat(
        fontSize: 48,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.5,
        color: AppColors.textPrimary,
      ),
      displayMedium: GoogleFonts.montserrat(
        fontSize: 32,
        fontWeight: FontWeight.w800,
        letterSpacing: -1.0,
        color: AppColors.textPrimary,
      ),
      headlineMedium: GoogleFonts.montserrat(
        fontSize: 24,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        color: AppColors.textPrimary,
      ),
      headlineSmall: GoogleFonts.montserrat(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: AppColors.textPrimary,
      ),
      titleLarge: GoogleFonts.montserrat(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      titleMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      bodyLarge: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      ),
      bodyMedium: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.textSecondary,
      ),
      bodySmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.textMuted,
      ),
      labelLarge: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
      labelSmall: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        letterSpacing: 0.5,
        color: AppColors.textMuted,
      ),
    );
  }
}
```

- [ ] **Step 3: Verify compilation**

```powershell
cd C:\Users\e159305\Projects\valettrashmobile\mobile
& "C:\Users\e159305\Apps\flutter\bin\flutter.bat" analyze --no-pub
```

Expected: No errors (warnings about `withOpacity` are pre-existing, not new).

- [ ] **Step 4: Run app and verify**

```powershell
& "C:\Users\e159305\Apps\flutter\bin\flutter.bat" run -d chrome --no-pub
```

Log in as `adam.grant824+res2@gmail.com` / `TestPass123!`. Verify background is pure `#0A0A0A` black and accent color is the RLV blue throughout.

- [ ] **Step 5: Commit**

```bash
git add mobile/lib/core/theme/app_colors.dart mobile/lib/core/theme/app_typography.dart
git commit -m "feat: apply RLV brand color palette and Montserrat/Inter typography"
```

---

## Task 2: Login Screen Redesign + OAuth Packages

**Prerequisites before wiring Apple/Google:**
- Google: Create OAuth credentials at console.cloud.google.com, add Client ID to Supabase Auth > Providers > Google
- Apple: Requires Apple Developer account (pending) — wire the code now, enable in Supabase when account is ready
- Supabase redirect URL: Add `com.relaxedliving.valet://login-callback` to Auth > URL Configuration > Redirect URLs (already done per brain file)

**Files:**
- Modify: `mobile/pubspec.yaml`
- Modify: `mobile/lib/features/auth/screens/simple_auth_screen.dart`

- [ ] **Step 1: Add OAuth packages to `pubspec.yaml`**

Add under `dependencies:`, after `supabase_flutter`:

```yaml
  sign_in_with_apple: ^6.1.4
  google_sign_in: ^6.2.2
```

- [ ] **Step 2: Install packages**

```powershell
cd C:\Users\e159305\Projects\valettrashmobile\mobile
& "C:\Users\e159305\Apps\flutter\bin\flutter.bat" pub get
```

- [ ] **Step 3: Replace `simple_auth_screen.dart`** with the redesigned version matching the brand sheet exactly.

The design shows: centered RLV logo → "Welcome Back" → "Sign in to continue" → email field → password field → "Forgot password?" → blue Sign In button → "or continue with" divider → [Apple] [Google] side-by-side buttons → "Don't have an account? Sign up".

```dart
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glow_badge.dart';
import '../../manager/screens/manager_dashboard_screen.dart';
import '../../manager/screens/property_manager_dashboard_new.dart';
import '../../owner/screens/owner_dashboard_screen.dart';
import '../../test/screens/test_connection_screen.dart';
import '../../worker/screens/worker_dashboard_screen.dart';
import 'change_password_screen.dart';
import 'resident_signup_screen.dart';

class SimpleAuthScreen extends StatefulWidget {
  const SimpleAuthScreen({super.key});

  @override
  State<SimpleAuthScreen> createState() => _SimpleAuthScreenState();
}

class _SimpleAuthScreenState extends State<SimpleAuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _isLoading = true; _error = null; });
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
    } catch (e) {
      String msg = e.toString();
      if (msg.contains('Invalid login credentials')) msg = 'Invalid email or password';
      else if (msg.contains('Email not confirmed')) msg = 'Please confirm your email before signing in.';
      setState(() => _error = msg);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      const webClientId = String.fromEnvironment('GOOGLE_WEB_CLIENT_ID');
      const iosClientId = String.fromEnvironment('GOOGLE_IOS_CLIENT_ID');
      final googleSignIn = GoogleSignIn(
        clientId: iosClientId.isNotEmpty ? iosClientId : null,
        serverClientId: webClientId.isNotEmpty ? webClientId : null,
      );
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) { setState(() => _isLoading = false); return; }
      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      final accessToken = googleAuth.accessToken;
      if (idToken == null) throw Exception('Google sign-in failed: no ID token');
      await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
    } catch (e) {
      setState(() => _error = 'Google sign-in failed. Please try again.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithApple() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
      );
      final idToken = credential.identityToken;
      if (idToken == null) throw Exception('Apple sign-in failed: no identity token');
      await Supabase.instance.client.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
        nonce: credential.authorizationCode,
      );
    } catch (e) {
      setState(() => _error = 'Apple sign-in failed. Please try again.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                _buildLogo(),
                const SizedBox(height: 36),
                _buildWelcomeText(),
                const SizedBox(height: 28),
                _buildEmailField(),
                const SizedBox(height: 12),
                _buildPasswordField(),
                _buildForgotPasswordLink(),
                const SizedBox(height: 8),
                if (_error != null) ...[
                  GlowBadge(label: _error!, accent: AppColors.error, showDot: false),
                  const SizedBox(height: 12),
                ],
                _buildSignInButton(),
                const SizedBox(height: 24),
                _buildDivider(),
                const SizedBox(height: 24),
                _buildOAuthButtons(),
                const SizedBox(height: 28),
                _buildSignUpLink(),
                if (kDebugMode) ...[
                  const SizedBox(height: 32),
                  _buildDebugSection(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Image.asset(
          'assets/icon/app_icon.png',
          width: 80,
          height: 80,
        ),
        const SizedBox(height: 16),
        Text(
          'RELAXED LIVING',
          textAlign: TextAlign.center,
          style: GoogleFonts.montserrat(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 3.0,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'VALET',
          textAlign: TextAlign.center,
          style: GoogleFonts.montserrat(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            letterSpacing: 4.0,
            color: AppColors.rlvBlue,
          ),
        ),
      ],
    ).animate().fadeIn(duration: 300.ms);
  }

  Widget _buildWelcomeText() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Welcome Back',
          style: GoogleFonts.montserrat(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Sign in to continue',
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    ).animate(delay: 60.ms).fadeIn(duration: 250.ms).slideY(begin: 0.06, end: 0);
  }

  Widget _buildEmailField() {
    return _styledField(
      controller: _emailController,
      label: 'Email address',
      keyboardType: TextInputType.emailAddress,
      validator: (v) {
        if (v == null || v.isEmpty) return 'Required';
        if (!v.contains('@')) return 'Enter a valid email';
        return null;
      },
    ).animate(delay: 120.ms).fadeIn(duration: 250.ms).slideY(begin: 0.06, end: 0);
  }

  Widget _buildPasswordField() {
    return _styledField(
      controller: _passwordController,
      label: 'Password',
      obscureText: _obscurePassword,
      suffixIcon: IconButton(
        icon: Icon(
          _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          size: 20,
          color: AppColors.textSecondary,
        ),
        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return 'Required';
        if (v.length < 6) return 'At least 6 characters';
        return null;
      },
    ).animate(delay: 180.ms).fadeIn(duration: 250.ms).slideY(begin: 0.06, end: 0);
  }

  Widget _styledField({
    required TextEditingController controller,
    required String label,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.inter(color: AppColors.textPrimary, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13),
        filled: true,
        fillColor: AppColors.surface1,
        suffixIcon: suffixIcon,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.rlvBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildForgotPasswordLink() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          'Forgot password?',
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.rlvBlue),
        ),
      ),
    );
  }

  Widget _buildSignInButton() {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _signIn,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.rlvBlue,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.rlvBlue.withValues(alpha: 0.5),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                'Sign In',
                style: GoogleFonts.montserrat(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
      ),
    ).animate(delay: 240.ms).fadeIn(duration: 250.ms);
  }

  Widget _buildDivider() {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.border, thickness: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'or continue with',
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
          ),
        ),
        const Expanded(child: Divider(color: AppColors.border, thickness: 1)),
      ],
    ).animate(delay: 300.ms).fadeIn(duration: 250.ms);
  }

  Widget _buildOAuthButtons() {
    return Row(
      children: [
        Expanded(
          child: _oauthButton(
            onPressed: _isLoading ? null : _signInWithApple,
            icon: const Icon(Icons.apple, size: 22, color: Colors.white),
            label: 'Apple',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _oauthButton(
            onPressed: _isLoading ? null : _signInWithGoogle,
            icon: Text(
              'G',
              style: GoogleFonts.montserrat(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            label: 'Google',
          ),
        ),
      ],
    ).animate(delay: 360.ms).fadeIn(duration: 250.ms);
  }

  Widget _oauthButton({
    required VoidCallback? onPressed,
    required Widget icon,
    required String label,
  }) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: AppColors.surface1,
        side: const BorderSide(color: AppColors.border),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon,
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignUpLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "Don't have an account? ",
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
        ),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ResidentSignupScreen()),
          ),
          child: Text(
            'Sign up',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.rlvBlue,
            ),
          ),
        ),
      ],
    ).animate(delay: 420.ms).fadeIn(duration: 250.ms);
  }

  Widget _buildDebugSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Divider(color: AppColors.border),
        const SizedBox(height: 8),
        Text(
          'DEBUG NAVIGATION',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        ...[
          ('Property Manager Dashboard', const PropertyManagerDashboardNewScreen()),
          ('Worker Dashboard', const WorkerDashboardScreen()),
          ('Operations Manager Dashboard', const ManagerDashboardScreen()),
          ('Owner Dashboard', const OwnerDashboardScreen()),
          ('Test Connection', const TestConnectionScreen()),
        ].map((entry) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: OutlinedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => entry.$2),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: const BorderSide(color: AppColors.border),
              foregroundColor: AppColors.textSecondary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(entry.$1, style: GoogleFonts.inter(fontSize: 12)),
          ),
        )),
      ],
    );
  }
}
```

- [ ] **Step 4: Verify compilation**

```powershell
& "C:\Users\e159305\Apps\flutter\bin\flutter.bat" analyze --no-pub
```

- [ ] **Step 5: Run and visually verify login screen**

Log out if already signed in. Verify:
- RLV app icon image is visible at top center
- "RELAXED LIVING / VALET" wordmark in blue
- "Welcome Back" in Montserrat bold
- Email + password fields with dark surface
- Blue "Sign In" button
- "or continue with" divider
- Apple + Google buttons side by side
- "Don't have an account? Sign up" link

- [ ] **Step 6: Commit**

```bash
git add mobile/pubspec.yaml mobile/pubspec.lock mobile/lib/features/auth/screens/simple_auth_screen.dart
git commit -m "feat: redesign login screen with RLV brand, Apple/Google OAuth buttons"
```

---

## Task 3: Resident Dashboard Redesign

**Goal:** Match the design sheet's Resident Dashboard — restructure the Home tab into three distinct sections (Upcoming Service, Service Status, Service Updates) and rename tabs to Home / Services / Messages / Profile.

**Tab mapping:**

| Design tab | Current tab | Content |
|---|---|---|
| Home | Home (tab 0) | Greeting + three info sections |
| Services | History (tab 1) | Pickup history + service calendar |
| Messages | Alerts (tab 2) | Notifications from `notifications` table |
| Profile | Profile (tab 3) | Same as current |

**Files:**
- Modify: `mobile/lib/features/resident/screens/resident_dashboard_screen.dart`

- [ ] **Step 1: Update bottom nav tab definitions**

In `_ResidentDashboardScreenState.build()`, replace the `RoleBottomNav` `items:` list:

```dart
items: const [
  RoleNavItem(
    icon: Icons.home_outlined,
    activeIcon: Icons.home,
    label: 'Home',
  ),
  RoleNavItem(
    icon: Icons.delete_outline,
    activeIcon: Icons.delete,
    label: 'Services',
  ),
  RoleNavItem(
    icon: Icons.chat_bubble_outline,
    activeIcon: Icons.chat_bubble,
    label: 'Messages',
  ),
  RoleNavItem(
    icon: Icons.person_outline,
    activeIcon: Icons.person,
    label: 'Profile',
  ),
],
```

Also update `_buildTab()` so tab labels match (the switch logic is unchanged — it's by index so no code change needed there).

- [ ] **Step 2: Update `_buildHistoryTab()` → rename to `_buildServicesTab()` and update `_buildTab()` switch**

In `_buildTab()`:
```dart
case 1:
  return _buildServicesTab();
case 2:
  return _buildMessagesTab();
```

Rename `_buildHistoryTab()` → `_buildServicesTab()` and update its header:
```dart
Widget _buildServicesTab() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _sectionHeader('Services'),
      Expanded(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          children: const [ResidentPickupHistoryView()],
        ),
      ),
    ],
  );
}
```

Rename `_buildAlertsTab()` → `_buildMessagesTab()` and update its header:
```dart
Widget _buildMessagesTab() {
  // Same body as the old _buildAlertsTab() — just rename the method and change the header text
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _sectionHeader('Messages'),
      // ... rest unchanged
    ],
  );
}
```

Update `_onTabChange()` — old reference was `index == 2`, keep as-is (Messages is still tab 2).

- [ ] **Step 3: Redesign the Home tab — replace `_buildHomeTab()` body**

The new layout has three clearly labelled sections replacing the old card/quick-actions structure:

```dart
Widget _buildHomeTab() {
  if (_loading) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      children: const [
        SkeletonCard(height: 52),
        SizedBox(height: 16),
        SkeletonCard(height: 88),
        SizedBox(height: 12),
        SkeletonCard(height: 88),
        SizedBox(height: 12),
        SkeletonCard(height: 110),
      ],
    );
  }
  return RefreshIndicator(
    onRefresh: _load,
    color: AppColors.rlvBlue,
    backgroundColor: AppColors.surface1,
    child: ListView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      children: [
        if (_loadError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GlowBadge(
              label: _loadError!,
              accent: AppColors.error,
              showDot: false,
            ),
          ),
        _buildDashboardHeader(),
        const SizedBox(height: 20),
        if (!_bannerDismissed && _runStatus != null && _runStatus != 'pending')
          _buildPickupStatusBanner(),
        _buildSectionLabel('Upcoming Service'),
        const SizedBox(height: 8),
        _buildUpcomingServiceCard(),
        const SizedBox(height: 16),
        _buildSectionLabel('Service Status'),
        const SizedBox(height: 8),
        _buildServiceStatusCard(),
        const SizedBox(height: 16),
        _buildSectionLabel('Service Updates'),
        const SizedBox(height: 8),
        _buildServiceUpdatesCard(),
      ],
    ),
  );
}

Widget _buildDashboardHeader() {
  final hour = DateTime.now().hour;
  final greeting = hour < 12 ? 'Good morning,' : hour < 17 ? 'Good afternoon,' : 'Good evening,';
  return Row(
    children: [
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              greeting,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Text(
                  _propertyName.isEmpty ? 'Your Property' : _propertyName,
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                if (_propertyName.isNotEmpty) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.textSecondary),
                ],
              ],
            ),
          ],
        ),
      ),
      IconButton(
        onPressed: () => _onTabChange(2),
        icon: Stack(
          children: [
            const Icon(Icons.notifications_outlined, color: AppColors.textPrimary, size: 24),
            if (_notifications.isNotEmpty)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.rlvBlue,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    ],
  );
}

Widget _buildSectionLabel(String label) {
  return Text(
    label,
    style: GoogleFonts.montserrat(
      fontSize: 13,
      fontWeight: FontWeight.w700,
      color: AppColors.textSecondary,
      letterSpacing: 0.3,
    ),
  );
}

Widget _buildUpcomingServiceCard() {
  final isOnSchedule = _runStatus == null || _runStatus == 'pending';
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.surface1,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.rlvBlue.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.delete_outline, color: AppColors.rlvBlue, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tonight',
                style: GoogleFonts.montserrat(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _windowShort == '--' ? 'No window configured' : _windowShort,
                style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: (isOnSchedule ? AppColors.success : AppColors.warning).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: (isOnSchedule ? AppColors.success : AppColors.warning).withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            isOnSchedule ? 'On Schedule' : 'In Progress',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isOnSchedule ? AppColors.success : AppColors.warning,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildServiceStatusCard() {
  final isAllClear = _runStatus == null || _runStatus == 'pending' || _runStatus == 'completed';
  final color = isAllClear ? AppColors.success : AppColors.warning;
  final icon = isAllClear ? Icons.check_circle_outline : Icons.local_shipping_outlined;
  final statusText = _runStatus == 'completed'
      ? 'Pickup Complete'
      : _runStatus == 'in_progress'
          ? 'Porter En Route'
          : 'All Clear';
  final subText = _runStatus == 'completed'
      ? 'Collected tonight'
      : _runStatus == 'in_progress'
          ? 'Your porter is collecting now'
          : 'No missed collections';

  return GestureDetector(
    onTap: _bannerDismissed ? null : () => setState(() => _bannerDismissed = true),
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: GoogleFonts.montserrat(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subText,
                  style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Icon(Icons.check_circle, color: color, size: 20),
        ],
      ),
    ),
  );
}

Widget _buildServiceUpdatesCard() {
  if (_notifications.isEmpty) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        'No updates at this time.',
        style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
      ),
    );
  }
  return Container(
    decoration: BoxDecoration(
      color: AppColors.surface1,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(
      children: _notifications.take(3).toList().asMap().entries.map((entry) {
        final i = entry.key;
        final n = entry.value;
        final isLast = i == (_notifications.length > 3 ? 2 : _notifications.length - 1);
        return Column(
          children: [
            InkWell(
              onTap: () => _onTabChange(2),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            n['message']?.toString() ?? n['title']?.toString() ?? '',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (n['created_at'] != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              _formatNotifDate(n['created_at'].toString()),
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, size: 18, color: AppColors.textSecondary),
                  ],
                ),
              ),
            ),
            if (!isLast) Divider(height: 1, color: AppColors.border),
          ],
        );
      }).toList(),
    ),
  );
}

String _formatNotifDate(String raw) {
  try {
    final dt = DateTime.parse(raw).toLocal();
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  } catch (_) {
    return raw;
  }
}
```

Also add `import 'package:google_fonts/google_fonts.dart';` at the top of the file.

Remove the now-unused `_buildGreeting()`, `_buildQuickActionsCard()`, `_buildNotifPreview()`, and `_actionRow()` helper methods since the new layout replaces them.

Keep: `_buildPickupStatusBanner()`, `_buildProfileTab()`, `_buildNotifCard()`, `_buildNotifCard()`, `_buildServicesTab()`, `_buildMessagesTab()`, `ResidentPickupHistoryView`, all Supabase data methods, `_sectionHeader()`.

- [ ] **Step 4: Analyze and run**

```powershell
& "C:\Users\e159305\Apps\flutter\bin\flutter.bat" analyze --no-pub
& "C:\Users\e159305\Apps\flutter\bin\flutter.bat" run -d chrome --no-pub
```

Log in as `adam.grant824+res2@gmail.com` / `TestPass123!`. Verify:
- Header shows property name with notification bell
- Three sections: Upcoming Service / Service Status / Service Updates
- Bottom nav: Home, Services, Messages, Profile
- Services tab shows pickup history
- Messages tab shows notifications

- [ ] **Step 5: Commit**

```bash
git add mobile/lib/features/resident/screens/resident_dashboard_screen.dart
git commit -m "feat: redesign resident dashboard — three-section home, rename tabs to match brand mockup"
```

---

## Task 4: Worker Dashboard Tab Alignment

**Goal:** Update bottom nav to match the design: Route, Stops, Scan, Messages, More.

**Files:**
- Modify: `mobile/lib/features/worker/screens/worker_dashboard_screen.dart`

- [ ] **Step 1: Update bottom nav items**

Locate the `RoleBottomNav` widget in `WorkerDashboardScreen.build()` and replace its `items:` with:

```dart
items: const [
  RoleNavItem(icon: Icons.map_outlined, activeIcon: Icons.map, label: 'Route'),
  RoleNavItem(icon: Icons.list_alt_outlined, activeIcon: Icons.list_alt, label: 'Stops'),
  RoleNavItem(icon: Icons.qr_code_scanner_outlined, activeIcon: Icons.qr_code_scanner, label: 'Scan'),
  RoleNavItem(icon: Icons.chat_bubble_outline, activeIcon: Icons.chat_bubble, label: 'Messages'),
  RoleNavItem(icon: Icons.more_horiz, activeIcon: Icons.more_horiz, label: 'More'),
],
```

- [ ] **Step 2: Map tab indexes to existing content**

In the `_buildTab()` switch:

```dart
case 0: return _buildRouteTab();    // existing route/map content
case 1: return _buildStopsTab();    // existing stops/pickup list
case 2: return _buildScanTab();     // existing scan/violation screen
case 3: return _buildMessagesTab(); // existing notifications
default: return _buildMoreTab();    // existing profile/settings/earnings
```

Rename existing tab-builder methods to match (only rename — do not change their bodies).

- [ ] **Step 3: Add Montserrat/Inter font imports and update accent color references**

Find any reference to `AppColors.worker` — already resolves to `rlvBlue` after Task 1, so no changes needed.

Add `import 'package:google_fonts/google_fonts.dart';` if not already present.

- [ ] **Step 4: Verify and commit**

```powershell
& "C:\Users\e159305\Apps\flutter\bin\flutter.bat" analyze --no-pub
```

Log in as `adam.grant824+worker@gmail.com` / `TestPass123!`. Verify bottom nav shows Route / Stops / Scan / Messages / More.

```bash
git add mobile/lib/features/worker/screens/worker_dashboard_screen.dart
git commit -m "feat: align worker dashboard bottom nav to design — Route, Stops, Scan, Messages, More"
```

---

## Task 5: Operations Manager Dashboard Tab Alignment

**Goal:** Update bottom nav to match: Overview, Routes, Alerts, Reports, More.

**Files:**
- Modify: `mobile/lib/features/manager/screens/manager_dashboard_screen.dart`

- [ ] **Step 1: Update bottom nav items**

```dart
items: const [
  RoleNavItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: 'Overview'),
  RoleNavItem(icon: Icons.route_outlined, activeIcon: Icons.route, label: 'Routes'),
  RoleNavItem(icon: Icons.notifications_outlined, activeIcon: Icons.notifications, label: 'Alerts'),
  RoleNavItem(icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart, label: 'Reports'),
  RoleNavItem(icon: Icons.more_horiz, activeIcon: Icons.more_horiz, label: 'More'),
],
```

- [ ] **Step 2: Map tabs to existing content**

```dart
case 0: return _buildOverviewTab();   // existing stats/community overview
case 1: return _buildRoutesTab();     // existing route list / worker map
case 2: return _buildAlertsTab();     // existing alerts screen
case 3: return _buildReportsTab();    // existing compliance/reports
default: return _buildMoreTab();      // existing profile/settings
```

Rename existing builder methods to these names without changing body logic.

- [ ] **Step 3: Verify and commit**

```powershell
& "C:\Users\e159305\Apps\flutter\bin\flutter.bat" analyze --no-pub
```

Log in as `adam.grant824+om@gmail.com` / `TestPass123!`. Verify bottom nav shows Overview / Routes / Alerts / Reports / More.

```bash
git add mobile/lib/features/manager/screens/manager_dashboard_screen.dart
git commit -m "feat: align operations manager bottom nav to design — Overview, Routes, Alerts, Reports, More"
```

---

## Task 6: Owner Dashboard Tab Alignment

**Goal:** Update bottom nav to match: Overview, Financials, Reports, More.

**Files:**
- Modify: `mobile/lib/features/owner/screens/owner_dashboard_screen.dart`

- [ ] **Step 1: Update bottom nav items**

```dart
items: const [
  RoleNavItem(icon: Icons.dashboard_outlined, activeIcon: Icons.dashboard, label: 'Overview'),
  RoleNavItem(icon: Icons.attach_money_outlined, activeIcon: Icons.attach_money, label: 'Financials'),
  RoleNavItem(icon: Icons.bar_chart_outlined, activeIcon: Icons.bar_chart, label: 'Reports'),
  RoleNavItem(icon: Icons.more_horiz, activeIcon: Icons.more_horiz, label: 'More'),
],
```

- [ ] **Step 2: Map tabs to existing content**

```dart
case 0: return _buildOverviewTab();    // existing portfolio stats — properties, units, residents
case 1: return _buildFinancialsTab();  // new: show invite usage as proxy for financials until Stripe is wired
case 2: return _buildReportsTab();     // existing reports
default: return _buildMoreTab();       // existing sign out / admin navigation
```

For the Financials tab (new), if no dedicated screen exists yet, render a placeholder card:

```dart
Widget _buildFinancialsTab() {
  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.attach_money, size: 48, color: AppColors.textSecondary),
        const SizedBox(height: 12),
        Text(
          'Financials — Coming Soon',
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Stripe Connect payouts and revenue reporting\nwill appear here.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
        ),
      ],
    ),
  );
}
```

- [ ] **Step 3: Verify and commit**

```powershell
& "C:\Users\e159305\Apps\flutter\bin\flutter.bat" analyze --no-pub
```

Log in as `relaxedlivingtx@gmail.com` / `RelaxedLiving2026!`. Verify bottom nav shows Overview / Financials / Reports / More.

```bash
git add mobile/lib/features/owner/screens/owner_dashboard_screen.dart
git commit -m "feat: align owner dashboard bottom nav to design — Overview, Financials, Reports, More"
```

---

## Task 7: Property Manager Dashboard Tab Alignment

**Goal:** Update bottom nav to match: Dashboard, Properties, Requests, More.

**Files:**
- Modify: `mobile/lib/features/manager/screens/property_manager_dashboard_new.dart`

- [ ] **Step 1: Update bottom nav items**

```dart
items: const [
  RoleNavItem(icon: Icons.grid_view_outlined, activeIcon: Icons.grid_view, label: 'Dashboard'),
  RoleNavItem(icon: Icons.apartment_outlined, activeIcon: Icons.apartment, label: 'Properties'),
  RoleNavItem(icon: Icons.inbox_outlined, activeIcon: Icons.inbox, label: 'Requests'),
  RoleNavItem(icon: Icons.more_horiz, activeIcon: Icons.more_horiz, label: 'More'),
],
```

- [ ] **Step 2: Map tabs to existing content**

```dart
case 0: return _buildDashboardTab();    // existing overview — open requests, work orders, announcements
case 1: return _buildPropertiesTab();   // existing property list / services view
case 2: return _buildRequestsTab();     // existing open requests / comebacks
default: return _buildMoreTab();        // existing profile / notifications sender / reports
```

- [ ] **Step 3: Verify and commit**

```powershell
& "C:\Users\e159305\Apps\flutter\bin\flutter.bat" analyze --no-pub
```

Log in as `adam.grant824+pm@gmail.com` / `TestPass123!`. Verify bottom nav shows Dashboard / Properties / Requests / More.

```bash
git add mobile/lib/features/manager/screens/property_manager_dashboard_new.dart
git commit -m "feat: align property manager bottom nav to design — Dashboard, Properties, Requests, More"
```

---

## External Setup Required (OAuth)

These steps require actions outside the codebase. The code in Task 2 is already wired — you just need to enable the providers.

### Google Sign In Setup
1. Go to [console.cloud.google.com](https://console.cloud.google.com)
2. Create OAuth 2.0 credentials → Web + iOS client IDs
3. In Supabase Dashboard → Authentication → Providers → Google: paste Client ID + Secret
4. Add `GOOGLE_WEB_CLIENT_ID` and `GOOGLE_IOS_CLIENT_ID` as build-time env vars or to `.env`

### Apple Sign In Setup
1. Requires active Apple Developer account (pending)
2. Register App ID with "Sign In with Apple" capability
3. In Supabase → Authentication → Providers → Apple: configure service ID + key
4. Add `com.relaxedliving.valet://login-callback` to Apple redirect URIs

---

## Self-Review

**Spec coverage check:**

| Requirement | Task |
|---|---|
| Login screen like design (Apple + Google) | Task 2 |
| Resident: Upcoming Service section | Task 3 |
| Resident: Service Status section | Task 3 |
| Resident: Service Updates (not Community Updates) | Task 3 |
| Resident tabs: Home / Services / Messages / Profile | Task 3 |
| Worker tabs: Route / Stops / Scan / Messages / More | Task 4 |
| Ops Manager tabs: Overview / Routes / Alerts / Reports / More | Task 5 |
| Owner tabs: Overview / Financials / Reports / More | Task 6 |
| PM tabs: Dashboard / Properties / Requests / More | Task 7 |
| RLV color palette (#0A84FF, #0A0A0A, etc.) | Task 1 |
| Montserrat + Inter typography | Task 1 |

All requirements covered. No gaps.
