import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TodayComebacksScreen extends StatefulWidget {
  const TodayComebacksScreen({super.key});

  @override
  State<TodayComebacksScreen> createState() => _TodayComebacksScreenState();
}

class _TodayComebacksScreenState extends State<TodayComebacksScreen> {
  List<Map<String, dynamic>> _comebacks = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final supabase = Supabase.instance.client;
      final now = DateTime.now();
      final todayStart =
          DateTime(now.year, now.month, now.day).toUtc().toIso8601String();

      final rows = await supabase
          .from('missed_pickup_requests')
          .select(
              'id, status, requested_at, completed_at, is_free, fee_amount, resident_user_id, pickup_id, pickups(unit_id, units(unit_number), nightly_run_id, nightly_runs(properties(name)))')
          .gte('created_at', todayStart)
          .order('created_at', ascending: false);

      if (mounted) {
        setState(() {
          _comebacks = List<Map<String, dynamic>>.from(rows as List);
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString();
        });
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'accepted':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'expired':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'accepted':
        return 'In Progress';
      case 'completed':
        return 'Completed';
      case 'expired':
        return 'Expired';
      default:
        return 'Pending';
    }
  }

  String? _unitNumber(Map<String, dynamic> row) {
    final pickup = row['pickups'];
    if (pickup is! Map) return null;
    final units = pickup['units'];
    if (units is! Map) return null;
    return units['unit_number']?.toString();
  }

  String? _propertyName(Map<String, dynamic> row) {
    final pickup = row['pickups'];
    if (pickup is! Map) return null;
    final run = pickup['nightly_runs'];
    if (run is! Map) return null;
    final prop = run['properties'];
    if (prop is! Map) return null;
    return prop['name']?.toString();
  }

  String _formatTime(String isoStr) {
    try {
      final dt = DateTime.parse(isoStr).toLocal();
      final h12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final min = dt.minute.toString().padLeft(2, '0');
      final ap = dt.hour >= 12 ? 'PM' : 'AM';
      return '$h12:$min $ap';
    } catch (_) {
      return isoStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pending =
        _comebacks.where((c) => c['status'] == 'pending').length;
    final inProgress =
        _comebacks.where((c) => c['status'] == 'accepted').length;
    final completed =
        _comebacks.where((c) => c['status'] == 'completed').length;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Today's Comebacks"),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadData,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline,
                            color: Colors.red.shade400, size: 48),
                        const SizedBox(height: 16),
                        Text(_error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadData,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                )
              : Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(20),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.refresh,
                                    color: Colors.orange, size: 24),
                              ),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Text(
                                  "Today's Comebacks",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              Text(
                                '${_comebacks.length} total',
                                style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                  child: _summaryCard(
                                      'Pending', pending, Colors.orange)),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: _summaryCard(
                                      'In Progress', inProgress, Colors.blue)),
                              const SizedBox(width: 12),
                              Expanded(
                                  child: _summaryCard(
                                      'Completed', completed, Colors.green)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _comebacks.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle_outline,
                                      color: Colors.green.shade400, size: 64),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'No comeback requests today',
                                    style: TextStyle(
                                        color: Colors.grey, fontSize: 16),
                                  ),
                                ],
                              ),
                            )
                          : RefreshIndicator(
                              onRefresh: _loadData,
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16),
                                itemCount: _comebacks.length,
                                itemBuilder: (context, index) =>
                                    _comebackCard(_comebacks[index]),
                              ),
                            ),
                    ),
                  ],
                ),
    );
  }

  Widget _summaryCard(String title, int count, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            '$count',
            style: TextStyle(
                fontSize: 20, fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
                fontSize: 12,
                color: color.withOpacity(0.8),
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _comebackCard(Map<String, dynamic> row) {
    final status = row['status'] as String? ?? 'pending';
    final statusColor = _getStatusColor(status);
    final statusLabel = _getStatusLabel(status);
    final unit = _unitNumber(row);
    final property = _propertyName(row);
    final isFree = row['is_free'] as bool? ?? true;
    final requestedAt = row['requested_at'] as String?;
    final completedAt = row['completed_at'] as String?;
    final id = row['id'] as String? ?? '';

    final locationLabel = property != null && unit != null
        ? '$property – Unit $unit'
        : unit != null
            ? 'Unit $unit'
            : 'Request ${id.length > 8 ? id.substring(0, 8) : id}…';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    locationLabel,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: statusColor.withOpacity(0.3)),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  isFree ? Icons.check_circle_outline : Icons.payment,
                  size: 16,
                  color: isFree
                      ? Colors.green.shade600
                      : Colors.orange.shade600,
                ),
                const SizedBox(width: 6),
                Text(
                  isFree ? 'Free pickup' : 'Paid pickup',
                  style:
                      TextStyle(fontSize: 13, color: Colors.grey.shade700),
                ),
                if (requestedAt != null) ...[
                  const SizedBox(width: 20),
                  Icon(Icons.access_time,
                      size: 16, color: Colors.grey.shade500),
                  const SizedBox(width: 4),
                  Text(
                    _formatTime(requestedAt),
                    style:
                        TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ],
            ),
            if (completedAt != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.check_circle,
                      size: 16, color: Colors.green.shade600),
                  const SizedBox(width: 6),
                  Text(
                    'Completed at ${_formatTime(completedAt)}',
                    style: TextStyle(
                        fontSize: 13, color: Colors.green.shade700),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
