# RLV Full Dashboard Build Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebuild all 5 role dashboards to match RLV brand sheet mockups with full Supabase integration including community announcements, direct messages, satisfaction ratings, and Amazon Flex-style worker scan flow.

**Architecture:** Each dashboard is a StatefulWidget with tab-based navigation using RoleBottomNav. Shared bento-card widgets live in `lib/core/widgets/`. Supabase realtime subscriptions power Messages tabs. New tables (`community_announcements`, `direct_messages`, `satisfaction_ratings`, `stop_completions`) are created with RLS policies.

**Tech Stack:** Flutter 3.41.9, Dart, supabase_flutter v1.10.25, fl_chart ^0.69.0, phosphor_flutter, google_fonts, flutter_animate, image_picker, shimmer

---

### Task 1: Supabase Schema — New Tables

**Files:**
- Modify: `mobile/lib/core/supabase/schema_notes.md` (create if missing — just documentation)

- [ ] **Step 1: Run SQL in Supabase SQL editor (via Chrome MCP or manually)**

```sql
-- community_announcements
create table if not exists public.community_announcements (
  id uuid primary key default gen_random_uuid(),
  property_id uuid references public.properties(id) on delete cascade,
  title text not null,
  body text not null,
  sent_by uuid references public.users(id),
  created_at timestamptz default now()
);
alter table public.community_announcements enable row level security;
create policy "residents can read their property announcements"
  on public.community_announcements for select
  using (
    property_id in (
      select property_id from public.resident_units
      where user_id = auth.uid() and is_active = true
    )
    or property_id in (
      select property_id from public.user_properties
      where user_id = auth.uid()
    )
    or exists (select 1 from public.users where id = auth.uid() and role in ('owner','operations_manager'))
  );
create policy "managers can insert announcements"
  on public.community_announcements for insert
  with check (
    exists (select 1 from public.users where id = auth.uid() and role in ('property_manager','operations_manager','owner'))
  );

-- direct_messages
create table if not exists public.direct_messages (
  id uuid primary key default gen_random_uuid(),
  sender_id uuid references public.users(id) on delete cascade,
  recipient_id uuid references public.users(id) on delete cascade,
  body text not null,
  read_at timestamptz,
  created_at timestamptz default now()
);
alter table public.direct_messages enable row level security;
create policy "users can read their own messages"
  on public.direct_messages for select
  using (sender_id = auth.uid() or recipient_id = auth.uid());
create policy "users can send messages"
  on public.direct_messages for insert
  with check (sender_id = auth.uid());
create policy "recipients can mark read"
  on public.direct_messages for update
  using (recipient_id = auth.uid());

-- satisfaction_ratings
create table if not exists public.satisfaction_ratings (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.users(id) on delete cascade,
  property_id uuid references public.properties(id),
  run_id uuid references public.nightly_runs(id),
  rating int check (rating between 1 and 5),
  comment text,
  created_at timestamptz default now()
);
alter table public.satisfaction_ratings enable row level security;
create policy "residents can insert their ratings"
  on public.satisfaction_ratings for insert
  with check (user_id = auth.uid());
create policy "managers and owners can read ratings"
  on public.satisfaction_ratings for select
  using (
    user_id = auth.uid()
    or exists (select 1 from public.users where id = auth.uid() and role in ('property_manager','operations_manager','owner'))
  );

-- stop_completions
create table if not exists public.stop_completions (
  id uuid primary key default gen_random_uuid(),
  stop_id uuid references public.route_stops(id) on delete cascade,
  run_id uuid references public.nightly_runs(id),
  completed_by uuid references public.users(id),
  photo_url text,
  method text check (method in ('photo','manual')),
  created_at timestamptz default now()
);
alter table public.stop_completions enable row level security;
create policy "workers can insert completions"
  on public.stop_completions for insert
  with check (completed_by = auth.uid());
create policy "workers and managers can view completions"
  on public.stop_completions for select
  using (
    completed_by = auth.uid()
    or exists (select 1 from public.users where id = auth.uid() and role in ('property_manager','operations_manager','owner'))
  );
```

- [ ] **Step 2: Create pickup-photos storage bucket in Supabase**
  - Go to Storage → New bucket → name: `pickup-photos`, public: false
  - Add policy: workers can upload (`auth.uid() is not null`)
  - Add policy: authenticated users can read

- [ ] **Step 3: Verify tables exist**
  ```sql
  select table_name from information_schema.tables
  where table_schema = 'public'
  and table_name in ('community_announcements','direct_messages','satisfaction_ratings','stop_completions');
  ```
  Expected: 4 rows returned

- [ ] **Step 4: Commit**
  ```bash
  git add -A
  git commit -m "feat: add supabase schema — announcements, messages, ratings, stop_completions"
  ```

---

### Task 2: Core Shared Widgets

**Files:**
- Create: `mobile/lib/core/widgets/bento_card.dart`
- Create: `mobile/lib/core/widgets/metric_tile.dart`

- [ ] **Step 1: Create BentoCard widget**

