import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/skeleton_card.dart';

/// Owner / super_admin inbox for [service_requests].
class ServiceRequestsInboxScreen extends StatefulWidget {
  const ServiceRequestsInboxScreen({super.key});

  @override
  State<ServiceRequestsInboxScreen> createState() =>
      _ServiceRequestsInboxScreenState();
}

class _ServiceRequestsInboxScreenState extends State<ServiceRequestsInboxScreen> {
  List<Map<String, dynamic>> _requests = [];
  bool _loading = true;
  String _filter = 'open';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final rows = await Supabase.instance.client
          .from('service_requests')
          .select(
            'id, service_type, preferred_date, message, status, created_at, '
            'users!resident_user_id(first_name, last_name, email), '
            'properties(name)',
          )
          .order('created_at', ascending: false);
      if (mounted) {
        setState(() {
          _requests = List<Map<String, dynamic>>.from(rows as List);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _updateStatus(String id, String status) async {
    try {
      await Supabase.instance.client
          .from('service_requests')
          .update({
            'status': status,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', id);
      _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $e')),
      );
    }
  }

  void _showDetail(Map<String, dynamic> row) {
    final user = row['users'];
    final name = user is Map
        ? '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim()
        : 'Resident';
    final email = user is Map ? user['email']?.toString() ?? '' : '';
    final prop = row['properties'] is Map
        ? row['properties']['name']?.toString() ?? ''
        : '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              row['service_type']?.toString() ?? 'Service',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '$name${email.isNotEmpty ? '\n$email' : ''}${prop.isNotEmpty ? '\n$prop' : ''}',
              style: GoogleFonts.inter(
                  fontSize: 12, color: AppColors.textSecondary),
            ),
            if (row['preferred_date'] != null) ...[
              const SizedBox(height: 12),
              Text(
                'Preferred: ${row['preferred_date']}',
                style: GoogleFonts.inter(
                    fontSize: 13, color: AppColors.rlvBlue),
              ),
            ],
            const SizedBox(height: 12),
            Text(
              row['message']?.toString() ?? '',
              style: GoogleFonts.inter(
                  fontSize: 14, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (row['status'] != 'in_review')
                  _actionChip('Mark In Review', () {
                    Navigator.pop(ctx);
                    _updateStatus(row['id'].toString(), 'in_review');
                  }),
                if (row['status'] != 'fulfilled')
                  _actionChip('Mark Fulfilled', () {
                    Navigator.pop(ctx);
                    _updateStatus(row['id'].toString(), 'fulfilled');
                  }),
                if (row['status'] != 'cancelled')
                  _actionChip('Cancel', () {
                    Navigator.pop(ctx);
                    _updateStatus(row['id'].toString(), 'cancelled');
                  }),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionChip(String label, VoidCallback onTap) {
    return ActionChip(
      label: Text(label),
      onPressed: onTap,
      backgroundColor: AppColors.rlvBlue.withValues(alpha: 0.15),
      labelStyle: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.rlvBlue),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered =
        _requests.where((r) => r['status'] == _filter).toList();
    final openCount =
        _requests.where((r) => r['status'] == 'open').length;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface1,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: Text(
          openCount > 0
              ? 'Service Requests ($openCount open)'
              : 'Service Requests',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w700),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: ['open', 'in_review', 'fulfilled', 'cancelled']
                  .map((s) {
                final active = _filter == s;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(s.replaceAll('_', ' ')),
                    selected: active,
                    onSelected: (_) => setState(() => _filter = s),
                    selectedColor: AppColors.rlvBlue,
                    labelStyle: TextStyle(
                      color: active ? Colors.white : AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: _loading
                ? ListView(
                    padding: const EdgeInsets.all(16),
                    children: const [
                      SkeletonCard(height: 88),
                      SizedBox(height: 8),
                      SkeletonCard(height: 88),
                    ],
                  )
                : filtered.isEmpty
                    ? Center(
                        child: Text(
                          'No $_filter requests',
                          style: GoogleFonts.inter(
                              color: AppColors.textSecondary),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        color: AppColors.rlvBlue,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (_, i) {
                            final r = filtered[i];
                            return _card(r);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _card(Map<String, dynamic> r) {
    final user = r['users'];
    final name = user is Map
        ? '${user['first_name'] ?? ''} ${user['last_name'] ?? ''}'.trim()
        : 'Resident';

    return InkWell(
      onTap: () => _showDetail(r),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface1,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    r['service_type']?.toString() ?? '',
                    style: GoogleFonts.montserrat(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.rlvBlue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    r['status']?.toString() ?? 'open',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.rlvBlue,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              r['message']?.toString() ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                  fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 6),
            Text(
              name,
              style: GoogleFonts.inter(
                  fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
