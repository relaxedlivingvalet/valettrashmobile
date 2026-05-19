import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/billing/property_billing.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/skeleton_card.dart';

/// Super admin: total doors, occupied doors, fee per door → auto billable + monthly $.
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

  Future<int> _countUnits(String propertyId) async {
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

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await Supabase.instance.client
          .from('properties')
          .select(
            'id, name, city, state, is_active, monthly_fee_per_door, '
            'minimum_billable_occupancy_percent, billing_total_doors, billing_occupied_doors',
          )
          .eq('is_active', true)
          .order('name');

      final list = List<Map<String, dynamic>>.from(rows as List);
      for (final p in list) {
        final propId = p['id']?.toString() ?? '';
        final countedUnits = propId.isEmpty ? 0 : await _countUnits(propId);
        final residents = await Supabase.instance.client
            .from('resident_units')
            .select('id')
            .eq('property_id', propId)
            .eq('is_active', true);
        final countedOccupied = (residents as List).length;
        final snap = PropertyBilling.snapshot(
          property: p,
          countedUnits: countedUnits,
          countedOccupied: countedOccupied,
        );
        p.addAll(snap);
        p['counted_units'] = countedUnits;
        p['counted_occupied'] = countedOccupied;
      }

      if (mounted) {
        setState(() {
          _properties = list;
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
    required int totalDoors,
    required int occupiedDoors,
    required double feePerDoor,
  }) async {
    if (totalDoors <= 0) {
      _snack('Enter total doors for the property', error: true);
      return;
    }
    if (occupiedDoors < 0 || occupiedDoors > totalDoors) {
      _snack('Occupied doors must be between 0 and total doors', error: true);
      return;
    }
    if (feePerDoor <= 0) {
      _snack('Fee per door must be greater than zero', error: true);
      return;
    }

    try {
      await Supabase.instance.client.from('properties').update({
        'billing_total_doors': totalDoors,
        'billing_occupied_doors': occupiedDoors,
        'monthly_fee_per_door': feePerDoor,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', propertyId);

      await _load();
      _snack('Billing saved');
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
    final total = property['total_doors'] as int? ?? 0;
    final occupied = property['occupied_doors'] as int? ?? 0;
    final fee = PropertyBilling.readFeePerDoor(property);
    final minPct = PropertyBilling.readMinBillablePercent(property);

    final totalCtrl = TextEditingController(text: total > 0 ? '$total' : '');
    final occupiedCtrl =
        TextEditingController(text: occupied > 0 ? '$occupied' : '');
    final feeCtrl = TextEditingController(text: fee.toStringAsFixed(2));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: c.surface1,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          final totalN = int.tryParse(totalCtrl.text.trim()) ?? 0;
          final occupiedN = int.tryParse(occupiedCtrl.text.trim()) ?? 0;
          final feeN = double.tryParse(feeCtrl.text.trim()) ?? 0;
          final snap = PropertyBilling.snapshot(
            property: {
              ...property,
              'billing_total_doors': totalN > 0 ? totalN : null,
              'billing_occupied_doors': totalN > 0 ? occupiedN : null,
              'monthly_fee_per_door': feeN > 0 ? feeN : null,
            },
            countedUnits: property['counted_units'] as int? ?? 0,
            countedOccupied: property['counted_occupied'] as int? ?? 0,
          );
          final occPct = ((snap['occupancy_percent'] as double) * 100).round();
          final billable = snap['billable_doors'] as int;
          final monthly = snap['monthly_amount'] as double;
          final minDoors = snap['minimum_billable_doors'] as int;

          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 28,
            ),
            child: SingleChildScrollView(
              child: Column(
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
                    'Enter door counts and your rate. We calculate occupancy, '
                    'billable doors (${(minPct * 100).round()}% minimum), and monthly total.',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: c.textSecondary,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: totalCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => setSheet(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Total doors (units in complex)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: occupiedCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (_) => setSheet(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Doors occupied (residents moved in)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: feeCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*\.?\d{0,2}')),
                    ],
                    onChanged: (_) => setSheet(() {}),
                    decoration: const InputDecoration(
                      labelText: 'What you pay per billable door / month',
                      border: OutlineInputBorder(),
                      prefixText: '\$ ',
                    ),
                  ),
                  if (totalN > 0) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.owner.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.owner.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'CALCULATED',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.1,
                              color: c.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          _calcRow(c, 'Occupancy', '$occPct%'),
                          _calcRow(
                            c,
                            'Minimum at ${(minPct * 100).round()}%',
                            '$minDoors doors',
                          ),
                          _calcRow(c, 'Billable doors', '$billable'),
                          const Divider(height: 20),
                          _calcRow(
                            c,
                            'Estimated monthly',
                            '\$${monthly.toStringAsFixed(2)}',
                            bold: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  PrimaryButton(
                    label: 'Save',
                    accent: const Color(0xFF6366F1),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _saveProperty(
                        propertyId: property['id']?.toString() ?? '',
                        totalDoors: totalN,
                        occupiedDoors: occupiedN,
                        feePerDoor: feeN,
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    ).whenComplete(() {
      totalCtrl.dispose();
      occupiedCtrl.dispose();
      feeCtrl.dispose();
    });
  }

  Widget _calcRow(
    AppColorsScheme c,
    String label,
    String value, {
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: c.textSecondary)),
          Text(
            value,
            style: TextStyle(
              fontSize: bold ? 16 : 14,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              color: c.textPrimary,
            ),
          ),
        ],
      ),
    );
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
                  SkeletonCard(height: 88),
                  SizedBox(height: 10),
                  SkeletonCard(height: 88),
                ],
              )
            : _error != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        TextButton(onPressed: _load, child: const Text('Retry')),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _load,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                      children: [
                        Text(
                          'Set total doors, how many are occupied, and your per-door rate. '
                          'Billable doors = the higher of occupied count or 85% of total.',
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
    final total = p['total_doors'] as int? ?? 0;
    final occupied = p['occupied_doors'] as int? ?? 0;
    final billable = p['billable_doors'] as int? ?? 0;
    final monthly = (p['monthly_amount'] as num?)?.toDouble() ?? 0;
    final occPct = ((p['occupancy_percent'] as num? ?? 0) * 100).round();
    final fee = PropertyBilling.readFeePerDoor(p);

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        p['name']?.toString() ?? 'Property',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: c.textPrimary,
                        ),
                      ),
                    ),
                    const Icon(Icons.edit_outlined, size: 20),
                  ],
                ),
                const SizedBox(height: 10),
                if (total <= 0)
                  Text(
                    'Tap to enter total doors, occupied, and rate',
                    style: TextStyle(fontSize: 12, color: c.textMuted),
                  )
                else ...[
                  Text(
                    '$occupied / $total occupied ($occPct%) · $billable billable @ \$${fee.toStringAsFixed(2)}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: c.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Est. monthly: \$${monthly.toStringAsFixed(2)}',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: c.textPrimary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