`mobile/lib/core/widgets/bento_card.dart`:
```dart
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class BentoCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;
  final double? height;
  final VoidCallback? onTap;

  const BentoCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
    this.height,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: height,
        padding: padding ?? const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color ?? AppColors.surface1,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: child,
      ),
    );
  }
}
```

- [ ] **Step 2: Create MetricTile widget**

`mobile/lib/core/widgets/metric_tile.dart`:
```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final String? subtitle;
  final Color? valueColor;
  final IconData? icon;

  const MetricTile({
    super.key,
    required this.label,
    required this.value,
    this.subtitle,
    this.valueColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: GoogleFonts.montserrat(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: valueColor ?? AppColors.textPrimary,
            height: 1.0,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}
```

- [ ] **Step 3: Commit**
  ```bash
  git add mobile/lib/core/widgets/bento_card.dart mobile/lib/core/widgets/metric_tile.dart
  git commit -m "feat: add BentoCard and MetricTile shared widgets"
  ```

---

### Task 3: Resident Dashboard — Home + Services Tabs

**Files:**
- Modify: `mobile/lib/features/resident/screens/resident_dashboard_screen.dart`

- [ ] **Step 1: Read current resident dashboard**
  Read `mobile/lib/features/resident/screens/resident_dashboard_screen.dart` lines 1-200

- [ ] **Step 2: Rewrite Home tab with bento cards**

Replace the `_buildHomeTab()` method with:
```dart
Widget _buildHomeTab() {
  return RefreshIndicator(
    onRefresh: _loadData,
    color: AppColors.rlvBlue,
    backgroundColor: AppColors.surface1,
    child: SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGreetingHeader(),
          const SizedBox(height: 20),
          _buildServiceStatusBento(),
          const SizedBox(height: 12),
          _buildSatisfactionCard(),
          const SizedBox(height: 20),
          _buildCommunityUpdates(),
        ],
      ),
    ),
  );
}

Widget _buildGreetingHeader() {
  final hour = DateTime.now().hour;
  final greeting = hour < 12 ? 'Good morning' : hour < 17 ? 'Good afternoon' : 'Good evening';
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            greeting,
            style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
          ),
          Text(
            _firstName ?? 'Resident',
            style: GoogleFonts.montserrat(
              fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
      Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: AppColors.rlvBlue.withValues(alpha: 0.15),
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.rlvBlue.withValues(alpha: 0.4)),
        ),
        child: const Icon(Icons.person_outline, color: AppColors.rlvBlue, size: 20),
      ),
    ],
  );
}

Widget _buildServiceStatusBento() {
  return Row(
    children: [
      Expanded(
        flex: 3,
        child: BentoCard(
          height: 140,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('NEXT SERVICE', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 1.2, color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              Text(
                _windowShort ?? '--:-- --',
                style: GoogleFonts.montserrat(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.rlvBlue, height: 1.0),
              ),
              const Spacer(),
              _buildRunStatusChip(),
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
              Text('STATUS', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 1.2, color: AppColors.textSecondary)),
              Icon(
                _runStatus == 'completed' ? Icons.check_circle_outline : 
                _runStatus == 'in_progress' ? Icons.loop : Icons.schedule_outlined,
                color: _runStatus == 'completed' ? const Color(0xFF30D158) :
                       _runStatus == 'in_progress' ? AppColors.rlvBlue : AppColors.textSecondary,
                size: 36,
              ),
              Text(
                _runStatus == 'completed' ? 'Done' :
                _runStatus == 'in_progress' ? 'Active' : 'Scheduled',
                style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

Widget _buildRunStatusChip() {
  final color = _runStatus == 'completed' ? const Color(0xFF30D158) :
                _runStatus == 'in_progress' ? AppColors.rlvBlue : AppColors.textSecondary;
  final label = _runStatus == 'completed' ? 'Completed' :
                _runStatus == 'in_progress' ? 'In Progress' : 'Scheduled';
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: color.withValues(alpha: 0.4)),
    ),
    child: Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
  );
}
```

- [ ] **Step 3: Add community announcements fetch and display**

Add field:
```dart
List<Map<String, dynamic>> _announcements = [];
```

Add to `_loadData()`:
```dart
final announcements = await Supabase.instance.client
    .from('community_announcements')
    .select()
    .eq('property_id', _propertyId!)
    .order('created_at', ascending: false)
    .limit(5);
if (mounted) setState(() => _announcements = List<Map<String, dynamic>>.from(announcements));
```

Add `_buildCommunityUpdates()`:
```dart
Widget _buildCommunityUpdates() {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text('COMMUNITY UPDATES', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 1.2, color: AppColors.textSecondary)),
      const SizedBox(height: 12),
      if (_announcements.isEmpty)
        BentoCard(
          child: Center(
            child: Text('No updates yet', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
          ),
        )
      else
        ..._announcements.map((a) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: BentoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a['title'] ?? '', style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const SizedBox(height: 4),
                Text(a['body'] ?? '', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
                const SizedBox(height: 6),
                Text(
                  _formatAnnTime(a['created_at']),
                  style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        )),
    ],
  );
}

String _formatAnnTime(String? iso) {
  if (iso == null) return '';
  final dt = DateTime.tryParse(iso)?.toLocal();
  if (dt == null) return '';
  final now = DateTime.now();
  final diff = now.difference(dt);
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}
```

