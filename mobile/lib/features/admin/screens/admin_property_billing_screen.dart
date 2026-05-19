import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/billing/property_billing.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/glow_badge.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/skeleton_card.dart';

/// Super admin: set per-property fee per door and minimum billable occupancy (85% rule).
class AdminPropertyBillingScreen extends StatefulWidget {
  const AdminPropertyBillingScreen({super.key});

  @override
  State<AdminPropertyBillingScreen> createState() =>
      _AdminPropertyBillingScreenState();
}

class _AdminPropertyBillingScreenState extends State<AdminPropertyBillingScreen> {
  List<Map<String, dynamic>> _properties = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await Supabase.instance.client
          .from('properties')
          .select(
            'id, name, city, state, is_active, monthly_fee_per_door, minimum_billable_occupancy_percent',
          )
          .eq('is_active', true)
          .order('name');
      if (mounted) {
        setState(() {
          _properties = List<Map<String, dynamic>>.from(rows as List);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _saveProperty({
    required String propertyId,
    required double feePerDoor,
    required double minBillablePercent,
  }) async {
    if (feePerDoor <= 0) {
      _snack('Fee per door must be greater than zero', error: true);
      return;
    }
    if (minBillablePercent <= 0 || minBillablePercent > 1) {
      _snack('Minimum billable must be between 1% and 100%', error: true);
      return;
    }

    try {
      await Supabase.instance.client.from('properties').update({
        'monthly_fee_per_door': feePerDoor,
        'minimum_billable_occupancy_percent': minBillablePercent,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', propertyId);

      await _load();
      _snack('Billing updated');
    } catch (e) {
      _snack('Save failed: $e', error: true);
    }
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openEditSheet(Map<String, dynamic> property) {
    final c = AppColorsScheme.light;
    final feeCtrl = TextEditingController(
      text: PropertyBilling.readFeePerDoor(property).toStringAsFixed(2),
    );
    final minCtrl = TextEditingController(
      text: (PropertyBilling.readMinBillablePercent(property) * 100)
          .round()
          .toString(),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: c.surface1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
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
              property['name']?.toString() ?? 'Property',
              style: GoogleFonts.montserrat(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: c.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'PMs pay for billable doors = max(occupied, minimum % of total units).',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: c.textSecondary,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: feeCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              decoration: const InputDecoration(
                labelText: 'Monthly fee per billable door',
                border: OutlineInputBorder(),
                prefixText: '\$ ',
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: minCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Minimum billable occupancy',
                hintText: '85',
                border: OutlineInputBorder(),
                suffixText: '% of total units',
              ),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Save billing',
              accent: const Color(0xFF6366F1),
              onPressed: () {
                final fee = double.tryParse(feeCtrl.text.trim()) ?? 0;
                final pct = (double.tryParse(minCtrl.text.trim()) ?? 85) / 100;
                Navigator.pop(ctx);
                _saveProperty(
                  propertyId: property['id']?.toString() ?? '',
                  feePerDoor: fee,
                  minBillablePercent: pct,
                );
              },
            ),
          ],
        ),
      ),
    ).whenComplete(() {
      feeCtrl.dispose();
      minCtrl.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColorsScheme.light;
    return Theme(
      data: AppTheme.light,
      child: Scaffold(
        backgroundColor: c.background,
        appBar: AppBar(
          title: Text(
            'Property billing',
            style: GoogleFonts.montserrat(
              fontWeight: FontWeight.w700,
              color: c.textPrimary,
            ),
          ),
          backgroundColor: c.surface1,
          foregroundColor: c.textPrimary,
          elevation: 0,
        ),
        body: _loading
            ? ListView(
                padding: const EdgeInsets.all(20),
                children: const [
                  SkeletonCard(height: 72),
                  SizedBox(height: 10),
                  SkeletonCard(height: 72),
                ],
              )
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_error!, textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                          TextButton(onPressed: _load, child: const Text('Retry')),
                        ],
                      ),
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                      children: [
                        Text(
                          'These rates drive PM estimated monthly bills and owner contract revenue on Financials.',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: c.textSecondary,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ..._properties.map((p) => _propertyTile(c, p)),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _propertyTile(AppColorsScheme c, Map<String, dynamic> p) {
    final fee = PropertyBilling.readFeePerDoor(p);
    final minPct = (PropertyBilling.readMinBillablePercent(p) * 100).round();
    final loc =
        '${p['city'] ?? ''}, ${p['state'] ?? ''}'.replaceAll(RegExp(r'^,\s*|,\s*$'), '');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: c.surface1,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: () => _openEditSheet(p),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: c.border),
            ),
            child: Row(
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
                          color: c.textPrimary,
                        ),
                      ),
                      if (loc.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          loc,
                          style: TextStyle(fontSize: 12, color: c.textSecondary),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        '\$${fee.toStringAsFixed(2)} / door · $minPct% minimum',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: c.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.edit_outlined, size: 20),
                const SizedBox(width: 8),
                GlowBadge(
                  label: 'Edit',
                  accent: const Color(0xFF6366F1),
                  showDot: false,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
