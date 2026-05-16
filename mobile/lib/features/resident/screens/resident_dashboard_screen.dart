import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'resident_notifications_screen.dart';
import 'resident_violations_screen.dart';

class ResidentDashboardScreen extends StatefulWidget {
  const ResidentDashboardScreen({super.key});

  static const Color green = Color(0xFF00A86B);
  static const Color dark = Color(0xFF0A1F1C);
  static const Color bg = Color(0xFFF6F8F8);

  @override
  State<ResidentDashboardScreen> createState() =>
      _ResidentDashboardScreenState();
}

class _ResidentDashboardScreenState extends State<ResidentDashboardScreen> {
  bool _loading = true;
  String? _loadError;

  String _residentName = 'Resident';
  String _propertyName = '';
  String _serviceDateStr = '--';
  String _windowShort = '--';
  String _countdownLabel = '—';
  int _freeRemain = 0;
  String _freeSummary = '--';
  int _violationsCount = 0;
  num _comebackFee = 15;

  @override
  void initState() {
    super.initState();
    _load();
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

  String _nextWindowPhrase(DateTime todayLocal, dynamic startStr, dynamic endStr) {
    final startLbl = _fmtTime(startStr);
    final endLbl = _fmtTime(endStr);
    final partsStart = startStr.toString().split(':');
    if (partsStart.length < 2) return 'Window $startLbl – $endLbl';
    final sh = int.tryParse(partsStart[0]) ?? 18;
    final sm = int.tryParse(partsStart[1]) ?? 0;
    var start = DateTime(todayLocal.year, todayLocal.month, todayLocal.day, sh, sm);
    if (todayLocal.isBefore(start)) {
      final mins = start.difference(todayLocal).inMinutes;
      if (mins < 60) return 'Starts in ${mins}m';
      final h = mins ~/ 60;
      final m = mins % 60;
      return 'Starts in ${h}h ${m}m';
    }
    final partsEnd = endStr.toString().split(':');
    if (partsEnd.length < 2) return 'In service until $endLbl';
    final eh = int.tryParse(partsEnd[0]) ?? 22;
    final em = int.tryParse(partsEnd[1]) ?? 0;
    final end = DateTime(todayLocal.year, todayLocal.month, todayLocal.day, eh, em);
    if (todayLocal.isBefore(end)) {
      return 'In service until ${_fmtTime(endStr)}';
    }
    return 'Next window tomorrow $startLbl – $endLbl';
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
        if (fn.isNotEmpty || ln.isNotEmpty) {
          _residentName = ('$fn $ln').trim();
        }
      }

      Map<String, dynamic>? prop;
      Map<String, dynamic>? assignmentMap;
      if (assignment != null) {
        assignmentMap = Map<String, dynamic>.from(assignment as Map);

        dynamic propsRaw = assignmentMap['properties'];
        if (propsRaw is Map) {
          prop = Map<String, dynamic>.from(propsRaw);
        }
      }

      if (prop != null && assignmentMap != null) {
        _propertyName = prop['name']?.toString() ?? '';
        _comebackFee = prop['comeback_pickup_fee'] is num
            ? prop['comeback_pickup_fee'] as num
            : 15;
        final freeCapRaw = prop['free_comeback_pickups_per_month'];
        final freeCap = freeCapRaw is int
            ? freeCapRaw
            : int.tryParse('$freeCapRaw') ?? 0;
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
        _freeRemain = remain < 0
            ? 0
            : (remain > freeCap ? freeCap : remain);

        _freeSummary = freeCap <= 0
            ? 'No free comebacks configured'
            : '$_freeRemain of $freeCap left this month';

        _serviceDateStr = '${now.month}/${now.day}/${now.year}';
        final startT = prop['service_window_start'];
        final endT = prop['service_window_end'];
        _windowShort = '${_fmtTime(startT)} – ${_fmtTime(endT)}';
        _countdownLabel = _nextWindowPhrase(now, startT, endT);
      }


      final viol = await Supabase.instance.client
          .from('violations')
          .select('id')
          .eq('resident_user_id', uid);
      _violationsCount = viol is List ? viol.length : 0;

      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _loading = false;
        _loadError = e.toString();
      });
    }
  }

  void _openPage(BuildContext context, String title, Widget child) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SimplePage(title: title, child: child),
      ),
    );
  }

  void _openSupportForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          left: 18,
          right: 18,
          top: 18,
          bottom: MediaQuery.of(context).viewInsets.bottom + 18,
        ),
        child: const SupportForm(),
      ),
    );
  }

  void _openBuyPickups(BuildContext context) {
    _openPage(
      context,
      "Buy Extra Pickups",
      Column(
        children: const [
          PickupPackage(title: "1 Extra Pickup", price: "\$5"),
          PickupPackage(title: "3 Extra Pickups", price: "\$13"),
          PickupPackage(title: "5 Extra Pickups", price: "\$20"),
        ],
      ),
    );
  }

  Future<void> _signOut(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
    if (!context.mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ResidentDashboardScreen.bg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.all(18),
                      children: [
                        if (_loadError != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Text(
                              _loadError!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        _header(context),
                        const SizedBox(height: 20),
                        _serviceCard(context),
                        const SizedBox(height: 16),
                        _statusRow(context),
                        const SizedBox(height: 16),
                        _quickActions(context),
                        const SizedBox(height: 16),
                        _services(context),
                        const SizedBox(height: 16),
                        _support(context),
                      ],
                    ),
            ),
            _bottomNav(context),
          ],
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Row(
      children: [
        const CircleAvatar(radius: 28, backgroundColor: Colors.blue),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Welcome!",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: ResidentDashboardScreen.dark,
                ),
              ),
              Text(_residentName.toUpperCase()),
              if (_propertyName.isNotEmpty)
                Text(
                  _propertyName,
                  style: const TextStyle(color: Colors.black54, fontSize: 13),
                ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: ResidentDashboardScreen.green.withOpacity(.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Column(
            children: [
              Text("Worker Status"),
              Row(
                children: [
                  CircleAvatar(radius: 4, backgroundColor: ResidentDashboardScreen.green),
                  SizedBox(width: 6),
                  Text(
                    "SCHEDULED",
                    style: TextStyle(
                      color: ResidentDashboardScreen.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ResidentNotificationsScreen(),
              ),
            );
          },
          child: const CircleAvatar(
            backgroundColor: ResidentDashboardScreen.green,
            child: Icon(Icons.notifications, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _serviceCard(BuildContext context) {
    final detail = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Upcoming service",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Text("Date: $_serviceDateStr"),
        Text("Service window: $_windowShort"),
        Text(_countdownLabel),
      ],
    );
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => _openPage(context, "Service details", detail),
      child: _card(
        child: Row(
          children: [
            const Icon(Icons.calendar_month, size: 40, color: Colors.blue),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _serviceDateStr,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(_windowShort),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text("Tonight"),
                Text(
                  _countdownLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: ResidentDashboardScreen.green,
                  ),
                  textAlign: TextAlign.right,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusRow(BuildContext context) {
    final feeLabel =
        '\$${_comebackFee is int ? (_comebackFee as int).toString() : _comebackFee.toStringAsFixed(2)} after limit';

    return Row(
      children: [
        Expanded(
          child: _card(
            color: ResidentDashboardScreen.green.withOpacity(.08),
            child: Column(
              children: [
                const Text("FREE COMEBACKS"),
                const SizedBox(height: 10),
                Text(
                  '$_freeRemain',
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(_freeSummary),
                Text(feeLabel, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ResidentViolationsScreen(),
                ),
              );
            },
            child: _card(
              color: Colors.red.withOpacity(.08),
              child: Column(
                children: [
                  const Text("VIOLATIONS"),
                  const SizedBox(height: 10),
                  Text(
                    '$_violationsCount',
                    style: const TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _violationsCount == 0 ? 'Clear' : 'Review details',
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _quickActions(BuildContext context) {
    return _card(
      child: Column(
        children: [
          _action(
            context,
            "Request pickup / comeback",
            _freeRemain > 0
                ? "Free (${_freeRemain} left this month)"
                : "Fees may apply — see property rules",
            Icons.event,
            () => _openPage(
              context,
              "Request pickup",
              const RequestPickupForm(),
            ),
          ),
          _action(
            context,
            "Service history",
            "Recent pickups",
            Icons.history,
            () => _openPage(
              context,
              "Service history",
              const ResidentPickupHistoryView(),
            ),
          ),
          _action(
            context,
            "Buy extra pickups",
            "Purchase pickups / comebacks",
            Icons.shopping_cart,
            () => _openBuyPickups(context),
          ),
        ],
      ),
    );
  }

  Widget _services(BuildContext context) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Available services",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _serviceTile(
                      context, "Moving Service", Icons.local_shipping)),
              const SizedBox(width: 10),
              Expanded(
                child:
                    _serviceTile(context, "Maid Service", Icons.cleaning_services),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                  child:
                      _serviceTile(context, "Bulk Trash Pickup", Icons.delete)),
              const SizedBox(width: 10),
              Expanded(
                child:
                    _serviceTile(context, "More services", Icons.more_horiz),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _support(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => _openSupportForm(context),
      child: _card(
        child: Row(
          children: [
            const Icon(Icons.support_agent),
            const SizedBox(width: 10),
            const Expanded(
              child:
                  Text("Questions or concerns? We’re here to help"),
            ),
            ElevatedButton(
              onPressed: () => _openSupportForm(context),
              style: ElevatedButton.styleFrom(
                  backgroundColor: ResidentDashboardScreen.green),
              child: const Text("Message"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card({required Widget child, Color color = Colors.white}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(18),
      ),
      child: child,
    );
  }

  Widget _action(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: ResidentDashboardScreen.green),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
    );
  }

  Widget _serviceTile(BuildContext context, String label, IconData icon) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _openPage(
        context,
        label,
        ServiceRequestPage(serviceName: label),
      ),
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.grey.shade100,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: ResidentDashboardScreen.green, size: 34),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _bottomNav(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: ResidentDashboardScreen.dark,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(context, Icons.home, "Home", () {}),
          _navItem(
            context,
            Icons.grid_view,
            "Extras",
            () => _openPage(
              context,
              "Extra services",
              const Text(
                "Moving, maid service, bulk pickup — request via property office.",
              ),
            ),
          ),
          _navItem(
            context,
            Icons.support,
            "Support",
            () => _openSupportForm(context),
          ),
          _navItem(
            context,
            Icons.person,
            "Profile",
            () => _openPage(
              context,
              "Profile",
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Signed in as\n${_residentName.isNotEmpty ? _residentName : 'Resident'}',
                      style: const TextStyle(fontSize: 16)),
                  const SizedBox(height: 24),
                  OutlinedButton(
                    onPressed: () => _signOut(context),
                    child: const Text('Sign out'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem(
    BuildContext context,
    IconData icon,
    String label,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}

/// Loads recent pickups for the authenticated resident.
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

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchPickups(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final list = snap.data!;
        if (list.isEmpty) {
          return const Text('No pickup history yet.');
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: list.length,
          itemBuilder: (context, i) {
            final row = list[i];
            final u = row['units'];
            String unit = '?';
            if (u is Map && u['unit_number'] != null) {
              unit = '${u['unit_number']}';
            }
            final when = row['completed_at'] ?? row['created_at'];
            return ListTile(
              leading: Icon(
                row['status'] == 'completed'
                    ? Icons.check_circle
                    : Icons.schedule,
                color: ResidentDashboardScreen.green,
              ),
              title: Text(_prettyStatus(row['status'] as String?)),
              subtitle: Text('Unit $unit · $when'),
            );
          },
        );
      },
    );
  }
}

class SimplePage extends StatelessWidget {
  final String title;
  final Widget child;

  const SimplePage({super.key, required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ResidentDashboardScreen.bg,
      appBar: AppBar(
        backgroundColor: ResidentDashboardScreen.dark,
        foregroundColor: Colors.white,
        title: Text(title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: child,
      ),
    );
  }
}

class SupportForm extends StatefulWidget {
  const SupportForm({super.key});

  @override
  State<SupportForm> createState() => _SupportFormState();
}

class _SupportFormState extends State<SupportForm> {
  String category = "Missed pickup";
  final _messageCtrl = TextEditingController();

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          "Send message",
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: category,
          decoration: const InputDecoration(
            labelText: "Category",
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(
                value: "Missed pickup", child: Text("Missed pickup")),
            DropdownMenuItem(value: "Billing", child: Text("Billing")),
            DropdownMenuItem(
                value: "Violation question",
                child: Text("Violation question")),
            DropdownMenuItem(
                value: "Extra service", child: Text("Extra service")),
            DropdownMenuItem(value: "Other", child: Text("Other")),
          ],
          onChanged: (value) => setState(() => category = value!),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _messageCtrl,
          maxLines: 5,
          decoration: const InputDecoration(
            labelText: "Message",
            hintText: "Type your concern here...",
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: ResidentDashboardScreen.green,
              padding: const EdgeInsets.all(14),
            ),
            child: const Text("Close"),
          ),
        ),
      ],
    );
  }
}

class RequestPickupForm extends StatelessWidget {
  const RequestPickupForm({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Request a missed pickup or comeback.",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 12),
        Text(
          "Property staff will coordinate based on tonight’s route. "
          "For urgent issues, contact the office from Support.",
        ),
        SizedBox(height: 24),
      ],
    );
  }
}

class PickupPackage extends StatelessWidget {
  final String title;
  final String price;

  const PickupPackage({super.key, required this.title, required this.price});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(title),
        subtitle: const Text("Extra pickup package"),
        trailing: Text(
          price,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("$title — checkout coming soon.")),
          );
        },
      ),
    );
  }
}

class ServiceRequestPage extends StatelessWidget {
  final String serviceName;

  const ServiceRequestPage({super.key, required this.serviceName});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Request $serviceName",
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        const TextField(
          decoration: InputDecoration(
            labelText: "Preferred date",
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        const TextField(
          decoration: InputDecoration(
            labelText: "Notes",
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 18),
        ElevatedButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text("$serviceName — request forwarded to property team."),
              ),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: ResidentDashboardScreen.green,
          ),
          child: const Text("Submit"),
        ),
      ],
    );
  }
}
