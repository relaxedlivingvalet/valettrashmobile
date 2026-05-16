import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PropertyManagerDashboardNewScreen extends StatefulWidget {
  const PropertyManagerDashboardNewScreen({super.key});

  @override
  State<PropertyManagerDashboardNewScreen> createState() =>
      _PropertyManagerDashboardNewScreenState();
}

class _PropertyManagerDashboardNewScreenState
    extends State<PropertyManagerDashboardNewScreen> {
  String _email = 'No user signed in';

  final String _propertyName = 'Sunset Gardens';
  final String _serviceWindow = '6:00 PM - 10:00 PM';
  final bool _serviceActive = true;
  final bool _serviceCompleted = false;
  final bool _workerOnDuty = true;

  final int _verifiedResidents = 42;
  final int _totalUnits = 80;
  final int _claimedUnits = 42;
  final int _unclaimedUnits = 38;
  final int _inviteCodesIssued = 80;
  final int _inviteCodesUsed = 42;

  final int _comebackRequests = 5;
  final int _residentConcerns = 7;
  final int _activeViolations = 3;
  final int _extraServiceRequests = 4;

  final List<Map<String, String>> _inviteCodes = const [
    {'unit': '101', 'code': 'APT101ABC', 'status': 'Used'},
    {'unit': '102', 'code': 'APT102XYZ', 'status': 'Active'},
    {'unit': '103', 'code': 'APT103LMN', 'status': 'Active'},
    {'unit': '104', 'code': 'APT104QRS', 'status': 'Used'},
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

  Widget _metricCard({
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

  Widget _actionCard({
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

  Widget _inviteCodeRow(Map<String, String> item) {
    final isUsed = item['status'] == 'Used';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.meeting_room, color: Colors.blue.shade700, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Unit ${item['unit']}  •  ${item['code']}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isUsed ? Colors.green.shade50 : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isUsed ? Colors.green.shade200 : Colors.orange.shade200,
              ),
            ),
            child: Text(
              item['status'] ?? '',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isUsed ? Colors.green.shade700 : Colors.orange.shade700,
              ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => _showMessage('Copied ${item['code']}'),
            child: const Text('Copy'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Property Manager Dashboard'),
        backgroundColor: Colors.indigo.shade700,
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
              title: 'Property Overview',
              icon: Icons.apartment,
              iconColor: Colors.indigo,
              child: Column(
                children: [
                  _metricCard(
                    title: 'Property',
                    value: _propertyName,
                    icon: Icons.business,
                    color: Colors.indigo,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _metricCard(
                          title: 'Service Window',
                          value: _serviceWindow,
                          icon: Icons.access_time,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _metricCard(
                          title: 'Worker Status',
                          value: _workerOnDuty ? 'On Duty' : 'Off Duty',
                          icon: Icons.work,
                          color: _workerOnDuty ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _metricCard(
                          title: 'Service Status',
                          value: _serviceCompleted
                              ? 'Completed'
                              : (_serviceActive ? 'Active' : 'Inactive'),
                          icon: Icons.task_alt,
                          color: _serviceCompleted
                              ? Colors.green
                              : (_serviceActive ? Colors.blue : Colors.grey),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _metricCard(
                          title: 'Verified Residents',
                          value: '$_verifiedResidents',
                          icon: Icons.people,
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
              title: 'Resident Activation',
              icon: Icons.groups,
              iconColor: Colors.green,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _metricCard(
                          title: 'Total Units',
                          value: '$_totalUnits',
                          icon: Icons.meeting_room,
                          color: Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _metricCard(
                          title: 'Claimed Units',
                          value: '$_claimedUnits',
                          icon: Icons.check_circle,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _metricCard(
                          title: 'Unclaimed Units',
                          value: '$_unclaimedUnits',
                          icon: Icons.radio_button_unchecked,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _metricCard(
                          title: 'Invite Codes Used',
                          value: '$_inviteCodesUsed / $_inviteCodesIssued',
                          icon: Icons.vpn_key,
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
              title: 'Invite Code Management',
              icon: Icons.key,
              iconColor: Colors.orange,
              child: Column(
                children: [
                  ..._inviteCodes.map(_inviteCodeRow),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _actionCard(
                          title: 'Regenerate Codes',
                          subtitle: 'Reset unit invite codes',
                          icon: Icons.refresh,
                          color: Colors.orange,
                          onTap: () {
                            _showMessage('Regenerating invite codes...');
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _actionCard(
                          title: 'Share Codes',
                          subtitle: 'Send codes to residents',
                          icon: Icons.share,
                          color: Colors.blue,
                          onTap: () {
                            _showMessage('Opening code sharing...');
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _sectionCard(
              title: 'Resident Communication',
              icon: Icons.notifications,
              iconColor: Colors.blue,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _actionCard(
                          title: 'Alert Entire Property',
                          subtitle: 'Notify all residents',
                          icon: Icons.campaign,
                          color: Colors.blue,
                          onTap: () {
                            _showMessage('Opening property-wide alert...');
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _actionCard(
                          title: 'Alert Specific Unit',
                          subtitle: 'Send to one unit',
                          icon: Icons.home,
                          color: Colors.purple,
                          onTap: () {
                            _showMessage('Opening unit alert...');
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _sectionCard(
              title: 'Open Queues',
              icon: Icons.list_alt,
              iconColor: Colors.red,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _metricCard(
                          title: 'Comeback Requests',
                          value: '$_comebackRequests',
                          icon: Icons.refresh,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _metricCard(
                          title: 'Resident Concerns',
                          value: '$_residentConcerns',
                          icon: Icons.support_agent,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _metricCard(
                          title: 'Active Violations',
                          value: '$_activeViolations',
                          icon: Icons.warning,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _metricCard(
                          title: 'Extra Services',
                          value: '$_extraServiceRequests',
                          icon: Icons.miscellaneous_services,
                          color: Colors.green,
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
              iconColor: Colors.teal,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _actionCard(
                          title: 'Power Washing / Sanitation',
                          subtitle: 'Request scheduled service',
                          icon: Icons.water_drop,
                          color: Colors.blue,
                          onTap: () {
                            _showMessage('Opening sanitation requests...');
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _actionCard(
                          title: 'Dumpster / Cleanup',
                          subtitle: 'Request cleanup service',
                          icon: Icons.delete_outline,
                          color: Colors.green,
                          onTap: () {
                            _showMessage('Opening cleanup requests...');
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
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'Signed in as: $_email',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade800,
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