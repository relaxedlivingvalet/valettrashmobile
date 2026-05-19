import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/primary_button.dart';

/// Super admin: link property managers & operations managers to properties
/// via [user_properties]. Property managers may also set [properties.company_id].
class AdminManagerAssignmentsScreen extends StatefulWidget {
  const AdminManagerAssignmentsScreen({
    super.key,
    this.initialPropertyId,
    this.initialPropertyName,
  });

  final String? initialPropertyId;
  final String? initialPropertyName;

  @override
  State<AdminManagerAssignmentsScreen> createState() =>
      _AdminManagerAssignmentsScreenState();
}

class _AdminManagerAssignmentsScreenState
    extends State<AdminManagerAssignmentsScreen> {
  List<Map<String, dynamic>> _links = [];
  List<Map<String, dynamic>> _managers = [];
  List<Map<String, dynamic>> _properties = [];
  bool _loading = true;
  String? _error;

  String? _selectedManagerId;
  String? _selectedPropertyId;
  bool _setCompanyIdForPm = true;

  static const _roleLabels = {
    'property_manager': 'Property Manager',
    'operations_manager': 'Operations Manager',
  };

  @override
  void initState() {
    super.initState();
    _selectedPropertyId = widget.initialPropertyId;
    _load();
  }

  Map<String, dynamic>? get _selectedManager {
    if (_selectedManagerId == null) return null;
    for (final m in _managers) {
      if (m['id']?.toString() == _selectedManagerId) return m;
    }
    return null;
  }

  bool get _selectedIsPropertyManager =>
      _selectedManager?['role']?.toString() == 'property_manager';

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final client = Supabase.instance.client;
      final results = await Future.wait([
        client
            .from('user_properties')
            .select(
                'id, user_id, property_id, role, created_at, users(first_name, last_name, email, role), properties(name)')
            .order('created_at', ascending: false),
        client
            .from('users')
            .select('id, first_name, last_name, email, role')
            .filter('role', 'in', '(property_manager,operations_manager)')
            .order('last_name'),
        client
            .from('properties')
            .select('id, name, is_active')
            .order('name'),
      ]);

      if (!mounted) return;
      setState(() {
        _links = List<Map<String, dynamic>>.from(results[0] as List);
        _managers = List<Map<String, dynamic>>.from(results[1] as List);
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
    final managerId = _selectedManagerId;
    final propertyId = _selectedPropertyId;
    if (managerId == null || propertyId == null) {
      _snack('Select a manager and a property', error: true);
      return;
    }

    try {
      final client = Supabase.instance.client;
      final manager = _selectedManager;
      final role = manager?['role']?.toString() ?? 'property_manager';

      await client.from('user_properties').upsert({
        'user_id': managerId,
        'property_id': propertyId,
        'role': 'manager',
      }, onConflict: 'user_id,property_id');

      if (role == 'property_manager' && _setCompanyIdForPm) {
        await client
            .from('properties')
            .update({'company_id': managerId}).eq('id', propertyId);
      }

      if (!mounted) return;
      _snack('Manager linked to property');
      setState(() {
        _selectedManagerId = null;
        if (widget.initialPropertyId == null) _selectedPropertyId = null;
      });
      await _load();
    } catch (e) {
      if (!mounted) return;
      _snack('Assign failed: $e', error: true);
    }
  }

  Future<void> _removeLink(String linkId) async {
    try {
      await Supabase.instance.client
          .from('user_properties')
          .delete()
          .eq('id', linkId);
      await _load();
      if (!mounted) return;
      _snack('Manager removed from property');
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

  String _managerLabel(Map<String, dynamic> m) {
    final name =
        '${m['first_name'] ?? ''} ${m['last_name'] ?? ''}'.trim();
    final email = m['email']?.toString() ?? '';
    final role = _roleLabels[m['role']?.toString()] ?? m['role']?.toString();
    final who = name.isEmpty ? email : '$name · $email';
    return '$who ($role)';
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColorsScheme.light;
    return Theme(
      data: AppTheme.light,
      child: Scaffold(
        backgroundColor: c.background,
        appBar: AppBar(
          title: Text('Manager Assignments',
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
                      'ACTIVE LINKS (${_links.length})',
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
                      child: _links.isEmpty
                          ? ListView(
                              children: [
                                const SizedBox(height: 40),
                                Icon(Icons.supervisor_account_outlined,
                                    size: 48, color: c.textMuted),
                                const SizedBox(height: 12),
                                Text(
                                  'No managers linked yet',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                      color: c.textSecondary, fontSize: 14),
                                ),
                              ],
                            )
                          : ListView.separated(
                              padding:
                                  const EdgeInsets.fromLTRB(16, 8, 16, 24),
                              itemCount: _links.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (ctx, i) {
                                final link = _links[i];
                                final user = link['users'];
                                final name = user is Map
                                    ? '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'
                                        .trim()
                                    : 'Unknown';
                                final userRole = user is Map
                                    ? _roleLabels[user['role']?.toString()] ??
                                        user['role']?.toString()
                                    : '';
                                final prop = (link['properties'] is Map)
                                    ? link['properties']['name']
                                            ?.toString() ??
                                        '?'
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
                                          color: AppColors.manager, size: 22),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              name.isEmpty ? 'Unnamed' : name,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w700,
                                                fontSize: 14,
                                                color: c.textPrimary,
                                              ),
                                            ),
                                            if (userRole != null)
                                              Text(userRole,
                                                  style: TextStyle(
                                                      fontSize: 11,
                                                      color: c.textSecondary)),
                                            const SizedBox(height: 4),
                                            Text(prop,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                  color: AppColors.manager,
                                                )),
                                          ],
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: 'Remove link',
                                        icon: const Icon(
                                            Icons.remove_circle_outline,
                                            color: AppColors.error),
                                        onPressed: () => _removeLink(
                                            link['id'].toString()),
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
        border: Border.all(color: AppColors.manager.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Assign manager to property',
            style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: c.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Ops managers use this for their dashboard. Property managers need this link (and optional primary PM below).',
            style: GoogleFonts.inter(fontSize: 12, color: c.textSecondary),
          ),
          const SizedBox(height: 16),
          _dropdown(
            c: c,
            label: 'Manager',
            hint: _managers.isEmpty
                ? 'No PMs/OMs — set role on Users tab first'
                : 'Select property or ops manager',
            value: _selectedManagerId,
            items: _managers
                .map((m) => DropdownMenuItem(
                      value: m['id'].toString(),
                      child: Text(_managerLabel(m),
                          style: GoogleFonts.inter(
                              fontSize: 13, color: c.textPrimary)),
                    ))
                .toList(),
            onChanged: _managers.isEmpty
                ? null
                : (v) => setState(() => _selectedManagerId = v),
          ),
          const SizedBox(height: 12),
          _dropdown(
            c: c,
            label: 'Property',
            hint: _properties.isEmpty ? 'Add a property first' : 'Select property',
            value: _selectedPropertyId,
            items: _properties
                .map((p) => DropdownMenuItem(
                      value: p['id'].toString(),
                      child: Text(p['name'].toString(),
                          style: GoogleFonts.inter(
                              fontSize: 14, color: c.textPrimary)),
                    ))
                .toList(),
            onChanged: _properties.isEmpty
                ? null
                : (v) => setState(() => _selectedPropertyId = v),
          ),
          if (widget.initialPropertyName != null) ...[
            const SizedBox(height: 8),
            Text('Pre-selected: ${widget.initialPropertyName}',
                style: GoogleFonts.inter(fontSize: 11, color: c.textMuted)),
          ],
          if (_selectedIsPropertyManager) ...[
            const SizedBox(height: 12),
            CheckboxListTile(
              value: _setCompanyIdForPm,
              onChanged: (v) =>
                  setState(() => _setCompanyIdForPm = v ?? true),
              activeColor: const Color(0xFF6366F1),
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Set as primary property manager (company_id)',
                style: GoogleFonts.inter(fontSize: 12, color: c.textPrimary),
              ),
              subtitle: Text(
                'Used by legacy access rules; last assign wins if multiple PMs.',
                style: GoogleFonts.inter(fontSize: 11, color: c.textMuted),
              ),
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ],
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Link manager to property',
            accent: AppColors.manager,
            icon: Icons.link,
            onPressed:
                (_selectedManagerId != null && _selectedPropertyId != null)
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
              hint: Text(hint,
                  style: GoogleFonts.inter(color: c.textMuted, fontSize: 14)),
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
