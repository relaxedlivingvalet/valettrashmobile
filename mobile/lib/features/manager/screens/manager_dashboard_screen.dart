import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'simple_notification_sender_screen.dart';
import 'today_comebacks_screen.dart';

class ManagerDashboardScreen extends StatefulWidget {
  const ManagerDashboardScreen({super.key});

  @override
  State<ManagerDashboardScreen> createState() => _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState extends State<ManagerDashboardScreen> {
  bool _loading = true;
  String? _error;
  String _email = '';

  List<String> _propertyIds = [];
  List<Map<String, dynamic>> _workers = [];
  List<Map<String, dynamic>> _runs = [];
  int _pendingComebacks = 0;
  int _acceptedComebacks = 0;
  int _completedComebacks = 0;
  List<Map<String, dynamic>> _comebackHistory = [];
  List<Map<String, dynamic>> _sentNotifications = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final supabase = Supabase.instance.client;
      final uid = supabase.auth.currentUser?.id;
      if (uid == null) {
        setState(() => _loading = false);
        return;
      }
      _email = supabase.auth.currentUser?.email ?? '';

      final userPropsRows = await supabase
          .from('user_properties')
          .select('property_id')
          .eq('user_id', uid);

      final propIds = (userPropsRows as List)
          .map((r) => r['property_id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toList();

      if (propIds.isEmpty) {
        setState(() {
          _propertyIds = [];
          _loading = false;
        });
        return;
      }

      _propertyIds = propIds;

      final now = DateTime.now();
      final todayStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final todayStartUtc =
          DateTime(now.year, now.month, now.day).toUtc().toIso8601String();
      final sevenDaysAgoUtc =
          now.subtract(const Duration(days: 7)).toUtc().toIso8601String();

      final results = await Future.wait([
        supabase
            .from('worker_assignments')
            .select('user_id, property_id, users(first_name, last_name, email)')
            .inFilter('property_id', propIds)
            .eq('is_active', true),
        supabase
            .from('nightly_runs')
            .select(
                'id, status, property_id, started_at, completed_at, completed_units, total_units, properties(name)')
            .inFilter('property_id', propIds)
            .eq('run_date', todayStr),
        supabase
            .from('missed_pickup_requests')
            .select('id, status')
            .gte('created_at', todayStartUtc),
        supabase
            .from('missed_pickup_requests')
            .select('id, status, completed_at, created_at')
            .gte('created_at', sevenDaysAgoUtc)
            .neq('status', 'pending')
            .order('created_at', ascending: false)
            .limit(10),
        supabase
            .from('notifications')
            .select('id, title, created_at, type')
            .eq('sender_id', uid)
            .order('created_at', ascending: false)
            .limit(5),
      ]);

      final workerRows =
          List<Map<String, dynamic>>.from(results[0] as List);
      final runRows =
          List<Map<String, dynamic>>.from(results[1] as List);
      final comebackRows =
          List<Map<String, dynamic>>.from(results[2] as List);
      final historyRows =
          List<Map<String, dynamic>>.from(results[3] as List);
      final notifRows =
          List<Map<String, dynamic>>.from(results[4] as List);

      // De-duplicate workers by user_id (same driver can be assigned to multiple properties)
      final seenIds = <String>{};
      final uniqueWorkers = <Map<String, dynamic>>[];
      for (final row in workerRows) {
        final userId = row['user_id']?.toString() ?? '';
        if (userId.isNotEmpty && seenIds.add(userId)) {
          uniqueWorkers.add(row);
        }
      }

      setState(() {
        _workers = uniqueWorkers;
        _runs = runRows;
        _pendingComebacks =
            comebackRows.where((r) => r['status'] == 'pending').length;
        _acceptedComebacks =
            comebackRows.where((r) => r['status'] == 'accepted').length;
        _completedComebacks =
            comebackRows.where((r) => r['status'] == 'completed').length;
        _comebackHistory = historyRows;
        _sentNotifications = notifRows;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  String _workerName(Map<String, dynamic> row) {
    final u = row['users'];
    if (u is! Map) return row['user_id']?.toString() ?? 'Unknown';
    final fn = u['first_name']?.toString() ?? '';
    final ln = u['last_name']?.toString() ?? '';
    if (fn.isNotEmpty || ln.isNotEmpty) return '$fn $ln'.trim();
    return u['email']?.toString() ?? 'Unknown';
  }

  Color _runStatusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'in_progress':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _runStatusLabel(String status) {
    switch (status) {
      case 'completed':
        return 'Completed';
      case 'in_progress':
        return 'In Progress';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  String _formatDate(String? isoStr) {
    if (isoStr == null) return '—';
    try {
      final dt = DateTime.parse(isoStr).toLocal();
      return '${dt.month}/${dt.day} ${_fmtTime(dt)}';
    } catch (_) {
      return isoStr;
    }
  }

  String _fmtTime(DateTime dt) {
    final h12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final min = dt.minute.toString().padLeft(2, '0');
    final ap = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h12:$min $ap';
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Color iconColor,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
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
                    color: iconColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _rowTile(Widget leading, String primary, [String? secondary]) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(primary,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 14)),
                if (secondary != null) ...[
                  const SizedBox(height: 2),
                  Text(secondary,
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey.shade600)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyRow(String label) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(label,
          style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          title: const Text('Operations Manager'),
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Operations Manager Dashboard'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
          IconButton(
            onPressed: _signOut,
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline,
                        color: Colors.red.shade400, size: 48),
                    const SizedBox(height: 16),
                    Text(_error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.red)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                        onPressed: _loadData,
                        child: const Text('Retry')),
                  ],
                ),
              ),
            )
          : _propertyIds.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.apartment,
                            color: Colors.grey.shade400, size: 64),
                        const SizedBox(height: 16),
                        const Text(
                          'No properties assigned',
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'A super admin must assign you to a property.',
                          style: TextStyle(color: Colors.grey.shade600),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        OutlinedButton(
                          onPressed: _signOut,
                          child: const Text('Sign Out'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // Worker Status
                        _sectionCard(
                          title: 'Assigned Workers',
                          icon: Icons.people,
                          iconColor: Colors.green,
                          child: _workers.isEmpty
                              ? _emptyRow('No workers assigned to your properties')
                              : Column(
                                  children: _workers.map((w) {
                                    return _rowTile(
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade50,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Icon(Icons.person,
                                            color: Colors.green.shade700,
                                            size: 18),
                                      ),
                                      _workerName(w),
                                      'Driver',
                                    );
                                  }).toList(),
                                ),
                        ),
                        const SizedBox(height: 24),

                        // Tonight's Runs
                        _sectionCard(
                          title: "Tonight's Service Runs",
                          icon: Icons.task_alt,
                          iconColor: Colors.blue,
                          child: _runs.isEmpty
                              ? _emptyRow('No service runs recorded for tonight yet')
                              : Column(
                                  children: _runs.map((run) {
                                    final status =
                                        run['status'] as String? ??
                                            'in_progress';
                                    final statusColor =
                                        _runStatusColor(status);
                                    final statusLabel =
                                        _runStatusLabel(status);
                                    final prop = run['properties'];
                                    final propName = prop is Map
                                        ? prop['name']?.toString() ??
                                            'Unknown Property'
                                        : 'Unknown Property';
                                    final completed =
                                        run['completed_units'] as int? ?? 0;
                                    final total =
                                        run['total_units'] as int? ?? 0;

                                    return Container(
                                      padding: const EdgeInsets.all(12),
                                      margin:
                                          const EdgeInsets.only(bottom: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade50,
                                        borderRadius:
                                            BorderRadius.circular(8),
                                        border: Border.all(
                                            color: Colors.grey.shade200),
                                      ),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(propName,
                                                    style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        fontSize: 14)),
                                                if (total > 0) ...[
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    '$completed / $total units',
                                                    style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors
                                                            .grey.shade600),
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding:
                                                const EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4),
                                            decoration: BoxDecoration(
                                              color: statusColor
                                                  .withOpacity(0.12),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              statusLabel,
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: statusColor),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                        ),
                        const SizedBox(height: 24),

                        // Today's Comebacks summary
                        _sectionCard(
                          title: "Today's Comebacks",
                          icon: Icons.refresh,
                          iconColor: Colors.orange,
                          child: InkWell(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const TodayComebacksScreen(),
                              ),
                            ),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: Colors.grey.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Total Requests',
                                              style: TextStyle(
                                                  fontSize: 14,
                                                  color:
                                                      Colors.grey.shade700,
                                                  fontWeight:
                                                      FontWeight.w600),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${_pendingComebacks + _acceptedComebacks + _completedComebacks}',
                                              style: const TextStyle(
                                                  fontSize: 24,
                                                  fontWeight:
                                                      FontWeight.bold,
                                                  color: Colors.black87),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(Icons.arrow_forward_ios,
                                          color: Colors.grey.shade400,
                                          size: 20),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: [
                                      _chip('Pending',
                                          _pendingComebacks, Colors.orange),
                                      _chip('In Progress',
                                          _acceptedComebacks, Colors.blue),
                                      _chip('Completed',
                                          _completedComebacks, Colors.green),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tap to view details',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.orange.shade700,
                                        fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Comeback History (past 7 days)
                        _sectionCard(
                          title: 'Comeback History (7 days)',
                          icon: Icons.history,
                          iconColor: Colors.purple,
                          child: _comebackHistory.isEmpty
                              ? _emptyRow('No resolved comebacks in the last 7 days')
                              : Column(
                                  children: _comebackHistory.map((h) {
                                    final status =
                                        h['status'] as String? ?? '';
                                    final date = _formatDate(
                                        h['completed_at'] as String? ??
                                            h['created_at'] as String?);
                                    Color c;
                                    String label;
                                    if (status == 'completed') {
                                      c = Colors.green;
                                      label = 'Completed';
                                    } else if (status == 'expired') {
                                      c = Colors.red;
                                      label = 'Expired';
                                    } else {
                                      c = Colors.orange;
                                      label = status;
                                    }

                                    return _rowTile(
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: c.withOpacity(0.12),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(label,
                                            style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: c)),
                                      ),
                                      date,
                                    );
                                  }).toList(),
                                ),
                        ),
                        const SizedBox(height: 24),

                        // Resident Communication
                        _sectionCard(
                          title: 'Resident Communication',
                          icon: Icons.notifications_active,
                          iconColor: Colors.amber.shade700,
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _actionTile(
                                      'Alert All Residents',
                                      'Send property-wide alert',
                                      Icons.campaign,
                                      Colors.blue,
                                      () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const SimpleNotificationSenderScreen(
                                                  initialMode: 'property'),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _actionTile(
                                      'Direct Notification',
                                      'Send to specific resident',
                                      Icons.person,
                                      Colors.purple,
                                      () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              const SimpleNotificationSenderScreen(
                                                  initialMode: 'user'),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (_sentNotifications.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: Colors.grey.shade200),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Recently Sent',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color: Colors.grey.shade700,
                                            fontSize: 13),
                                      ),
                                      const SizedBox(height: 8),
                                      ..._sentNotifications.map((n) {
                                        return Padding(
                                          padding: const EdgeInsets.only(
                                              bottom: 4),
                                          child: Row(
                                            children: [
                                              Icon(Icons.check_circle,
                                                  size: 14,
                                                  color:
                                                      Colors.green.shade600),
                                              const SizedBox(width: 6),
                                              Expanded(
                                                child: Text(
                                                  n['title']?.toString() ??
                                                      'Notification',
                                                  style: const TextStyle(
                                                      fontSize: 13),
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                _formatDate(n['created_at']
                                                    as String?),
                                                style: TextStyle(
                                                    fontSize: 11,
                                                    color: Colors
                                                        .grey.shade500),
                                              ),
                                            ],
                                          ),
                                        );
                                      }).toList(),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Property Services placeholders
                        _sectionCard(
                          title: 'Property Services',
                          icon: Icons.cleaning_services,
                          iconColor: Colors.cyan.shade700,
                          child: Row(
                            children: [
                              Expanded(
                                child: _actionTile(
                                  'Power Washing',
                                  'Coming soon',
                                  Icons.water_drop,
                                  Colors.blue,
                                  () => _showMessage(
                                      'Power washing management coming soon'),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _actionTile(
                                  'Property Cleanup',
                                  'Coming soon',
                                  Icons.cleaning_services,
                                  Colors.green,
                                  () => _showMessage(
                                      'Property cleanup coming soon'),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Footer
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Signed in as: $_email',
                                style: TextStyle(
                                    color: Colors.grey.shade700,
                                    fontSize: 14),
                              ),
                              Text(
                                '${_propertyIds.length} propert${_propertyIds.length == 1 ? 'y' : 'ies'} · ${_workers.length} worker${_workers.length == 1 ? '' : 's'}',
                                style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _chip(String label, int count, Color color) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  Widget _actionTile(String title, String subtitle, IconData icon,
      Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 2),
            Text(subtitle,
                style:
                    TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}