- [ ] **Step 4: Add satisfaction card**

Add fields:
```dart
int _completedRunCount = 0;
bool _satisfactionCardDismissed = false;
bool _showSatisfactionModal = false;
```

Add to `_loadData()`:
```dart
final ratings = await Supabase.instance.client
    .from('satisfaction_ratings')
    .select('id')
    .eq('user_id', Supabase.instance.client.auth.currentUser!.id);
_completedRunCount = (ratings as List).length;
```

Add `_buildSatisfactionCard()`:
```dart
Widget _buildSatisfactionCard() {
  // Show modal every 5th run, card between
  final shouldShowModal = _completedRunCount > 0 && _completedRunCount % 5 == 0;
  final shouldShowCard = !_satisfactionCardDismissed && !shouldShowModal && _completedRunCount % 5 != 0;
  
  if (shouldShowModal && _showSatisfactionModal) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _showRatingModal());
  }
  
  if (!shouldShowCard) return const SizedBox.shrink();
  
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: BentoCard(
      child: Row(
        children: [
          const Icon(Icons.star_outline, color: AppColors.rlvBlue, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('How was your last service?', style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                Text('Tap to rate', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18, color: AppColors.textSecondary),
            onPressed: () => setState(() => _satisfactionCardDismissed = true),
          ),
          TextButton(
            onPressed: _showRatingModal,
            child: Text('Rate', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.rlvBlue)),
          ),
        ],
      ),
    ),
  );
}

Future<void> _showRatingModal() async {
  int selectedRating = 0;
  await showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.surface1,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setModal) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 36, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text('Rate Your Service', style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Text('How was your trash valet service?', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) => GestureDetector(
                onTap: () => setModal(() => selectedRating = i + 1),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Icon(
                    i < selectedRating ? Icons.star : Icons.star_outline,
                    color: AppColors.rlvBlue,
                    size: 40,
                  ),
                ),
              )),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: selectedRating == 0 ? null : () async {
                  Navigator.pop(ctx);
                  await _submitRating(selectedRating);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.rlvBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Submit', style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w700)),
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
  await Supabase.instance.client.from('satisfaction_ratings').insert({
    'user_id': uid,
    'property_id': _propertyId,
    'rating': rating,
  });
}
```

- [ ] **Step 5: Add imports at top**
```dart
import '../../../core/widgets/bento_card.dart';
import '../../../core/widgets/metric_tile.dart';
```

- [ ] **Step 6: Run tests**
  ```bash
  cd mobile && flutter test test/widget_test.dart
  ```
  Expected: passes

- [ ] **Step 7: Commit**
  ```bash
  git add mobile/lib/features/resident/
  git commit -m "feat: resident home tab — bento cards, community announcements, satisfaction rating"
  ```

---

### Task 4: Resident Dashboard — Messages Tab

**Files:**
- Modify: `mobile/lib/features/resident/screens/resident_dashboard_screen.dart`

- [ ] **Step 1: Add messages state fields**
```dart
List<Map<String, dynamic>> _conversations = [];
RealtimeChannel? _msgChannel;
```

- [ ] **Step 2: Add messages loading + realtime sub**
```dart
Future<void> _loadMessages() async {
  final uid = Supabase.instance.client.auth.currentUser?.id;
  if (uid == null) return;
  final msgs = await Supabase.instance.client
      .from('direct_messages')
      .select('*, sender:users!sender_id(first_name, last_name), recipient:users!recipient_id(first_name, last_name)')
      .or('sender_id.eq.$uid,recipient_id.eq.$uid')
      .order('created_at', ascending: false);
  
  // Group by conversation partner
  final Map<String, Map<String, dynamic>> convMap = {};
  for (final m in (msgs as List)) {
    final partnerId = m['sender_id'] == uid ? m['recipient_id'] : m['sender_id'];
    final partner = m['sender_id'] == uid ? m['recipient'] : m['sender'];
    if (!convMap.containsKey(partnerId)) {
      convMap[partnerId] = {
        'partner_id': partnerId,
        'partner_name': '${partner?['first_name'] ?? ''} ${partner?['last_name'] ?? ''}'.trim(),
        'last_message': m['body'],
        'last_time': m['created_at'],
        'unread': m['recipient_id'] == uid && m['read_at'] == null ? 1 : 0,
      };
    } else if (m['recipient_id'] == uid && m['read_at'] == null) {
      convMap[partnerId]!['unread'] = (convMap[partnerId]!['unread'] as int) + 1;
    }
  }
  if (mounted) setState(() => _conversations = convMap.values.toList());
}

void _subscribeMessages() {
  final uid = Supabase.instance.client.auth.currentUser?.id;
  if (uid == null) return;
  _msgChannel = Supabase.instance.client
      .channel('direct_messages_$uid')
      .on(RealtimeListenTypes.postgresChanges, ChannelFilter(
        event: 'INSERT', schema: 'public', table: 'direct_messages',
        filter: 'recipient_id=eq.$uid',
      ), (payload, [ref]) => _loadMessages())
      .subscribe();
}
```

