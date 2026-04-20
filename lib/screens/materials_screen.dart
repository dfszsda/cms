import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/drive_service.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:cloud_firestore/cloud_firestore.dart';

class MaterialsScreen extends StatefulWidget {
  final String role; // 'teacher' or 'student'
  const MaterialsScreen({super.key, required this.role});

  @override
  State<MaterialsScreen> createState() => _MaterialsScreenState();
}

class _MaterialsScreenState extends State<MaterialsScreen> {
  final GoogleDriveService _driveService = GoogleDriveService();
  final String _folderId = "1MT9UO2nH8BM9BpaBs_ASFLyncOSXPAdU";
  List<drive.File>? _files;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchFiles();
  }

  Future<void> _fetchFiles() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final files = await _driveService.listFiles(_folderId);
    if (!mounted) return;
    setState(() {
      _files = files;
      _isLoading = false;
    });
  }

  Future<void> _uploadMaterial() async {
    FilePickerResult? result = await FilePicker.pickFiles();

    if (result != null && result.files.single.path != null) {
      File file = File(result.files.single.path!);
      
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final driveFile = await _driveService.uploadFile(file, _folderId);
      
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog
      
      if (driveFile != null) {
        // Save metadata to Firestore
        try {
          await FirebaseFirestore.instance.collection('materials').add({
            'fileId': driveFile.id,
            'name': driveFile.name,
            'mimeType': driveFile.mimeType,
            'viewLink': driveFile.webViewLink,
            'uploadedAt': FieldValue.serverTimestamp(),
          });
          
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("File uploaded and saved successfully!")),
          );
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Drive upload success, but Firestore error: $e")),
          );
        }
        _fetchFiles();
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to upload file.")),
        );
      }
    }
  }

  Future<void> _openFile(String? webViewLink) async {
    if (webViewLink == null) return;
    final Uri url = Uri.parse(webViewLink);
    
    // Using InAppBrowserView keeps the user inside the app
    if (!await launchUrl(
      url, 
      mode: LaunchMode.inAppBrowserView,
      browserConfiguration: const BrowserConfiguration(showTitle: true),
    )) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not open the file.")),
        );
      }
    }
  }

  IconData _getFileIcon(String? mimeType) {
    if (mimeType == null) return Icons.insert_drive_file;
    if (mimeType.contains('pdf')) return Icons.picture_as_pdf;
    if (mimeType.contains('word') || mimeType.contains('officedocument.wordprocessingml')) return Icons.description;
    if (mimeType.contains('presentation') || mimeType.contains('powerpoint')) return Icons.slideshow;
    if (mimeType.contains('image')) return Icons.image;
    if (mimeType.contains('text')) return Icons.text_snippet;
    return Icons.insert_drive_file;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isTeacher = widget.role == 'teacher';

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Study Materials & Assignments", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchFiles,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _files == null || _files!.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.folder_open, size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      const Text("No materials found in the folder.", style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _files!.length,
                  itemBuilder: (context, index) {
                    final file = _files![index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(_getFileIcon(file.mimeType), color: theme.colorScheme.primary),
                        ),
                        title: Text(file.name ?? "Unknown File", style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(file.mimeType?.split('.').last ?? "File"),
                        trailing: const Icon(Icons.open_in_new, size: 20),
                        onTap: () => _openFile(file.webViewLink),
                      ),
                    );
                  },
                ),
      floatingActionButton: isTeacher
          ? FloatingActionButton.extended(
              onPressed: _uploadMaterial,
              label: const Text("Upload Material"),
              icon: const Icon(Icons.upload_file),
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }
}
