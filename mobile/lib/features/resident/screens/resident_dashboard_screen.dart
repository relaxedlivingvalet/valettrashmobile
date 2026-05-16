import 'package:flutter/material.dart';

class ResidentDashboardScreen extends StatelessWidget {
  const ResidentDashboardScreen({super.key});

  static const Color green = Color(0xFF00A86B);
  static const Color dark = Color(0xFF0A1F1C);
  static const Color bg = Color(0xFFF6F8F8);

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(18),
                children: [
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
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Welcome!",
                  style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: dark)),
              Text("JOHN DOE"),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: green.withOpacity(.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Column(
            children: [
              Text("Worker Status"),
              Row(
                children: [
                  CircleAvatar(radius: 4, backgroundColor: green),
                  SizedBox(width: 6),
                  Text("ON DUTY",
                      style: TextStyle(
                          color: green, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        InkWell(
          onTap: () => _openPage(
            context,
            "Notifications",
            const Text("No new notifications right now."),
          ),
          child: const CircleAvatar(
            backgroundColor: green,
            child: Icon(Icons.notifications, color: Colors.white),
          ),
        )
      ],
    );
  }

  Widget _serviceCard(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => _openPage(
        context,
        "Service Calendar",
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Upcoming Service", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 12),
            Text("Date: April 26, 2026"),
            Text("Service Time: 6:00 PM - 10:00 PM"),
            Text("Next Pickup: 2h 15m"),
          ],
        ),
      ),
      child: _card(
        child: const Row(
          children: [
            Icon(Icons.calendar_month, size: 40, color: Colors.blue),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("April 26, 2026",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 6),
                  Text("Service: 6PM - 10PM"),
                ],
              ),
            ),
            Column(
              children: [
                Text("Next Pickup"),
                Text("2h 15m",
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: green)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _statusRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _card(
            color: green.withOpacity(.08),
            child: const Column(
              children: [
                Text("FREE COMEBACKS"),
                SizedBox(height: 10),
                Text("1",
                    style:
                        TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
                Text("1 of 1 left"),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => _openPage(
              context,
              "Violations",
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Current Status",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  SizedBox(height: 12),
                  Text("You currently have 1 warning."),
                  SizedBox(height: 10),
                  Text("Reason: Trash bag was not tied properly."),
                  SizedBox(height: 10),
                  Text("Next violation may result in a penalty."),
                ],
              ),
            ),
            child: _card(
              color: Colors.red.withOpacity(.08),
              child: const Column(
                children: [
                  Text("VIOLATIONS"),
                  SizedBox(height: 10),
                  Text("1",
                      style:
                          TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
                  Text("Warning"),
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
            "Request Pickup",
            "Free (1 left) • \$5 after limit",
            Icons.event,
            () => _openPage(
              context,
              "Request Pickup",
              const RequestPickupForm(),
            ),
          ),
          _action(
            context,
            "Service History",
            "View past pickups",
            Icons.history,
            () => _openPage(
              context,
              "Service History",
              const ServiceHistoryList(),
            ),
          ),
          _action(
            context,
            "Buy Extra Pickups",
            "Purchase pickups",
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
          const Text("Available Services",
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _serviceTile(context, "Moving Service",
                      Icons.local_shipping)),
              const SizedBox(width: 10),
              Expanded(
                  child:
                      _serviceTile(context, "Maid Service", Icons.cleaning_services)),
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
                  child: _serviceTile(context, "More Services", Icons.more_horiz)),
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
                child: Text("Questions or Concerns? We’re here to help")),
            ElevatedButton(
              onPressed: () => _openSupportForm(context),
              style: ElevatedButton.styleFrom(backgroundColor: green),
              child: const Text("Message"),
            )
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

  Widget _action(BuildContext context, String title, String subtitle,
      IconData icon, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: green),
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
            Icon(icon, color: green, size: 34),
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
        color: dark,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(context, Icons.home, "Home", () {}),
          _navItem(
              context,
              Icons.grid_view,
              "Extra Services",
              () => _openPage(
                    context,
                    "Extra Services",
                    const Text(
                        "Moving Service, Maid Service, Bulk Trash Pickup, TV Mounting, and more."),
                  )),
          _navItem(context, Icons.support, "Support",
              () => _openSupportForm(context)),
          _navItem(
              context,
              Icons.person,
              "Profile",
              () => _openPage(
                    context,
                    "Profile",
                    const Text("Resident profile details will appear here."),
                  )),
        ],
      ),
    );
  }

  Widget _navItem(
      BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12))
        ],
      ),
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
      body: Padding(
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
  String category = "Missed Pickup";

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text("Send Message",
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          value: category,
          decoration: const InputDecoration(
            labelText: "Category",
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: "Missed Pickup", child: Text("Missed Pickup")),
            DropdownMenuItem(value: "Billing", child: Text("Billing")),
            DropdownMenuItem(value: "Violation Question", child: Text("Violation Question")),
            DropdownMenuItem(value: "Extra Service", child: Text("Extra Service")),
            DropdownMenuItem(value: "Other", child: Text("Other")),
          ],
          onChanged: (value) => setState(() => category = value!),
        ),
        const SizedBox(height: 12),
        const TextField(
          maxLines: 5,
          decoration: InputDecoration(
            labelText: "Message",
            hintText: "Type your concern here...",
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.photo_camera),
          label: const Text("Attach Photo"),
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
            child: const Text("Send Message"),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Request a missed pickup.",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        const Text("You have 1 free comeback left this month."),
        const SizedBox(height: 12),
        const TextField(
          maxLines: 4,
          decoration: InputDecoration(
            labelText: "Notes",
            hintText: "Example: Trash is outside my door.",
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.photo_camera),
          label: const Text("Attach Photo"),
        ),
        const SizedBox(height: 18),
        ElevatedButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Pickup request submitted.")),
            );
          },
          style: ElevatedButton.styleFrom(
              backgroundColor: ResidentDashboardScreen.green),
          child: const Text("Submit Request"),
        ),
      ],
    );
  }
}

class ServiceHistoryList extends StatelessWidget {
  const ServiceHistoryList({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        ListTile(
          leading: Icon(Icons.check_circle, color: ResidentDashboardScreen.green),
          title: Text("Pickup Completed"),
          subtitle: Text("April 25, 2026 • 8:12 PM"),
        ),
        ListTile(
          leading: Icon(Icons.check_circle, color: ResidentDashboardScreen.green),
          title: Text("Pickup Completed"),
          subtitle: Text("April 23, 2026 • 7:45 PM"),
        ),
        ListTile(
          leading: Icon(Icons.warning, color: Colors.orange),
          title: Text("Violation Warning"),
          subtitle: Text("April 20, 2026 • Bag not tied"),
        ),
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
        trailing: Text(price,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("$title selected")),
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
        Text("Request $serviceName",
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        const TextField(
          decoration: InputDecoration(
            labelText: "Preferred Date",
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        const TextField(
          decoration: InputDecoration(
            labelText: "Address / Unit",
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        const TextField(
          maxLines: 4,
          decoration: InputDecoration(
            labelText: "Details",
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 18),
        ElevatedButton(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("$serviceName request submitted.")),
            );
          },
          style: ElevatedButton.styleFrom(
              backgroundColor: ResidentDashboardScreen.green),
          child: const Text("Submit Request"),
        ),
      ],
    );
  }
}