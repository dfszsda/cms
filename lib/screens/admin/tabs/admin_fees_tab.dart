import 'package:flutter/material.dart';
import '../../admin_exam_fee_screen.dart';
import '../../admin_college_fee_screen.dart';

class AdminFeesTab extends StatelessWidget {
  const AdminFeesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Fees Management"), backgroundColor: Colors.indigo, foregroundColor: Colors.white),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildFeeCard(
            context,
            "College Fees",
            "Manage semester-wise academic fees",
            Icons.account_balance_wallet_rounded,
            Colors.green,
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminCollegeFeeScreen())),
          ),
          const SizedBox(height: 16),
          _buildFeeCard(
            context,
            "Examination Fees",
            "Manage semester-wise exam fees",
            Icons.assignment_rounded,
            Colors.blue,
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminExamFeeScreen())),
          ),
        ],
      ),
    );
  }

  Widget _buildFeeCard(BuildContext context, String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        contentPadding: const EdgeInsets.all(20),
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