- [ ] **Step 3: Build Messages tab UI**
```dart
Widget _buildMessagesTab() {
  return Column(
    children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Messages', style: GoogleFonts.montserrat(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppColors.rlvBlue),
              onPressed: _showNewMessageSheet,
            ),
          ],
        ),
      ),
      Expanded(
        child: _conversations.isEmpty
            ? Center(child: Text('No messages yet', style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary)))
            : ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _conversations.length,
                separatorBuilder: (_, __) => const Divider(color: AppColors.border, height: 1),
                itemBuilder: (_, i) {
                  final c = _conversations[i];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: AppColors.rlvBlue.withValues(alpha: 0.15),
                      child: Text(
                        (c['partner_name'] as String).isNotEmpty ? (c['partner_name'] as String)[0] : '?',
                        style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, color: AppColors.rlvBlue),
                      ),
                    ),
                    title: Text(c['partner_name'] ?? 'Unknown', style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                    subtitle: Text(c['last_message'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                    trailing: c['unread'] > 0
                        ? Container(
                            width: 20, height: 20,
                            decoration: const BoxDecoration(color: AppColors.rlvBlue, shape: BoxShape.circle),
                            child: Center(child: Text('${c['unread']}', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white))),
                          )
                        : null,
                    onTap: () => _openConversation(c['partner_id'], c['partner_name']),
                  );
                },
              ),
      ),
    ],
  );
}
```

- [ ] **Step 4: Build conversation detail screen inline push**
```dart
Future<void> _openConversation(String partnerId, String partnerName) async {
  await Navigator.push(context, MaterialPageRoute(
    builder: (_) => _ConversationScreen(partnerId: partnerId, partnerName: partnerName),
  ));
  _loadMessages();
}

void _showNewMessageSheet() {
  // Simple — just open new conversation to property manager
  // For now navigate to send message flow
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Contact your property manager from the Requests tab')),
  );
}
```

- [ ] **Step 5: Create conversation screen class in same file**

Add at bottom of file (outside the state class):
```dart
class _ConversationScreen extends StatefulWidget {
  final String partnerId;
  final String partnerName;
  const _ConversationScreen({required this.partnerId, required this.partnerName});

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
    final msgs = await Supabase.instance.client
        .from('direct_messages')
        .select()
        .or('and(sender_id.eq.$uid,recipient_id.eq.${widget.partnerId}),and(sender_id.eq.${widget.partnerId},recipient_id.eq.$uid)')
        .order('created_at');
    // Mark received messages as read
    await Supabase.instance.client
        .from('direct_messages')
        .update({'read_at': DateTime.now().toIso8601String()})
        .eq('sender_id', widget.partnerId)
        .eq('recipient_id', uid!)
        .isFilter('read_at', null);
    if (mounted) setState(() => _messages = List<Map<String, dynamic>>.from(msgs));
  }

  void _subscribe() {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;
    _channel = Supabase.instance.client
        .channel('conv_${uid}_${widget.partnerId}')
        .on(RealtimeListenTypes.postgresChanges, ChannelFilter(
          event: 'INSERT', schema: 'public', table: 'direct_messages',
        ), (payload, [ref]) => _load())
        .subscribe();
  }

  Future<void> _send() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    final text = _ctrl.text.trim();
    if (uid == null || text.isEmpty) return;
    setState(() => _sending = true);
    await Supabase.instance.client.from('direct_messages').insert({
      'sender_id': uid,
      'recipient_id': widget.partnerId,
      'body': text,
    });
    _ctrl.clear();
    setState(() => _sending = false);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface1,
        title: Text(widget.partnerName, style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (_, i) {
                final m = _messages[i];
                final isMe = m['sender_id'] == uid;
                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
                    decoration: BoxDecoration(
                      color: isMe ? AppColors.rlvBlue : AppColors.surface1,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(m['body'] ?? '', style: GoogleFonts.inter(fontSize: 14, color: Colors.white)),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            color: AppColors.surface1,
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _ctrl,
                    style: GoogleFonts.inter(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Message...',
                      hintStyle: GoogleFonts.inter(color: AppColors.textSecondary),
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _sending ? null : _send,
                  child: Container(
                    width: 44, height: 44,
                    decoration: const BoxDecoration(color: AppColors.rlvBlue, shape: BoxShape.circle),
                    child: const Icon(Icons.send, color: Colors.white, size: 20),
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
```

- [ ] **Step 6: Add realtime import**
```dart
import 'package:supabase_flutter/supabase_flutter.dart';
```
(already imported — just verify `RealtimeListenTypes` and `ChannelFilter` are accessible)

- [ ] **Step 7: Commit**
  ```bash
  git add mobile/lib/features/resident/
  git commit -m "feat: resident messages tab — realtime direct messages with conversation view"
  ```

---

### Task 5: Worker Dashboard — Route + Stops + Scan Tabs

**Files:**
- Modify: `mobile/lib/features/worker/screens/worker_dashboard_screen.dart`

- [ ] **Step 1: Read current worker dashboard**
  Read `mobile/lib/features/worker/screens/worker_dashboard_screen.dart` lines 1-400

