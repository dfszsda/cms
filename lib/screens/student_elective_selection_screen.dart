// ignore_for_file: unused_field

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../models/student_selection_model.dart';
import '../services/error_handler.dart';

class StudentElectiveSelectionScreen extends StatefulWidget {
  final UserModel user;
  const StudentElectiveSelectionScreen({super.key, required this.user});

  @override
  State<StudentElectiveSelectionScreen> createState() => _StudentElectiveSelectionScreenState();
}

class _StudentElectiveSelectionScreenState extends State<StudentElectiveSelectionScreen> {
  final _auth = AuthService();
  final Map<String, String?> _selectedElectives = {}; // type -> subjectId
  StudentSelectionModel? _existingSelection;
  bool _isAlreadySubmitted = false;

  @override
  void initState() {
    super.initState();
    _checkExistingSelection();
  }

  Future<void> _checkExistingSelection() async {
    try {
      final selection = await _auth.getStudentElectiveSelection(widget.user.uid, widget.user.semester ?? 1).first;
      if (selection != null && mounted) {
        setState(() {
          _existingSelection = selection;
          _isAlreadySubmitted = true;
        });
      }
    } catch (e) {
      debugPrint("Error checking existing selection: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Elective Subjects"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: true, // Allow going back if already submitted
      ),
      body: _isAlreadySubmitted ? _buildSubmittedView() : _buildSelectionView(),
    );
  }

  Widget _buildSubmittedView() {
    return StreamBuilder<QuerySnapshot>(
      stream: _auth.getAvailableElectives(
        widget.user.branch ?? '',
        widget.user.semester ?? 1,
        widget.user.collegeId ?? '',
      ),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return AppErrorHandler.buildErrorWidget(snapshot.error, () => setState(() {}));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return AppErrorHandler.buildLoadingWidget();
        }
        
        final allSubjects = snapshot.data?.docs ?? [];
        final selectedIds = _existingSelection?.selectedSubjectIds ?? [];
        
        final selectedSubjects = allSubjects.where((doc) => selectedIds.contains(doc.id)).toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green, size: 48),
                    const SizedBox(height: 12),
                    const Text("Selection Completed", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green)),
                    const SizedBox(height: 4),
                    Text("Your choices for Sem ${widget.user.semester} are locked.", style: TextStyle(color: Colors.green[700])),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              const Text("Your Selected Subjects", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ...selectedSubjects.map((s) {
                final data = s.data() as Map<String, dynamic>;
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.indigo.withOpacity(0.1),
                      child: const Icon(Icons.book, color: Colors.indigo, size: 20),
                    ),
                    title: Text(data['name'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("${data['type']} • ${data['code'] ?? ''}"),
                  ),
                );
              }),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.indigo),
                  SizedBox(width: 8),
                  Text(
                    "General Subjects: OK",
                    style: TextStyle(
                      color: Colors.indigo,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Go Back Home"),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  "To change subjects, please contact the System Admin.",
                  style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSelectionView() {
    return StreamBuilder<QuerySnapshot>(
        stream: _auth.getAvailableElectives(
          widget.user.branch ?? '',
          widget.user.semester ?? 1,
          widget.user.collegeId ?? '',
        ),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return AppErrorHandler.buildErrorWidget(snapshot.error, () => setState(() {}));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return AppErrorHandler.buildLoadingWidget();
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No elective subjects available for your semester."));
          }

          final subjects = snapshot.data!.docs;

          final peSubjects = subjects.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final type = (data['type'] as String? ?? '').toLowerCase();
            return type.contains('professional') || type == 'pe';
          }).toList();
          
          final oeSubjects = subjects.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final type = (data['type'] as String? ?? '').toLowerCase();
            return type.contains('open') || type == 'oe';
          }).toList();

          if (peSubjects.isEmpty && oeSubjects.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.info_outline, size: 60, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text("No elective subjects found."),
                  const Text("Please contact your coordinator.", style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 24),
                  ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text("Go Back"))
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.indigo.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info, color: Colors.indigo),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Choose your subjects for Sem ${widget.user.semester}. This choice is permanent for this semester.",
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (peSubjects.isNotEmpty) ...[
                  const Text("Professional Elective (PE)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const Text("Select one specialized subject from your branch", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 12),
                  ...peSubjects.map((s) {
                    final data = s.data() as Map<String, dynamic>;
                    return RadioListTile<String>(
                      title: Text(data['name'] ?? 'Unknown Subject', style: const TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: Text(data['code'] ?? ""),
                      value: s.id,
                      groupValue: _selectedElectives['PE'],
                      activeColor: Colors.indigo,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) => setState(() => _selectedElectives['PE'] = val),
                    );
                  }),
                  const Divider(height: 40),
                ],
                if (oeSubjects.isNotEmpty) ...[
                  const Text("Open Elective (OE)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const Text("Select one interdisciplinary subject", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 12),
                  ...oeSubjects.map((s) {
                    final data = s.data() as Map<String, dynamic>;
                    return RadioListTile<String>(
                      title: Text(data['name'] ?? 'Unknown Subject', style: const TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: Text(data['code'] ?? ""),
                      value: s.id,
                      groupValue: _selectedElectives['OE'],
                      activeColor: Colors.indigo,
                      contentPadding: EdgeInsets.zero,
                      onChanged: (val) => setState(() => _selectedElectives['OE'] = val),
                    );
                  }),
                ],
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton(
                    onPressed: _submitSelection,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 4,
                    ),
                    child: const Text("Confirm & Submit Selection", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      );
  }

  void _submitSelection() async {
    // Check if all needed selections are made
    // (Assuming one PE and one OE if available)
    if (_selectedElectives.isEmpty) {
      AppErrorHandler.showError(context, "Please select your subjects first.");
      return;
    }

    LoadingOverlay.show(context);
    try {
      final selection = StudentSelectionModel(
        id: '', // Firestore will set or we use custom ID
        studentId: widget.user.uid,
        collegeId: widget.user.collegeId ?? '',
        branchId: widget.user.branch ?? '',
        semester: widget.user.semester ?? 1,
        selectedSubjectIds: _selectedElectives.values.whereType<String>().toList(),
        timestamp: DateTime.now(),
      );

      await _auth.saveStudentElectiveSelection(selection);
      if (mounted) {
        AppErrorHandler.showSuccess(context, "Selection saved successfully!");
        Navigator.pop(context); // Go back to home
      }
    } catch (e) {
      if (mounted) AppErrorHandler.showError(context, e);
    } finally {
      if (mounted) LoadingOverlay.hide(context);
    }
  }
}
