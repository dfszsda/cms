// ignore_for_file: unused_field

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:file_picker/file_picker.dart';
import '../models/user_model.dart';
import '../models/leave_model.dart';
import '../services/auth_service.dart';
import '../services/error_handler.dart';

class StudentLeaveScreen extends StatefulWidget {
  final UserModel student;
  const StudentLeaveScreen({super.key, required this.student});

  @override
  State<StudentLeaveScreen> createState() => _StudentLeaveScreenState();
}

class _StudentLeaveScreenState extends State<StudentLeaveScreen> {
  final _auth = AuthService();
  final _reasonCtrl = TextEditingController();
  DateTime _focusedDay = DateTime.now();
  DateTime? _rangeStart;
  DateTime? _rangeEnd;
  PlatformFile? _pickedFile;
  bool _isUploading = false;
  String _coordinatorName = "Loading...";

  @override
  void initState() {
    super.initState();
    _fetchCoordinatorName();
  }

  Future<void> _fetchCoordinatorName() async {
    try {
      final batchSnap = await FirebaseFirestore.instance
          .collection('batches')
          .where('fullName', isEqualTo: widget.student.batch)
          .limit(1)
          .get();
      
      if (batchSnap.docs.isNotEmpty) {
        String? coordinatorId = batchSnap.docs.first.data()['coordinatorId'];
        if (coordinatorId != null) {
          final userDoc = await FirebaseFirestore.instance.collection('users').doc(coordinatorId).get();
          if (userDoc.exists) {
            setState(() => _coordinatorName = userDoc.data()?['fullName'] ?? "Not Assigned");
            return;
          }
        }
      }
      setState(() => _coordinatorName = "Not Assigned");
    } catch (e) {
      if (mounted) AppErrorHandler.showError(context, e);
      setState(() => _coordinatorName = "Error loading name");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Request Leave"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Coordinator Info Section
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.indigo.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.indigo.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_pin_rounded, color: Colors.indigo),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Batch Coordinator:", style: TextStyle(fontSize: 12, color: Colors.indigo, fontWeight: FontWeight.bold)),
                        Text(_coordinatorName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text("Select Leave Dates", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            TableCalendar(
              firstDay: DateTime.now(),
              lastDay: DateTime.now().add(const Duration(days: 365)),
              focusedDay: _focusedDay,
              rangeStartDay: _rangeStart,
              rangeEndDay: _rangeEnd,
              calendarFormat: CalendarFormat.month,
              rangeSelectionMode: RangeSelectionMode.toggledOn,
              onRangeSelected: (start, end, focusedDay) {
                setState(() {
                  _rangeStart = start;
                  _rangeEnd = end;
                  _focusedDay = focusedDay;
                });
              },
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _reasonCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: "Reason for Leave",
                border: OutlineInputBorder(),
                hintText: "Enter the reason for your leave request...",
              ),
            ),
            const SizedBox(height: 20),
            const Text("Upload Proof (Photo or PDF)", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            InkWell(
              onTap: _pickFile,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[100],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.attach_file),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(_pickedFile?.name ?? "No file selected"),
                    ),
                    if (_pickedFile != null)
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () => setState(() => _pickedFile = null),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
                onPressed: _submitLeaveRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(50),
                ),
                child: const Text("SUBMIT REQUEST"),
              ),
            const SizedBox(height: 30),
            const Text("Your Recent Leave Requests", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _buildLeaveHistory(),
          ],
        ),
      ),
    );
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
    );

    if (result != null) {
      setState(() => _pickedFile = result.files.first);
    }
  }

  Future<void> _submitLeaveRequest() async {
    if (_rangeStart == null || _reasonCtrl.text.isEmpty) {
      AppErrorHandler.showError(context, "Please select dates and enter reason");
      return;
    }

    LoadingOverlay.show(context);

    try {
      // Find coordinator for the student's batch
      String? coordinatorId;
      final batchSnap = await FirebaseFirestore.instance
          .collection('batches')
          .where('fullName', isEqualTo: widget.student.batch)
          .limit(1)
          .get();
      
      if (batchSnap.docs.isNotEmpty) {
        coordinatorId = batchSnap.docs.first.data()['coordinatorId'];
      }

      if (coordinatorId == null) {
        AppErrorHandler.showError(context, "Coordinator not assigned for your batch yet. Contact Admin.");
        return;
      }

      // In a real app, you would upload _pickedFile to Firebase Storage here
      // and get the download URL. For now, we'll store the name as a placeholder.
      String? proofUrl = _pickedFile?.name;
      String? proofType = _pickedFile?.extension == 'pdf' ? 'pdf' : 'image';

      final leave = LeaveModel(
        id: '',
        studentUid: widget.student.uid,
        studentName: widget.student.fullName,
        batch: widget.student.batch ?? 'N/A',
        branch: widget.student.branch ?? 'N/A',
        startDate: _rangeStart!,
        endDate: _rangeEnd ?? _rangeStart!,
        reason: _reasonCtrl.text.trim(),
        proofUrl: proofUrl,
        proofType: proofType,
        status: 'pending',
        coordinatorId: coordinatorId,
        createdAt: DateTime.now(),
      );

      await FirebaseFirestore.instance.collection('leaves').add(leave.toMap());
      
      if (mounted) {
        AppErrorHandler.showSuccess(context, "Leave request submitted successfully!");
        _reasonCtrl.clear();
        setState(() {
          _rangeStart = null;
          _rangeEnd = null;
          _pickedFile = null;
        });
      }
    } catch (e) {
      if (mounted) AppErrorHandler.showError(context, e);
    } finally {
      LoadingOverlay.hide(context);
    }
  }

  Widget _buildLeaveHistory() {
    return StreamBuilder<List<LeaveModel>>(
      stream: _auth.getStudentLeaves(widget.student.uid),
      builder: (context, snapshot) {
        if (snapshot.hasError) return AppErrorHandler.buildErrorWidget(snapshot.error, () => setState(() {}));
        if (!snapshot.hasData) return AppErrorHandler.buildLoadingWidget();
        final leaves = snapshot.data!;
        if (leaves.isEmpty) return const Text("No leave requests found.");

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: leaves.length,
          itemBuilder: (context, index) {
            final leave = leaves[index];
            Color statusColor = Colors.orange;
            if (leave.status == 'approved') statusColor = Colors.green;
            if (leave.status == 'rejected') statusColor = Colors.red;

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                title: Text("${DateFormat('dd MMM').format(leave.startDate)} - ${DateFormat('dd MMM').format(leave.endDate)}"),
                subtitle: Text("Reason: ${leave.reason}"),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: statusColor),
                  ),
                  child: Text(
                    leave.status.toUpperCase(),
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
