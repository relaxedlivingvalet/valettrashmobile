import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/primary_button.dart';

/// Super admin: create a property (+ optional starter building / unit).
class AdminAddPropertyScreen extends StatefulWidget {
  const AdminAddPropertyScreen({super.key});

  @override
  State<AdminAddPropertyScreen> createState() => _AdminAddPropertyScreenState();
}

class _AdminAddPropertyScreenState extends State<AdminAddPropertyScreen> {
  final _nameCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _stateCtrl = TextEditingController();
  final _zipCtrl = TextEditingController();
  final _startCtrl = TextEditingController(text: '18:00:00');
  final _endCtrl = TextEditingController(text: '22:00:00');
  final _buildingCtrl = TextEditingController(text: 'Building A');
  final _unitCtrl = TextEditingController(text: '101');
  final _feePerDoorCtrl = TextEditingController(text: '25');
  final _totalDoorsCtrl = TextEditingController();
  final _occupiedDoorsCtrl = TextEditingController();

  bool _createStarterUnit = true;
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _stateCtrl.dispose();
    _zipCtrl.dispose();
    _startCtrl.dispose();
    _endCtrl.dispose();
    _buildingCtrl.dispose();
    _unitCtrl.dispose();
    _feePerDoorCtrl.dispose();
    _totalDoorsCtrl.dispose();
    _occupiedDoorsCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    final address = _addressCtrl.text.trim();
    final city = _cityCtrl.text.trim();
    final state = _stateCtrl.text.trim();
    final zip = _zipCtrl.text.trim();
    if (name.isEmpty || address.isEmpty || city.isEmpty || state.isEmpty || zip.isEmpty) {
      _snack('Fill in name, address, city, state, and ZIP', error: true);
      return;
    }

    final feePerDoor = double.tryParse(_feePerDoorCtrl.text.trim()) ?? 25;
    final totalDoors = int.tryParse(_totalDoorsCtrl.text.trim());
    final occupiedDoors = int.tryParse(_occupiedDoorsCtrl.text.trim());
    if (feePerDoor <= 0) {
      _snack('Enter a valid fee per door', error: true);
      return;
    }
    if (totalDoors != null &&
        (totalDoors <= 0 || (occupiedDoors != null && occupiedDoors > totalDoors))) {
      _snack('Check total doors and occupied count', error: true);
      return;
    }