- [ ] **Step 2: Add stop_completions insert helper**
```dart
Future<void> _completeStop(String stopId, {String? photoUrl, required String method}) async {
  final uid = Supabase.instance.client.auth.currentUser?.id;
  if (uid == null) return;
  await Supabase.instance.client.from('stop_completions').insert({
    'stop_id': stopId,
    'run_id': _activeRunId,
    'completed_by': uid,
    'photo_url': photoUrl,
    'method': method,
  });
}
```

- [ ] **Step 3: Build Scan tab (Amazon Flex style)**

Add `_buildScanTab()`:
```dart
int _currentStopIndex = 0;
List<Map<String, dynamic>> _stops = [];
bool _isCompletingStop = false;

Widget _buildScanTab() {
  if (_stops.isEmpty) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_outline, color: Color(0xFF30D158), size: 64),
          const SizedBox(height: 16),
          Text('All stops complete!', style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  final stop = _currentStopIndex < _stops.length ? _stops[_currentStopIndex] : null;
  
  return Padding(
    padding: const EdgeInsets.fromLTRB(20, 32, 20, 100),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('CURRENT STOP', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 1.2, color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        Text(
          '${_currentStopIndex + 1} of ${_stops.length}',
          style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.rlvBlue),
        ),
        const SizedBox(height: 20),
        if (stop != null) BentoCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                stop['unit_number'] ?? 'Unit',
                style: GoogleFonts.montserrat(fontSize: 36, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                stop['floor_name'] ?? '',
                style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isCompletingStop ? null : () => _photoConfirmStop(stop),
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: Text('Photo', style: GoogleFonts.montserrat(fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.surface1,
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isCompletingStop ? null : () => _manualCompleteStop(stop),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.rlvBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Mark Done', style: GoogleFonts.montserrat(fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _isCompletingStop ? null : () => _flagComeback(stop),
          icon: const Icon(Icons.flag_outlined, color: Color(0xFFFF453A)),
          label: Text('Flag Comeback', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: const Color(0xFFFF453A))),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFFFF453A)),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    ),
  );
}

Future<void> _photoConfirmStop(Map<String, dynamic>? stop) async {
  if (stop == null) return;
  final picker = ImagePicker();
  final image = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
  if (image == null) return;
  setState(() => _isCompletingStop = true);
  try {
    final bytes = await image.readAsBytes();
    final uid = Supabase.instance.client.auth.currentUser?.id ?? 'unknown';
    final path = 'stops/${stop['id']}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await Supabase.instance.client.storage.from('pickup-photos').uploadBinary(path, bytes);
    final url = Supabase.instance.client.storage.from('pickup-photos').getPublicUrl(path);
    await _completeStop(stop['id'], photoUrl: url, method: 'photo');
    _advanceStop();
  } finally {
    if (mounted) setState(() => _isCompletingStop = false);
  }
}

Future<void> _manualCompleteStop(Map<String, dynamic>? stop) async {
  if (stop == null) return;
  setState(() => _isCompletingStop = true);
  try {
    await _completeStop(stop['id'], method: 'manual');
    _advanceStop();
  } finally {
    if (mounted) setState(() => _isCompletingStop = false);
  }
}

void _advanceStop() {
  if (mounted) {
    setState(() => _currentStopIndex++);
  }
}

Future<void> _flagComeback(Map<String, dynamic>? stop) async {
  if (stop == null) return;
  // Reuse existing comeback request flow
  await Supabase.instance.client.from('missed_pickup_requests').insert({
    'unit_id': stop['unit_id'],
    'status': 'pending',
    'requested_at': DateTime.now().toIso8601String(),
  });
  if (mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Comeback flagged'), backgroundColor: Color(0xFFFF9F0A)),
    );
  }
  _advanceStop();
}
```

- [ ] **Step 4: Load stops from route_stops**

In `_loadData()` add:
```dart
// Load route stops with unit info
if (_activeRouteId != null) {
  final stopsData = await Supabase.instance.client
      .from('route_stops')
      .select('id, stop_order, unit_id, units(unit_number, floors(name))')
      .eq('route_id', _activeRouteId!)
      .order('stop_order');
  
  // Filter out already completed stops
  final completed = await Supabase.instance.client
      .from('stop_completions')
      .select('stop_id')
      .eq('run_id', _activeRunId ?? '');
  
  final completedIds = (completed as List).map((c) => c['stop_id'] as String).toSet();
  final remaining = (stopsData as List).where((s) => !completedIds.contains(s['id'])).map((s) {
    final unit = s['units'] as Map?;
    final floor = unit?['floors'] as Map?;
    return {
      'id': s['id'],
      'unit_id': s['unit_id'],
      'unit_number': unit?['unit_number'] ?? 'Unit',
      'floor_name': floor?['name'] ?? '',
    };
  }).toList();
  
  if (mounted) setState(() {
    _stops = remaining;
    _currentStopIndex = 0;
  });
}
```

- [ ] **Step 5: Wire Scan tab into bottom nav**

Ensure the Worker dashboard nav has: Route / Stops / Scan / Messages / More
And `_buildBody()` returns `_buildScanTab()` for index 2.

