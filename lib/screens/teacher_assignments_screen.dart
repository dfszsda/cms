import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
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
  PlatformFile? _pickedFile;

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx', 'jpg', 'png'],
    );

    if (result != null) {
      setState(() {
        _pickedFile = result.files.first;
        _urlCtrl.clear(); // Clear URL if file is picked
      });
    }
  }

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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    const Text("Upload New Assignment", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                    const SizedBox(height: 16),
                    TextField(controller: _titleCtrl, decoration: const InputDecoration(labelText: "Assignment Title", border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    TextField(controller: _subjectCtrl, decoration: const InputDecoration(labelText: "Subject Name", border: OutlineInputBorder())),
                    const SizedBox(height: 12),
                    StreamBuilder<QuerySnapshot>(
                      stream: _auth.getBatchesByBranch(widget.branchId),
                      builder: (context, snap) {
                        if (!snap.hasData) return const LinearProgressIndicator();
                        return DropdownButtonFormField<String>(
                          decoration: const InputDecoration(labelText: "Target Batch", border: OutlineInputBorder()),
                          items: snap.data!.docs.map((doc) => DropdownMenuItem(value: doc['fullName'].toString(), child: Text(doc['fullName']))).toList(),
                          onChanged: (val) => _selectedBatch = val,
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    const Text("Upload Method:", style: TextStyle(fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _pickFile,
                            icon: const Icon(Icons.attach_file),
                            label: Text(_pickedFile != null ? "File Selected" : "Pick File"),
                          ),
                        ),
                        const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text("OR")),
                        Expanded(
                          child: TextField(
                            controller: _urlCtrl,
                            decoration: const InputDecoration(labelText: "Paste Link", border: OutlineInputBorder()),
                            onChanged: (v) { if(v.isNotEmpty) setState(() => _pickedFile = null); },
                          ),
                        ),
                      ],
                    ),
                    if (_pickedFile != null) Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text("Selected: ${_pickedFile!.name}", style: const TextStyle(color: Colors.green, fontSize: 12)),
                    ),
                    const SizedBox(height: 20),
                    if (_isLoading) const CircularProgressIndicator()
                    else ElevatedButton(
                      onPressed: _upload,
                      style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50), backgroundColor: Colors.orange, foregroundColor: Colors.white),
                      child: const Text("Post Assignment"),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Align(alignment: Alignment.centerLeft, child: Text("Student Submissions", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
            const SizedBox(height: 10),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('submissions').orderBy('submittedAt', descending: true).snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                if (snap.data!.docs.isEmpty) return const Text("No submissions yet.");
                
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snap.data!.docs.length,
                  itemBuilder: (context, i) {
                    var doc = snap.data!.docs[i];
                    String status = doc['status'];
                    Color statusColor = status == 'verified' ? Colors.green : (status == 'returned' ? Colors.red : Colors.orange);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        title: Text("${doc['studentName']} - ${doc['assignmentTitle']}"),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Status: ${status.toUpperCase()}", style: TextStyle(color: statusColor, fontWeight: FontWeight.bold)),
                            if (status == 'returned' && doc.data().toString().contains('feedback'))
                              Text("Feedback: ${doc['feedback']}", style: const TextStyle(fontStyle: FontStyle.italic)),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(icon: const Icon(Icons.open_in_new, color: Colors.blue), onPressed: () => _launchURL(doc['fileUrl'])),
                            if (status == 'pending') ...[
                              IconButton(icon: const Icon(Icons.check_circle_outline, color: Colors.green), onPressed: () => _verifySubmission(doc.reference)),
                              IconButton(icon: const Icon(Icons.assignment_return_outlined, color: Colors.red), onPressed: () => _showFeedbackDialog(doc.reference)),
                            ]
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

  void _verifySubmission(DocumentReference docRef) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Verify Submission?"),
        content: const Text("This will mark the assignment as completed for the student."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(onPressed: () {
            docRef.update({'status': 'verified'});
            Navigator.pop(ctx);
          }, child: const Text("Verify"))
        ],
      ),
    );
  }

  void _showFeedbackDialog(DocumentReference docRef) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Return with Feedback"),
        content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: "Explain what needs to be fixed...", border: OutlineInputBorder()), maxLines: 3),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(onPressed: () {
            if (ctrl.text.isNotEmpty) {
              docRef.update({'status': 'returned', 'feedback': ctrl.text});
              Navigator.pop(ctx);
            }
          }, child: const Text("Return"))
        ],
      ),
    );
  }

  Future<void> _upload() async {
    if (_titleCtrl.text.isEmpty || _selectedBatch == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all required fields")));
      return;
    }
    
    if (_pickedFile == null && _urlCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please provide a file or a link")));
      return;
    }

    setState(() => _isLoading = true);
    
    String finalUrl = _urlCtrl.text;
    
    // In a real app with Firebase Storage:
    // if (_pickedFile != null) { finalUrl = await _uploadToStorage(_pickedFile!); }

    await _auth.uploadAssignment({
      'title': _titleCtrl.text,
      'subject': _subjectCtrl.text,
      'branchId': widget.branchId,
      'batchId': _selectedBatch,
      'fileUrl': finalUrl,
      'fileName': _pickedFile?.name ?? "Link",
      'createdAt': FieldValue.serverTimestamp(),
    });

    _titleCtrl.clear();
    _subjectCtrl.clear();
    _urlCtrl.clear();
    setState(() {
      _pickedFile = null;
      _isLoading = false;
    });
    
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Assignment Posted!")));
  }

  Future<void> _launchURL(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Could not open link")));
    }
  }
}
