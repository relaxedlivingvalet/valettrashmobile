import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/bento_card.dart';
import '../../../core/widgets/glow_badge.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/role_bottom_nav.dart';
import '../../../core/widgets/skeleton_card.dart';
import '../../auth/screens/change_password_screen.dart';
import 'resident_vacation_hold_screen.dart';

class ResidentDashboardScreen extends StatefulWidget {
  const ResidentDashboardScreen({super.key});

  @override
  State<ResidentDashboardScreen> createState() =>
      _ResidentDashboardScreenState();
}

class _ResidentDashboardScreenState extends State<ResidentDashboardScreen> {
  int _tabIndex = 0;
  bool _loading = true;
  String? _loadError;

  String _residentName = 'Resident';
  String _firstName = 'Resident';
  String _email = '';
  String _propertyName = '';
  String _windowShort = '--';
  int _freeRemain = 0;
  String _freeSummary = '--';

  String? _runStatus;
  String? _propertyId;
  Timer? _statusTimer;

  // Community announcements
  List<Map<String, dynamic>> _announcements = [];

  // Satisfaction
  int _completedRatingCount = 0;
  bool _satisfactionCardDismissed = false;

  // Messages
  List<Map<String, dynamic>> _conversations = [];
  RealtimeChannel? _msgChannel;
  bool _messagesLoaded = false;

