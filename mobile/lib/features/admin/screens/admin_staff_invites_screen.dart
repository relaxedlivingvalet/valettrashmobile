import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/primary_button.dart';

const _staffRoles = [
  ('property_manager', 'Property Manager'),
  ('operations_manager', 'Operations Manager'),
  ('driver', 'Worker / Driver'),
];

/// Super admin: generate staff invite codes for PM / OM / driver signup.
class AdminStaffInvitesScreen extends StatefulWidget {
  const AdminStaffInvitesScreen({required this.properties, super.key});

  final List<Map<String, dynamic>> properties;

  @override
  State<AdminStaffInvitesScreen> createState() =>
      _AdminStaffInvitesScreenState();
}

class _AdminStaffInvitesScreenState extends State<AdminStaffInvitesScreen> {
  List<Map<String, dynamic>> _codes = [];
  bool _loading = true;
  String? _propFilter;

  @override
  void initState() {
    super.initState();
    if (widget.properties.isNotEmpty) {
      _propFilter = widget.properties.first['id']?.toString();
    }
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      var query = Supabase.instance.client.from('staff_invites').select(
          'id, code, target_role, property_id, max_uses, use_count, expires_at, is_active, claimed_at, properties(name)');

      if (_propFilter != null) {
        query = query.eq('property_id', _propFilter!);
      }

      final rows = await query.order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          _codes = List<Map<String, dynamic>>.from(rows as List);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _snack('Load failed: $e', error: true);
      }
    }
  }

  Future<void> _revoke(String id) async {
    try {
      await Supabase.instance.client
          .from('staff_invites')
          .update({'is_active': false}).eq('id', id);
      await _load();
      _snack('Invite revoked');
    } catch (e) {
      _snack('Failed: $e', error: true);
    }
  }

  String _randomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rng = Random.secure();
    return 'STAFF${List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join()}';
  }

  Future<void> _generate({
    required String propertyId,
    required String targetRole,
    required int maxUses,
    required int daysValid,
  }) async {
    final code = _randomCode();
    final expires = DateTime.now()
        .add(Duration(days: daysValid))
        .toUtc()
        .toIso8601String();
    try {
      await Supabase.instance.client.from('staff_invites').insert({
        'code': code,
        'property_id': propertyId,
        'target_role': targetRole,
        'max_uses': maxUses,
        'use_count': 0,
        'expires_at': expires,
        'is_active': true,
        'created_by': Supabase.instance.client.auth.currentUser?.id,
      });
      await _load();
      _snack('Staff code $code created — share with new hire');
    } catch (e) {
      _snack('Failed: $e', error: true);
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

  void _copyCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    _snack('Copied $code');
  }

  void _showGenerateSheet() {
    String? propertyId = _propFilter ??
        (widget.properties.isNotEmpty
            ? widget.properties.first['id']?.toString()
            : null);
    String targetRole = 'property_manager';
    int maxUses = 1;
    int daysValid = 14;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final c = AppColorsScheme.light;
          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 28,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Generate staff invite',
                  style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: c.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'New hire uses Staff Sign Up on the login screen with this code.',
                  style: GoogleFonts.inter(
                      fontSize: 12, color: c.textSecondary),
                ),
                const SizedBox(height: 16),
                _sheetDropdown(
                  c: c,
                  label: 'Role',
                  value: targetRole,
                  items: _staffRoles
                      .map((r) => DropdownMenuItem(
                            value: r.$1,
                            child: Text(r.$2,
                                style: GoogleFonts.inter(
                                    color: c.textPrimary, fontSize: 14)),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setSheet(() => targetRole = v);
                  },
                ),
                const SizedBox(height: 12),
                _sheetDropdown(
                  c: c,
                  label: 'Property',
                  value: propertyId,
                  items: widget.properties
                      .map((p) => DropdownMenuItem(
                            value: p['id'].toString(),
                            child: Text(p['name'].toString(),
                                style: GoogleFonts.inter(
                                    color: c.textPrimary, fontSize: 14)),
                          ))
                      .toList(),
                  onChanged: (v) => setSheet(() => propertyId = v),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _sheetDropdown(
                        c: c,
                        label: 'Max uses',
                        value: '$maxUses',
                        items: [1, 3, 5, 10]
                            .map((n) => DropdownMenuItem(
                                  value: '$n',
                                  child: Text('$n',
                                      style: GoogleFonts.inter(
                                          color: c.textPrimary)),
                                ))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setSheet(() => maxUses = int.parse(v));
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _sheetDropdown(
                        c: c,
                        label: 'Valid (days)',
                        value: '$daysValid',
                        items: [7, 14, 30, 90]
                            .map((n) => DropdownMenuItem(
                                  value: '$n',
                                  child: Text('$n',
                                      style: GoogleFonts.inter(
                                          color: c.textPrimary)),
                                ))
                            .toList(),
                        onChanged: (v) {
                          if (v != null) {
                            setSheet(() => daysValid = int.parse(v));
                          }
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                PrimaryButton(
                  label: 'Generate code',
                  accent: AppColors.manager,
                  onPressed: propertyId == null
                      ? null
                      : () {
                          Navigator.pop(ctx);
                          _generate(
                            propertyId: propertyId!,
                            targetRole: targetRole,
                            maxUses: maxUses,
                            daysValid: daysValid,
                          );
                        },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _roleLabel(String? role) {
    for (final r in _staffRoles) {
      if (r.$1 == role) return r.$2;
    }
    return role ?? '?';
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColorsScheme.light;
    return Theme(
      data: AppTheme.light,
      child: Scaffold(
        backgroundColor: c.background,
        appBar: AppBar(
          title: Text('Staff Invites',
              style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w700, color: c.textPrimary)),
          backgroundColor: c.surface1,
          foregroundColor: c.textPrimary,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: widget.properties.isEmpty ? null : _showGenerateSheet,
            ),
          ],
        ),
        body: Column(
          children: [
            if (widget.properties.isNotEmpty)
              SizedBox(
                height: 40,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  children: widget.properties.map((p) {
                    final id = p['id'].toString();
                    final active = _propFilter == id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(p['name'].toString()),
                        selected: active,
                        onSelected: (_) {
                          setState(() => _propFilter = id);
                          _load();
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: _codes.isEmpty
                          ? ListView(
                              children: [
                                const SizedBox(height: 48),
                                Text(
                                  'No staff invites yet',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                      color: c.textSecondary),
                                ),
                              ],
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: _codes.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (ctx, i) {
                                final row = _codes[i];
                                final code = row['code']?.toString() ?? '';
                                final role =
                                    _roleLabel(row['target_role']?.toString());
                                final prop = row['properties'] is Map
                                    ? row['properties']['name']?.toString()
                                    : '';
                                final used = row['use_count'] as int? ?? 0;
                                final max = row['max_uses'] as int? ?? 1;
                                final active = row['is_active'] == true;
                                return Container(
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: c.surface1,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: c.border),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              code,
                                              style: GoogleFonts.montserrat(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w800,
                                                color: c.textPrimary,
                                                letterSpacing: 1.2,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.copy,
                                                size: 18),
                                            onPressed: () => _copyCode(code),
                                          ),
                                          if (active)
                                            IconButton(
                                              icon: const Icon(
                                                  Icons.block,
                                                  color: AppColors.error,
                                                  size: 20),
                                              onPressed: () => _revoke(
                                                  row['id'].toString()),
                                            ),
                                        ],
                                      ),
                                      Text(
                                        '$role · $prop',
                                        style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: c.textSecondary),
                                      ),
                                      Text(
                                        'Uses: $used / $max · ${active ? 'Active' : 'Revoked'}',
                                        style: GoogleFonts.inter(
                                            fontSize: 11, color: c.textMuted),
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
        floatingActionButton: widget.properties.isEmpty
            ? null
            : FloatingActionButton.extended(
                onPressed: _showGenerateSheet,
                backgroundColor: AppColors.manager,
                icon: const Icon(Icons.add),
                label: const Text('New staff code'),
              ),
      ),
    );
  }

  Widget _sheetDropdown({
    required AppColorsScheme c,
    required String label,
    required String? value,
    required List<DropdownMenuItem<String>> items,
    required ValueChanged<String?>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: GoogleFonts.inter(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: c.textSecondary)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: c.background,
            border: Border.all(color: c.border),
            borderRadius: BorderRadius.circular(10),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: c.surface1,
              style: GoogleFonts.inter(color: c.textPrimary, fontSize: 14),
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
