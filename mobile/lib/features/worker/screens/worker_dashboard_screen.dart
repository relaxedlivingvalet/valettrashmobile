import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/page_transitions.dart';
import '../../../core/widgets/glow_badge.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/role_bottom_nav.dart';
import '../../../core/widgets/role_hero_card.dart';
import '../../../core/widgets/skeleton_card.dart';
import '../../../core/widgets/stat_tile.dart';
import 'violation_report_screen.dart';

class WorkerDashboardScreen extends StatefulWidget {
  const WorkerDashboardScreen({super.key});

  @override
  State<WorkerDashboardScreen> createState() => _WorkerDashboardScreenState();
}

class _WorkerDashboardScreenState extends State<WorkerDashboardScreen> {
  int _tabIndex = 0;
  bool _loading = true;
  String _email = '';
  bool _isOnDuty = false;
  String _assignedProperty = 'No property assigned';
  String _assignedRoute = 'No active route';
  List<Map<String, dynamic>> _comebackRequests = [];
  Set<String> _propertyIds = {};

  @override
  void initState() {
    super.initState();
    _email = Supabase.instance.client.auth.currentUser?.email ?? '';
    _loadRouteData();
  }

  // ── Data ─────────────────────────────────────────────────────────────────────

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
      final assignList = List<Map<String, dynamic>>.from(assigns as List);
      final names = <String>[];
      final propertyIds = <String>{};
      for (final row in assignList) {
        final p = row['properties'];
        if (p is Map && p['name'] != null) names.add('${p['name']}');
        final pid = row['property_id']?.toString();
        if (pid != null) propertyIds.add(pid);
      }
      if (names.isNotEmpty) _assignedProperty = names.join(', ');
      _propertyIds = propertyIds;

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
              return u is Map ? u['unit_number']?.toString() : null;
            })
            .whereType<String>()
            .toList();
        _assignedRoute =
            '${routeList.first['name']}: ${nums.take(20).join(', ')}${nums.length > 20 ? '…' : ''}';
      }

      final rawComebacks = await client
          .from('missed_pickup_requests')
          .select(
              'id, status, requested_at, pickups(units(unit_number), nightly_runs(property_id))')
          .limit(80);
      final cbList = List<Map<String, dynamic>>.from(rawComebacks as List);
      _comebackRequests = [];
      for (final row in cbList) {
        final p = row['pickups'];
        if (p is! Map) continue;
        final nr = p['nightly_runs'];
        final propId = nr is Map ? nr['property_id']?.toString() : null;
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
    } catch (_) {
      _comebackRequests = [];
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
        }).eq('id', id);
      } catch (_) {}
    }
    if (mounted) {
      setState(() => _comebackRequests.removeAt(index));
      _snack('Comeback completed');
    }
  }

  Future<void> _signOut() async {
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _toggleDuty() {
    setState(() => _isOnDuty = !_isOnDuty);
    _snack(_isOnDuty ? 'You are now on duty' : 'You are now off duty');
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      backgroundColor: AppColors.surface1,
      content: Text(msg, style: const TextStyle(color: AppColors.textPrimary)),
    ));
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _buildTab()),
            RoleBottomNav(
              currentIndex: _tabIndex,
              onTap: (i) => setState(() => _tabIndex = i),
              accent: AppColors.worker,
              items: const [
                RoleNavItem(
                  icon: Icons.map_outlined,
                  activeIcon: Icons.map,
                  label: 'Route',
                ),
                RoleNavItem(
                  icon: Icons.replay_outlined,
                  activeIcon: Icons.replay,
                  label: 'Comebacks',
                ),
                RoleNavItem(
                  icon: Icons.warning_amber_outlined,
                  activeIcon: Icons.warning_amber,
                  label: 'Violations',
                ),
                RoleNavItem(
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  label: 'Profile',
                ),
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
        return _buildRouteTab();
      case 1:
        return _buildComebacksTab();
      case 2:
        return _buildViolationsTab();
      default:
        return _buildProfileTab();
    }
  }

  // ── Route ─────────────────────────────────────────────────────────────────────

  Widget _buildRouteTab() {
    if (_loading) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        children: const [
          SkeletonCard(height: 140),
          SizedBox(height: 12),
          SkeletonCard(height: 60),
          SizedBox(height: 16),
          SkeletonCard(height: 56),
        ],
      );
    }
    return RefreshIndicator(
      onRefresh: _loadRouteData,
      color: AppColors.worker,
      backgroundColor: AppColors.surface1,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        children: [
          RoleHeroCard(
            accent: AppColors.worker,
            eyebrow: "TONIGHT'S ROUTE",
            title: _assignedProperty,
            subtitle: _assignedRoute == 'No active route'
                ? 'No route assigned'
                : _assignedRoute.length > 60
                    ? '${_assignedRoute.substring(0, 60)}…'
                    : _assignedRoute,
            badgeLabel: _isOnDuty ? 'On Duty' : 'Off Duty',
            showDot: _isOnDuty,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              StatTile(
                value: '${_comebackRequests.length}',
                label: 'Comebacks',
                valueColor: _comebackRequests.isNotEmpty
                    ? AppColors.error
                    : null,
              ),
              const SizedBox(width: 8),
              StatTile(
                value: _isOnDuty ? 'Active' : 'Idle',
                label: 'Status',
                valueColor: _isOnDuty ? AppColors.worker : AppColors.textMuted,
              ),
            ],
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: _isOnDuty ? 'Clock Out' : 'Clock In',
            onPressed: _toggleDuty,
            accent: _isOnDuty ? AppColors.error : AppColors.worker,
            icon: _isOnDuty ? Icons.stop_circle_outlined : Icons.play_circle_outline,
          ),
          if (!_isOnDuty) ...[
            const SizedBox(height: 12),
            const Text(
              'Clock in to begin your route for tonight.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Comebacks ─────────────────────────────────────────────────────────────────

  Widget _buildComebacksTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'Comebacks',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              if (_comebackRequests.isNotEmpty)
                GlowBadge(
                  label: '${_comebackRequests.length} pending',
                  accent: AppColors.warning,
                  showDot: true,
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (_loading)
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: const [
                SkeletonCard(height: 70),
                SizedBox(height: 10),
                SkeletonCard(height: 70),
                SizedBox(height: 10),
                SkeletonCard(height: 70),
              ],
            ),
          )
        else if (_comebackRequests.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.check_circle_outline,
                      size: 48, color: AppColors.success),
                  SizedBox(height: 12),
                  Text(
                    'No comeback requests',
                    style: TextStyle(
                        color: AppColors.textMuted, fontSize: 14),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadRouteData,
              color: AppColors.worker,
              backgroundColor: AppColors.surface1,
              child: ListView.separated(
                padding:
                    const EdgeInsets.fromLTRB(20, 0, 20, 20),
                itemCount: _comebackRequests.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, i) =>
                    _buildComebackCard(i, _comebackRequests[i]),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildComebackCard(int index, Map<String, dynamic> req) {
    final unit = req['unit']?.toString() ?? '?';
    final time = req['time']?.toString() ?? '';
    final status = req['status']?.toString() ?? 'pending';
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.home_outlined,
              size: 20,
              color: AppColors.warning,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Unit $unit',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  time.length > 16 ? time.substring(0, 16) : time,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          if (status != 'completed')
            TextButton(
              onPressed: () => _completeComebackRequest(index),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.success,
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
              ),
              child: const Text(
                'Complete',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            )
          else
            GlowBadge(
              label: 'Done',
              accent: AppColors.success,
              showDot: false,
            ),
        ],
      ),
    );
  }

  // ── Violations ────────────────────────────────────────────────────────────────

  Widget _buildViolationsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Violations'),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            children: [
              RoleHeroCard(
                accent: AppColors.worker,
                eyebrow: 'DOCUMENTATION',
                title: 'Report a Violation',
                subtitle:
                    'Photograph and document rule violations per property policy',
                badgeLabel: 'Worker',
                showDot: false,
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Report Violation',
                onPressed: () => Navigator.push(
                  context,
                  SharedAxisPageRoute(
                    builder: (_) => const ViolationReportScreen(),
                  ),
                ),
                accent: AppColors.error,
                icon: Icons.camera_alt_outlined,
              ),
              const SizedBox(height: 12),
              const Text(
                'Document any rule violations with a photo, violation type, '
                'and unit number. Residents are notified automatically.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textMuted,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Profile ───────────────────────────────────────────────────────────────────

  Widget _buildProfileTab() {
    final initial = _email.isNotEmpty ? _email[0].toUpperCase() : 'W';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Profile'),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface1,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: AppColors.worker.withOpacity(0.15),
                      child: Text(
                        initial,
                        style: TextStyle(
                          color: AppColors.worker,
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
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _assignedProperty,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GlowBadge(
                      label: _isOnDuty ? 'On Duty' : 'Off Duty',
                      accent: _isOnDuty ? AppColors.worker : AppColors.textMuted,
                      showDot: _isOnDuty,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
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

  // ── Helpers ───────────────────────────────────────────────────────────────────

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
          letterSpacing: -0.5,
        ),
      ),
    );
  }
}
