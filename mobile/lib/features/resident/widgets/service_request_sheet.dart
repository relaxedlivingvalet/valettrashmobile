import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/lottie_feedback.dart';
import '../../../core/widgets/primary_button.dart';

const kServiceTypes = [
  'Moving Service',
  'Maid Service',
  'Bulk Trash Pickup',
  'Carpet Cleaning',
  'Other',
];

/// Bottom sheet: service type, preferred date, message → [service_requests].
Future<bool?> showServiceRequestSheet(
  BuildContext context, {
  String? initialServiceType,
  String? propertyId,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface1,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => _ServiceRequestSheet(
      initialServiceType: initialServiceType,
      propertyId: propertyId,
    ),
  );
}

class _ServiceRequestSheet extends StatefulWidget {
  const _ServiceRequestSheet({
    this.initialServiceType,
    this.propertyId,
  });

  final String? initialServiceType;
  final String? propertyId;

  @override
  State<_ServiceRequestSheet> createState() => _ServiceRequestSheetState();
}

class _ServiceRequestSheetState extends State<_ServiceRequestSheet> {
  late String _serviceType;
  DateTime? _preferredDate;
  final _messageController = TextEditingController();
  bool _submitting = false;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    final initial = widget.initialServiceType;
    _serviceType = initial != null && kServiceTypes.contains(initial)
        ? initial
        : kServiceTypes.first;
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _preferredDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.rlvBlue,
              surface: AppColors.surface1,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _preferredDate = picked);
  }

  Future<void> _submit() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add details about your request.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final client = Supabase.instance.client;
      final uid = client.auth.currentUser?.id;
      if (uid == null) return;

      String? propertyId = widget.propertyId;
      if (propertyId == null) {
        try {
          final unitRow = await client
              .from('resident_units')
              .select('property_id')
              .eq('user_id', uid)
              .eq('is_active', true)
              .maybeSingle();
          propertyId = unitRow?['property_id']?.toString();
        } catch (_) {}
      }

      await client.from('service_requests').insert({
        'resident_user_id': uid,
        'property_id': propertyId,
        'service_type': _serviceType,
        'preferred_date': _preferredDate != null
            ? '${_preferredDate!.year}-${_preferredDate!.month.toString().padLeft(2, '0')}-${_preferredDate!.day.toString().padLeft(2, '0')}'
            : null,
        'message': message,
      });

      if (mounted) setState(() => _submitted = true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not submit request: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottom),
      child: _submitted
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const LottieSuccessView(
                  message: 'Request Submitted',
                  subtitle:
                      'Our team will review your request and follow up soon.',
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: 'Done',
                  accent: AppColors.rlvBlue,
                  onPressed: () => Navigator.pop(context, true),
                ),
              ],
            )
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Request a Service',
                    style: GoogleFonts.montserrat(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _label('SERVICE'),
                  const SizedBox(height: 8),
                  _dropdown(),
                  const SizedBox(height: 16),
                  _label('PREFERRED DATE'),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today_outlined, size: 18),
                    label: Text(
                      _preferredDate == null
                          ? 'Select date (optional)'
                          : '${_preferredDate!.month}/${_preferredDate!.day}/${_preferredDate!.year}',
                      style: GoogleFonts.inter(fontSize: 14),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _label('MESSAGE'),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _messageController,
                    maxLines: 4,
                    style: GoogleFonts.inter(
                        fontSize: 14, color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Tell us what you need…',
                      hintStyle: GoogleFonts.inter(
                          fontSize: 13, color: AppColors.textMuted),
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  PrimaryButton(
                    label: _submitting ? 'Submitting…' : 'Submit Request',
                    accent: AppColors.rlvBlue,
                    onPressed: _submitting ? null : _submit,
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.inter(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: AppColors.textSecondary,
        ),
      );

  Widget _dropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _serviceType,
          isExpanded: true,
          dropdownColor: AppColors.surface1,
          style: GoogleFonts.inter(
              fontSize: 14, color: AppColors.textPrimary),
          items: kServiceTypes
              .map((s) => DropdownMenuItem(value: s, child: Text(s)))
              .toList(),
          onChanged: (v) {
            if (v != null) setState(() => _serviceType = v);
          },
        ),
      ),
    );
  }
}
