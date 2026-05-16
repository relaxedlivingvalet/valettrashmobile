import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import 'violation_report_screen.dart';

class WorkerDashboardScreen extends StatefulWidget {
  const WorkerDashboardScreen({super.key});

  @override
  State<WorkerDashboardScreen> createState() => _WorkerDashboardScreenState();
}

class _WorkerDashboardScreenState extends State<WorkerDashboardScreen> {
  bool _loading = true;
  String _email = 'No user signed in';
  bool _isOnDuty = false;
  String _assignedProperty = 'No property assignment';
  String _assignedRoute = 'No active route';
  List<Map<String, dynamic>> _comebackRequests = [];
  List<Map<String, dynamic>> _assignedIssues = [];

  @override
  void initState() {
    super.initState();
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      _email = user.email ?? user.id;
    }
    _loadRouteData();
  }

  Future<void> _loadRouteData() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    setState(() => _loading = true);
    if (user == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final assigns = await client
          .from('worker_assignments')
          .select('property_id, properties(name)')
          .eq('user_id', user.id)
          .eq('is_active', true);
      final assignList =
          List<Map<String, dynamic>>.from(assigns as List);
      final names = <String>[];
      final propertyIds = <String>{};
      for (final row in assignList) {
        final p = row['properties'];
        if (p is Map && p['name'] != null) {
          names.add('${p['name']}');
        }
        final pid = row['property_id']?.toString();
        if (pid != null) propertyIds.add(pid);
      }
      if (names.isNotEmpty) {
        _assignedProperty = names.join(', ');
      }

      final routes = await client
          .from('routes')
          .select('id, name')
          .eq('worker_id', user.id)
          .eq('is_active', true);
      final routeList = List<Map<String, dynamic>>.from(routes as List);
      if (routeList.isNotEmpty) {
        final routeId = routeList.first['id'];
        final stops = await client
            .from('route_stops')
            .select('stop_order, units(unit_number)')
            .eq('route_id', routeId)
            .order('stop_order', ascending: true);
        final stopList = List<Map<String, dynamic>>.from(stops as List);
        final nums = stopList
            .map((s) {
              final u = s['units'];
              if (u is Map) return u['unit_number']?.toString();
              return null;
            })
            .whereType<String>()
            .toList();
        _assignedRoute =
            '${routeList.first['name']}: ${nums.take(20).join(', ')}${nums.length > 20 ? '…' : ''}';
      }

      final rawComebacks = await client
          .from('missed_pickup_requests')
          .select(
            'id, status, requested_at, pickups(units(unit_number), nightly_runs(property_id))',
          )
          .limit(80);
      final cbList = List<Map<String, dynamic>>.from(rawComebacks as List);
      _comebackRequests = [];
      for (final row in cbList) {
        final p = row['pickups'];
        if (p is! Map) continue;
        final nr = p['nightly_runs'];
        final propId =
            nr is Map ? nr['property_id']?.toString() : null;
        if (propId != null && !propertyIds.contains(propId)) continue;
        final u = p['units'];
        final unit = u is Map ? u['unit_number']?.toString() ?? '?' : '?';
        _comebackRequests.add({
          'id': row['id']?.toString(),
          'unit': unit,
          'type': 'Comeback',
          'time': row['requested_at']?.toString() ?? '',
          'status': row['status']?.toString() ?? 'pending',
        });
      }

      _assignedIssues = [];
    } catch (_) {
      _comebackRequests = [];
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }


  Future<void> _refresh() async {
    await _loadRouteData();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _toggleDutyStatus() {
    setState(() {
      _isOnDuty = !_isOnDuty;
    });
    _showMessage(_isOnDuty ? 'You are now on duty' : 'You are now off duty');
  }

  void _startService() {
    if (!_isOnDuty) {
      _showMessage('Please mark yourself on duty first');
      return;
    }
    _showMessage('Service started for $_assignedProperty');
  }

  void _completeService() {
    if (!_isOnDuty) {
      _showMessage('Please mark yourself on duty first');
      return;
    }
    _showMessage('Service completed for $_assignedProperty');
  }

  void _reportViolation() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ViolationReportScreen(),
      ),
    );
  }

  Future<void> _completeComebackRequest(int index) async {
    final item = _comebackRequests[index];
    final id = item['id']?.toString();
    if (id != null) {
      try {
        await Supabase.instance.client
            .from('missed_pickup_requests')
            .update({
              'status': 'completed',
              'completed_at': DateTime.now().toUtc().toIso8601String(),
            })
            .eq('id', id);
      } catch (_) {}
    }
    if (mounted) {
      setState(() => _comebackRequests.removeAt(index));
      _showMessage('Comeback request completed successfully!');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Worker Dashboard'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loading ? null : _refresh,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh routes',
          ),
          IconButton(
            onPressed: _signOut,
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refresh,
              child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      _isOnDuty ? Icons.work : Icons.work_off,
                      color: _isOnDuty ? Colors.green : Colors.red,
                      size: 32,
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Worker Status',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          Text(
                            _isOnDuty ? 'On Duty' : 'Off Duty',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: _isOnDuty ? Colors.green : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _toggleDutyStatus,
                      icon: Icon(
                        _isOnDuty ? Icons.work_off : Icons.work,
                        size: 18,
                      ),
                      label: Text(_isOnDuty ? 'Clock Out' : 'Clock In'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isOnDuty ? Colors.red : Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Assignment Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          color: Colors.blue,
                          size: 24,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Assignment',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Property',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _assignedProperty,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.info,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Route',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _assignedRoute,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.info,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Service Actions
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _startService,
                    icon: const Icon(Icons.play_arrow, size: 18),
                    label: const Text('Start Service'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _completeService,
                    icon: const Icon(Icons.check, size: 18),
                    label: const Text('Complete Service'),
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
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _reportViolation,
                    icon: const Icon(Icons.warning, size: 18),
                    label: const Text('Report Violation'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade600,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Comeback Requests
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.refresh,
                          color: Colors.orange,
                          size: 24,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Comeback Requests',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_comebackRequests.length}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.orange.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_comebackRequests.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: const Text(
                          'No comeback requests',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    else
                      ..._comebackRequests.asMap().entries.map((entry) {
                        final index = entry.key;
                        final request = entry.value;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.textSecondary,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.home,
                                size: 16,
                                color: AppColors.textSecondary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Unit ${request['unit']} - ${request['type']}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              Text(
                                request['time'],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed: () => _completeComebackRequest(index),
                                icon: const Icon(Icons.check, size: 16),
                                label: const Text('Complete'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade600,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Assigned Issues
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
                            color: Colors.purple.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.note_alt,
                            color: Colors.purple.shade700,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Text(
                            'Notes & Issues',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.purple.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_assignedIssues.length}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.purple.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_assignedIssues.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: const Text(
                          'No assigned issues',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    else
                      ..._assignedIssues.map((item) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: item['priority'] == 'high' 
                              ? Colors.red.shade50 
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: item['priority'] == 'high' 
                                ? Colors.red.shade200 
                                : Colors.grey.shade200,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  item['type'] == 'Issue' 
                                      ? Icons.warning 
                                      : Icons.note,
                                  size: 16,
                                  color: item['priority'] == 'high' 
                                      ? Colors.red.shade600 
                                      : Colors.grey.shade600,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Unit ${item['unit']} - ${item['type']}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: item['priority'] == 'high' 
                                          ? Colors.red.shade800 
                                          : Colors.black87,
                                    ),
                                  ),
                                ),
                                Text(
                                  item['time'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            if (item['description'] != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                item['description'],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      )),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Debug Info Card
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Worker Info',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Email: $_email',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    Text(
                      'Status: ${_isOnDuty ? "On Duty" : "Off Duty"}',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
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
