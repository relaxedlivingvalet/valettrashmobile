import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SimpleNotificationSenderScreen extends StatefulWidget {
  final String? initialPropertyId;
  final String? initialMode;

  const SimpleNotificationSenderScreen({
    super.key,
    this.initialPropertyId,
    this.initialMode,
  });

  @override
  State<SimpleNotificationSenderScreen> createState() =>
      _SimpleNotificationSenderScreenState();
}

class _SimpleNotificationSenderScreenState
    extends State<SimpleNotificationSenderScreen> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _userIdController = TextEditingController();

  late String _selectedType;
  late String _selectedMode;
  String? _selectedPropertyId;
  bool _isLoading = false;
  bool _propertiesLoading = true;
  List<Map<String, dynamic>> _properties = [];

  final _notificationTypes = [
    {'value': 'cancellation', 'label': 'Weather Cancellation'},
    {'value': 'holiday', 'label': 'Holiday Cancellation'},
    {'value': 'completed', 'label': 'Service Completed'},
    {'value': 'reminder', 'label': 'Bring Bins Back In'},
    {'value': 'alert', 'label': 'General Property Alert'},
  ];

  final _sendModes = [
    {'value': 'user', 'label': 'One Resident'},
    {'value': 'property', 'label': 'All Residents at Property'},
    {'value': 'service_alert', 'label': 'Service Alert (All Residents)'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedType = 'cancellation';
    _selectedMode = widget.initialMode ?? 'property';
    _selectedPropertyId = widget.initialPropertyId;
    _loadProperties();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    _userIdController.dispose();
    super.dispose();
  }

  Future<void> _loadProperties() async {
    try {
      final rows = await Supabase.instance.client
          .from('properties')
          .select('id, name')
          .eq('is_active', true)
          .order('name');
      setState(() {
        _properties = List<Map<String, dynamic>>.from(rows as List);
        if (_selectedPropertyId == null && _properties.isNotEmpty) {
          _selectedPropertyId = _properties.first['id']?.toString();
        }
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _propertiesLoading = false);
    }
  }

  String _toDbNotificationType(String ui) {
    switch (ui) {
      case 'cancellation':
      case 'holiday':
        return 'pickup_reminder';
      case 'completed':
      case 'reminder':
        return 'team_arrived';
      case 'alert':
        return 'violation_reported';
      default:
        return 'billing_alert';
    }
  }

  Future<void> _sendNotification() async {
    if (_titleController.text.trim().isEmpty ||
        _messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please fill in both title and message')),
      );
      return;
    }

    if (_selectedMode == 'user' &&
        _userIdController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a resident user ID')),
      );
      return;
    }

    if ((_selectedMode == 'property' || _selectedMode == 'service_alert') &&
        _selectedPropertyId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a property')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) return;

      final uiTemplate =
          _selectedMode == 'service_alert' ? 'completed' : _selectedType;

      final notificationData = <String, dynamic>{
        'title': _titleController.text.trim(),
        'message': _messageController.text.trim(),
        'type': _toDbNotificationType(uiTemplate),
        'sender_id': currentUser.id,
        'is_active': true,
        'data': {
          'ui_type': _selectedType,
          'mode': _selectedMode,
        },
      };

      switch (_selectedMode) {
        case 'user':
          notificationData['user_id'] = _userIdController.text.trim();
          break;
        case 'property':
        case 'service_alert':
          notificationData['property_id'] = _selectedPropertyId;
          break;
      }

      await supabase.from('notifications').insert(notificationData);

      _titleController.clear();
      _messageController.clear();
      _userIdController.clear();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notification sent successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send notification: $e'),
          backgroundColor: Colors.red,
        ),
      );
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
          'Send Notification',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.black26,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.send,
                          color: Colors.green.shade700,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Text(
                          'Send Notification',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Form card
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Notification Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Send Mode
                      DropdownButtonFormField<String>(
                        value: _selectedMode,
                        decoration: const InputDecoration(
                          labelText: 'Send To',
                          border: OutlineInputBorder(),
                        ),
                        items: _sendModes.map((mode) {
                          return DropdownMenuItem(
                            value: mode['value'],
                            child: Text(mode['label']!),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedMode = value!);
                        },
                      ),
                      const SizedBox(height: 16),

                      // Property dropdown (for property/service_alert modes)
                      if (_selectedMode == 'property' ||
                          _selectedMode == 'service_alert') ...[
                        _propertiesLoading
                            ? const LinearProgressIndicator()
                            : DropdownButtonFormField<String>(
                                value: _selectedPropertyId,
                                decoration: const InputDecoration(
                                  labelText: 'Property',
                                  border: OutlineInputBorder(),
                                  prefixIcon: Icon(Icons.apartment),
                                ),
                                items: _properties.map((p) {
                                  return DropdownMenuItem(
                                    value: p['id']?.toString(),
                                    child:
                                        Text(p['name']?.toString() ?? ''),
                                  );
                                }).toList(),
                                onChanged: (v) => setState(
                                    () => _selectedPropertyId = v),
                              ),
                        const SizedBox(height: 16),
                      ],

                      // User ID field (for user mode)
                      if (_selectedMode == 'user') ...[
                        TextFormField(
                          controller: _userIdController,
                          decoration: const InputDecoration(
                            labelText: 'Resident User ID',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.person),
                            hintText: 'Paste resident UUID here...',
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // Notification Type
                      DropdownButtonFormField<String>(
                        value: _selectedType,
                        decoration: const InputDecoration(
                          labelText: 'Notification Type',
                          border: OutlineInputBorder(),
                        ),
                        items: _notificationTypes.map((type) {
                          return DropdownMenuItem(
                            value: type['value'],
                            child: Text(type['label']!),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedType = value!);
                        },
                      ),
                      const SizedBox(height: 16),

                      // Title
                      TextFormField(
                        controller: _titleController,
                        decoration: const InputDecoration(
                          labelText: 'Title',
                          border: OutlineInputBorder(),
                          hintText: 'Enter notification title...',
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Message
                      TextFormField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          labelText: 'Message',
                          border: OutlineInputBorder(),
                          hintText: 'Enter message body...',
                        ),
                        maxLines: 4,
                      ),
                      const SizedBox(height: 24),

                      // Send button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _isLoading ? null : _sendNotification,
                          icon: _isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.send),
                          label: Text(
                              _isLoading ? 'Sending...' : 'Send Notification'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            foregroundColor: Colors.white,
                            padding:
                                const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
