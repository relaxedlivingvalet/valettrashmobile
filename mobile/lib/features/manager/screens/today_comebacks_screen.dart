import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TodayComebacksScreen extends StatefulWidget {
  const TodayComebacksScreen({super.key});

  @override
  State<TodayComebacksScreen> createState() => _TodayComebacksScreenState();
}

class _TodayComebacksScreenState extends State<TodayComebacksScreen> {
  String _email = 'No user signed in';

  // Mock comeback data
  final List<Map<String, dynamic>> _comebacks = const [
    {
      'id': '1',
      'property': 'Sunset Apartments',
      'unit': '101',
      'serviceType': 'Trash Removal',
      'status': 'In Queue',
      'assignedWorker': 'John Smith',
      'requestTime': '2:30 PM',
      'completionTime': '',
    },
    {
      'id': '2',
      'property': 'Sunset Apartments',
      'unit': '205',
      'serviceType': 'Package Delivery',
      'status': 'In Progress',
      'assignedWorker': 'Mike Johnson',
      'requestTime': '3:15 PM',
      'completionTime': '',
    },
    {
      'id': '3',
      'property': 'Ocean View Condos',
      'unit': '312',
      'serviceType': 'Trash Removal',
      'status': 'Completed',
      'assignedWorker': 'Sarah Wilson',
      'requestTime': '1:45 PM',
      'completionTime': '2:20 PM',
    },
    {
      'id': '4',
      'property': 'Riverside Complex',
      'unit': '108',
      'serviceType': 'Maintenance',
      'status': 'In Queue',
      'assignedWorker': '',
      'requestTime': '4:00 PM',
      'completionTime': '',
    },
    {
      'id': '5',
      'property': 'Sunset Apartments',
      'unit': '415',
      'serviceType': 'Trash Removal',
      'status': 'In Progress',
      'assignedWorker': 'Tom Davis',
      'requestTime': '3:30 PM',
      'completionTime': '',
    },
    {
      'id': '6',
      'property': 'Ocean View Condos',
      'unit': '220',
      'serviceType': 'Package Delivery',
      'status': 'Completed',
      'assignedWorker': 'Lisa Chen',
      'requestTime': '11:30 AM',
      'completionTime': '12:15 PM',
    },
    {
      'id': '7',
      'property': 'Riverside Complex',
      'unit': '305',
      'serviceType': 'Trash Removal',
      'status': 'In Queue',
      'assignedWorker': '',
      'requestTime': '4:15 PM',
      'completionTime': '',
    },
    {
      'id': '8',
      'property': 'Sunset Apartments',
      'unit': '318',
      'serviceType': 'Maintenance',
      'status': 'In Progress',
      'assignedWorker': 'Alex Turner',
      'requestTime': '2:00 PM',
      'completionTime': '',
    },
  ];

  @override
  void initState() {
    super.initState();
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      _email = user.email ?? user.id;
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Completed':
        return Colors.green;
      case 'In Progress':
        return Colors.blue;
      case 'In Queue':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'Completed':
        return Icons.check_circle;
      case 'In Progress':
        return Icons.hourglass_bottom;
      case 'In Queue':
        return Icons.pending;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    final inQueueCount = _comebacks.where((c) => c['status'] == 'In Queue').length;
    final inProgressCount = _comebacks.where((c) => c['status'] == 'In Progress').length;
    final completedCount = _comebacks.where((c) => c['status'] == 'Completed').length;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Today's Comebacks"),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Summary Card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(20),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.refresh, color: Colors.orange, size: 24),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Text(
                        "Today's Comebacks Summary",
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
                Row(
                  children: [
                    Expanded(
                      child: _buildSummaryCard('In Queue', inQueueCount.toString(), Colors.orange),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryCard('In Progress', inProgressCount.toString(), Colors.blue),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildSummaryCard('Completed', completedCount.toString(), Colors.green),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Comeback List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _comebacks.length,
              itemBuilder: (context, index) {
                final comeback = _comebacks[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${comeback['property']} - Unit ${comeback['unit']}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _getStatusColor(comeback['status']).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: _getStatusColor(comeback['status']).withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    _getStatusIcon(comeback['status']),
                                    size: 14,
                                    color: _getStatusColor(comeback['status']),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    comeback['status'],
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: _getStatusColor(comeback['status']),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Icon(Icons.work_outline, size: 16, color: Colors.grey.shade600),
                            const SizedBox(width: 6),
                            Text(
                              comeback['serviceType'],
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(width: 20),
                            Icon(Icons.access_time, size: 16, color: Colors.grey.shade600),
                            const SizedBox(width: 6),
                            Text(
                              'Requested: ${comeback['requestTime']}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                        if (comeback['assignedWorker'].isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.person_outline, size: 16, color: Colors.grey.shade600),
                              const SizedBox(width: 6),
                              Text(
                                'Assigned: ${comeback['assignedWorker']}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (comeback['completionTime'].isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.check_circle_outline, size: 16, color: Colors.green.shade600),
                              const SizedBox(width: 6),
                              Text(
                                'Completed: ${comeback['completionTime']}',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.green.shade700,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
