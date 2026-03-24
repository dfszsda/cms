import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class SemesterManagementScreen extends StatefulWidget {
  const SemesterManagementScreen({super.key});

  @override
  State<SemesterManagementScreen> createState() => _SemesterManagementScreenState();
}

class _SemesterManagementScreenState extends State<SemesterManagementScreen> {
  final AuthService _auth = AuthService();
  String? _selectedBatch;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Semester Management"), centerTitle: true),
      body: Column(
        children: [
          _buildBatchSelector(),
          Expanded(child: _selectedBatch == null ? _buildBatchList() : _buildStudentList()),
        ],
      ),
    );
  }

  Widget _buildBatchSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('batches').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const CircularProgressIndicator();
          final batches = snapshot.data!.docs;
          return DropdownButtonFormField<String>(
            initialValue: _selectedBatch,
            decoration: const InputDecoration(labelText: "Filter by Batch", border: OutlineInputBorder()),
            items: batches.map((b) => DropdownMenuItem(value: b['fullName'] as String, child: Text(b['fullName']))).toList(),
            onChanged: (val) => setState(() => _selectedBatch = val),
          );
        },
      ),
    );
  }

  Widget _buildBatchList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('batches').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final batches = snapshot.data!.docs;
        return ListView.builder(
          itemCount: batches.length,
          itemBuilder: (context, index) {
            final batch = batches[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text(batch['fullName'], style: const TextStyle(fontWeight: FontWeight.bold)),
                trailing: ElevatedButton(
                  onPressed: () => _showBatchUpdateDialog(batch['fullName']),
                  child: const Text("Update All"),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStudentList() {
    return StreamBuilder<List<UserModel>>(
      stream: _auth.getStudentsByBatch(_selectedBatch!),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final students = snapshot.data!;
        return ListView.builder(
          itemCount: students.length,
          itemBuilder: (context, index) {
            final student = students[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ListTile(
                title: Text(student.fullName),
                subtitle: Text("Current: Sem ${student.semester ?? 'N/A'}"),
                trailing: IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _showIndividualUpdateDialog(student),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showBatchUpdateDialog(String batchName) {
    int? newSem;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text("Update Sem for $batchName"),
        content: DropdownButtonFormField<int>(
          decoration: const InputDecoration(labelText: "Select New Semester"),
          items: List.generate(8, (i) => i + 1).map((s) => DropdownMenuItem(value: s, child: Text("Semester $s"))).toList(),
          onChanged: (val) => newSem = val,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (newSem != null) {
                final messenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(dialogContext);
                await _auth.updateBatchSemester(batchName, newSem!);
                if (!mounted) return;
                navigator.pop();
                messenger.showSnackBar(SnackBar(content: Text("Batch $batchName updated to Sem $newSem")));
              }
            },
            child: const Text("Update All"),
          ),
        ],
      ),
    );
  }

  void _showIndividualUpdateDialog(UserModel student) {
    int? newSem;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text("Update Sem: ${student.fullName}"),
        content: DropdownButtonFormField<int>(
          initialValue: student.semester,
          decoration: const InputDecoration(labelText: "Select New Semester"),
          items: List.generate(8, (i) => i + 1).map((s) => DropdownMenuItem(value: s, child: Text("Semester $s"))).toList(),
          onChanged: (val) => newSem = val,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (newSem != null) {
                final messenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(dialogContext);
                await _auth.updateStudentSemester(student.uid, newSem!);
                if (!mounted) return;
                navigator.pop();
                messenger.showSnackBar(SnackBar(content: Text("${student.fullName} updated to Sem $newSem")));
              }
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }
}
