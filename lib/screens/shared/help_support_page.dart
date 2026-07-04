import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpSupportPage extends StatelessWidget {
  final bool isDriver;
  const HelpSupportPage({super.key, this.isDriver = false});

  static const String supportEmail = "support@sajiloride.com";
  static const String supportPhone = "+977-9845673344";

  static const List<Map<String, String>> _passengerFaqs = [
    {
      "q": "How do I book a ride?",
      "a": "Set your pickup and drop-off location on the home screen, choose a ride type, "
          "and confirm the booking. A nearby driver will be assigned to you.",
    },
    {
      "q": "How can I track my driver?",
      "a": "Once a driver accepts your ride, you can see their live location and estimated "
          "arrival time on the map screen.",
    },
    {
      "q": "Can I cancel a ride after booking?",
      "a": "Yes, you can cancel a ride before the driver arrives at your pickup location. "
          "Go to 'My Ride History' and select the ongoing ride to cancel it.",
    },
    {
      "q": "What payment methods are supported?",
      "a": "You can pay using eSewa or Cash. You can choose your preferred method before "
          "or after the ride from the Payment Methods section.",
    },
    {
      "q": "What is the refund policy?",
      "a": "If a ride is cancelled after payment, any amount paid is refunded to your original "
          "payment method within 3–5 working days.",
    },
    {
      "q": "How do I report an issue with a ride?",
      "a": "Go to My Ride History, select the ride in question, and tap 'Report an Issue', "
          "or contact our support team directly using the details below.",
    },
  ];

  static const List<Map<String, String>> _driverFaqs = [
    {
      "q": "How do I start receiving ride requests?",
      "a": "Go to 'My Vehicle Details' in your profile and save your vehicle information "
          "(plate number, model, price per km, photo). Once saved, you become visible "
          "to nearby passengers automatically.",
    },
    {
      "q": "How do ride requests work?",
      "a": "When a passenger selects your car, a ride request appears on your Driver Home "
          "screen. You can choose to Accept or Decline it.",
    },
    {
      "q": "How is the fare calculated?",
      "a": "Fare is calculated using the price per kilometer you set in your vehicle details, "
          "multiplied by the actual distance of the ride.",
    },
    {
      "q": "Can I cancel a ride after accepting it?",
      "a": "Yes, you can cancel from the active ride screen. However, frequent cancellations "
          "after accepting may affect your reliability with passengers.",
    },
    {
      "q": "Where can I see my earnings?",
      "a": "Go to your Profile and open 'Ride History' or 'My Earnings' to see the total "
          "earned from your completed rides.",
    },
    {
      "q": "How do I update my vehicle details?",
      "a": "Go to Profile → My Vehicle Details to update your plate number, car model, "
          "price per km, or vehicle photo anytime.",
    },
    {
      "q": "What is the document verification step for?",
      "a": "During signup, you submit your license and complete a quick face verification. "
          "This confirms your identity before you can start accepting rides.",
    },
  ];

  Future<void> _launchEmail(BuildContext context) async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: supportEmail,
      query: 'subject=Sajilo Ride Support Request',
    );
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not open email app")),
      );
    }
  }

  Future<void> _launchPhone(BuildContext context) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: supportPhone);
    if (await canLaunchUrl(phoneUri)) {
      await launchUrl(phoneUri);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not open dialer")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final faqs = isDriver ? _driverFaqs : _passengerFaqs;
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Help & Support", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionCard(
            title: "Help & FAQs",
            child: Column(
              children: faqs
                  .map((faq) => _FaqTile(question: faq["q"]!, answer: faq["a"]!))
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
          _sectionCard(
            title: "Contact Support",
            child: Column(
              children: [
                _contactTile(
                  icon: Icons.email_outlined,
                  label: "Email",
                  value: supportEmail,
                  onTap: () => _launchEmail(context),
                ),
                const Divider(height: 1),
                _contactTile(
                  icon: Icons.call_outlined,
                  label: "Phone Number",
                  value: supportPhone,
                  onTap: () => _launchPhone(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _contactTile({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: Colors.orange),
      ),
      title: Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      subtitle: Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
    );
  }
}

class _FaqTile extends StatelessWidget {
  final String question;
  final String answer;

  const _FaqTile({required this.question, required this.answer});

  @override
  Widget build(BuildContext context) {
    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 12, right: 4),
      iconColor: Colors.orange,
      collapsedIconColor: Colors.grey,
      title: Text(
        "Q: $question",
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            "A: $answer",
            style: const TextStyle(fontSize: 13, color: Colors.black87, height: 1.4),
          ),
        ),
      ],
    );
  }
}