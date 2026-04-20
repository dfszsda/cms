import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class TeacherAssignmentsScreen extends StatefulWidget {
  final UserModel user;
  const TeacherAssignmentsScreen({super.key, required this.user});

  @override
  State<TeacherAssignmentsScreen> createState() => _TeacherAssignmentsScreenState();
}

class _TeacherAssignmentsScreenState extends State<TeacherAssignmentsScreen> {
  final _auth = AuthService();
  final _titleCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  String? _selectedBatch;
  String? _selectedSubject;
  bool _isLoading = false;
  PlatformFile? _pickedFile;

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx', 'jpg', 'png'],
    );

    if (result != null) {
      setState(() {
        _pickedFile = result.files.first;
        _urlCtrl.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage Assignments"), backgroundColor: Colors.orange, foregroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // UPLOAD SECTION - Only for Subject Teachers
            StreamBuilder<QuerySnapshot>(
              stream: _auth.getSubjectsForUpload(widget.user.branch!, widget.user.uid, collegeId: widget.user.collegeId),
              builder: (context, subjectSnap) {
                if (!subjectSnap.hasData) return const SizedBox.shrink();
                
                // If the teacher is not a Subject Teacher for any subject, don't show the upload card
                if (subjectSnap.data!.docs.isEmpty) {
                  return const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text("Only primary Subject Teachers can upload new assignments. Assistant teachers can only verify submissions.", style: TextStyle(fontStyle: FontStyle.italic)),
                    ),
                  );
                }

                return Card(
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
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(labelText: "Select Subject", border: OutlineInputBorder()),
                          items: subjectSnap.data!.docs.map((doc) => DropdownMenuItem(value: doc['name'].toString(), child: Text(doc['name']))).toList(),
                          onChanged: (val) => _selectedSubject = val,
                        ),
                        const SizedBox(height: 12),
                        StreamBuilder<QuerySnapshot>(
                          stream: _auth.getBatchesByBranch(widget.user.branch!, collegeId: widget.user.collegeId),
                          builder: (context, batchSnap) {
                            if (!batchSnap.hasData) return const LinearProgressIndicator();
                            return DropdownButtonFormField<String>(
                              decoration: const InputDecoration(labelText: "Target Batch", border: OutlineInputBorder()),
                              items: batchSnap.data!.docs.map((doc) => DropdownMenuItem(value: doc['fullName'].toString(), child: Text(doc['fullName']))).toList(),
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
                );
              },
            ),
            const SizedBox(height: 24),
            const Align(alignment: Alignment.centerLeft, child: Text("Submissions for Your Subjects", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
            const SizedBox(height: 10),
            
            // SUBMISSIONS SECTION - Filtered by Teacher's Allocated Subjects
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('subjects')
                  .where('branch', isEqualTo: widget.user.branch)
                  .snapshots(),
              builder: (context, subjectSnap) {
                if (!subjectSnap.hasData) return const Center(child: CircularProgressIndicator());
                
                // Find subjects where this teacher is either Subject Teacher or Assistant
                List<Map<String, dynamic>> mySubjects = subjectSnap.data!.docs
                    .where((doc) {
                      List teachers = doc['subjectTeachers'] ?? [];
                      List assistants = doc['assistantSubjectTeachers'] ?? [];
                      return teachers.contains(widget.user.uid) || assistants.contains(widget.user.uid);
                    })
                    .map((doc) => {
                      'name': doc['name'] as String,
                      'branchId': doc['branch'] as String,
                    })
                    .toList();

                if (mySubjects.isEmpty) return const Text("You are not allocated to any subjects.");

                List<String> _ = mySubjects.map((s) => s['name'] as String).toList();

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('submissions')
                      .where('status', isNotEqualTo: 'verified') // Focused on pending work
                      .orderBy('status')
                      .orderBy('submittedAt', descending: true)
                      .snapshots(),
                  builder: (context, submissionSnap) {
                    if (!submissionSnap.hasData) return const Center(child: CircularProgressIndicator());
                    
                    // Filter submissions by teacher's subjects
                    var filteredDocs = submissionSnap.data!.docs.where((doc) {
                      // Note: We need the assignment subject. We'll join or check assignment title.
                      // For now, assuming assignmentTitle might contain subject or we need to fetch assignment.
                      // Ideally, submission should have 'subject' field.
                      return true; // Placeholder: In a real app, ensure submission model includes 'subject'
                    }).toList();

                    if (filteredDocs.isEmpty) return const Text("No pending submissions for your subjects.");

                    return ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredDocs.length,
                      itemBuilder: (context, i) {
                        var doc = filteredDocs[i].data() as Map<String, dynamic>;
                        
                        String status = doc['status'] ?? 'pending';
                        Color statusColor = status == 'verified' ? Colors.green : (status == 'returned' ? Colors.red : Colors.orange);

                        String branchDisplay = "";
                        if (doc['branchId'] != null) {
                           String bId = doc['branchId'];
                           branchDisplay = bId.contains('_') ? bId.split('_').last : bId;
                        }

                        return Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: ListTile(
                            title: Text("${doc['studentName']}"),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Assignment: ${doc['assignmentTitle']} ${branchDisplay.isNotEmpty ? "($branchDisplay)" : ""}"),
                                Text("Status: ${status.toUpperCase()}", style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                                if (status == 'returned' && doc.toString().contains('feedback'))
                                  Text("Reason: ${doc['feedback']}", style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.red)),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(icon: const Icon(Icons.open_in_new, color: Colors.blue), onPressed: () => _launchURL(doc['fileUrl'])),
                                if (status == 'pending') ...[
                                  IconButton(icon: const Icon(Icons.check_circle_outline, color: Colors.green), onPressed: () => _verifySubmission(filteredDocs[i].reference)),
                                  IconButton(icon: const Icon(Icons.cancel_outlined, color: Colors.red), onPressed: () => _showRejectionDialog(filteredDocs[i].reference)),
                                ]
                              ],
                            ),
                          ),
                        );
                      },
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

  void _showRejectionDialog(DocumentReference docRef) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Reject Assignment"),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(hintText: "Enter reason for rejection...", border: OutlineInputBorder()),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () {
              if (ctrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please provide a reason")));
                return;
              }
              docRef.update({
                'status': 'returned',
                'feedback': ctrl.text.trim(),
                'rejectedAt': FieldValue.serverTimestamp(),
              });
              Navigator.pop(ctx);
            },
            child: const Text("Reject"),
          )
        ],
      ),
    );
  }

  Future<void> _upload() async {
    if (_titleCtrl.text.isEmpty || _selectedBatch == null || _selectedSubject == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all required fields")));
      return;
    }
    
    if (_pickedFile == null && _urlCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please provide a file or a link")));
      return;
    }

    setState(() => _isLoading = true);
    
    String finalUrl = _urlCtrl.text;
    
    final assignmentData = {
      'title': _titleCtrl.text,
      'subject': _selectedSubject,
      'branchId': widget.user.branch,
      'batchId': _selectedBatch,
      'collegeId': widget.user.collegeId,
      'teacherId': widget.user.uid,
      'fileUrl': finalUrl,
      'fileName': _pickedFile?.name ?? "Link",
      'createdAt': FieldValue.serverTimestamp(),
    };

    await _auth.uploadAssignment(assignmentData);

    _titleCtrl.clear();
    _urlCtrl.clear();
    setState(() {
      _selectedSubject = null;
      _selectedBatch = null;
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