  @override
  void initState() {
    super.initState();
    _email = Supabase.instance.client.auth.currentUser?.email ?? '';
    _load();
    _statusTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted && _propertyId != null) _pollRunStatus();
    });
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _msgChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> _pollRunStatus() async {
    if (_propertyId == null) return;
    try {
      final now = DateTime.now();
      final todayStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final row = await Supabase.instance.client
          .from('nightly_runs')
          .select('status')
          .eq('property_id', _propertyId!)
          .eq('run_date', todayStr)
          .maybeSingle();
      if (row == null) return;
      final newStatus = row['status']?.toString();
      if (newStatus != null && newStatus != _runStatus && mounted) {
        setState(() => _runStatus = newStatus);
      }
    } catch (_) {}
  }

  String _fmtTime(dynamic pgTime) {
    if (pgTime == null) return '--';
    final parts = pgTime.toString().split(':');
    if (parts.length < 2) return pgTime.toString();
    final hRaw = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    final ap = hRaw >= 12 ? 'PM' : 'AM';
    var h12 = hRaw % 12;
    if (h12 == 0) h12 = 12;
    return '$h12:${m.toString().padLeft(2, '0')} $ap';
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }
    try {
      final assignment = await Supabase.instance.client
          .from('resident_units')
          .select('''
              property_id,
              properties (
                name,
                service_window_start,
                service_window_end,
                free_comeback_pickups_per_month,
                comeback_pickup_fee
              )
            ''')
          .eq('user_id', uid)
          .eq('is_active', true)
          .maybeSingle();

      final profile = await Supabase.instance.client
          .from('users')
          .select('first_name,last_name')
          .eq('id', uid)
          .maybeSingle();

      if (mounted && profile != null) {
        final fn = '${profile['first_name'] ?? ''}'.trim();
        final ln = '${profile['last_name'] ?? ''}'.trim();
        _firstName = fn.isNotEmpty ? fn : 'Resident';
        if (fn.isNotEmpty || ln.isNotEmpty) {
          _residentName = ('$fn $ln').trim();
        }
      }

      Map<String, dynamic>? prop;
      Map<String, dynamic>? assignmentMap;
      if (assignment != null) {
        assignmentMap = Map<String, dynamic>.from(assignment as Map);
        final propsRaw = assignmentMap['properties'];
        if (propsRaw is Map) prop = Map<String, dynamic>.from(propsRaw);
      }

      if (prop != null && assignmentMap != null) {
        _propertyName = prop['name']?.toString() ?? '';
        _propertyId = assignmentMap['property_id']?.toString();
        final freeCapRaw = prop['free_comeback_pickups_per_month'];
        final freeCap =
            freeCapRaw is int ? freeCapRaw : int.tryParse('$freeCapRaw') ?? 0;
        final now = DateTime.now();
        final monthStart =
            '${now.year}-${now.month.toString().padLeft(2, '0')}-01';
        final pid = assignmentMap['property_id']?.toString();

        Map<String, dynamic>? usage;
        if (pid != null) {
          usage = await Supabase.instance.client
              .from('resident_monthly_usage')
              .select('free_comeback_used, paid_comeback_used')
              .eq('resident_user_id', uid)
              .eq('property_id', pid)
              .eq('month', monthStart)
              .maybeSingle();
        }

        final usedFree =
            usage == null ? 0 : (usage['free_comeback_used'] as int? ?? 0);
        final remain = freeCap - usedFree;
        _freeRemain =
            remain < 0 ? 0 : (remain > freeCap ? freeCap : remain);
        _freeSummary = freeCap <= 0
            ? 'No free comebacks configured'
            : '$_freeRemain of $freeCap left this month';

        final startT = prop['service_window_start'];
        final endT = prop['service_window_end'];
        _windowShort = '${_fmtTime(startT)} – ${_fmtTime(endT)}';
      }

      // Load announcements
      if (_propertyId != null) {
        try {
          final anns = await Supabase.instance.client
              .from('community_announcements')
              .select()
              .eq('property_id', _propertyId!)
              .order('created_at', ascending: false)
              .limit(5);
          _announcements = List<Map<String, dynamic>>.from(anns as List);
        } catch (_) {}
      }

      // Load satisfaction count
      try {
        final ratings = await Supabase.instance.client
            .from('satisfaction_ratings')
            .select('id')
            .eq('user_id', uid);
        _completedRatingCount = (ratings as List).length;
      } catch (_) {}

      if (mounted) setState(() => _loading = false);
      if (_propertyId != null) _pollRunStatus();
    } catch (e) {
      if (mounted) setState(() {
        _loading = false;
        _loadError = e.toString();
      });
    }
  }

  Future<void> _loadMessages() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    try {
      final msgs = await Supabase.instance.client
          .from('direct_messages')
          .select('id, sender_id, recipient_id, body, read_at, created_at, sender:users!sender_id(first_name, last_name), recipient:users!recipient_id(first_name, last_name)')
          .or('sender_id.eq.$uid,recipient_id.eq.$uid')
          .order('created_at', ascending: false);

      final Map<String, Map<String, dynamic>> convMap = {};
      for (final m in (msgs as List)) {
        final isMe = m['sender_id'] == uid;
        final partnerId = isMe ? m['recipient_id'] : m['sender_id'];
        final partnerRaw = isMe ? m['recipient'] : m['sender'];
        final partner = partnerRaw is Map ? partnerRaw : <String, dynamic>{};
        final partnerName =
            '${partner['first_name'] ?? ''} ${partner['last_name'] ?? ''}'.trim();
        if (!convMap.containsKey(partnerId)) {
          convMap[partnerId] = {
            'partner_id': partnerId,
            'partner_name': partnerName.isEmpty ? 'Unknown' : partnerName,
            'last_message': m['body'],
            'last_time': m['created_at'],
            'unread': (!isMe && m['read_at'] == null) ? 1 : 0,
          };
        } else if (!isMe && m['read_at'] == null) {
          convMap[partnerId]!['unread'] =
              (convMap[partnerId]!['unread'] as int) + 1;
        }
      }
      if (mounted) {
        setState(() {
          _conversations = convMap.values.toList();
          _messagesLoaded = true;
        });
      }
    } catch (_) {}
  }

  void _subscribeMessages() {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null || _msgChannel != null) return;
    _msgChannel = Supabase.instance.client
        .channel('dm_resident_$uid')
        .on(
          RealtimeListenTypes.postgresChanges,
          ChannelFilter(
            event: 'INSERT',
            schema: 'public',
            table: 'direct_messages',
            filter: 'recipient_id=eq.$uid',
          ),
          (payload, [ref]) => _loadMessages(),
        );
    _msgChannel?.subscribe();
  }

  void _onTabChange(int index) {
    setState(() => _tabIndex = index);
    if (index == 2 && !_messagesLoaded) {
      _loadMessages();
      _subscribeMessages();
    }
  }

  Future<void> _signOut(BuildContext ctx) async {
    await Supabase.instance.client.auth.signOut();
    if (!ctx.mounted) return;
    Navigator.of(ctx).popUntil((route) => route.isFirst);
  }

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(child: _buildTab()),
            RoleBottomNav(
              currentIndex: _tabIndex,
              onTap: _onTabChange,
              accent: AppColors.rlvBlue,
              items: const [
                RoleNavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home,
                  label: 'Home',
                ),
                RoleNavItem(
                  icon: Icons.delete_outline,
                  activeIcon: Icons.delete,
                  label: 'Services',
                ),
                RoleNavItem(
                  icon: Icons.chat_bubble_outline,
                  activeIcon: Icons.chat_bubble,
                  label: 'Messages',
                ),
                RoleNavItem(
                  icon: Icons.person_outline,
                  activeIcon: Icons.person,
                  label: 'Profile',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab() {
    switch (_tabIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return _buildServicesTab();
      case 2:
        return _buildMessagesTab();
      default:
        return _buildProfileTab();
    }
  }

  // ── Home Tab ──────────────────────────────────────────────────────────────────

  Widget _buildHomeTab() {
    if (_loading) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        children: const [
          SkeletonCard(height: 52),
          SizedBox(height: 16),
          SkeletonCard(height: 140),
          SizedBox(height: 12),
          SkeletonCard(height: 80),
          SizedBox(height: 12),
          SkeletonCard(height: 110),
        ],
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.rlvBlue,
      backgroundColor: AppColors.surface1,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        children: [
          if (_loadError != null) ...[
            GlowBadge(
              label: _loadError!,
              accent: AppColors.error,
              showDot: false,
            ),
            const SizedBox(height: 12),
          ],
          _buildGreetingHeader(),
          const SizedBox(height: 20),
          _buildServiceBentoRow(),
          const SizedBox(height: 12),
          _buildSatisfactionCard(),
          const SizedBox(height: 20),
          _buildCommunityUpdatesSection(),
        ],
      ),
    );
  }

  Widget _buildGreetingHeader() {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              greeting,
              style: GoogleFonts.inter(
                  fontSize: 13, color: AppColors.textSecondary),
            ),
            Text(
              _firstName,
              style: GoogleFonts.montserrat(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.rlvBlue.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(
                color: AppColors.rlvBlue.withValues(alpha: 0.3)),
          ),
          child: const Icon(Icons.person_outline,
              color: AppColors.rlvBlue, size: 22),
        ),
      ],
    );
  }

  Widget _buildServiceBentoRow() {
    final isCompleted = _runStatus == 'completed';
    final isInProgress = _runStatus == 'in_progress';
    final statusColor = isCompleted
        ? const Color(0xFF30D158)
        : isInProgress
            ? AppColors.rlvBlue
            : AppColors.textSecondary;
    final statusLabel = isCompleted
        ? 'Done'
        : isInProgress
            ? 'Active'
            : 'Scheduled';
    final statusIcon = isCompleted
        ? Icons.check_circle_outline
        : isInProgress
            ? Icons.loop
            : Icons.schedule_outlined;

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: BentoCard(
            height: 140,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NEXT SERVICE',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _windowShort == '--'
                            ? 'Not set'
                            : _windowShort.split('–').first.trim(),
                        style: GoogleFonts.montserrat(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppColors.rlvBlue,
                          height: 1.0,
                        ),
                      ),
                      if (_windowShort.contains('–'))
                        Text(
                          '– ${_windowShort.split('–').last.trim()}',
                          style: GoogleFonts.inter(
                              fontSize: 12,
                              color: AppColors.textSecondary),
                        ),
                    ],
                  ),
                ),
                _buildRunStatusChip(statusColor, statusLabel),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: BentoCard(
            height: 140,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'STATUS',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                    color: AppColors.textSecondary,
                  ),
                ),
                Icon(statusIcon, color: statusColor, size: 36),
                Text(
                  statusLabel,
                  style: GoogleFonts.montserrat(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRunStatusChip(Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
            fontSize: 11, fontWeight: FontWeight.w600, color: color),
      ),
    );
  }

  Widget _buildSatisfactionCard() {
    final shouldShowModal =
        _completedRatingCount > 0 && _completedRatingCount % 5 == 0;
    final shouldShowCard = !_satisfactionCardDismissed && !shouldShowModal;

    if (shouldShowModal) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _showRatingModal();
      });
    }
    if (!shouldShowCard) return const SizedBox.shrink();

    return BentoCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.star_outline, color: AppColors.rlvBlue, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How was your last service?',
                  style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary),
                ),
                Text(
                  'Tap to rate',
                  style: GoogleFonts.inter(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _showRatingModal,
            style: TextButton.styleFrom(
              minimumSize: Size.zero,
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            ),
            child: Text(
              'Rate',
              style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.rlvBlue),
            ),
          ),
          GestureDetector(
            onTap: () =>
                setState(() => _satisfactionCardDismissed = true),
            child: const Icon(Icons.close,
                size: 16, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Future<void> _showRatingModal() async {
    int selectedRating = 0;
    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface1,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2)),
              ),
              const SizedBox(height: 20),
              Text(
                'Rate Your Service',
                style: GoogleFonts.montserrat(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary),
              ),
              const SizedBox(height: 6),
              Text(
                'How was your trash valet service?',
                style: GoogleFonts.inter(
                    fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (i) => GestureDetector(
                    onTap: () => setModal(() => selectedRating = i + 1),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(
                        i < selectedRating
                            ? Icons.star
                            : Icons.star_outline,
                        color: AppColors.rlvBlue,
                        size: 40,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: selectedRating == 0
                      ? null
                      : () async {
                          Navigator.pop(ctx);
                          await _submitRating(selectedRating);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.rlvBlue,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        AppColors.rlvBlue.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'Submit',
                    style: GoogleFonts.montserrat(
                        fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitRating(int rating) async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null || _propertyId == null) return;
    try {
      await Supabase.instance.client.from('satisfaction_ratings').insert({
        'user_id': uid,
        'property_id': _propertyId,
        'rating': rating,
      });
      if (mounted) setState(() => _completedRatingCount++);
    } catch (_) {}
  }

  Widget _buildCommunityUpdatesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'COMMUNITY UPDATES',
          style: GoogleFonts.inter(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 12),
        if (_announcements.isEmpty)
          BentoCard(
            child: Center(
              child: Text(
                'No updates yet',
                style: GoogleFonts.inter(
                    fontSize: 13, color: AppColors.textSecondary),
              ),
            ),
          )
        else
          ..._announcements.map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: BentoCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a['title'] ?? '',
                        style: GoogleFonts.montserrat(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        a['body'] ?? '',
                        style: GoogleFonts.inter(
                            fontSize: 13, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _timeAgo(a['created_at']),
                        style: GoogleFonts.inter(
                            fontSize: 10, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              )),
      ],
    );
  }

  String _timeAgo(String? iso) {
    if (iso == null) return '';
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  // ── Services Tab ──────────────────────────────────────────────────────────────

  Widget _buildServicesTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Services'),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            children: const [ResidentPickupHistoryView()],
          ),
        ),
      ],
    );
  }

  // ── Messages Tab ──────────────────────────────────────────────────────────────

  Widget _buildMessagesTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Messages',
                style: GoogleFonts.montserrat(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary),
              ),
            ],
          ),
        ),
        Expanded(
          child: !_messagesLoaded
              ? const Center(
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.rlvBlue))
              : _conversations.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.chat_bubble_outline,
                              size: 48, color: AppColors.textSecondary),
                          const SizedBox(height: 12),
                          Text(
                            'No messages yet',
                            style: GoogleFonts.inter(
                                fontSize: 14,
                                color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadMessages,
                      color: AppColors.rlvBlue,
                      backgroundColor: AppColors.surface1,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _conversations.length,
                        separatorBuilder: (context, index) =>
                            const Divider(color: AppColors.border, height: 1),
                        itemBuilder: (_, i) {
                          final c = _conversations[i];
                          final name = c['partner_name'] as String? ?? '?';
                          final initial =
                              name.isNotEmpty ? name[0].toUpperCase() : '?';
                          final unread = c['unread'] as int? ?? 0;
                          return ListTile(
                            contentPadding:
                                const EdgeInsets.symmetric(vertical: 8),
                            leading: CircleAvatar(
                              backgroundColor: AppColors.rlvBlue
                                  .withValues(alpha: 0.15),
                              child: Text(
                                initial,
                                style: GoogleFonts.montserrat(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.rlvBlue),
                              ),
                            ),
                            title: Text(
                              name,
                              style: GoogleFonts.montserrat(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary),
                            ),
                            subtitle: Text(
                              c['last_message'] ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: AppColors.textSecondary),
                            ),
                            trailing: unread > 0
                                ? Container(
                                    width: 20,
                                    height: 20,
                                    decoration: const BoxDecoration(
                                        color: AppColors.rlvBlue,
                                        shape: BoxShape.circle),
                                    child: Center(
                                      child: Text(
                                        '$unread',
                                        style: GoogleFonts.inter(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white),
                                      ),
                                    ),
                                  )
                                : null,
                            onTap: () => _openConversation(
                                c['partner_id'], name),
                          );
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Future<void> _openConversation(String? partnerId, String partnerName) async {
    if (partnerId == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _ConversationScreen(
            partnerId: partnerId, partnerName: partnerName),
      ),
    );
    _loadMessages();
  }

  // ── Profile Tab ──────────────────────────────────────────────────────────────

  Widget _buildProfileTab() {
    final initial =
        _residentName.isNotEmpty ? _residentName[0].toUpperCase() : 'R';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Profile'),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            children: [
              BentoCard(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor:
                          AppColors.rlvBlue.withValues(alpha: 0.15),
                      child: Text(
                        initial,
                        style: GoogleFonts.montserrat(
                            color: AppColors.rlvBlue,
                            fontWeight: FontWeight.w700,
                            fontSize: 20),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _residentName,
                            style: GoogleFonts.montserrat(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _email,
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    GlowBadge(
                      label: 'Resident',
                      accent: AppColors.rlvBlue,
                    ),
                  ],
                ),
              ),
              if (_propertyName.isNotEmpty) ...[
                const SizedBox(height: 12),
                BentoCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PROPERTY',
                        style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _propertyName,
                        style: GoogleFonts.montserrat(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Service window: $_windowShort',
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _freeSummary,
                        style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              BentoCard(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          const ResidentVacationHoldScreen()),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF9F0A).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.beach_access_outlined,
                          color: Color(0xFFFF9F0A), size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Vacation Hold',
                            style: GoogleFonts.montserrat(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary),
                          ),
                          Text(
                            'Pause pickups while away',
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right,
                        color: AppColors.textSecondary, size: 20),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Change Password',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ChangePasswordScreen()),
                ),
                accent: AppColors.rlvBlue,
                icon: Icons.lock_reset_outlined,
              ),
              const SizedBox(height: 10),
              PrimaryButton(
                label: 'Sign Out',
                onPressed: () => _signOut(context),
                accent: AppColors.error,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Text(
        title,
        style: GoogleFonts.montserrat(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

// ── Conversation Screen ───────────────────────────────────────────────────────

class _ConversationScreen extends StatefulWidget {
  final String partnerId;
  final String partnerName;

  const _ConversationScreen({
    required this.partnerId,
    required this.partnerName,
  });

  @override
  State<_ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<_ConversationScreen> {
  final _ctrl = TextEditingController();
  List<Map<String, dynamic>> _messages = [];
  RealtimeChannel? _channel;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
    _subscribe();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    try {
      final msgs = await Supabase.instance.client
          .from('direct_messages')
          .select()
          .or('and(sender_id.eq.$uid,recipient_id.eq.${widget.partnerId}),and(sender_id.eq.${widget.partnerId},recipient_id.eq.$uid)')
          .order('created_at');
      // Mark received as read
      await Supabase.instance.client
          .from('direct_messages')
          .update({'read_at': DateTime.now().toIso8601String()})
          .eq('sender_id', widget.partnerId)
          .eq('recipient_id', uid)
          .filter('read_at', 'is', 'null');
      if (mounted) {
        setState(
            () => _messages = List<Map<String, dynamic>>.from(msgs as List));
      }
    } catch (_) {}
  }

  void _subscribe() {
    _channel = Supabase.instance.client
        .channel('conv_${widget.partnerId}')
        .on(
          RealtimeListenTypes.postgresChanges,
          ChannelFilter(
              event: 'INSERT', schema: 'public', table: 'direct_messages'),
          (payload, [ref]) => _load(),
        );
    _channel?.subscribe();
  }

  Future<void> _send() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    final text = _ctrl.text.trim();
    if (uid == null || text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await Supabase.instance.client.from('direct_messages').insert({
        'sender_id': uid,
        'recipient_id': widget.partnerId,
        'body': text,
      });
      _ctrl.clear();
      await _load();
    } catch (_) {}
    if (mounted) setState(() => _sending = false);
  }

  @override
  Widget build(BuildContext context) {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface1,
        elevation: 0,
        title: Text(
          widget.partnerName,
          style: GoogleFonts.montserrat(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Text(
                      'Start a conversation',
                      style: GoogleFonts.inter(
                          fontSize: 14, color: AppColors.textSecondary),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (_, i) {
                      final m = _messages[i];
                      final isMe = m['sender_id'] == uid;
                      return Align(
                        alignment: isMe
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width * 0.72),
                          decoration: BoxDecoration(
                            color: isMe
                                ? AppColors.rlvBlue
                                : AppColors.surface1,
                            borderRadius: BorderRadius.circular(16),
                            border: isMe
                                ? null
                                : Border.all(color: AppColors.border),
                          ),
                          child: Text(
                            m['body'] ?? '',
                            style: GoogleFonts.inter(
                                fontSize: 14,
                                color: isMe
                                    ? Colors.white
                                    : AppColors.textPrimary),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(
                16, 8, 16, MediaQuery.of(context).viewInsets.bottom + 16),
            color: AppColors.surface1,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    style: GoogleFonts.inter(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Message...',
                      hintStyle: GoogleFonts.inter(
                          color: AppColors.textSecondary),
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _send,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                        color: AppColors.rlvBlue, shape: BoxShape.circle),
                    child: _sending
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white),
                          )
                        : const Icon(Icons.send,
                            color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Pickup History ────────────────────────────────────────────────────────────

class ResidentPickupHistoryView extends StatelessWidget {
  const ResidentPickupHistoryView({super.key});

  Future<List<Map<String, dynamic>>> _fetchPickups() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return [];
    final rows = await Supabase.instance.client
        .from('pickups')
        .select('status, completed_at, created_at, units ( unit_number )')
        .eq('resident_user_id', uid)
        .order('created_at', ascending: false)
        .limit(25);
    return List<Map<String, dynamic>>.from(rows as List);
  }

  String _prettyStatus(String? s) {
    if (s == null) return 'Unknown';
    return s.replaceAll('_', ' ');
  }

  Color _statusColor(String? s) {
    switch (s) {
      case 'completed':
        return AppColors.success;
      case 'missed':
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchPickups(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Column(
            children: [
              SkeletonCard(height: 66),
              SizedBox(height: 10),
              SkeletonCard(height: 66),
              SizedBox(height: 10),
              SkeletonCard(height: 66),
            ],
          );
        }
        final list = snap.data!;
        if (list.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.history_outlined,
                      size: 48, color: AppColors.textSecondary),
                  const SizedBox(height: 12),
                  Text(
                    'No pickup history yet',
                    style: GoogleFonts.inter(
                        fontSize: 14, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          );
        }
        return Column(
          children: list.map((row) {
            final u = row['units'];
            final unit = (u is Map && u['unit_number'] != null)
                ? '${u['unit_number']}'
                : '?';
            final when = row['completed_at'] ?? row['created_at'] ?? '';
            final status = row['status'] as String?;
            final color = _statusColor(status);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.surface1,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                          color: color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _prettyStatus(status).toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: color,
                              letterSpacing: 0.8,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Unit $unit · $when',
                            style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
