import 'dart:io' show File, Platform;

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Maps to Postgres enum `violation_type`.
final List<Map<String, String>> kViolationDbTypes = [
  {'value': 'too_many_bags', 'label': 'Too many bags'},
  {'value': 'untied_bags', 'label': 'Untied bags'},
  {'value': 'leaking_bags', 'label': 'Leaking bags'},
  {'value': 'prohibited_items', 'label': 'Prohibited items'},
  {'value': 'outside_rules', 'label': 'Outside rules'},
];

class ViolationReportScreen extends StatefulWidget {
  const ViolationReportScreen({super.key});

  @override
  State<ViolationReportScreen> createState() => _ViolationReportScreenState();
}

class _ViolationReportScreenState extends State<ViolationReportScreen> {
  final _unitController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _picker = ImagePicker();

  String _selectedViolationType = kViolationDbTypes.first['value']!;
  bool _isLoading = false;
  XFile? _image;

  @override
  void dispose() {
    _unitController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _pickPhoto(ImageSource src) async {
    final picked = await _picker.pickImage(source: src, maxWidth: 1600);
    if (picked != null) setState(() => _image = picked);
  }

  Future<String?> _uploadPhoto(String workerId) async {
    final file = _image;
    if (file == null) return null;
    final shortName = file.path.split(Platform.pathSeparator).last;
    final name =
        '${DateTime.now().millisecondsSinceEpoch}_$shortName'.replaceAll(' ', '');
    final path = 'workers/$workerId/$name';
    await Supabase.instance.client.storage
        .from('violations')
        .upload(path, File(file.path), fileOptions: const FileOptions(upsert: true));
    return path;
  }

  Future<void> _submitViolation() async {
    final unitNumber = _unitController.text.trim();
    if (unitNumber.isEmpty) {
      _showMessage('Please enter a unit number');
      return;
    }

    if (_descriptionController.text.trim().isEmpty) {
      _showMessage('Please enter a description');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) {
        _showMessage('Sign in required');
        return;
      }

      final assigns = await supabase
          .from('worker_assignments')
          .select('property_id')
          .eq('user_id', currentUser.id)
          .eq('is_active', true);
      final plist =
          List<Map<String, dynamic>>.from(assigns as List).map((e) {
        return e['property_id']?.toString();
      }).whereType<String>().toSet();
      if (plist.isEmpty) {
        _showMessage('No property assignment — contact dispatch.');
        return;
      }

      final unitsResp = await supabase
          .from('units')
          .select('id, floors!inner(buildings!inner(property_id))')
          .eq('unit_number', unitNumber);
      final rows = List<Map<String, dynamic>>.from(unitsResp as List);
      String? unitId;
      for (final r in rows) {
        final nested = r['floors'];
        if (nested is! Map) continue;
        final b = nested['buildings'];
        if (b is! Map) continue;
        final pid = b['property_id']?.toString();
        if (pid != null && plist.contains(pid)) {
          unitId = r['id']?.toString();
          break;
        }
      }
      if (unitId == null) {
        _showMessage(
            'Unit not found or not on your assigned properties.');
        return;
      }

      final ru = await supabase
          .from('resident_units')
          .select('user_id')
          .eq('unit_id', unitId)
          .eq('is_active', true)
          .maybeSingle();
      if (ru == null || ru['user_id'] == null) {
        _showMessage('No active resident mapped to this unit.');
        return;
      }
      final residentId = ru['user_id'].toString();

      final pickupResp = await supabase
          .from('pickups')
          .select('id')
          .eq('unit_id', unitId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      final pickupId =
          pickupResp == null ? null : pickupResp['id']?.toString();

      String? photoPath;
      if (_image != null) {
        photoPath = await _uploadPhoto(currentUser.id);
      }

      await supabase.from('violations').insert({
        if (pickupId != null) 'pickup_id': pickupId,
        'unit_id': unitId,
        'resident_user_id': residentId,
        'worker_user_id': currentUser.id,
        'violation_type': _selectedViolationType,
        'description': _descriptionController.text.trim(),
        if (photoPath != null) 'photo_url': photoPath,
        'status': 'pending',
      });

      _showMessage('Violation reported successfully!');
      _unitController.clear();
      _descriptionController.clear();
      setState(() => _image = null);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      _showMessage('Failed to report violation: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Report violation',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.red.shade700,
        foregroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.black26,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Document the condition at the door per property rules.',
                      style: TextStyle(fontSize: 15),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedViolationType,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Violation type',
                      ),
                      items: kViolationDbTypes
                          .map(
                            (e) => DropdownMenuItem(
                              value: e['value'],
                              child: Text(e['label']!),
                            ),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          setState(() => _selectedViolationType = v);
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _unitController,
                      decoration: const InputDecoration(
                        labelText: 'Unit number',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.text,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: _isLoading
                      ? null
                      : () => _pickPhoto(ImageSource.camera),
                  icon: const Icon(Icons.photo_camera_outlined),
                  label: const Text('Photo (camera)'),
                ),
                OutlinedButton.icon(
                  onPressed: _isLoading
                      ? null
                      : () => _pickPhoto(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Photo (gallery)'),
                ),
              ],
            ),
            if (_image != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  _image!.path.split('/').last,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitViolation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade700,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child:
                            CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Submit report'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
