import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/primary_button.dart';

/// Super admin: assign drivers to properties ([worker_assignments]).
class AdminWorkerAssignmentsScreen extends StatefulWidget {
  const AdminWorkerAssignmentsScreen({
    super.key,
    this.initialPropertyId,
    this.initialPropertyName,
  });

  /// Pre-select property when opened from Properties tab.
  final String? initialPropertyId;
  final String? initialPropertyName;

  @override
  State<AdminWorkerAssignmentsScreen> createState() =>
      _AdminWorkerAssignmentsScreenState();
}

class _AdminWorkerAssignmentsScreenState
    extends State<AdminWorkerAssignmentsScreen> {
  List<Map<String, dynamic>> _assignments = [];
  List<Map<String, dynamic>> _workers = [];
  List<Map<String, dynamic>> _properties = [];
  bool _loading = true;
  String? _error;

  String? _selectedWorkerId;
  String? _selectedPropertyId;

  @override
  void initState() {
    super.initState();
    _selectedPropertyId = widget.initialPropertyId;
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final client = Supabase.instance.client;
      final results = await Future.wait([
        client
            .from('worker_assignments')
            .select(
                'id, user_id, property_id, is_active, assigned_at, users(first_name, last_name, email), properties(name)')
            .eq('is_active', true)
            .order('assigned_at', ascending: false),
        client
            .from('users')
            .select('id, first_name, last_name, email')
            .eq('role', 'driver')
            .order('last_name'),
        client
            .from('properties')
            .select('id, name, is_active')
            .order('name'),
      ]);

      if (!mounted) return;
      setState(() {
        _assignments = List<Map<String, dynamic>>.from(results[0] as List);
        _workers = List<Map<String, dynamic>>.from(results[1] as List);
        _properties = List<Map<String, dynamic>>.from(results[2] as List);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _assign() async {
    final workerId = _selectedWorkerId;
    final propertyId = _selectedPropertyId;
    if (workerId == null || propertyId == null) {
      _snack('Select a worker and a property', error: true);
      return;
    }

    try {
      final client = Supabase.instance.client;

      final existing = await client
          .from('worker_assignments')
          .select('id, is_active')
          .eq('user_id', workerId)
          .eq('property_id', propertyId)
          .maybeSingle();

      if (existing != null) {
        await client
            .from('worker_assignments')
            .update({'is_active': true}).eq('id', existing['id']);
      } else {
        await client.from('worker_assignments').insert({
          'user_id': workerId,
          'property_id': propertyId,
          'is_active': true,
        });
      }

      if (!mounted) return;
      _snack('Worker assigned to property');
      setState(() {
        _selectedWorkerId = null;
        if (widget.initialPropertyId == null) {
          _selectedPropertyId = null;
        }
      });
      await _load();
    } catch (e) {
      if (!mounted) return;
      _snack('Assign failed: $e', error: true);
    }
  }

  Future<void> _removeAssignment(String id) async {
    try {
      await Supabase.instance.client
          .from('worker_assignments')
          .update({'is_active': false})
          .eq('id', id);
      await _load();
      if (!mounted) return;
      _snack('Assignment removed');
    } catch (e) {
      if (!mounted) return;
      _snack('Remove failed: $e', error: true);
    }
  }

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _workerLabel(Map<String, dynamic> w) {
    final name =
        '${w['first_name'] ?? ''} ${w['last_name'] ?? ''}'.trim();
    final email = w['email']?.toString() ?? '';
    if (name.isEmpty) return email;
    return email.isEmpty ? name : '$name · $email';
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColorsScheme.light;
    return Theme(
      data: AppTheme.light,
      child: Scaffold(
        backgroundColor: c.background,
        appBar: AppBar(
          title: Text('Worker Assignments',
              style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w700, color: c.textPrimary)),
          backgroundColor: c.surface1,
          foregroundColor: c.textPrimary,
          elevation: 0,
        ),
        body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildAssignForm(c),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(_error!,
                        style: const TextStyle(color: AppColors.error)),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                  child: Text(
                    'ACTIVE ASSIGNMENTS (${_assignments.length})',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: c.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _load,
                    child: _assignments.isEmpty
                        ? ListView(
                            children: [
                              const SizedBox(height: 40),
                              Icon(Icons.engineering_outlined,
                                  size: 48, color: c.textMuted),
                              const SizedBox(height: 12),
                              Text(
                                'No workers assigned yet',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                    color: c.textSecondary, fontSize: 14),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Use the form above to assign a driver to a property.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                    color: c.textMuted, fontSize: 12),
                              ),
                            ],
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                            itemCount: _assignments.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 8),
                            itemBuilder: (ctx, i) {
                              final a = _assignments[i];
                              final user = a['users'];
                              final name = user is Map
                                  ? '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'
                                      .trim()
                                  : 'Unknown driver';
                              final email = user is Map
                                  ? user['email']?.toString() ?? ''
                                  : '';
                              final prop = (a['properties'] is Map)
                                  ? a['properties']['name']?.toString() ?? '?'
                                  : '?';
                              return Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: c.surface1,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: c.border),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.badge_outlined,
                                        color: Color(0xFF6366F1), size: 22),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(name,
                                              style: TextStyle(
                                                  fontWeight: FontWeight.w700,
                                                  fontSize: 14,
                                                  color: c.textPrimary)),
                                          if (email.isNotEmpty)
                                            Text(email,
                                                style: TextStyle(
                                                    fontSize: 11,
                                                    color: c.textSecondary)),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(Icons.apartment,
                                                  size: 14,
                                                  color: c.textMuted),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(prop,
                                                    style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        color:
                                                            AppColors.manager)),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      tooltip: 'Remove assignment',
                                      icon: const Icon(
                                          Icons.remove_circle_outline,
                                          color: AppColors.error),
                                      onPressed: () => _removeAssignment(
                                          a['id'].toString()),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
      ),
    );
  }

  Widget _buildAssignForm(AppColorsScheme c) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface1,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Assign worker to property',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Drivers see assigned properties on their Route tab after login. Residents see ON DUTY when they clock in.',
            style: GoogleFonts.inter(fontSize: 12, color: c.textSecondary),
          ),
          const SizedBox(height: 16),
          _dropdown(
            c: c,
            label: 'Worker / Driver',
            hint: _workers.isEmpty
                ? 'No drivers — create user with Driver role first'
                : 'Select worker',
            value: _selectedWorkerId,
            items: _workers
                .map((w) => DropdownMenuItem(
                      value: w['id'].toString(),
                      child: Text(
                        _workerLabel(w),
                        style: GoogleFonts.inter(
                            fontSize: 14, color: c.textPrimary),
                      ),
                    ))
                .toList(),
            onChanged:
                _workers.isEmpty ? null : (v) => setState(() => _selectedWorkerId = v),
          ),
          const SizedBox(height: 12),
          _dropdown(
            c: c,
            label: 'Property',
            hint: _properties.isEmpty ? 'No properties' : 'Select property',
            value: _selectedPropertyId,
            items: _properties
                .map((p) => DropdownMenuItem(
                      value: p['id'].toString(),
                      child: Text(
                        p['is_active'] == false
                            ? '${p['name']} (inactive)'
                            : p['name'].toString(),
                        style: GoogleFonts.inter(
                            fontSize: 14, color: c.textPrimary),
                      ),
                    ))
                .toList(),
            onChanged: _properties.isEmpty
                ? null
                : (v) => setState(() => _selectedPropertyId = v),
          ),
          if (widget.initialPropertyName != null) ...[
            const SizedBox(height: 8),
            Text(
              'Pre-selected: ${widget.initialPropertyName}',
              style: GoogleFonts.inter(fontSize: 11, color: c.textMuted),
            ),
          ],
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Assign to property',
            accent: const Color(0xFF6366F1),
            icon: Icons.link,
            onPressed: (_selectedWorkerId != null && _selectedPropertyId != null)
                ? _assign
                : null,
          ),
        ],
      ),
    );
  }

  Widget _dropdown({
    required AppColorsScheme c,
    required String label,
    required String hint,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
            color: c.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: c.background,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: c.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              hint: Text(
                hint,
                style: GoogleFonts.inter(color: c.textMuted, fontSize: 14),
              ),
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: c.textPrimary,
              ),
              dropdownColor: c.surface1,
              iconEnabledColor: c.textSecondary,
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
