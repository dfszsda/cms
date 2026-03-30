import 'package:flutter/material.dart';
import '../../admin_exam_form_screen.dart';
import '../../admin_exam_timetable_screen.dart';

class AdminExaminationTab extends StatelessWidget {
  final String collegeId;
  const AdminExaminationTab({super.key, required this.collegeId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Examination Management"), backgroundColor: Colors.indigo, foregroundColor: Colors.white),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildExamCard(
            context,
            "Exam Forms",
            "Review and approve student exam forms",
            Icons.assignment_ind_rounded,
            Colors.purple,
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminExamFormScreen(collegeId: collegeId))),
          ),
          const SizedBox(height: 16),
          _buildExamCard(
            context,
            "Exam Timetable",
            "Schedule examinations for branches",
            Icons.calendar_month_rounded,
            Colors.deepPurple,
            () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminExamTimetableScreen(collegeId: collegeId))),
          ),
        ],
      ),
    );
  }

  Widget _buildExamCard(BuildContext context, String title, String subtitle, IconData icon, Color color, VoidCallback onTap) {
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
