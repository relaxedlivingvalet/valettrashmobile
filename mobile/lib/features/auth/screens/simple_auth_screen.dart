import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


import '../../worker/screens/worker_dashboard_screen.dart';
import '../../manager/screens/manager_dashboard_screen.dart';
import '../../manager/screens/property_manager_dashboard_new.dart';
import '../../owner/screens/owner_dashboard_screen.dart';
import '../../test/screens/test_connection_screen.dart';
import '../../../core/app_theme.dart';
import '../../../core/brand_colors.dart';
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
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();

  bool _isLoading = false;
  bool _isLogin = true;
  String? _error;
  String? _success;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    super.dispose();
  }

  Future<void> _ensureUserProfileExists() async {
    try {
      final supabase = Supabase.instance.client;
      final currentUser = supabase.auth.currentUser;

      if (currentUser == null) return;

      final existingProfile = await supabase
          .from('users')
          .select('id')
          .eq('id', currentUser.id)
          .maybeSingle();

      if (existingProfile == null) {
        await supabase.from('users').insert({
          'id': currentUser.id,
          'email': currentUser.email,
          'first_name': _firstNameController.text.trim().isNotEmpty
              ? _firstNameController.text.trim()
              : 'New',
          'last_name': _lastNameController.text.trim().isNotEmpty
              ? _lastNameController.text.trim()
              : 'User',
          'role': 'resident',
        });
      }
    } catch (e) {
      debugPrint('Failed to ensure user profile exists: $e');
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
      _success = null;
    });

    try {
      final supabase = Supabase.instance.client;

      if (_isLogin) {
        await supabase.auth.signInWithPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

        final session = supabase.auth.currentSession;
        if (session != null) {
          await _ensureUserProfileExists();

          setState(() {
            _success = 'Signed in successfully!';
          });
        } else {
          setState(() {
            _error = 'Sign in completed but no session created';
          });
        }
      } else {
        final response = await supabase.auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          data: {
            'first_name': _firstNameController.text.trim(),
            'last_name': _lastNameController.text.trim(),
            'role': 'resident',
          },
        );

        if (response.user != null) {
          await _ensureUserProfileExists();

          setState(() {
            _success = response.user?.emailConfirmedAt != null
                ? 'Account created successfully!'
                : 'Account created! Please check your email for confirmation.';
            if (response.user?.emailConfirmedAt == null) {
              _isLogin = true;
            }
          });
        } else {
          setState(() {
            _error = 'Account creation failed. Please try again.';
          });
        }
      }
    } catch (e) {
      String errorMessage = e.toString();

      if (errorMessage.contains('Invalid login credentials')) {
        errorMessage = 'Invalid email or password';
      } else if (errorMessage.contains('User already registered')) {
        errorMessage = 'Email already registered. Please sign in.';
      } else if (errorMessage.contains('Email not confirmed')) {
        errorMessage = 'Please confirm your email before signing in.';
      }

      setState(() {
        _error = errorMessage;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _toggleMode() {
    setState(() {
      _isLogin = !_isLogin;
      _error = null;
      _success = null;
    });
  }

  Widget _buildMessageBox({
    required Color background,
    required Color border,
    required Color textColor,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: background,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(color: textColor),
      ),
    );
  }

  Widget _buildNavButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: BrandColors.white,
          foregroundColor: BrandColors.primaryBlack,
          side: const BorderSide(color: BrandColors.lightGray),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Text(label),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              // Simple app title
              const Text(
                'Valet Service',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Simple & Reliable Service',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 48),
              Text(
                _isLogin ? 'Sign In' : 'Sign Up',
                style: Theme.of(context).textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              if (!_isLogin) ...[
                TextFormField(
                  controller: _firstNameController,
                  decoration: const InputDecoration(
                    labelText: 'First Name',
                  ),
                  validator: (value) {
                    if (!_isLogin &&
                        (value == null || value.isEmpty)) {
                      return 'Please enter your first name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _lastNameController,
                  decoration: const InputDecoration(
                    labelText: 'Last Name',
                  ),
                  validator: (value) {
                    if (!_isLogin &&
                        (value == null || value.isEmpty)) {
                      return 'Please enter your last name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  prefixIcon: Icon(Icons.email),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your email';
                  }
                  if (!value.contains('@')) {
                    return 'Please enter a valid email';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your password';
                  }
                  if (value.length < 6) {
                    return 'Password must be at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              if (_error != null) ...[
                _buildMessageBox(
                  background: Colors.red.shade50,
                  border: Colors.red.shade200,
                  textColor: Colors.red.shade800,
                  text: _error!,
                ),
                const SizedBox(height: 16),
              ],
              if (_success != null) ...[
                _buildMessageBox(
                  background: Colors.green.shade50,
                  border: Colors.green.shade200,
                  textColor: Colors.green.shade800,
                  text: _success!,
                ),
                const SizedBox(height: 16),
              ],
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: AppTheme.primaryButtonStyle,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: BrandColors.white,
                          ),
                        )
                      : Text(
                          _isLogin ? 'Sign In' : 'Sign Up',
                          style: const TextStyle(fontSize: 16),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _toggleMode,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  _isLogin
                      ? 'Don\'t have an account? Sign up'
                      : 'Already have an account? Sign in',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const ResidentSignupScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.vpn_key, size: 18),
                  label:
                      const Text('Resident Sign Up (Invite Code)'),
                  style: AppTheme.secondaryButtonStyle,
                ),
              ),
              const SizedBox(height: 32),
              if (kDebugMode) ...[
                const Divider(),
                const SizedBox(height: 16),
                Text(
                  'Test Navigation (debug only)',
                  style: Theme.of(context).textTheme.titleSmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                _buildNavButton(
                  label: 'Property Manager Dashboard',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const PropertyManagerDashboardNewScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                _buildNavButton(
                  label: 'Worker Dashboard',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const WorkerDashboardScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                _buildNavButton(
                  label: 'Operations Manager Dashboard',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const ManagerDashboardScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                _buildNavButton(
                  label: 'Owner Dashboard',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const OwnerDashboardScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                _buildNavButton(
                  label: 'Test Connection',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const TestConnectionScreen(),
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}