    setState(() => _saving = true);
    try {
      final client = Supabase.instance.client;
      final prop = await client
          .from('properties')
          .insert({
            'name': name,
            'address': address,
            'city': city,
            'state': state,
            'zip_code': zip,
            'service_window_start': _startCtrl.text.trim(),
            'service_window_end': _endCtrl.text.trim(),
            'free_comeback_pickups_per_month': 1,
            'comeback_pickup_fee': 5.00,
            'monthly_fee_per_door': feePerDoor,
            if (totalDoors != null) 'billing_total_doors': totalDoors,
            if (occupiedDoors != null) 'billing_occupied_doors': occupiedDoors,
            'is_active': true,
          })
          .select('id')
          .single();

      final propertyId = prop['id']?.toString();
      if (propertyId != null && _createStarterUnit) {
        final building = await client
            .from('buildings')
            .insert({
              'property_id': propertyId,
              'name': _buildingCtrl.text.trim().isEmpty
                  ? 'Building A'
                  : _buildingCtrl.text.trim(),
              'floors': 1,
              'sort_order': 1,
            })
            .select('id')
            .single();

        final buildingId = building['id']?.toString();
        if (buildingId != null) {
          final floor = await client
              .from('floors')
              .insert({
                'building_id': buildingId,
                'floor_number': 1,
                'sort_order': 1,
              })
              .select('id')
              .single();

          final floorId = floor['id']?.toString();
          if (floorId != null) {
            await client.from('units').insert({
              'floor_id': floorId,
              'unit_number':
                  _unitCtrl.text.trim().isEmpty ? '101' : _unitCtrl.text.trim(),
              'sort_order': 1,
              'is_active': true,
            });
          }
        }
      }

      if (!mounted) return;
      Navigator.pop(context, propertyId);
    } catch (e) {
      if (!mounted) return;
      _snack('Could not create property: $e', error: true);
    } finally {
      if (mounted) setState(() => _saving = false);
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

  @override
  Widget build(BuildContext context) {
    final c = AppColorsScheme.light;
    return Theme(
      data: AppTheme.light,
      child: Scaffold(
        backgroundColor: c.background,
        appBar: AppBar(
          title: Text('Add Property',
              style: GoogleFonts.montserrat(
                  fontWeight: FontWeight.w700, color: c.textPrimary)),
          backgroundColor: c.surface1,
          foregroundColor: c.textPrimary,
          elevation: 0,
        ),
        body: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              'Creates the property in Supabase. Optionally add one building, floor, and unit so invite codes can be generated.',
              style: GoogleFonts.inter(fontSize: 13, color: c.textSecondary),
            ),
            const SizedBox(height: 20),
            _field(c, _nameCtrl, 'Property name', 'Riverside Commons'),
            const SizedBox(height: 12),
            _field(c, _addressCtrl, 'Street address', '100 Main St'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _field(c, _cityCtrl, 'City', 'Dallas')),
                const SizedBox(width: 12),
                SizedBox(
                  width: 72,
                  child: _field(c, _stateCtrl, 'State', 'TX'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _field(c, _zipCtrl, 'ZIP', '75201'),
            const SizedBox(height: 16),
            Text('SERVICE WINDOW (24h)',
                style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                    color: c.textSecondary)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _field(c, _startCtrl, 'Start', '18:00:00')),
                const SizedBox(width: 12),
                Expanded(child: _field(c, _endCtrl, 'End', '22:00:00')),
              ],
            ),
            const SizedBox(height: 20),
            Text('BILLING (OPTIONAL)',
                style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.1,
                    color: c.textSecondary)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _field(c, _totalDoorsCtrl, 'Total doors', '120'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _field(c, _occupiedDoorsCtrl, 'Occupied', '85'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _field(c, _feePerDoorCtrl, 'Fee per billable door / month', '25'),
            const SizedBox(height: 8),
            Text(
              'Billable doors = max(occupied, 85% of total). Edit anytime under Property Billing Rates.',
              style: GoogleFonts.inter(fontSize: 12, color: c.textSecondary),
            ),
            const SizedBox(height: 20),
            CheckboxListTile(
              value: _createStarterUnit,
              onChanged: (v) => setState(() => _createStarterUnit = v ?? true),
              activeColor: const Color(0xFF6366F1),
              contentPadding: EdgeInsets.zero,
              title: Text('Create starter building + unit',
                  style: GoogleFonts.inter(
                      fontSize: 14, color: c.textPrimary)),
              subtitle: Text(
                'Needed before invite codes / resident signup for this site.',
                style: GoogleFonts.inter(fontSize: 12, color: c.textMuted),
              ),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            if (_createStarterUnit) ...[
              const SizedBox(height: 8),
              _field(c, _buildingCtrl, 'Building name', 'Building A'),
              const SizedBox(height: 12),
              _field(c, _unitCtrl, 'First unit number', '101'),
            ],
            const SizedBox(height: 28),
            PrimaryButton(
              label: _saving ? 'Creating…' : 'Create property',
              accent: const Color(0xFF6366F1),
              icon: Icons.apartment,
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    AppColorsScheme c,
    TextEditingController ctrl,
    String label,
    String hint,
  ) {
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
        TextField(
          controller: ctrl,
          style: GoogleFonts.inter(fontSize: 14, color: c.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(color: c.textMuted, fontSize: 13),
            filled: true,
            fillColor: c.surface1,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: c.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: c.border),
            ),
          ),
        ),
      ],
    );
  }
}
