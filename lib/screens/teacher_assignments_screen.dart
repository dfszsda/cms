import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class TeacherAssignmentsScreen extends StatefulWidget {
  final String branchId;
  const TeacherAssignmentsScreen({super.key, required this.branchId});

  @override
  State<TeacherAssignmentsScreen> createState() => _TeacherAssignmentsScreenState();
}

class _TeacherAssignmentsScreenState extends State<TeacherAssignmentsScreen> {
  final _auth = AuthService();
  final _titleCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  String? _selectedBatch;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage Assignments"), backgroundColor: Colors.orange),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text("Upload New Assignment", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 16),
                    TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: "Assignment Title")),
                    TextField(controller: _subjectCtrl, decoration: const InputDecoration(labelText: "Subject Name")),
                    const SizedBox(height: 16),
                    StreamBuilder<QuerySnapshot>(
                      stream: _auth.getBatchesByBranch(widget.branchId),
                      builder: (context, snap) {
                        if (!snap.hasData) return const LinearProgressIndicator();
                        return DropdownButtonFormField<String>(
                          hint: const Text("Select Target Batch"),
                          items: snap.data!.docs.map((doc) => DropdownMenuItem(value: doc['fullName'].toString(), child: Text(doc['fullName']))).toList(),
                          onChanged: (val) => _selectedBatch = val,
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    TextField(controller: _urlCtrl, decoration: const InputDecoration(labelText: "File Link (Drive/Cloud)")),
                    const SizedBox(height: 20),
                    if (_isLoading) const CircularProgressIndicator()
                    else ElevatedButton(onPressed: _upload, child: const Text("Post Assignment")),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Align(alignment: Alignment.centerLeft, child: Text("Recent Submissions", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
            const SizedBox(height: 10),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('submissions').snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) return const SizedBox();
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snap.data!.docs.length,
                  itemBuilder: (context, i) {
                    var doc = snap.data!.docs[i];
                    return Card(
                      child: ListTile(
                        title: Text("Status: ${doc['status']}"),
                        subtitle: Text("File: ${doc['fileName']}"),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: const Icon(Icons.check, color: Colors.green), onPressed: () => doc.reference.update({'status': 'verified'})),
                            IconButton(icon: const Icon(Icons.refresh, color: Colors.red), onPressed: () => _showFeedbackDialog(doc.reference)),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            )
          ],
        ),
      ),
    );
  }

  void _showFeedbackDialog(DocumentReference docRef) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Return with Feedback"),
        content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: "What needs to be fixed?")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(onPressed: () {
            docRef.update({'status': 'returned', 'feedback': ctrl.text});
            Navigator.pop(ctx);
          }, child: const Text("Return"))
        ],
      ),
    );
  }

  Future<void> _upload() async {
    if (_titleCtrl.text.isEmpty || _selectedBatch == null) return;
    setState(() => _isLoading = true);
    await _auth.uploadAssignment({
      'title': _titleCtrl.text,
      'subject': _subjectCtrl.text,
      'branchId': widget.branchId,
      'batchId': _selectedBatch,
      'fileUrl': _urlCtrl.text,
    });
    setState(() => _isLoading = false);
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Assignment Posted!")));
  }
}
