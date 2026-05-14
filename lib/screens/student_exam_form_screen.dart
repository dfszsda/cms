import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/exam_form_model.dart';
import '../services/auth_service.dart';
import '../services/error_handler.dart';

class StudentExamFormScreen extends StatefulWidget {
  final UserModel student;
  const StudentExamFormScreen({super.key, required this.student});

  @override
  State<StudentExamFormScreen> createState() => _StudentExamFormScreenState();
}

class _StudentExamFormScreenState extends State<StudentExamFormScreen> {
  final _auth = AuthService();
  final TextEditingController _reasonCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Exam Form"),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<ExamFormModel?>(
        stream: _auth.getStudentExamForm(widget.student.uid),
        builder: (context, snapshot) {
          if (snapshot.hasError) return AppErrorHandler.buildErrorWidget(snapshot.error, () => setState(() {}));
          if (snapshot.connectionState == ConnectionState.waiting) {
            return AppErrorHandler.buildLoadingWidget();
          }
          
          final form = snapshot.data;
          
          if (form == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_late_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text("Exam form not generated yet.", style: TextStyle(fontSize: 18, color: Colors.grey)),
                  Text("Please contact admin.", style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          return Column(
            children: [
              _buildStatusBanner(form.status),
              if (form.status == 'Rejected')
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  color: Colors.red[50],
                  child: Text("REJECTION REASON: ${form.rejectReason}", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: form.subjects.length,
                  itemBuilder: (context, index) {
                    final sub = form.subjects[index];
                    return Card(
                      child: ListTile(
                        leading: Icon(sub.type == 'Theory' ? Icons.menu_book : Icons.science, color: Colors.deepOrange),
                        title: Text(sub.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(sub.type),
                      ),
                    );
                  },
                ),
              ),
              if (form.status == 'Pending' || form.status == 'Rejected')
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _showRejectDialog(form.id!),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                          child: const Text("REJECT FORM"),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _handleConfirm(form.id!),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                          ),
                          child: const Text("CONFIRM FORM"),
                        ),
                      ),
                    ],
                  ),
                )
              else if (form.status == 'Confirmed')
                const Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, color: Colors.green),
                      SizedBox(width: 10),
                      Text("You have confirmed this form.", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatusBanner(String status) {
    Color color = Colors.orange;
    if (status == 'Confirmed') color = Colors.green;
    if (status == 'Rejected') color = Colors.red;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: color.withOpacity(0.1),
      child: Center(
        child: Text(
          "STATUS: ${status.toUpperCase()}",
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  void _handleConfirm(String formId) async {
    LoadingOverlay.show(context);
    try {
      await _auth.updateExamFormStatus(formId, 'Confirmed');
      if (mounted) AppErrorHandler.showSuccess(context, "Exam Form Confirmed!");
    } catch (e) {
      if (mounted) AppErrorHandler.showError(context, e);
    } finally {
      if (mounted) LoadingOverlay.hide(context);
    }
  }

  void _showRejectDialog(String formId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Reject Exam Form"),
        content: TextField(
          controller: _reasonCtrl,
          decoration: const InputDecoration(
            hintText: "Enter reason for rejection...",
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (_reasonCtrl.text.isEmpty) {
                AppErrorHandler.showError(ctx, "Please enter a reason");
                return;
              }
              
              LoadingOverlay.show(ctx);
              try {
                await _auth.updateExamFormStatus(formId, 'Rejected', reason: _reasonCtrl.text.trim());
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                }
                if (mounted) {
                  _reasonCtrl.clear();
                  AppErrorHandler.showSuccess(context, "Form Rejected and Admin notified.");
                }
              } catch (e) {
                if (ctx.mounted) AppErrorHandler.showError(ctx, e);
              } finally {
                if (ctx.mounted) LoadingOverlay.hide(ctx);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text("Submit Rejection"),
          ),
        ],
      ),
    );
  }
}
