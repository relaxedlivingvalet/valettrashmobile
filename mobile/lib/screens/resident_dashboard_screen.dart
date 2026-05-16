import 'package:flutter/material.dart';

class ResidentDashboardScreen extends StatelessWidget {
  const ResidentDashboardScreen({super.key});

  static const Color darkGreen = Color(0xFF00382F);
  static const Color mainGreen = Color(0xFF0FA958);
  static const Color lightGreen = Color(0xFFEFFFF6);
  static const Color softBorder = Color(0xFFE5EAEA);
  static const Color navDark = Color(0xFF061014);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFA),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _topHeader(),
                    const SizedBox(height: 20),
                    _serviceCard(),
                    const SizedBox(height: 18),
                    _statusCards(),
                    const SizedBox(height: 18),
                    _quickActions(),
                    const SizedBox(height: 18),
                    _availableServices(),
                    const SizedBox(height: 18),
                    _supportCard(),
                  ],
                ),
              ),
            ),
            _bottomNav(),
          ],
        ),
      ),
    );
  }

  Widget _topHeader() {
    return Row(
      children: [
        const CircleAvatar(
          radius: 32,
          backgroundColor: Colors.blueAccent,
          child: Icon(Icons.person, color: Colors.white, size: 38),
        ),
        const SizedBox(width: 18),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome!',
                style: TextStyle(
                  fontSize: 29,
                  fontWeight: FontWeight.w800,
                  color: darkGreen,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'JOHN DOE',
                style: TextStyle(
                  fontSize: 17,
                  letterSpacing: 0.5,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            color: lightGreen,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: mainGreen.withOpacity(.35)),
          ),
          child: const Column(
            children: [
              Text(
                'Worker Status',
                style: TextStyle(fontSize: 13),
              ),
              SizedBox(height: 5),
              Row(
                children: [
                  CircleAvatar(radius: 5, backgroundColor: mainGreen),
                  SizedBox(width: 8),
                  Text(
                    'ON DUTY',
                    style: TextStyle(
                      color: mainGreen,
                      fontWeight: FontWeight.w900,
                      fontSize: 17,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 3),
              Text(
                'Worker is active',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        const CircleAvatar(
          radius: 27,
          backgroundColor: mainGreen,
          child: Icon(Icons.notifications, color: Colors.white, size: 28),
        ),
      ],
    );
  }

  Widget _serviceCard() {
    return _card(
      child: Row(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: Color(0xFFEAF1FF),
            child: Icon(Icons.calendar_month, color: Colors.blue, size: 31),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'April 26, 2026',
                  style: TextStyle(
                    fontSize: 27,
                    fontWeight: FontWeight.w900,
                    color: darkGreen,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF93E0B2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    'Service Time: 6:00 PM - 10:00 PM',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          Container(width: 1, height: 85, color: softBorder),
          const SizedBox(width: 22),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Next Pickup In', style: TextStyle(fontSize: 15)),
                SizedBox(height: 8),
                Text(
                  '2h 15m',
                  style: TextStyle(
                    fontSize: 31,
                    fontWeight: FontWeight.w900,
                    color: mainGreen,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Starts at 6:00 PM',
                  style: TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
          const Icon(Icons.local_shipping, color: mainGreen, size: 60),
        ],
      ),
    );
  }

  Widget _statusCards() {
    return Row(
      children: [
        Expanded(
          child: _card(
            borderColor: mainGreen.withOpacity(.25),
            color: lightGreen,
            child: Column(
              children: [
                const Row(
                  children: [
                    Expanded(
                      child: Text(
                        'FREE COMEBACKS REMAINING',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    Icon(Icons.sync, color: mainGreen, size: 31),
                  ],
                ),
                const SizedBox(height: 15),
                const Text(
                  '1',
                  style: TextStyle(
                    fontSize: 62,
                    fontWeight: FontWeight.w900,
                    color: mainGreen,
                  ),
                ),
                const SizedBox(height: 10),
                _miniPill('1 of 1 used this month'),
                const SizedBox(height: 8),
                const Text('\$5 after limit'),
              ],
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _card(
            borderColor: Colors.red.withOpacity(.25),
            color: const Color(0xFFFFF4F4),
            child: Column(
              children: [
                const Row(
                  children: [
                    Expanded(
                      child: Text(
                        'VIOLATIONS',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    Icon(Icons.warning_amber_rounded,
                        color: Colors.red, size: 42),
                  ],
                ),
                const SizedBox(height: 15),
                const Text(
                  '1',
                  style: TextStyle(
                    fontSize: 62,
                    fontWeight: FontWeight.w900,
                    color: Colors.red,
                  ),
                ),
                const Text(
                  'Warning',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 14),
                _miniPill('Next violation = penalty'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _quickActions() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'QUICK ACTIONS',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 14),
          _actionTile(
            icon: Icons.event_available,
            title: 'Request Missed Pickup',
            subtitle: 'Free (1 left) – \$5 after limit',
            highlighted: true,
          ),
          _actionTile(
            icon: Icons.history,
            title: 'Service History',
            subtitle: 'View your past pickups and activity',
          ),
          _actionTile(
            icon: Icons.shopping_cart,
            title: 'Buy Extra Pickups',
            subtitle: 'Purchase additional pickups or comebacks',
            highlighted: true,
          ),
        ],
      ),
    );
  }

  Widget _availableServices() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'AVAILABLE SERVICES',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _serviceTile(Icons.local_shipping, 'Moving Service', 'Starting at \$59', Colors.blue),
              _serviceTile(Icons.cleaning_services, 'Maid Service', 'Starting at \$49', Colors.purple),
              _serviceTile(Icons.chair, 'Bulk Trash Pickup', 'Starting at \$29', Colors.orange),
              _serviceTile(Icons.more_horiz, 'More Services', 'View all', Colors.black87),
            ],
          ),
        ],
      ),
    );
  }

  Widget _supportCard() {
    return _card(
      child: Row(
        children: [
          const CircleAvatar(
            radius: 27,
            backgroundColor: Color(0xFFE2F5EE),
            child: Icon(Icons.headset_mic, color: Colors.black, size: 30),
          ),
          const SizedBox(width: 15),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Questions or Concerns?',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
                ),
                SizedBox(height: 4),
                Text(
                  "We're here to help.",
                  style: TextStyle(color: Colors.black54),
                ),
              ],
            ),
          ),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.send, color: mainGreen),
            label: const Text(
              'Send Message',
              style: TextStyle(
                color: mainGreen,
                fontWeight: FontWeight.w800,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: mainGreen),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bottomNav() {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 0, 18, 14),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: navDark,
        borderRadius: BorderRadius.circular(26),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(icon: Icons.home, label: 'Home', active: true),
          _NavItem(icon: Icons.groups, label: 'Extra Services'),
          _NavItem(icon: Icons.headset_mic, label: 'Support'),
          _NavItem(icon: Icons.person, label: 'Profile'),
        ],
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    bool highlighted = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: highlighted ? lightGreen : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: highlighted ? mainGreen : softBorder,
          width: 1.2,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        leading: Container(
          height: 58,
          width: 58,
          decoration: BoxDecoration(
            color: highlighted ? darkGreen : lightGreen,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: highlighted ? Colors.white : darkGreen),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right, size: 32),
        onTap: () {},
      ),
    );
  }

  Widget _serviceTile(
    IconData icon,
    String title,
    String subtitle,
    Color iconColor,
  ) {
    return Expanded(
      child: Container(
        height: 122,
        margin: const EdgeInsets.symmetric(horizontal: 5),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: softBorder),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 34),
            const SizedBox(height: 9),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13),
            ),
            const SizedBox(height: 5),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card({
    required Widget child,
    Color color = Colors.white,
    Color borderColor = softBorder,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(.025),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _miniPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.7),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: softBorder),
      ),
      child: Text(text),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;

  const _NavItem({
    required this.icon,
    required this.label,
    this.active = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: active ? ResidentDashboardScreen.mainGreen : Colors.white70,
          size: 28,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: active ? ResidentDashboardScreen.mainGreen : Colors.white,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