- [ ] **Step 6: Run tests**
  ```bash
  cd mobile && flutter analyze lib/features/worker/
  ```

- [ ] **Step 7: Commit**
  ```bash
  git add mobile/lib/features/worker/
  git commit -m "feat: worker scan tab — Amazon Flex style stop flow with photo + manual completion"
  ```

---

### Task 6: Operations Manager Dashboard

**Files:**
- Modify: `mobile/lib/features/manager/screens/manager_dashboard_screen.dart`

- [ ] **Step 1: Read current OM dashboard**
  Read `mobile/lib/features/manager/screens/manager_dashboard_screen.dart` lines 1-400

- [ ] **Step 2: Build Overview tab with bento + fl_chart line chart**

Add fields:
```dart
List<FlSpot> _serviceCompletionSpots = [];
List<String> _dateLabels = [];
```

Add to `_loadData()`:
```dart
// 7-day completion chart
final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
final runs = await Supabase.instance.client
    .from('nightly_runs')
    .select('run_date, status')
    .gte('run_date', sevenDaysAgo.toIso8601String())
    .order('run_date');

final Map<String, int> completedByDay = {};
for (final r in (runs as List)) {
  if (r['status'] == 'completed') {
    final day = (r['run_date'] as String).substring(0, 10);
    completedByDay[day] = (completedByDay[day] ?? 0) + 1;
  }
}
final spots = <FlSpot>[];
final labels = <String>[];
for (int i = 6; i >= 0; i--) {
  final day = DateTime.now().subtract(Duration(days: i));
  final key = '${day.year}-${day.month.toString().padLeft(2,'0')}-${day.day.toString().padLeft(2,'0')}';
  spots.add(FlSpot((6 - i).toDouble(), (completedByDay[key] ?? 0).toDouble()));
  labels.add(key.substring(5)); // MM-DD
}
if (mounted) setState(() {
  _serviceCompletionSpots = spots;
  _dateLabels = labels;
});
```

Rewrite `_buildOverviewTab()`:
```dart
Widget _buildOverviewTab() {
  return SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildOMGreeting(),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: BentoCard(height: 110, child: MetricTile(label: 'Properties', value: '$_totalProperties'))),
            const SizedBox(width: 12),
            Expanded(child: BentoCard(height: 110, child: MetricTile(label: 'Active Routes', value: '$_activeRoutes'))),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: BentoCard(height: 110, child: MetricTile(label: 'Tonight', value: '$_scheduledTonight', subtitle: 'properties', valueColor: AppColors.rlvBlue))),
            const SizedBox(width: 12),
            Expanded(child: BentoCard(height: 110, child: MetricTile(label: 'Comebacks', value: '$_openComebacks', valueColor: const Color(0xFFFF9F0A)))),
          ],
        ),
        const SizedBox(height: 20),
        Text('7-DAY SERVICE COMPLETIONS', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 1.2, color: AppColors.textSecondary)),
        const SizedBox(height: 12),
        BentoCard(
          height: 180,
          padding: const EdgeInsets.fromLTRB(16, 16, 24, 12),
          child: _serviceCompletionSpots.isEmpty
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.rlvBlue))
              : LineChart(LineChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, meta) {
                        final i = v.toInt();
                        if (i < 0 || i >= _dateLabels.length) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(_dateLabels[i], style: GoogleFonts.inter(fontSize: 9, color: AppColors.textSecondary)),
                        );
                      },
                    )),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _serviceCompletionSpots,
                      isCurved: true,
                      color: AppColors.rlvBlue,
                      barWidth: 2.5,
                      dotData: FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.rlvBlue.withValues(alpha: 0.1),
                      ),
                    ),
                  ],
                )),
        ),
      ],
    ),
  );
}
```

- [ ] **Step 3: Add fl_chart import**
```dart
import 'package:fl_chart/fl_chart.dart';
```

- [ ] **Step 4: Build Routes tab**
```dart
Widget _buildRoutesTab() {
  return SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Routes by Property', style: GoogleFonts.montserrat(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        const SizedBox(height: 20),
        ..._propertyRoutes.map((pr) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: BentoCard(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(pr['property_name'] ?? '', style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      Text('${pr['route_count']} route(s)', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OmWorkerMapScreen(propertyId: pr['property_id']))),
                  icon: const Icon(Icons.map_outlined, size: 16),
                  label: Text('Live Map', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                  style: TextButton.styleFrom(foregroundColor: AppColors.rlvBlue),
                ),
              ],
            ),
          ),
        )),
      ],
    ),
  );
}
```

- [ ] **Step 5: Load property routes data**
```dart
List<Map<String, dynamic>> _propertyRoutes = [];
int _activeRoutes = 0;
int _scheduledTonight = 0;
int _openComebacks = 0;

// In _loadData():
final propRoutes = await Supabase.instance.client
    .from('routes')
    .select('id, property_id, properties(name)')
    .eq('is_active', true);

final Map<String, Map<String, dynamic>> routeMap = {};
for (final r in (propRoutes as List)) {
  final pid = r['property_id'] as String;
  if (!routeMap.containsKey(pid)) {
    routeMap[pid] = {
      'property_id': pid,
      'property_name': (r['properties'] as Map?)?['name'] ?? 'Unknown',
      'route_count': 0,
    };
  }
  routeMap[pid]!['route_count'] = (routeMap[pid]!['route_count'] as int) + 1;
}
_propertyRoutes = routeMap.values.toList();
_activeRoutes = (propRoutes as List).length;

final comebacks = await Supabase.instance.client
    .from('missed_pickup_requests')
    .select('id')
    .eq('status', 'pending');
_openComebacks = (comebacks as List).length;
```

