import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/user_model.dart';
import '../models/leave_model.dart';
import '../services/auth_service.dart';

class CoordinatorLeaveScreen extends StatefulWidget {
  final UserModel coordinator;
  const CoordinatorLeaveScreen({super.key, required this.coordinator});

  @override
  State<CoordinatorLeaveScreen> createState() => _CoordinatorLeaveScreenState();
}

class _CoordinatorLeaveScreenState extends State<CoordinatorLeaveScreen> {
  final _auth = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Student Leave Requests"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<LeaveModel>>(
        stream: _auth.getLeaveRequestsForCoordinator(widget.coordinator.uid),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final leaves = snapshot.data!;
          if (leaves.isEmpty) return const Center(child: Text("No leave requests found for your batches."));

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: leaves.length,
            itemBuilder: (context, index) {
              final leave = leaves[index];
              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(leave.studentName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                                Text("${leave.batch} | ${leave.branch}", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                              ],
                            ),
                          ),
                          _buildStatusBadge(leave.status),
                        ],
                      ),
                      const Divider(height: 24),
                      _buildInfoRow(Icons.calendar_today, "Dates", "${DateFormat('dd MMM').format(leave.startDate)} to ${DateFormat('dd MMM').format(leave.endDate)}"),
                      const SizedBox(height: 8),
                      _buildInfoRow(Icons.info_outline, "Reason", leave.reason),
                      const SizedBox(height: 12),
                      if (leave.proofUrl != null) ...[
                        Row(
                          children: [
                            const Icon(Icons.attach_file, size: 20, color: Colors.indigo),
                            const SizedBox(width: 8),
                            TextButton(
                              onPressed: () => _showProofDialog(leave),
                              child: Text("View Proof (${leave.proofType?.toUpperCase() ?? 'File'})", style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ],
                      if (leave.status == 'pending') ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => _auth.updateLeaveStatus(leave.id, 'rejected'),
                                style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                                child: const Text("REJECT"),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () => _auth.updateLeaveStatus(leave.id, 'approved'),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                child: const Text("APPROVE"),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color = Colors.orange;
    if (status == 'approved') color = Colors.green;
    if (status == 'rejected') color = Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(status.toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11)),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(color: Colors.black, fontSize: 14),
              children: [
                TextSpan(text: "$label: ", style: const TextStyle(fontWeight: FontWeight.bold)),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showProofDialog(LeaveModel leave) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Leave Proof"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Proof File: ${leave.proofUrl}"),
            const SizedBox(height: 20),
            const Icon(Icons.description, size: 64, color: Colors.grey),
            const SizedBox(height: 20),
            const Text("In a real app, the image or PDF would be displayed here using a URL from Firebase Storage.", textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Close")),
        ],
      ),
    );
  }
}
