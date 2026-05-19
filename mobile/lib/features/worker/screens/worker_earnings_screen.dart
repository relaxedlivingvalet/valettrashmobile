import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/stat_tile.dart';
import '../../../core/workforce/clock_hours.dart';

class WorkerEarningsScreen extends StatefulWidget {
  const WorkerEarningsScreen({super.key});

  @override
  State<WorkerEarningsScreen> createState() => _WorkerEarningsScreenState();
}

class _WorkerEarningsScreenState extends State<WorkerEarningsScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _events = [];

  List<ClockShift> get _shifts => ClockHours.shiftsFromEvents(_events);

  double get _weekHours =>
      ClockHours.totalHours(_shifts, since: ClockHours.weekStartLocal());

  double get _monthHours =>
      ClockHours.totalHours(_shifts, since: ClockHours.monthStartLocal());

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    final since = DateTime.now()
        .subtract(const Duration(days: 30))
        .toUtc()
        .toIso8601String();
    final rows = await Supabase.instance.client
        .from('clock_events')
        .select('event_type, created_at')
        .eq('user_id', uid)
        .gte('created_at', since)
        .order('created_at', ascending: true);
    if (mounted) {
      setState(() {
        _events = List<Map<String, dynamic>>.from(rows as List);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface1,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text('Earnings',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 17)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
              children: [
                Row(children: [
                  StatTile(
                      value: ClockHours.formatDuration(_weekHours),
                      label: 'This Week'),
                  const SizedBox(width: 8),
                  StatTile(
                      value: ClockHours.formatDuration(_monthHours),
                      label: 'This Month'),
                ]),
                const SizedBox(height: 28),
                const Text('CLOCK HISTORY — LAST 30 DAYS',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted,
                        letterSpacing: 1.2)),
                const SizedBox(height: 12),
                if (_events.isEmpty)
                  const Text('No clock events yet.',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 14))
                else
                  ..._buildPairs(),
              ],
            ),
    );
  }

  List<Widget> _buildPairs() {
    final widgets = <Widget>[];
    for (final s in _shifts.reversed) {
      widgets.add(_shiftTile(
        ClockHours.formatTimestamp(s.clockInIso),
        s.open
            ? 'Still clocked in'
            : ClockHours.formatTimestamp(s.clockOutIso!),
        s.open ? '—' : ClockHours.formatDuration(s.hours),
      ));
    }
    return widgets;
  }

  Widget _shiftTile(String inTime, String outTime, String duration) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface1,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.schedule_outlined,
              color: AppColors.worker, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('In: $inTime',
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
                Text('Out: $outTime',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12)),
              ],
            ),
          ),
          Text(duration,
              style: const TextStyle(
                  color: AppColors.worker,
                  fontWeight: FontWeight.w700,
                  fontSize: 14)),
        ],
      ),
    );
  }
}