- [ ] **Step 6: Build Alerts tab**
```dart
Widget _buildAlertsTab() {
  return FutureBuilder(
    future: Supabase.instance.client
        .from('missed_pickup_requests')
        .select('id, status, requested_at, units(unit_number)')
        .order('requested_at', ascending: false)
        .limit(20),
    builder: (ctx, snap) {
      if (!snap.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.rlvBlue));
      final items = snap.data as List;
      return ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
        itemCount: items.length + 1,
        itemBuilder: (_, i) {
          if (i == 0) return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text('Alerts', style: GoogleFonts.montserrat(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          );
          final item = items[i - 1];
          final isPending = item['status'] == 'pending';
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: BentoCard(
              child: Row(
                children: [
                  Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(
                      color: isPending ? const Color(0xFFFF453A) : const Color(0xFF30D158),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Comeback Request — Unit ${(item['units'] as Map?)?['unit_number'] ?? '?'}',
                          style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                        Text(item['status'] ?? '', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
```

- [ ] **Step 7: Commit**
  ```bash
  git add mobile/lib/features/manager/screens/manager_dashboard_screen.dart
  git commit -m "feat: operations manager dashboard — bento overview, line chart, routes, alerts"
  ```

---

### Task 7: Owner Dashboard

**Files:**
- Modify: `mobile/lib/features/owner/screens/owner_dashboard_screen.dart`

- [ ] **Step 1: Add earned from comebacks metric**

Add field:
```dart
double _earnedFromComebacks = 0.0;
double _avgSatisfaction = 0.0;
```

In `_loadData()` add:
```dart
// Comeback earnings — count completed comeback runs * fee ($10 default)
final completedComebacks = await Supabase.instance.client
    .from('missed_pickup_requests')
    .select('id')
    .eq('status', 'completed');
_earnedFromComebacks = (completedComebacks as List).length * 10.0;

// Avg satisfaction
final ratings = await Supabase.instance.client
    .from('satisfaction_ratings')
    .select('rating');
if ((ratings as List).isNotEmpty) {
  final sum = ratings.fold<int>(0, (acc, r) => acc + (r['rating'] as int));
  _avgSatisfaction = sum / ratings.length;
}
```

- [ ] **Step 2: Rewrite Overview tab**
```dart
Widget _buildOverviewTab() {
  return SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Portfolio', style: GoogleFonts.montserrat(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        const SizedBox(height: 4),
        Text('Owner overview', style: GoogleFonts.inter(fontSize: 14, color: AppColors.textSecondary)),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(child: BentoCard(height: 110, child: MetricTile(label: 'Communities', value: '$_totalProperties'))),
            const SizedBox(width: 12),
            Expanded(child: BentoCard(height: 110, child: MetricTile(label: 'Total Units', value: '$_totalUnits'))),
          ],
        ),
        const SizedBox(height: 12),
        BentoCard(
          height: 120,
          child: MetricTile(
            label: 'Earned from Comebacks',
            value: '\$${_earnedFromComebacks.toStringAsFixed(0)}',
            subtitle: 'comeback service fees',
            valueColor: const Color(0xFF30D158),
          ),
        ),
        const SizedBox(height: 12),
        BentoCard(
          height: 110,
          child: Row(
            children: [
              Expanded(child: MetricTile(label: 'Residents', value: '$_totalResidents')),
              Container(width: 1, height: 60, color: AppColors.border),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: MetricTile(
                    label: 'Satisfaction',
                    value: _avgSatisfaction > 0 ? '${_avgSatisfaction.toStringAsFixed(1)}★' : '--',
                    subtitle: 'avg rating',
                    valueColor: AppColors.rlvBlue,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
```

- [ ] **Step 3: Commit**
  ```bash
  git add mobile/lib/features/owner/screens/owner_dashboard_screen.dart
  git commit -m "feat: owner dashboard — comeback earnings, satisfaction aggregate, bento layout"
  ```

---

### Task 8: Property Manager Dashboard

**Files:**
- Modify: `mobile/lib/features/manager/screens/property_manager_dashboard_new.dart`

- [ ] **Step 1: Read current PM dashboard**
  Read `mobile/lib/features/manager/screens/property_manager_dashboard_new.dart` lines 1-400

