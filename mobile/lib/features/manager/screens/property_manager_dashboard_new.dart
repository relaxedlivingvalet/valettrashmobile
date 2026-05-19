import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/bento_card.dart';
import '../../../core/widgets/metric_tile.dart';
import '../../auth/screens/change_password_screen.dart';
import '../../../core/widgets/glow_badge.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/role_bottom_nav.dart';
import '../../../core/widgets/skeleton_card.dart';
import 'pm_compliance_report_screen.dart';
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

  int _tabIndex = 0;

  List<Map<String, dynamic>> _properties = [];
  List<Map<String, dynamic>> _inviteCodes = [];
  // ignore: unused_field
  List<Map<String, dynamic>> _recentRuns = [];
  // ignore: unused_field
  String? _firstName;
  double _avgSatisfaction = 0;
  double _serviceCompliance = 0; // 0.0 – 1.0
  int _openRequestsCount = 0;
  List<Map<String, dynamic>> _recentAnnouncements = [];

  AppColorsScheme _c = AppColorsScheme.dark;

  // ignore: unused_element
  int get _totalUnits =>
      _properties.fold(0, (s, p) => s + (p['unit_count'] as int? ?? 0));
  // ignore: unused_element
  int get _totalResidents =>
      _properties.fold(0, (s, p) => s + (p['resident_count'] as int? ?? 0));
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _c = context.roleColors;
  }

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
        .filter('building_id', 'in', '(${buildingIds.join(',')})');
    final floorIds = (floors as List)
        .map((f) => f['id']?.toString())
        .whereType<String>()
        .toList();
    if (floorIds.isEmpty) return 0;

    final units = await client
        .from('units')
        .select('id')
        .filter('floor_id', 'in', '(${floorIds.join(',')})')
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
        .filter('building_id', 'in', '(${buildingIds.join(',')})');
    final floorIds = (floors as List)
        .map((f) => f['id']?.toString())
        .whereType<String>()
        .toList();
    if (floorIds.isEmpty) return [];

    final units = await client
        .from('units')
        .select('id')
        .filter('floor_id', 'in', '(${floorIds.join(',')})')
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
      // Profile name
      try {
        final profile = await client
            .from('users')
            .select('first_name')
            .eq('id', uid)
            .maybeSingle();
        if (profile != null) _firstName = profile['first_name']?.toString();
      } catch (_) {}

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

        final results = await Future.wait(<Future<dynamic>>[
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
              .filter('unit_id', 'in', '(${unitIds.join(',')})')
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

      // Load recent runs, satisfaction, compliance for assigned properties
      List<Map<String, dynamic>> recentRuns = [];
      double avgSatisfaction = 0;
      double serviceCompliance = 0;
      int openRequestsCount = 0;
      List<Map<String, dynamic>> recentAnnouncements = [];
      final allPropIds = properties.map((p) => p['id'] as String).toList();
      if (allPropIds.isNotEmpty) {
        try {
          final runs = await client
              .from('nightly_runs')
              .select('id, run_date, status, completed_units, total_units, properties(name)')
              .filter('property_id', 'in', '(${allPropIds.join(',')})')
              .order('run_date', ascending: false)
              .limit(5);
          recentRuns = List<Map<String, dynamic>>.from(runs as List);

          // Compliance: % of completed runs out of total recent runs
          if (recentRuns.isNotEmpty) {
            final completed = recentRuns.where((r) => r['status'] == 'completed').length;
            serviceCompliance = completed / recentRuns.length;
          }
        } catch (_) {}
        try {
          final ratings = await client
              .from('satisfaction_ratings')
              .select('rating')
              .filter('property_id', 'in', '(${allPropIds.join(',')})');
          final ratingList = (ratings as List);
          if (ratingList.isNotEmpty) {
            final sum = ratingList.fold<double>(
                0, (acc, r) => acc + (r['rating'] as int? ?? 0).toDouble());
            avgSatisfaction = sum / ratingList.length;
          }
        } catch (_) {}

        // Open requests: pending comeback requests for PM's properties
        try {
          final openReqs = await client
              .from('missed_pickup_requests')
              .select('id')
              .eq('status', 'pending');
          openRequestsCount = (openReqs as List).length;
        } catch (_) {}

        // Recent announcements for PM's properties
        try {
          final announcements = await client
              .from('community_announcements')
              .select('id, title, body, created_at, property_id')
              .filter('property_id', 'in', '(${allPropIds.join(',')})')
              .order('created_at', ascending: false)
              .limit(3);
          recentAnnouncements = List<Map<String, dynamic>>.from(announcements as List);
        } catch (_) {}
      }

      setState(() {
        _properties = properties;
        _inviteCodes = allInviteCodes;
        _recentRuns = recentRuns;
        _avgSatisfaction = avgSatisfaction;
        _serviceCompliance = serviceCompliance;
        _openRequestsCount = openRequestsCount;
        _recentAnnouncements = recentAnnouncements;
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

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _c.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _buildTab()),
            RoleBottomNav(
              currentIndex: _tabIndex,
              onTap: (i) => setState(() => _tabIndex = i),
              accent: AppColors.manager,
              items: const [
                RoleNavItem(icon: Icons.grid_view_outlined, activeIcon: Icons.grid_view, label: 'Dashboard'),
                RoleNavItem(icon: Icons.apartment_outlined, activeIcon: Icons.apartment, label: 'Properties'),
                RoleNavItem(icon: Icons.inbox_outlined, activeIcon: Icons.inbox, label: 'Requests'),
                RoleNavItem(icon: Icons.more_horiz, activeIcon: Icons.more_horiz, label: 'More'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab() {
    switch (_tabIndex) {
      case 0:
        return _buildDashboardTab();
      case 1:
        return _buildPropertiesTab();
      case 2:
        return _buildRequestsTab();
      default:
        return _buildMoreTab();
    }
  }

  // ── Dashboard tab ─────────────────────────────────────────────────────────────

  Widget _buildDashboardTab() {
    if (_loading) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        children: [
          SkeletonCard(height: 128),
          SizedBox(height: 12),
          SkeletonCard(height: 60),
          SizedBox(height: 16),
          SkeletonCard(height: 110),
          SizedBox(height: 16),
          SkeletonCard(height: 110),
        ],
      );
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GlowBadge(label: _error!, accent: AppColors.error, showDot: false),
            const SizedBox(height: 16),
            TextButton(onPressed: _loadData, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (_properties.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.apartment_outlined, size: 56, color: _c.textMuted),
            SizedBox(height: 16),
            Text(
              'No properties assigned',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _c.textPrimary),
            ),
            SizedBox(height: 8),
            Text(
              'A super admin must assign you to a property.',
              style: TextStyle(fontSize: 13, color: _c.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.rlvBlue,
      backgroundColor: _c.surface1,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Property Manager View',
                style: GoogleFonts.montserrat(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: _c.textPrimary,
                ),
              ),
              _buildAllPropertiesPill(),
            ],
          ),
          const SizedBox(height: 20),
          // Open Requests card
          _buildRequestCard(
            label: 'Open Requests',
            count: _openRequestsCount,
            linkLabel: 'View all',
            onTap: () => setState(() => _tabIndex = 2),
            countColor: _openRequestsCount > 0 ? AppColors.warning : AppColors.rlvBlue,
          ),
          const SizedBox(height: 12),
          // Work Orders card (placeholder — no work_orders table yet)
          _buildRequestCard(
            label: 'Work Orders',
            count: 0,
            linkLabel: 'In Progress',
            onTap: null,
            countColor: _c.textPrimary,
          ),
          const SizedBox(height: 20),
          // Announcements section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ANNOUNCEMENTS',
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                  color: _c.textSecondary,
                ),
              ),
              if (_recentAnnouncements.isNotEmpty)
                TextButton(
                  onPressed: _showAnnouncementSheet,
                  style: TextButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: EdgeInsets.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'New +',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.rlvBlue),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (_recentAnnouncements.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _c.surface1,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _c.border),
              ),
              child: Row(
                children: [
                  Icon(Icons.campaign_outlined, size: 20, color: _c.textSecondary),
                  const SizedBox(width: 12),
                  Text(
                    'No announcements yet',
                    style: GoogleFonts.inter(fontSize: 13, color: _c.textSecondary),
                  ),
                ],
              ),
            )
          else
            ..._recentAnnouncements.map((a) => _buildAnnouncementRow(a)),
          const SizedBox(height: 20),
          // Send Announcement button
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _showAnnouncementSheet,
              icon: const Icon(Icons.campaign_outlined),
              label: Text(
                'Send Community Announcement',
                style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.rlvBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
          ),
          // Compliance / satisfaction metrics
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: BentoCard(
                  height: 90,
                  child: MetricTile(
                    label: 'Compliance',
                    value: '${(_serviceCompliance * 100).toStringAsFixed(0)}%',
                    valueColor: _serviceCompliance >= 0.9
                        ? AppColors.success
                        : _serviceCompliance >= 0.7
                            ? AppColors.warning
                            : AppColors.error,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: BentoCard(
                  height: 90,
                  child: MetricTile(
                    label: 'Satisfaction',
                    value: _avgSatisfaction > 0 ? _avgSatisfaction.toStringAsFixed(1) : '--',
                    valueColor: _avgSatisfaction >= 4
                        ? AppColors.success
                        : _avgSatisfaction >= 3
                            ? AppColors.warning
                            : _avgSatisfaction > 0
                                ? AppColors.error
                                : _c.textPrimary,
                    subtitle: _avgSatisfaction > 0 ? '/ 5.0' : 'No ratings',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAllPropertiesPill() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _c.surface1,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _c.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'All Properties',
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _c.textPrimary,
            ),
          ),
          const SizedBox(width: 4),
          Icon(Icons.keyboard_arrow_down, size: 16, color: _c.textSecondary),
        ],
      ),
    );
  }

  Widget _buildRequestCard({
    required String label,
    required int count,
    required String linkLabel,
    required VoidCallback? onTap,
    required Color countColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: _c.surface1,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _c.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.inter(fontSize: 13, color: _c.textSecondary)),
                const SizedBox(height: 2),
                Text(
                  '$count',
                  style: GoogleFonts.montserrat(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: countColor,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
          if (onTap != null)
            TextButton(
              onPressed: onTap,
              style: TextButton.styleFrom(
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text('$linkLabel ›', style: GoogleFonts.inter(fontSize: 13, color: AppColors.rlvBlue)),
            )
          else
            Text(linkLabel, style: GoogleFonts.inter(fontSize: 13, color: _c.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildAnnouncementRow(Map<String, dynamic> a) {
    final title = a['title']?.toString() ?? '';
    final body = a['body']?.toString() ?? '';
    final createdAt = a['created_at']?.toString() ?? '';
    String dateLabel = '';
    try {
      final dt = DateTime.parse(createdAt).toLocal();
      dateLabel = '${dt.month}/${dt.day}';
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _c.surface1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _c.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _c.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (body.isNotEmpty)
                  Text(
                    body,
                    style: GoogleFonts.inter(fontSize: 11, color: _c.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (dateLabel.isNotEmpty) ...[
            const SizedBox(width: 8),
            Text(dateLabel, style: GoogleFonts.inter(fontSize: 11, color: _c.textSecondary)),
          ],
        ],
      ),
    );
  }

  Future<void> _showAnnouncementSheet() async {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    String? selectedPropertyId =
        _properties.isNotEmpty ? _properties.first['id'] as String? : null;
    bool sending = false;

    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface1,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 28,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text('Send Announcement',
                  style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary)),
              const SizedBox(height: 4),
              Text('Residents will see this in their Community Updates feed',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 16),
              if (_properties.length > 1) ...[
                DropdownButtonFormField<String>(
                  initialValue: selectedPropertyId,
                  dropdownColor: AppColors.surface2,
                  style: GoogleFonts.inter(
                      color: AppColors.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    labelText: 'Property',
                    labelStyle: GoogleFonts.inter(
                        color: AppColors.textSecondary, fontSize: 13),
                    filled: true,
                    fillColor: AppColors.surface2,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                  items: _properties
                      .map((p) => DropdownMenuItem<String>(
                            value: p['id'] as String?,
                            child: Text(p['name']?.toString() ?? ''),
                          ))
                      .toList(),
                  onChanged: (v) => setModal(() => selectedPropertyId = v),
                ),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: titleCtrl,
                style: GoogleFonts.inter(
                    color: AppColors.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Title',
                  labelStyle: GoogleFonts.inter(
                      color: AppColors.textSecondary, fontSize: 13),
                  filled: true,
                  fillColor: AppColors.surface2,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: bodyCtrl,
                maxLines: 4,
                style: GoogleFonts.inter(
                    color: AppColors.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  labelText: 'Message',
                  labelStyle: GoogleFonts.inter(
                      color: AppColors.textSecondary, fontSize: 13),
                  filled: true,
                  fillColor: AppColors.surface2,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: sending
                      ? null
                      : () async {
                          final title = titleCtrl.text.trim();
                          final body = bodyCtrl.text.trim();
                          if (title.isEmpty || body.isEmpty) return;
                          setModal(() => sending = true);
                          try {
                            final uid = Supabase.instance.client.auth
                                .currentUser?.id;
                            await Supabase.instance.client
                                .from('community_announcements')
                                .insert({
                              'property_id': selectedPropertyId,
                              'title': title,
                              'body': body,
                              'sent_by': uid,
                            });
                            if (ctx.mounted) Navigator.pop(ctx);
                            _snack('Announcement sent!');
                          } catch (e) {
                            setModal(() => sending = false);
                            _snack('Failed to send: $e');
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.rlvBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: sending
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation(Colors.white)),
                        )
                      : Text('Send Announcement',
                          style: GoogleFonts.montserrat(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    titleCtrl.dispose();
    bodyCtrl.dispose();
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: AppColors.surface1,
      content: Text(msg, style: const TextStyle(color: AppColors.textPrimary)),
    ));
  }

  // ignore: unused_element
  Widget _buildPropertyCard(Map<String, dynamic> p) {
    final violations = p['violation_count'] as int? ?? 0;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _c.surface1,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _c.border),
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
                      p['name']?.toString() ?? 'Property',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _c.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      p['service_window']?.toString() ?? '--',
                      style: TextStyle(
                        fontSize: 12,
                        color: _c.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (violations > 0)
                GlowBadge(
                  label: '$violations violations',
                  accent: AppColors.error,
                  showDot: true,
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _miniStat(
                    '${p['unit_count'] ?? 0}', 'Units', AppColors.info),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _miniStat(
                    '${p['resident_count'] ?? 0}', 'Residents', AppColors.manager),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _miniStat(
                    '${p['claimed_count'] ?? 0}/${p['invite_count'] ?? 0}',
                    'Codes',
                    AppColors.warning),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openNotificationSender(
                    propertyId: p['id']?.toString(),
                    mode: 'property',
                  ),
                  icon: const Icon(Icons.campaign_outlined, size: 16),
                  label: const Text('Alert All'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.manager,
                    side: BorderSide(color: _c.border),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openNotificationSender(
                    propertyId: p['id']?.toString(),
                    mode: 'user',
                  ),
                  icon: const Icon(Icons.person_outline, size: 16),
                  label: const Text('1 Resident'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _c.textSecondary,
                    side: BorderSide(color: _c.border),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 7,
              fontWeight: FontWeight.w700,
              color: _c.textMuted,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  // ── Properties tab ───────────────────────────────────────────────────────────

  Widget _buildPropertiesTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Property Services',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: _c.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              GlowBadge(
                label: '${_properties.length} properties',
                accent: AppColors.manager,
                showDot: false,
              ),
            ],
          ),
        ),
        if (_loading)
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                SkeletonCard(height: 66),
                SizedBox(height: 10),
                SkeletonCard(height: 66),
                SizedBox(height: 10),
                SkeletonCard(height: 66),
              ],
            ),
          )
        else if (_inviteCodes.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.vpn_key_outlined,
                      size: 48, color: _c.textMuted),
                  SizedBox(height: 12),
                  Text(
                    'No invite codes issued yet',
                    style:
                        TextStyle(color: _c.textMuted, fontSize: 14),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadData,
              color: AppColors.manager,
              backgroundColor: _c.surface1,
              child: ListView.separated(
                padding:
                    const EdgeInsets.fromLTRB(20, 0, 20, 20),
                itemCount: _inviteCodes.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, i) =>
                    _buildCodeCard(_inviteCodes[i]),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCodeCard(Map<String, dynamic> item) {
    final isUsed = item['assigned_user_id'] != null;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _c.surface1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _c.border),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.manager.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.vpn_key_outlined,
                size: 18, color: AppColors.manager),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['code']?.toString() ?? '--',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _c.textPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item['property_name']?.toString() ?? '',
                  style: TextStyle(
                    fontSize: 11,
                    color: _c.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          GlowBadge(
            label: isUsed ? 'Claimed' : 'Active',
            accent: isUsed ? AppColors.success : AppColors.manager,
            showDot: !isUsed,
          ),
        ],
      ),
    );
  }

  // ── Requests tab ─────────────────────────────────────────────────────────────

  Widget _buildRequestsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Text(
            'Open Requests',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: _c.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            children: [
              BentoCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('MAINTENANCE',
                        style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                            color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    Text('Work Orders',
                        style: GoogleFonts.montserrat(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 4),
                    Text('Manage service requests and comeback items',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Alert All Residents',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const SimpleNotificationSenderScreen(
                            initialMode: 'property'),
                  ),
                ),
                accent: AppColors.manager,
                icon: Icons.campaign_outlined,
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        const SimpleNotificationSenderScreen(
                            initialMode: 'user'),
                  ),
                ),
                icon: const Icon(Icons.person_outline, size: 18),
                label: const Text('Notify Specific Resident'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _c.textSecondary,
                  side: BorderSide(color: _c.border),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── More tab ───────────────────────────────────────────────────────────────

  Widget _buildMoreTab() {
    final initial = _email.isNotEmpty ? _email[0].toUpperCase() : 'M';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Text(
            'More',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: _c.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _c.surface1,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: _c.border),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.manager.withValues(alpha: 0.15),
                      child: Text(
                        initial,
                        style: TextStyle(
                          color: AppColors.manager,
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _email,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: _c.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_properties.length} propert${_properties.length == 1 ? 'y' : 'ies'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: _c.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GlowBadge(
                      label: 'PM',
                      accent: AppColors.manager,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text('REPORTS',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _c.textMuted,
                      letterSpacing: 1.2)),
              const SizedBox(height: 10),
              ..._properties.map((p) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      tileColor: _c.surface1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: _c.border),
                      ),
                      leading: const Icon(Icons.bar_chart_outlined,
                          color: AppColors.manager, size: 22),
                      title: Text(p['name']?.toString() ?? '',
                          style: TextStyle(
                              color: _c.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                      subtitle: Text('Service history & SLA',
                          style: TextStyle(
                              color: _c.textSecondary, fontSize: 12)),
                      trailing: Icon(Icons.chevron_right,
                          color: _c.textMuted, size: 20),
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => PmComplianceReportScreen(
                                    propertyId: p['id']?.toString() ?? '',
                                    propertyName:
                                        p['name']?.toString() ?? '',
                                  ))),
                    ),
                  )),
              const SizedBox(height: 12),
              PrimaryButton(
                label: 'Change Password',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ChangePasswordScreen()),
                ),
                accent: AppColors.info,
                icon: Icons.lock_reset_outlined,
              ),
              const SizedBox(height: 10),
              PrimaryButton(
                label: 'Sign Out',
                onPressed: _signOut,
                accent: AppColors.error,
              ),
            ],
          ),
        ),
      ],
    );
  }

}
