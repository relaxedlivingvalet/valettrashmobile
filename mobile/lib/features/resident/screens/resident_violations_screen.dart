import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ResidentViolationsScreen extends StatefulWidget {
  const ResidentViolationsScreen({super.key});

  @override
  State<ResidentViolationsScreen> createState() => _ResidentViolationsScreenState();
}

class _ResidentViolationsScreenState extends State<ResidentViolationsScreen> {
  List<Map<String, dynamic>> _violations = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadViolations();
  }

  Future<void> _loadViolations() async {
    try {
      final supabase = Supabase.instance.client;
      final currentUser = supabase.auth.currentUser;
      
      if (currentUser != null) {
        // Try to get violations for the current user
        final violations = await supabase
            .from('violations')
            .select('*')
            .eq('resident_user_id', currentUser.id)
            .order('created_at', ascending: false);
        
        setState(() {
          _violations = List<Map<String, dynamic>>.from(violations);
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
          _error = 'User not authenticated';
        });
      }
    } catch (e) {
      // If violations table doesn't exist or query fails, show empty state
      setState(() {
        _isLoading = false;
        _violations = [];
      });
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown date';
    try {
      final date = DateTime.parse(dateString);
      return '${date.month}/${date.day}/${date.year}';
    } catch (e) {
      return dateString;
    }
  }

  String _getViolationTypeDisplay(String? type) {
    switch (type?.toLowerCase()) {
      case 'missed_pickup':
        return 'Missed Pickup';
      case 'contamination':
        return 'Contamination';
      case 'overweight':
        return 'Overweight';
      case 'improper_disposal':
        return 'Improper Disposal';
      default:
        return type ?? 'Violation';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'My Violations',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.black26,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _violations.isEmpty
              ? _buildEmptyState()
              : _buildViolationsList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
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
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Icon(
                      Icons.check_circle,
                      color: Colors.green.shade600,
                      size: 48,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'No Violations',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Great job! You have no violations this month.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back to Dashboard'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViolationsList() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_violations.length} Violation${_violations.length == 1 ? '' : 's'}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),
            ..._violations.map((violation) => _buildViolationCard(violation)),
          ],
        ),
      ),
    );
  }

  Widget _buildViolationCard(Map<String, dynamic> violation) {
    final type = _getViolationTypeDisplay(violation['violation_type']);
    final description = violation['description'] ?? 'No description available';
    final date = _formatDate(violation['created_at']);
    final isCharged = (violation['is_warning'] == false);
    final photoUrl = violation['photo_url'];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isCharged ? Colors.red.shade50 : Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isCharged ? Icons.money : Icons.warning,
                    color: isCharged ? Colors.red.shade600 : Colors.orange.shade600,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    type,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isCharged ? Colors.red.shade100 : Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isCharged ? 'Charged' : 'Warning',
                    style: TextStyle(
                      color: isCharged ? Colors.red.shade700 : Colors.orange.shade700,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  color: Colors.grey.shade500,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  date,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            if (photoUrl != null && photoUrl.isNotEmpty) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  photoUrl,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.broken_image,
                              color: Colors.grey.shade400,
                              size: 48,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Photo unavailable',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
