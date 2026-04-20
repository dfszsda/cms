import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../models/student_selection_model.dart';

class StudentElectiveSelectionScreen extends StatefulWidget {
  final UserModel user;
  const StudentElectiveSelectionScreen({super.key, required this.user});

  @override
  State<StudentElectiveSelectionScreen> createState() => _StudentElectiveSelectionScreenState();
}

class _StudentElectiveSelectionScreenState extends State<StudentElectiveSelectionScreen> {
  final _auth = AuthService();
  final Map<String, String?> _selectedElectives = {}; // type -> subjectId
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Select Elective Subjects"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false, // Force selection
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _auth.getAvailableElectives(
          widget.user.branch ?? '',
          widget.user.semester ?? 1,
          widget.user.collegeId ?? '',
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No elective subjects available for your semester."));
          }

          final subjects = snapshot.data!.docs;

          final peSubjects = subjects.where((doc) {
            final type = (doc.get('type') as String).toLowerCase();
            return type.contains('professional') || type == 'pe';
          }).toList();
          
          final oeSubjects = subjects.where((doc) {
            final type = (doc.get('type') as String).toLowerCase();
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
                  ...peSubjects.map((s) => RadioListTile<String>(
                    title: Text(s.get('name'), style: const TextStyle(fontWeight: FontWeight.w500)),
                    subtitle: Text(s.get('code') ?? ""),
                    value: s.id,
                    groupValue: _selectedElectives['PE'],
                    activeColor: Colors.indigo,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) => setState(() => _selectedElectives['PE'] = val),
                  )),
                  const Divider(height: 40),
                ],
                if (oeSubjects.isNotEmpty) ...[
                  const Text("Open Elective (OE)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const Text("Select one interdisciplinary subject", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 12),
                  ...oeSubjects.map((s) => RadioListTile<String>(
                    title: Text(s.get('name'), style: const TextStyle(fontWeight: FontWeight.w500)),
                    subtitle: Text(s.get('code') ?? ""),
                    value: s.id,
                    groupValue: _selectedElectives['OE'],
                    activeColor: Colors.indigo,
                    contentPadding: EdgeInsets.zero,
                    onChanged: (val) => setState(() => _selectedElectives['OE'] = val),
                  )),
                ],
                const SizedBox(height: 40),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : SizedBox(
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
      ),
    );
  }

  void _submitSelection() async {
    // Check if all needed selections are made
    // (Assuming one PE and one OE if available)
    if (_selectedElectives.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select your subjects first.")));
      return;
    }

    setState(() => _isLoading = true);
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Selection saved successfully!")));
        Navigator.pop(context); // Go back to home
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
