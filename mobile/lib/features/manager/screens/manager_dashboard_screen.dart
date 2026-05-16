import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'simple_notification_sender_screen.dart';
import 'today_comebacks_screen.dart';
import '../../worker/screens/worker_dashboard_screen.dart';
import '../../resident/screens/resident_dashboard_screen.dart';

class ManagerDashboardScreen extends StatefulWidget {
  const ManagerDashboardScreen({super.key});

  @override
  State<ManagerDashboardScreen> createState() => _ManagerDashboardScreenState();
}

class _ManagerDashboardScreenState extends State<ManagerDashboardScreen> {
  String _email = 'No user signed in';

  // Mock worker data
  final List<Map<String, dynamic>> _workers = [
    {'name': 'John Smith', 'onDuty': true, 'checkInTime': '6:45 AM'},
    {'name': 'Mike Johnson', 'onDuty': true, 'checkInTime': '6:52 AM'},
    {'name': 'Sarah Wilson', 'onDuty': false, 'checkInTime': ''},
    {'name': 'Tom Davis', 'onDuty': true, 'checkInTime': '7:05 AM'},
    {'name': 'Lisa Chen', 'onDuty': false, 'checkInTime': ''},
  ];

  // Mock property service data
  final List<Map<String, dynamic>> _properties = [
    {'name': 'Sunset Apartments', 'status': 'Completed', 'assignedWorker': 'John Smith', 'completionTime': '8:30 PM'},
    {'name': 'Ocean View Condos', 'status': 'In Progress', 'assignedWorker': 'Mike Johnson', 'completionTime': ''},
    {'name': 'Riverside Complex', 'status': 'Not Started', 'assignedWorker': '', 'completionTime': ''},
  ];

  // Mock comeback data
  final List<Map<String, dynamic>> _comebacks = [
    {'property': 'Sunset Apartments', 'unit': '101', 'serviceType': 'Trash Removal', 'status': 'In Queue', 'assignedWorker': ''},
    {'property': 'Sunset Apartments', 'unit': '205', 'serviceType': 'Package Delivery', 'status': 'In Progress', 'assignedWorker': 'Mike Johnson'},
    {'property': 'Ocean View Condos', 'unit': '312', 'serviceType': 'Trash Removal', 'status': 'Completed', 'assignedWorker': 'Sarah Wilson'},
    {'property': 'Riverside Complex', 'unit': '108', 'serviceType': 'Maintenance', 'status': 'Incomplete', 'assignedWorker': 'Tom Davis'},
    {'property': 'Sunset Apartments', 'unit': '415', 'serviceType': 'Trash Removal', 'status': 'In Progress', 'assignedWorker': 'Tom Davis'},
  ];

  // Mock comeback history data
  final List<Map<String, dynamic>> _comebackHistory = [
    {'property': 'Sunset Apartments', 'unit': '102', 'date': '2024-04-21', 'status': 'Completed', 'assignedWorker': 'John Smith', 'completionTime': '8:15 PM'},
    {'property': 'Ocean View Condos', 'unit': '210', 'date': '2024-04-21', 'status': 'Completed', 'assignedWorker': 'Lisa Chen', 'completionTime': '7:45 PM'},
    {'property': 'Riverside Complex', 'unit': '305', 'date': '2024-04-20', 'status': 'Incomplete', 'assignedWorker': 'Mike Johnson', 'completionTime': ''},
    {'property': 'Sunset Apartments', 'unit': '318', 'date': '2024-04-20', 'status': 'Completed', 'assignedWorker': 'Sarah Wilson', 'completionTime': '8:20 PM'},
    {'property': 'Ocean View Condos', 'unit': '115', 'date': '2024-04-19', 'status': 'Completed', 'assignedWorker': 'Tom Davis', 'completionTime': '7:55 PM'},
  ];

