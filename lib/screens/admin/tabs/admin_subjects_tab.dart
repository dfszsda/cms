import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/auth_service.dart';

class AdminSubjectsTab extends StatefulWidget {
  final String collegeId;
  const AdminSubjectsTab({super.key, required this.collegeId});

  @override
  State<AdminSubjectsTab> createState() => _AdminSubjectsTabState();
}

class _AdminSubjectsTabState extends State<AdminSubjectsTab> {
  final _auth = AuthService();
  final _subjectNameCtrl = TextEditingController();
  String? _selectedBranchId;
  int _selectedSemester = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage Subjects"), backgroundColor: Colors.indigo, foregroundColor: Colors.white),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Add New Subject", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: StreamBuilder<QuerySnapshot>(
                            stream: _auth.getBranches(collegeId: widget.collegeId),
                            builder: (context, snap) {
                              if (!snap.hasData) return const LinearProgressIndicator();
                              return DropdownButtonFormField<String>(
                                decoration: const InputDecoration(labelText: "Branch", border: OutlineInputBorder()),
                                items: snap.data!.docs.map((doc) => DropdownMenuItem(value: doc.id, child: Text(doc.get('branchId') ?? doc.id))).toList(),
                                onChanged: (val) => setState(() => _selectedBranchId = val),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: _selectedSemester,
                            decoration: const InputDecoration(labelText: "Semester", border: OutlineInputBorder()),
                            items: List.generate(8, (i) => i + 1).map((s) => DropdownMenuItem(value: s, child: Text("Sem $s"))).toList(),
                            onChanged: (val) => setState(() => _selectedSemester = val!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(controller: _subjectNameCtrl, decoration: const InputDecoration(labelText: "Subject Name", border: OutlineInputBorder())),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (_selectedBranchId == null || _subjectNameCtrl.text.isEmpty) return;
                          await _auth.addSubject(_selectedBranchId!, _selectedSemester, _subjectNameCtrl.text.trim(), widget.collegeId);
                          _subjectNameCtrl.clear();
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Subject Added!")));
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                        child: const Text("Add Subject"),
                      ),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('subjects').where('collegeId', isEqualTo: widget.collegeId).orderBy('createdAt', descending: true).snapshots(),
                builder: (context, snap) {
                  if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                  final docs = snap.data!.docs;
                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, i) {
                      var data = docs[i].data() as Map<String, dynamic>;
                      return Card(
                        child: ListTile(
                          title: Text(data['name'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                          subtitle: Text("Branch: ${data['branch']} | Sem: ${data['semester']}"),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => docs[i].reference.delete(),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
