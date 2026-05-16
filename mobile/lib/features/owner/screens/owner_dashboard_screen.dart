import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/brand_colors.dart';
import '../../manager/screens/simple_notification_sender_screen.dart';
import '../../manager/screens/manager_dashboard_screen.dart';
import '../../worker/screens/worker_dashboard_screen.dart';
import '../../resident/screens/resident_dashboard_screen.dart';

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  bool _loading = true;
  String? _error;
  String _email = '';

  List<Map<String, dynamic>> _properties = [];

  int get _totalProperties => _properties.length;
  int get _totalUnits =>
      _properties.fold(0, (s, p) => s + (p['unit_count'] as int? ?? 0));
  int get _totalResidents =>
      _properties.fold(0, (s, p) => s + (p['resident_count'] as int? ?? 0));
  int get _totalInvitesIssued =>
      _properties.fold(0, (s, p) => s + (p['invite_count'] as int? ?? 0));
  int get _totalInvitesUsed =>
      _properties.fold(0, (s, p) => s + (p['claimed_count'] as int? ?? 0));

  @override
  void initState() {
    super.initState();
    _email = Supabase.instance.client.auth.currentUser?.email ?? '';
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

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final client = Supabase.instance.client;

    try {
      final propsRows = await client
          .from('properties')
          .select('id, name, service_window_start, service_window_end, is_active, city, state')
          .eq('is_active', true)
          .order('name');

      final rows = List<Map<String, dynamic>>.from(propsRows as List);
      final List<Map<String, dynamic>> properties = [];

      await Future.wait(rows.map((prop) async {
        final propId = prop['id']?.toString() ?? '';
        final propName = prop['name']?.toString() ?? '';

        final results = await Future.wait([
          client
              .from('resident_units')
              .select('id')
              .eq('property_id', propId)
              .eq('is_active', true),
          client
              .from('invite_codes')
              .select('id, assigned_user_id')
              .eq('property_id', propId),
          _unitCountForProperty(propId),
        ]);

        final residentCount = (results[0] as List).length;
        final invites = List<Map<String, dynamic>>.from(results[1] as List);
        final unitCount = results[2] as int;
        final claimedCount =
            invites.where((i) => i['assigned_user_id'] != null).length;

        final sw = prop['service_window_start'] ?? '18:00';
        final ew = prop['service_window_end'] ?? '22:00';

        properties.add({
          'id': propId,
          'name': propName,
          'location': '${prop['city'] ?? ''}, ${prop['state'] ?? ''}',
          'service_window': '${_fmtTime(sw)} – ${_fmtTime(ew)}',
          'unit_count': unitCount,
          'resident_count': residentCount,
          'invite_count': invites.length,
          'claimed_count': claimedCount,
          'unclaimed_count': unitCount - residentCount,
        });
      }));

      // Sort by name
      properties.sort((a, b) =>
          (a['name'] as String).compareTo(b['name'] as String));

      setState(() => _properties = properties);
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

  Widget _metricCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
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
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _propertyCard(Map<String, dynamic> p) {
    final unitCount = p['unit_count'] as int? ?? 0;
    final residentCount = p['resident_count'] as int? ?? 0;
    final pct = unitCount > 0
        ? (residentCount / unitCount * 100).toStringAsFixed(1)
        : '0.0';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
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
                Expanded(
                  child: Text(
                    p['name'] ?? '',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Text(
                    '$pct% active',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.green.shade700,
                    ),
                  ),
                ),
              ],
            ),
            if ((p['location'] as String? ?? '').trim().isNotEmpty &&
                p['location'] != ', ')
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  p['location'] ?? '',
                  style: TextStyle(
                      fontSize: 13, color: Colors.grey.shade600),
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                _propStat(Icons.home, 'Units', '${p['unit_count'] ?? 0}'),
                const SizedBox(width: 16),
                _propStat(Icons.people, 'Residents',
                    '${p['resident_count'] ?? 0}'),
                const SizedBox(width: 16),
                _propStat(Icons.vpn_key, 'Codes Used',
                    '${p['claimed_count'] ?? 0} / ${p['invite_count'] ?? 0}'),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Service: ${p['service_window'] ?? '--'}',
              style: TextStyle(
                  fontSize: 13, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SimpleNotificationSenderScreen(
                      initialPropertyId: p['id']?.toString(),
                      initialMode: 'property',
                    ),
                  ),
                ),
                icon: const Icon(Icons.campaign, size: 16),
                label: const Text('Alert All Residents'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.indigo,
                  side: const BorderSide(color: Colors.indigo),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _propStat(IconData icon, String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: Colors.grey.shade500),
              const SizedBox(width: 4),
              Text(label,
                  style: TextStyle(
                      fontSize: 11, color: Colors.grey.shade600)),
            ],
          ),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Owner Dashboard'),
        backgroundColor: Colors.blue,
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
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Portfolio Overview
                        Card(
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
                                        color: BrandColors.primaryBlue
                                            .withOpacity(0.1),
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      child: Icon(Icons.business,
                                          color: BrandColors.primaryBlue,
                                          size: 24),
                                    ),
                                    const SizedBox(width: 16),
                                    const Expanded(
                                      child: Text(
                                        'Portfolio Overview',
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
                                      child: _metricCard(
                                        'Properties',
                                        '$_totalProperties',
                                        Icons.apartment,
                                        BrandColors.primaryBlue,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _metricCard(
                                        'Total Units',
                                        '$_totalUnits',
                                        Icons.home,
                                        Colors.blue,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _metricCard(
                                        'Residents',
                                        '$_totalResidents',
                                        Icons.people,
                                        Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _metricCard(
                                        'Codes Issued',
                                        '$_totalInvitesIssued',
                                        Icons.vpn_key,
                                        Colors.orange,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _metricCard(
                                        'Codes Used',
                                        '$_totalInvitesUsed',
                                        Icons.check_circle,
                                        Colors.teal,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _metricCard(
                                        'Activation Rate',
                                        _totalUnits > 0
                                            ? '${(_totalResidents / _totalUnits * 100).toStringAsFixed(1)}%'
                                            : '—',
                                        Icons.trending_up,
                                        Colors.purple,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Per-property cards
                        const Text(
                          'Properties',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ..._properties.map(_propertyCard),

                        // Navigation
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
                                  'Switch View',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const ManagerDashboardScreen(),
                                          ),
                                        ),
                                        icon: const Icon(
                                            Icons.admin_panel_settings,
                                            size: 18),
                                        label: const Text('Manager'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              Colors.blue.shade600,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const WorkerDashboardScreen(),
                                          ),
                                        ),
                                        icon: const Icon(Icons.work, size: 18),
                                        label: const Text('Worker'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              Colors.orange.shade600,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const ResidentDashboardScreen(),
                                          ),
                                        ),
                                        icon: const Icon(Icons.home, size: 18),
                                        label: const Text('Resident'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              Colors.green.shade600,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                              vertical: 12),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),
                        Text(
                          'Signed in as: $_email',
                          style: TextStyle(
                              fontSize: 13, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }
}
