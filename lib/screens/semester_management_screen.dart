import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class SemesterManagementScreen extends StatefulWidget {
  final UserModel viewer;
  const SemesterManagementScreen({super.key, required this.viewer});

  @override
  State<SemesterManagementScreen> createState() => _SemesterManagementScreenState();
}

class _SemesterManagementScreenState extends State<SemesterManagementScreen> {
  final _auth = AuthService();
  String _managementType = "Batch"; // Batch or Individual
  dynamic _selectedBatch;
  String _studentSearchQuery = "";
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Semester Management"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: "Batch", label: Text("Batch-wise"), icon: Icon(Icons.groups)),
                ButtonSegment(value: "Individual", label: Text("Individual"), icon: Icon(Icons.person)),
              ],
              selected: {_managementType},
              onSelectionChanged: (val) => setState(() => _managementType = val.first),
            ),
          ),
          if (_managementType == "Batch") _buildBatchManagement() else _buildIndividualManagement(),
        ],
      ),
    );
  }

  Widget _buildBatchManagement() {
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: _auth.getAllBatches(),
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
                  subtitle: const Text("Update semester for all students in this batch"),
                  trailing: const Icon(Icons.edit, color: Colors.indigo),
                  onTap: () => _showBatchUpdateDialog(batch['fullName']),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildIndividualManagement() {
    return Expanded(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search student by name...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (val) => setState(() => _studentSearchQuery = val),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: StreamBuilder<List<UserModel>>(
              stream: _auth.getAllUsers(), // Filtering students in code for simplicity
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final students = snapshot.data!
                    .where((u) => u.role == 'student' && u.fullName.toLowerCase().contains(_studentSearchQuery.toLowerCase()))
                    .toList();

                return ListView.builder(
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final student = students[index];
                    return ListTile(
                      leading: CircleAvatar(child: Text(student.fullName[0])),
                      title: Text(student.fullName),
                      subtitle: Text("Current Sem: ${student.semester} | Batch: ${student.batch}"),
                      trailing: const Icon(Icons.edit),
                      onTap: () => _showIndividualUpdateDialog(student),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showBatchUpdateDialog(String batchName) {
    int? newSem;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Update Sem: $batchName"),
        content: DropdownButtonFormField<int>(
          decoration: const InputDecoration(labelText: "Select New Semester"),
          items: List.generate(8, (i) => i + 1).map((s) => DropdownMenuItem(value: s, child: Text("Semester $s"))).toList(),
          onChanged: (val) => newSem = val,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (newSem != null) {
                await _auth.updateBatchSemester(batchName, newSem!);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Batch $batchName updated to Sem $newSem")));
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
      builder: (context) => AlertDialog(
        title: Text("Update Sem: ${student.fullName}"),
        content: DropdownButtonFormField<int>(
          initialValue: student.semester,
          decoration: const InputDecoration(labelText: "Select New Semester"),
          items: List.generate(8, (i) => i + 1).map((s) => DropdownMenuItem(value: s, child: Text("Semester $s"))).toList(),
          onChanged: (val) => newSem = val,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (newSem != null) {
                await _auth.updateStudentSemester(student.uid, newSem!);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${student.fullName} updated to Sem $newSem")));
              }
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }
}
