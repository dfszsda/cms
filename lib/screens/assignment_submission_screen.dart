// ignore_for_file: unused_field, unused_element

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:file_picker/file_picker.dart';
import '../models/user_model.dart';
import '../services/error_handler.dart';

class AssignmentSubmissionScreen extends StatefulWidget {
  final UserModel user;
  const AssignmentSubmissionScreen({super.key, required this.user});

  @override
  State<AssignmentSubmissionScreen> createState() => _AssignmentSubmissionScreenState();
}

class _AssignmentSubmissionScreenState extends State<AssignmentSubmissionScreen> {
  final _urlController = TextEditingController();
  PlatformFile? _pickedFile;

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx', 'jpg', 'png'],
    );

    if (result != null) {
      setState(() {
        _pickedFile = result.files.first;
        _urlController.clear();
      });
    }
  }

  Future<void> _submitAssignment(String assignmentId, String title, {String? existingSubmissionId}) async {
    if (_urlController.text.isEmpty && _pickedFile == null) {
      AppErrorHandler.showError(context, "Please provide a file or a link");
      return;
    }

    LoadingOverlay.show(context);

    String finalUrl = _urlController.text.trim();
    String fileName = _pickedFile?.name ?? "Link";

    // In a real app: upload _pickedFile to Firebase Storage and get URL
    
    try {
      final submissionData = {
        'assignmentId': assignmentId,
        'assignmentTitle': title,
        'studentId': widget.user.uid,
        'studentName': widget.user.fullName,
        'branchId': widget.user.branch,
        'fileUrl': finalUrl,
        'fileName': fileName,
        'status': 'pending',
        'submittedAt': FieldValue.serverTimestamp(),
      };

      if (existingSubmissionId != null) {
        await FirebaseFirestore.instance.collection('submissions').doc(existingSubmissionId).update(submissionData);
      } else {
        await FirebaseFirestore.instance.collection('submissions').add(submissionData);
      }

      if (mounted) {
        AppErrorHandler.showSuccess(context, "Assignment submitted successfully!");
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) AppErrorHandler.showError(context, e);
    } finally {
      if (mounted) LoadingOverlay.hide(context);
    }
  }

  void _showSubmitDialog(String assignmentId, String title, {String? existingSubmissionId, String? currentUrl}) {
    _urlController.text = currentUrl ?? "";
    _pickedFile = null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existingSubmissionId != null ? "Resubmit: $title" : "Submit: $title"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _urlController,
                decoration: const InputDecoration(hintText: "Paste Google Drive/File Link", border: OutlineInputBorder()),
                onChanged: (v) { if(v.isNotEmpty) setDialogState(() => _pickedFile = null); },
              ),
              const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Text("OR")),
              OutlinedButton.icon(
                onPressed: () async {
                  final result = await FilePicker.pickFiles(type: FileType.custom, allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx']);
                  if (result != null) {
                    setDialogState(() {
                      _pickedFile = result.files.first;
                      _urlController.clear();
                    });
                  }
                },
                icon: const Icon(Icons.attach_file),
                label: Text(_pickedFile != null ? "File: ${_pickedFile!.name}" : "Select File (PDF/Docs/PPT)"),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () => _submitAssignment(assignmentId, title, existingSubmissionId: existingSubmissionId),
              child: const Text("Submit"),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _launchURL(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Assignments"), backgroundColor: Colors.purple, foregroundColor: Colors.white),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('assignments')
            .where('branchId', isEqualTo: widget.user.branch)
            .where('batchId', isEqualTo: widget.user.batch)
            .snapshots(),
        builder: (context, assignmentSnap) {
          if (assignmentSnap.hasError) return AppErrorHandler.buildErrorWidget(assignmentSnap.error, () => setState(() {}));
          if (!assignmentSnap.hasData) return AppErrorHandler.buildLoadingWidget();
          
              final assignmentsDocs = assignmentSnap.data!.docs;
              
              return StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('submissions')
                    .where('studentId', isEqualTo: widget.user.uid)
                    .snapshots(),
                builder: (context, submissionSnap) {
                  if (submissionSnap.hasError) return AppErrorHandler.buildErrorWidget(submissionSnap.error, () => setState(() {}));
                  if (!submissionSnap.hasData) return AppErrorHandler.buildLoadingWidget();
                  
                  final submissionDocs = submissionSnap.data!.docs;
                  
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: assignmentsDocs.length,
                    itemBuilder: (context, index) {
                      final assignment = assignmentsDocs[index].data() as Map<String, dynamic>;
                      
                      final submissionDoc = submissionDocs.where((s) => s['assignmentId'] == assignmentsDocs[index].id).firstOrNull;
                      Map<String, dynamic>? submission;
                      if (submissionDoc != null) {
                        submission = submissionDoc.data() as Map<String, dynamic>;
                      }
                      
                      String status = submission != null ? (submission['status'] ?? 'pending') : 'not_submitted';
                      Color statusColor = status == 'verified' ? Colors.green : (status == 'returned' ? Colors.red : Colors.orange);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            children: [
                              ListTile(
                                title: Text(assignment['title'] ?? 'Untitled', style: const TextStyle(fontWeight: FontWeight.bold)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Subject: ${assignment['subject'] ?? 'N/A'}"),
                                    if (status != 'not_submitted') 
                                      Text("Status: ${status.toUpperCase()}", style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 12)),
                                    if (status == 'returned' && submission != null && submission.toString().contains('feedback'))
                                      Text("Feedback: ${submission['feedback']}", style: const TextStyle(color: Colors.red, fontStyle: FontStyle.italic, fontSize: 13)),
                                  ],
                                ),
                                trailing: IconButton(icon: const Icon(Icons.download, color: Colors.blue), onPressed: () => _launchURL(assignment['fileUrl'] ?? "")),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    if (status == 'not_submitted')
                                      ElevatedButton(onPressed: () => _showSubmitDialog(assignmentsDocs[index].id, assignment['title'] ?? ""), child: const Text("Submit Now"))
                                    else if (status == 'returned')
                                      ElevatedButton.icon(
                                        onPressed: () => _showSubmitDialog(assignmentsDocs[index].id, assignment['title'] ?? "", existingSubmissionId: submissionDoc!.id, currentUrl: submission!['fileUrl']),
                                        icon: const Icon(Icons.refresh),
                                        label: const Text("Resubmit"),
                                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                      )
                                    else if (status == 'pending')
                                      const Chip(label: Text("Pending Verification"), backgroundColor: Colors.orangeAccent)
                                    else
                                      const Chip(label: Text("Verified"), backgroundColor: Colors.greenAccent, avatar: Icon(Icons.check, size: 16)),
                                  ],
                                ),
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              );
        },
      ),
    );
  }
}
