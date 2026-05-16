import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../resident/screens/resident_dashboard_screen.dart';

class ResidentSignupScreen extends StatefulWidget {
  const ResidentSignupScreen({super.key});

  @override
  State<ResidentSignupScreen> createState() => _ResidentSignupScreenState();
}

class _ResidentSignupScreenState extends State<ResidentSignupScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _unitController = TextEditingController();
  final _inviteCodeController = TextEditingController();
  String? _selectedPropertyId;
  bool _isLoading = false;
  List<Map<String, dynamic>> _properties = [];

  @override
  void initState() {
    super.initState();
    _loadProperties();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _unitController.dispose();
    _inviteCodeController.dispose();
    super.dispose();
  }

  Future<void> _loadProperties() async {
    try {
      final supabase = Supabase.instance.client;
      final properties = await supabase
          .from('properties')
          .select('id, name')
          .order('name');
      
      setState(() {
        _properties = List<Map<String, dynamic>>.from(properties);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load properties: $e')),
      );
    }
  }

  Future<Map<String, dynamic>?> _verifyInviteCode() async {
    if (_selectedPropertyId == null || 
        _unitController.text.trim().isEmpty || 
        _inviteCodeController.text.trim().isEmpty) {
      return null;
    }

    try {
      final supabase = Supabase.instance.client;
      final result = await supabase.rpc('verify_invite_code', params: {
        'p_invite_code': _inviteCodeController.text.trim(),
        'p_property_id': _selectedPropertyId,
        'p_unit_number': _unitController.text.trim(),
      });
      
      return result.isNotEmpty ? result.first : null;
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error verifying invite code: $e')),
      );
      return null;
    }
  }

  Future<void> _signUp() async {
    // Validate inputs
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty ||
        _selectedPropertyId == null ||
        _unitController.text.trim().isEmpty ||
        _inviteCodeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Step 1: Verify invite code
      final verification = await _verifyInviteCode();
      if (verification == null || !verification['is_valid']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invalid invite code for this property and unit'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Step 2: Create auth user
      final supabase = Supabase.instance.client;
      final authResponse = await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (authResponse.user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create account'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Step 3: Insert user profile into public.users
      await supabase.from('users').insert({
        'id': authResponse.user!.id,
        'email': _emailController.text.trim(),
        'property_id': _selectedPropertyId,
        'unit_number': _unitController.text.trim(),
        'role': 'resident',
      });

      // Step 4: Update invite code as assigned
      await supabase.from('invite_codes').update({
        'assigned_user_id': authResponse.user!.id,
        'assigned_at': DateTime.now().toIso8601String(),
      }).eq('id', verification['invite_id']);

      // Step 5: Show success message and navigate
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate to resident dashboard
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const ResidentDashboardScreen(),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Signup failed: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Resident Sign Up',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.black26,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Instructions Card
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.person_add,
                                color: Colors.blue.shade700,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Text(
                                'Create Your Account',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Enter your details and invite code to create your resident account.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Sign Up Form Card
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Account Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Email
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                            hintText: 'Enter your email...',
                            prefixIcon: Icon(Icons.email),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                        const SizedBox(height: 16),

                        // Password
                        TextFormField(
                          controller: _passwordController,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            border: OutlineInputBorder(),
                            hintText: 'Enter your password...',
                            prefixIcon: Icon(Icons.lock),
                          ),
                          obscureText: true,
                        ),
                        const SizedBox(height: 16),

                        // Property Dropdown
                        DropdownButtonFormField<String>(
                          value: _selectedPropertyId,
                          decoration: const InputDecoration(
                            labelText: 'Property',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.apartment),
                          ),
                          items: _properties.map((property) {
                            return DropdownMenuItem(
                              value: property['id'].toString(),
                              child: Text(property['name']),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _selectedPropertyId = value);
                          },
                        ),
                        const SizedBox(height: 16),

                        // Unit Number
                        TextFormField(
                          controller: _unitController,
                          decoration: const InputDecoration(
                            labelText: 'Unit Number',
                            border: OutlineInputBorder(),
                            hintText: 'Enter your unit number...',
                            prefixIcon: Icon(Icons.home),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Invite Code
                        TextFormField(
                          controller: _inviteCodeController,
                          decoration: const InputDecoration(
                            labelText: 'Invite Code',
                            border: OutlineInputBorder(),
                            hintText: 'Enter your invite code...',
                            prefixIcon: Icon(Icons.vpn_key),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Sign Up Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _signUp,
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.person_add),
                            label: Text(_isLoading ? 'Creating Account...' : 'Sign Up'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Sign In Link
                        Center(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              'Already have an account? Sign In',
                              style: TextStyle(color: Colors.blue.shade600),
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
        ),
      ),
    );
  }
}