- [ ] **Step 2: Rewrite Dashboard tab**
```dart
Widget _buildDashboardTab() {
  return SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Dashboard', style: GoogleFonts.montserrat(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                Text(_propertyName ?? 'Your Property', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
              ],
            ),
            ElevatedButton.icon(
              onPressed: _sendAnnouncement,
              icon: const Icon(Icons.campaign_outlined, size: 18),
              label: Text('Announce', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.rlvBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(child: BentoCard(height: 110, child: MetricTile(label: 'Total Units', value: '$_totalUnits'))),
            const SizedBox(width: 12),
            Expanded(child: BentoCard(height: 110, child: MetricTile(label: 'Enrolled', value: '$_enrolledUnits', valueColor: AppColors.rlvBlue))),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: BentoCard(height: 110, child: MetricTile(label: 'Compliance', value: '$_complianceRate%', valueColor: const Color(0xFF30D158)))),
            const SizedBox(width: 12),
            Expanded(child: BentoCard(height: 110, child: MetricTile(label: 'Satisfaction', value: _avgSat > 0 ? '${_avgSat.toStringAsFixed(1)}★' : '--', valueColor: AppColors.rlvBlue))),
          ],
        ),
        const SizedBox(height: 20),
        Text('RECENT RUNS', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w600, letterSpacing: 1.2, color: AppColors.textSecondary)),
        const SizedBox(height: 12),
        ..._recentRuns.map((r) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: BentoCard(
            child: Row(
              children: [
                Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    color: r['status'] == 'completed' ? const Color(0xFF30D158) :
                           r['status'] == 'in_progress' ? AppColors.rlvBlue : AppColors.textSecondary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(r['run_date'] ?? '', style: GoogleFonts.inter(fontSize: 13, color: AppColors.textPrimary)),
                ),
                Text(r['status'] ?? '', style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
        )),
      ],
    ),
  );
}
```

- [ ] **Step 3: Add announcement send flow**
```dart
double _avgSat = 0.0;
int _enrolledUnits = 0;
int _complianceRate = 0;
List<Map<String, dynamic>> _recentRuns = [];

Future<void> _sendAnnouncement() async {
  final titleCtrl = TextEditingController();
  final bodyCtrl = TextEditingController();
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface1,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (ctx) => Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Send Announcement', style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
          const SizedBox(height: 16),
          TextField(
            controller: titleCtrl,
            style: GoogleFonts.inter(color: AppColors.textPrimary),
            decoration: InputDecoration(
              labelText: 'Title',
              labelStyle: GoogleFonts.inter(color: AppColors.textSecondary),
              filled: true, fillColor: AppColors.background,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: bodyCtrl,
            style: GoogleFonts.inter(color: AppColors.textPrimary),
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Message',
              labelStyle: GoogleFonts.inter(color: AppColors.textSecondary),
              filled: true, fillColor: AppColors.background,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.border)),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              final uid = Supabase.instance.client.auth.currentUser?.id;
              if (uid == null || _propertyId == null) return;
              await Supabase.instance.client.from('community_announcements').insert({
                'property_id': _propertyId,
                'title': titleCtrl.text.trim(),
                'body': bodyCtrl.text.trim(),
                'sent_by': uid,
              });
              if (ctx.mounted) Navigator.pop(ctx);
              if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Announcement sent')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.rlvBlue, foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text('Send', style: GoogleFonts.montserrat(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    ),
  );
}
```

- [ ] **Step 4: Load PM stats in _loadData()**
```dart
// Enrolled units (units with active resident_units records for this property)
final enrolled = await Supabase.instance.client
    .from('resident_units')
    .select('id')
    .eq('property_id', _propertyId!)
    .eq('is_active', true);
_enrolledUnits = (enrolled as List).length;

// Compliance rate
_complianceRate = _totalUnits > 0 ? ((_enrolledUnits / _totalUnits) * 100).round() : 0;

// Satisfaction for this property
final ratings = await Supabase.instance.client
    .from('satisfaction_ratings')
    .select('rating')
    .eq('property_id', _propertyId!);
if ((ratings as List).isNotEmpty) {
  final sum = ratings.fold<int>(0, (acc, r) => acc + (r['rating'] as int));
  _avgSat = sum / ratings.length;
}

// Recent runs
final runs = await Supabase.instance.client
    .from('nightly_runs')
    .select('run_date, status')
    .eq('property_id', _propertyId!)
    .order('run_date', ascending: false)
    .limit(5);
_recentRuns = List<Map<String, dynamic>>.from(runs);
```

- [ ] **Step 5: Commit**
  ```bash
  git add mobile/lib/features/manager/screens/property_manager_dashboard_new.dart
  git commit -m "feat: property manager dashboard — community health, compliance, satisfaction, announcements"
  ```

---

### Task 9: Full analyze + test + fix

**Files:** All modified files

- [ ] **Step 1: Run flutter analyze**
  ```bash
  cd mobile && flutter analyze --no-fatal-infos 2>&1 | head -60
  ```

- [ ] **Step 2: Fix any errors found**

- [ ] **Step 3: Run widget test**
  ```bash
  cd mobile && flutter test test/widget_test.dart -v
  ```

- [ ] **Step 4: Hot reload test on device/emulator**
  ```bash
  cd mobile && flutter run --debug
  ```
  Test each dashboard role via debug navigation buttons.

- [ ] **Step 5: Fix any runtime errors**

- [ ] **Step 6: Final commit**
  ```bash
  git add -A
  git commit -m "fix: post-build analyze and test fixes — all dashboards passing"
  ```

---