  @override
  void initState() {
    super.initState();
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      _email = user.email ?? user.id;
    }
  }

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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

  Widget _metricTile({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
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

  Widget _navButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Expanded(
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        '$label: $count',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  // Helper methods for operational lists
  Color _getStatusColor(String status) {
    switch (status) {
      case 'Completed':
        return Colors.green;
      case 'In Progress':
        return Colors.blue;
      case 'In Queue':
        return Colors.orange;
      case 'Not Started':
        return Colors.grey;
      case 'Incomplete':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _workerRow(Map<String, dynamic> worker) {
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
          Icon(
            worker['onDuty'] ? Icons.check_circle : Icons.cancel,
            color: worker['onDuty'] ? Colors.green : Colors.red,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              worker['name'],
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: worker['onDuty'] ? Colors.green.shade50 : Colors.red.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              worker['onDuty'] ? 'On Duty' : 'Off Duty',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: worker['onDuty'] ? Colors.green.shade700 : Colors.red.shade700,
              ),
            ),
          ),
          if (worker['onDuty'] && worker['checkInTime'].isNotEmpty) ...[
            const SizedBox(width: 12),
            Text(
              worker['checkInTime'],
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _propertyRow(Map<String, dynamic> property) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  property['name'],
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(property['status']).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  property['status'],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(property['status']),
                  ),
                ),
              ),
            ],
          ),
          if (property['assignedWorker'].isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.person_outline, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Text(
                  'Assigned: ${property['assignedWorker']}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ],
          if (property['completionTime'].isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.check_circle_outline, size: 16, color: Colors.green.shade600),
                const SizedBox(width: 6),
                Text(
                  'Completed: ${property['completionTime']}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _comebackRow(Map<String, dynamic> comeback) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${comeback['property']} - Unit ${comeback['unit']}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(comeback['status']).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  comeback['status'],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(comeback['status']),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.work_outline, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(
                comeback['serviceType'],
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                ),
              ),
              if (comeback['assignedWorker'].isNotEmpty) ...[
                const SizedBox(width: 20),
                Icon(Icons.person_outline, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Text(
                  comeback['assignedWorker'],
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _historyRow(Map<String, dynamic> history) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${history['property']} - Unit ${history['unit']}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(history['status']).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  history['status'],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getStatusColor(history['status']),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(
                history['date'],
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade700,
                ),
              ),
              if (history['assignedWorker'].isNotEmpty) ...[
                const SizedBox(width: 20),
                Icon(Icons.person_outline, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 6),
                Text(
                  history['assignedWorker'],
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ],
          ),
          if (history['completionTime'].isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.check_circle_outline, size: 16, color: Colors.green.shade600),
                const SizedBox(width: 6),
                Text(
                  'Completed: ${history['completionTime']}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Operations Manager Dashboard'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _signOut,
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _sectionCard(
              title: 'Worker Status',
              icon: Icons.people,
              iconColor: Colors.green,
              child: Column(
                children: [
                  ..._workers.map((worker) => _workerRow(worker)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _sectionCard(
              title: 'Service Status',
              icon: Icons.task_alt,
              iconColor: Colors.blue,
              child: Column(
                children: [
                  ..._properties.map((property) => _propertyRow(property)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _sectionCard(
              title: "Today's Comebacks",
              icon: Icons.refresh,
              iconColor: Colors.orange,
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const TodayComebacksScreen(),
                    ),
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Total Requests',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_comebacks.length}',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.grey.shade400,
                            size: 20,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          _buildStatusChip('In Queue', _comebacks.where((c) => c['status'] == 'In Queue').length, Colors.orange),
                          const SizedBox(width: 8),
                          _buildStatusChip('In Progress', _comebacks.where((c) => c['status'] == 'In Progress').length, Colors.blue),
                          const SizedBox(width: 8),
                          _buildStatusChip('Completed', _comebacks.where((c) => c['status'] == 'Completed').length, Colors.green),
                          if (_comebacks.where((c) => c['status'] == 'Incomplete').isNotEmpty) ...[
                            const SizedBox(width: 8),
                            _buildStatusChip('Incomplete', _comebacks.where((c) => c['status'] == 'Incomplete').length, Colors.red),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Tap to view details',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            _sectionCard(
              title: 'Comeback History',
              icon: Icons.history,
              iconColor: Colors.purple,
              child: Column(
                children: [
                  ..._comebackHistory.map((history) => _historyRow(history)),
                ],
              ),
            ),
            const SizedBox(height: 24),
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
                          title: 'Send Alert to Property',
                          subtitle: 'Notify all residents',
                          icon: Icons.send,
                          color: Colors.blue,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const SimpleNotificationSenderScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _actionTile(
                          title: 'Send to Specific Unit',
                          subtitle: 'Direct notification',
                          icon: Icons.person,
                          color: Colors.purple,
                          onTap: () {
                            _showMessage('Opening unit-specific notification...');
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      'Recent Notifications Sent\n\n'
                      '• Service completed: 2:30 PM - All residents notified\n'
                      '• Weather alert: 11:00 AM - All residents notified',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade800,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _sectionCard(
              title: 'Review Queues',
              icon: Icons.queue,
              iconColor: Colors.orange,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _metricTile(
                          title: 'Resident Concerns',
                          value: '${_comebackHistory.where((h) => h['status'] == 'Completed').length + _comebacks.where((c) => c['status'] == 'Completed').length} tickets',
                          icon: Icons.support_agent,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _metricTile(
                          title: 'Worker Violations',
                          value: '${_comebacks.where((c) => c['status'] == 'Incomplete').length + _comebackHistory.where((h) => h['status'] == 'Incomplete').length} reports',
                          icon: Icons.warning,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _metricTile(
                          title: 'Comeback Requests',
                          value: '${_comebacks.where((c) => c['status'] == 'In Queue' || c['status'] == 'In Progress').length} pending',
                          icon: Icons.refresh,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _metricTile(
                          title: 'Extra Services',
                          value: '${_comebacks.where((c) => c['serviceType'] == 'Package Delivery').length} requests',
                          icon: Icons.miscellaneous_services,
                          color: Colors.purple,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _sectionCard(
              title: 'Property Services',
              icon: Icons.cleaning_services,
              iconColor: Colors.cyan.shade700,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _actionTile(
                          title: 'Power Washing / Sanitation',
                          subtitle: 'Manage service schedules',
                          icon: Icons.water_drop,
                          color: Colors.blue,
                          onTap: () {
                            _showMessage('Opening Power Washing management...');
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _actionTile(
                          title: 'Property Cleanup',
                          subtitle: 'Request cleanup services',
                          icon: Icons.cleaning_services,
                          color: Colors.green,
                          onTap: () {
                            _showMessage('Opening Property Cleanup requests...');
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Operations Navigation',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Signed in as: $_email',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _navButton(
                          label: 'Send',
                          icon: Icons.send,
                          color: Colors.green,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const SimpleNotificationSenderScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        _navButton(
                          label: 'Worker',
                          icon: Icons.work,
                          color: Colors.orange,
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
                        const SizedBox(width: 8),
                        _navButton(
                          label: 'Resident',
                          icon: Icons.home,
                          color: Colors.blue,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const ResidentDashboardScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}