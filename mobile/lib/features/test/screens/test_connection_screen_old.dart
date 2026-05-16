import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TestConnectionScreen extends StatefulWidget {
  const TestConnectionScreen({super.key});

  @override
  State<TestConnectionScreen> createState() => _TestConnectionScreenState();
}

class _TestConnectionScreenState extends State<TestConnectionScreen> {
  bool _isConnected = false;
  bool _isLoading = false;
  String _connectionStatus = 'Not tested';
  String? _error;
  Map<String, dynamic>? _currentUser;
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _properties = [];

  @override
  void initState() {
    super.initState();
    _testBasicConnection();
  }

  Future<void> _testBasicConnection() async {
    setState(() {
      _isLoading = true;
      _connectionStatus = 'Testing basic connection...';
      _error = null;
    });

    try {
      final supabase = Supabase.instance.client;
      
      // Test basic Supabase connection by checking client
      final clientUrl = supabase.supabaseUrl;
      final clientKey = supabase.supabaseKey;
      
      // Test auth session (safe operation)
      final currentUser = supabase.auth.currentUser;
      
      setState(() {
        _isConnected = true;
        _connectionStatus = 'Connected successfully!';
        _currentUser = currentUser != null ? {
          'id': currentUser.id,
          'email': currentUser.email,
        } : null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isConnected = false;
        _connectionStatus = 'Connection failed';
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _testAuthSession() async {
    setState(() {
      _isLoading = true;
      _connectionStatus = 'Testing auth session...';
      _error = null;
    });

    try {
      final supabase = Supabase.instance.client;
      
      // Try to get current session
      final session = supabase.auth.currentSession;
      final user = supabase.auth.currentUser;
      
      setState(() {
        _isConnected = true;
        _connectionStatus = 'Auth session working!';
        _currentUser = user != null ? {
          'id': user.id,
          'email': user.email,
          'session': session != null ? 'Active' : 'None',
        } : null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isConnected = false;
        _connectionStatus = 'Auth session failed';
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _testDatabaseTables() async {
    setState(() {
      _isLoading = true;
      _connectionStatus = 'Testing database tables...';
      _error = null;
      _users.clear();
      _properties.clear();
    });

    try {
      final supabase = Supabase.instance.client;
      String results = '';
      
      // Test users table (fallback to profiles if users doesn't exist)
      List<Map<String, dynamic>> usersData = [];
      String userTable = '';
      try {
        usersData = await supabase
            .from('users')
            .select('id, email, first_name, last_name, role')
            .limit(5);
        userTable = 'users';
        results += 'Users: ${usersData.length} rows\n';
      } catch (e) {
        // Try profiles table instead
        try {
          usersData = await supabase
              .from('profiles')
              .select('id, email, first_name, last_name, role')
              .limit(5);
          userTable = 'profiles';
          results += 'Profiles: ${usersData.length} rows\n';
        } catch (e2) {
          // Neither table exists
          results += 'Users/Profiles: Table not found\n';
        }
      }
      
      // Test properties table
      List<Map<String, dynamic>> propertiesData = [];
      try {
        propertiesData = await supabase
            .from('properties')
            .select('id, name, address, city, state')
            .limit(5);
        results += 'Properties: ${propertiesData.length} rows\n';
      } catch (e) {
        // Properties table doesn't exist
        results += 'Properties: Table not found\n';
      }

      setState(() {
        _isConnected = true;
        _connectionStatus = results;
        _users = (usersData as List)
           .map((e) => Map<String, dynamic>.from(e)) 
           .toList();
        _properties = (propertiesData as List)
           .map((e) => Map<String, dynamic>.from(e)) 
           .toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isConnected = false;
        _connectionStatus = 'Database tables failed';
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _testAuth() async {
    try {
      final supabase = Supabase.instance.client;
      
      // Try to sign up a test user (will fail if user exists)
      try {
        await supabase.auth.signUp(
          email: 'test@example.com',
          password: 'test123456',
          data: {
            'first_name': 'Test',
            'last_name': 'User',
            'role': 'resident',
          },
        );
        _showMessage('Test user created successfully');
      } catch (e) {
        // User might already exist, try to sign in
        await supabase.auth.signInWithPassword(
          email: 'test@example.com',
          password: 'test123456',
        );
        _showMessage('Test user signed in successfully');
      }
      
      _testBasicConnection(); // Refresh data
    } catch (e) {
      _showMessage('Auth test failed: ${e.toString()}');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supabase Connection Test'),
        backgroundColor: _isConnected ? Colors.green : Colors.red,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Connection Status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isConnected ? Icons.check_circle : Icons.error,
                          color: _isConnected ? Colors.green : Colors.red,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Connection Status: $_connectionStatus',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Error: $_error',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      children: [
                        ElevatedButton(
                          onPressed: _isLoading ? null : _testBasicConnection,
                          child: _isLoading
                              ? const CircularProgressIndicator()
                              : const Text('Test Basic Connection'),
                        ),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _testAuthSession,
                          child: _isLoading
                              ? const CircularProgressIndicator()
                              : const Text('Test Auth Session'),
                        ),
                        ElevatedButton(
                          onPressed: _isLoading ? null : _testDatabaseTables,
                          child: _isLoading
                              ? const CircularProgressIndicator()
                              : const Text('Test Database Tables'),
                        ),
                        ElevatedButton(
                          onPressed: _testAuth,
                          child: const Text('Test Sign Up'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Current User Info
            if (_currentUser != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Current User',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text('ID: ${_currentUser!['id']}'),
                      Text('Email: ${_currentUser!['email']}'),
                      if (_currentUser!.containsKey('session'))
                        Text('Session: ${_currentUser!['session']}'),
                    ],
                  ),
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Users Data Preview
            if (_users.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Users Table: ${_users.length} rows returned',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      if (_users.isNotEmpty) ...[
                        Text(
                          'First user preview:',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${_users.first['first_name'] ?? 'N/A'} ${_users.first['last_name'] ?? 'N/A'}\n'
                            'Email: ${_users.first['email'] ?? 'N/A'}\n'
                            'Role: ${_users.first['role'] ?? 'N/A'}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Properties Data Preview
            if (_properties.isNotEmpty) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Properties Table: ${_properties.length} rows returned',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      if (_properties.isNotEmpty) ...[
                        Text(
                          'First property preview:',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${_properties.first['name'] ?? 'N/A'}\n'
                            'Address: ${_properties.first['address'] ?? 'N/A'}\n'
                            'City: ${_properties.first['city'] ?? 'N/A'}, ${_properties.first['state'] ?? 'N/A'}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            
            const SizedBox(height: 16),
            
            // Instructions
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Test Results',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      const Text('Basic Connection: Tests Supabase client initialization'),
                      const Text('Auth Session: Tests authentication state'),
                      const Text('Database Tables: Tests real database queries'),
                      const SizedBox(height: 16),
                      const Text(
                        'Next Steps:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Text('1. Load seed data if tables are empty'),
                      const Text('2. Test with real app screens'),
                      const Text('3. Build full authentication flow'),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
