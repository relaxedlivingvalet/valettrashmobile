import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SimpleNotificationSenderScreen extends StatefulWidget {
  const SimpleNotificationSenderScreen({super.key});

  @override
  State<SimpleNotificationSenderScreen> createState() => _SimpleNotificationSenderScreenState();
}

class _SimpleNotificationSenderScreenState extends State<SimpleNotificationSenderScreen> {
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();
  final _targetController = TextEditingController();
  String _selectedType = 'cancellation';
  String _selectedMode = 'property';
  bool _isLoading = false;

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
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    _targetController.dispose();
    super.dispose();
  }

  Future<void> _sendNotification() async {
    if (_titleController.text.trim().isEmpty || _messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in both title and message')),
      );
      return;
    }

    if (_selectedMode == 'user' && _targetController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a user ID')),
      );
      return;
    }

    if (_selectedMode == 'property' && _targetController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a property ID')),
      );
      return;
    }

    if (_selectedMode == 'service_alert' && _targetController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a property ID for service alert')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final supabase = Supabase.instance.client;
      final currentUser = supabase.auth.currentUser;

      if (currentUser != null) {
        Map<String, dynamic> notificationData = {
          'title': _titleController.text.trim(),
          'message': _messageController.text.trim(),
          'type': _selectedType,
          'audience': 'resident',
          'sender_id': currentUser.id,
          'is_active': true,
        };

        // Set targeting based on mode
        switch (_selectedMode) {
          case 'user':
            notificationData['user_id'] = _targetController.text.trim();
            break;
          case 'property':
            notificationData['property_id'] = _targetController.text.trim();
            break;
          case 'service_alert':
            // Service alerts must go to all residents at property
            notificationData['property_id'] = _targetController.text.trim();
            notificationData['type'] = 'service_completed'; // Default to service completed for service alerts
            break;
        }

        await supabase.from('notifications').insert(notificationData);

        _titleController.clear();
        _messageController.clear();
        _targetController.clear();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Notification sent successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send notification: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
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
              // Instructions Card
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
                      Row(
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
                      const SizedBox(height: 16),
                      Text(
                        'Send notifications to residents about service updates, cancellations, and important information.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade700,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Notification Form Card
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
                        maxLines: 2,
                      ),
                      const SizedBox(height: 16),

                      // Message
                      TextFormField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          labelText: 'Message',
                          border: OutlineInputBorder(),
                          hintText: 'Enter detailed message...',
                        ),
                        maxLines: 4,
                      ),
                      const SizedBox(height: 16),

                      // Send Mode
                      DropdownButtonFormField<String>(
                        value: _selectedMode,
                        decoration: const InputDecoration(
                          labelText: 'Send Mode',
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

                      // Target Field (User ID or Property ID)
                      TextFormField(
                        controller: _targetController,
                        decoration: InputDecoration(
                          labelText: _selectedMode == 'user' ? 'User ID' : 
                                     _selectedMode == 'service_alert' ? 'Property ID' : 'Property ID',
                          border: OutlineInputBorder(),
                          hintText: _selectedMode == 'user' 
                              ? 'Enter resident user ID...'
                              : 'Enter property ID...',
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Send Button
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
                          label: Text(_isLoading ? 'Sending...' : 'Send Notification'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
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
