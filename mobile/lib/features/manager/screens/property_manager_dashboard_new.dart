import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'simple_notification_sender_screen.dart';

class PropertyManagerDashboardNewScreen extends StatefulWidget {
  const PropertyManagerDashboardNewScreen({super.key});

  @override
  State<PropertyManagerDashboardNewScreen> createState() =>
      _PropertyManagerDashboardNewScreenState();
}

class _PropertyManagerDashboardNewScreenState
    extends State<PropertyManagerDashboardNewScreen> {
  bool _loading = true;
  String? _error;
  String _email = '';

  List<Map<String, dynamic>> _properties = [];
  List<Map<String, dynamic>> _inviteCodes = [];

  int get _totalUnits =>
      _properties.fold(0, (s, p) => s + (p['unit_count'] as int? ?? 0));
  int get _totalResidents =>
      _properties.fold(0, (s, p) => s + (p['resident_count'] as int? ?? 0));
  int get _totalViolations =>
      _properties.fold(0, (s, p) => s + (p['violation_count'] as int? ?? 0));
  int get _totalComebacks =>
      _properties.fold(0, (s, p) => s + (p['comeback_count'] as int? ?? 0));
  int get _claimedCodes =>
      _inviteCodes.where((c) => c['assigned_user_id'] != null).length;

  @override
  void initState() {
    super.initState();
    _email =
        Supabase.instance.client.auth.currentUser?.email ?? '';
    _loadData();
  }

  Future<int> _unitCountForProperty(String propertyId) async {
    final client = Supabase.instance.client;
    final buildings = await client
        .from('buildings')
        .select('id')
        .eq('property_id', propertyId);
    final buildingIds = (buildings as List)
        .map((b) => b['id']?.toString())
        .whereType<String>()
        .toList();
    if (buildingIds.isEmpty) return 0;

    final floors = await client
        .from('floors')
        .select('id')
        .inFilter('building_id', buildingIds);
    final floorIds = (floors as List)
        .map((f) => f['id']?.toString())
        .whereType<String>()
        .toList();
    if (floorIds.isEmpty) return 0;

    final units = await client
        .from('units')
        .select('id')
        .inFilter('floor_id', floorIds)
        .eq('is_active', true);
    return (units as List).length;
  }

  Future<List<String>> _unitIdsForProperty(String propertyId) async {
    final client = Supabase.instance.client;
    final buildings = await client
        .from('buildings')
        .select('id')
        .eq('property_id', propertyId);
    final buildingIds = (buildings as List)
        .map((b) => b['id']?.toString())
        .whereType<String>()
        .toList();
    if (buildingIds.isEmpty) return [];

    final floors = await client
        .from('floors')
        .select('id')
        .inFilter('building_id', buildingIds);
    final floorIds = (floors as List)
        .map((f) => f['id']?.toString())
        .whereType<String>()
        .toList();
    if (floorIds.isEmpty) return [];

    final units = await client
        .from('units')
        .select('id')
        .inFilter('floor_id', floorIds)
        .eq('is_active', true);
    return (units as List)
        .map((u) => u['id']?.toString())
        .whereType<String>()
        .toList();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final client = Supabase.instance.client;
    final uid = client.auth.currentUser?.id;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final userPropsRows = await client
          .from('user_properties')
          .select(
            'property_id, properties(id, name, service_window_start, service_window_end, is_active)',
          )
          .eq('user_id', uid);

      final rows = List<Map<String, dynamic>>.from(userPropsRows as List);
      final List<Map<String, dynamic>> properties = [];
      final List<Map<String, dynamic>> allInviteCodes = [];

      for (final row in rows) {
        final propData = row['properties'];
        if (propData is! Map) continue;
        final propId = propData['id']?.toString() ?? '';
        final propName = propData['name']?.toString() ?? '';

        final results = await Future.wait([
          client
              .from('resident_units')
              .select('id')
              .eq('property_id', propId)
              .eq('is_active', true),
          client
              .from('invite_codes')
              .select('id, code, unit_id, assigned_user_id, use_count, max_uses')
              .eq('property_id', propId)
              .order('created_at', ascending: false)
              .limit(10),
          _unitCountForProperty(propId),
          _unitIdsForProperty(propId),
        ]);

        final residentCount = (results[0] as List).length;
        final propInvites =
            List<Map<String, dynamic>>.from(results[1] as List);
        final unitCount = results[2] as int;
        final unitIds = results[3] as List<String>;

        int violationCount = 0;
        int comebackCount = 0;
        if (unitIds.isNotEmpty) {
          final violations = await client
              .from('violations')
              .select('id')
              .inFilter('unit_id', unitIds)
              .eq('status', 'pending');
          violationCount = (violations as List).length;
        }

        final sw = propData['service_window_start'] ?? '18:00';
        final ew = propData['service_window_end'] ?? '22:00';

        properties.add({
          'id': propId,
          'name': propName,
          'service_window': '${_fmtTime(sw)} – ${_fmtTime(ew)}',
          'unit_count': unitCount,
          'resident_count': residentCount,
          'violation_count': violationCount,
          'comeback_count': comebackCount,
          'invite_count': propInvites.length,
          'claimed_count': propInvites
              .where((c) => c['assigned_user_id'] != null)
              .length,
        });

        for (final ic in propInvites.take(6)) {
          allInviteCodes.add({...ic, 'property_id': propId, 'property_name': propName});
        }
      }

      setState(() {
        _properties = properties;
        _inviteCodes = allInviteCodes;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _fmtTime(dynamic t) {
    if (t == null) return '--';
    final parts = t.toString().split(':');
    if (parts.length < 2) return t.toString();
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    final ap = h >= 12 ? 'PM' : 'AM';
    var h12 = h % 12;
    if (h12 == 0) h12 = 12;
    return '$h12:${m.toString().padLeft(2, '0')} $ap';
  }

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _openNotificationSender({String? propertyId, String mode = 'property'}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SimpleNotificationSenderScreen(
          initialPropertyId: propertyId,
          initialMode: mode,
        ),
      ),
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
            Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _inviteCodeRow(Map<String, dynamic> item) {
    final isUsed = item['assigned_user_id'] != null;
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
              '${item['property_name'] ?? ''}  •  ${item['code'] ?? ''}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isUsed ? Colors.green.shade50 : Colors.orange.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isUsed
                    ? Colors.green.shade200
                    : Colors.orange.shade200,
              ),
            ),
            child: Text(
              isUsed ? 'Used' : 'Active',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isUsed
                    ? Colors.green.shade700
                    : Colors.orange.shade700,
              ),
            ),
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
            onPressed: _loading ? null : _loadData,
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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline,
                            color: Colors.red, size: 48),
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
              : _properties.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.apartment,
                              size: 64, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            'No properties assigned yet.',
                            style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'A super admin must assign you to a property.',
                            style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            // Portfolio overview
                            _sectionCard(
                              title: 'Portfolio Overview',
                              icon: Icons.apartment,
                              iconColor: Colors.indigo,
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _metricCard(
                                          title: 'Properties',
                                          value: '${_properties.length}',
                                          icon: Icons.business,
                                          color: Colors.indigo,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _metricCard(
                                          title: 'Total Units',
                                          value: '$_totalUnits',
                                          icon: Icons.meeting_room,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _metricCard(
                                          title: 'Verified Residents',
                                          value: '$_totalResidents',
                                          icon: Icons.people,
                                          color: Colors.green,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _metricCard(
                                          title: 'Pending Violations',
                                          value: '$_totalViolations',
                                          icon: Icons.warning,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _metricCard(
                                          title: 'Codes Issued',
                                          value:
                                              '${_inviteCodes.length}',
                                          icon: Icons.vpn_key,
                                          color: Colors.orange,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: _metricCard(
                                          title: 'Codes Used',
                                          value: '$_claimedCodes',
                                          icon: Icons.check_circle,
                                          color: Colors.teal,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Per-property breakdown
                            ..._properties.map((p) => Padding(
                                  padding: const EdgeInsets.only(bottom: 24),
                                  child: _sectionCard(
                                    title: p['name'] ?? 'Property',
                                    icon: Icons.apartment,
                                    iconColor: Colors.indigo,
                                    child: Column(
                                      children: [
                                        _metricCard(
                                          title: 'Service Window',
                                          value:
                                              p['service_window'] ?? '--',
                                          icon: Icons.access_time,
                                          color: Colors.blue,
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _metricCard(
                                                title: 'Units',
                                                value:
                                                    '${p['unit_count'] ?? 0}',
                                                icon: Icons.home,
                                                color: Colors.blue,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: _metricCard(
                                                title: 'Residents',
                                                value:
                                                    '${p['resident_count'] ?? 0}',
                                                icon: Icons.people,
                                                color: Colors.green,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _metricCard(
                                                title: 'Violations',
                                                value:
                                                    '${p['violation_count'] ?? 0}',
                                                icon: Icons.warning,
                                                color: Colors.red,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: _metricCard(
                                                title: 'Codes Used',
                                                value:
                                                    '${p['claimed_count'] ?? 0} / ${p['invite_count'] ?? 0}',
                                                icon: Icons.vpn_key,
                                                color: Colors.orange,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: _actionCard(
                                                title: 'Alert All Residents',
                                                subtitle:
                                                    'Notify entire property',
                                                icon: Icons.campaign,
                                                color: Colors.blue,
                                                onTap: () =>
                                                    _openNotificationSender(
                                                  propertyId: p['id']
                                                      ?.toString(),
                                                  mode: 'property',
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: _actionCard(
                                                title: 'Alert Resident',
                                                subtitle: 'Send to one user',
                                                icon: Icons.person,
                                                color: Colors.purple,
                                                onTap: () =>
                                                    _openNotificationSender(
                                                  propertyId: p['id']
                                                      ?.toString(),
                                                  mode: 'user',
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                )),

                            // Invite codes
                            if (_inviteCodes.isNotEmpty) ...[
                              _sectionCard(
                                title: 'Invite Codes',
                                icon: Icons.key,
                                iconColor: Colors.orange,
                                child: Column(
                                  children: _inviteCodes
                                      .map(_inviteCodeRow)
                                      .toList(),
                                ),
                              ),
                              const SizedBox(height: 24),
                            ],

                            // Footer
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
                    ),
    );
  }
}
