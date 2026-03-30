import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/auth_service.dart';
import '../../../models/user_model.dart';

class AdminBatchesTab extends StatefulWidget {
  final String collegeId;
  const AdminBatchesTab({super.key, required this.collegeId});

  @override
  State<AdminBatchesTab> createState() => _AdminBatchesTabState();
}

class _AdminBatchesTabState extends State<AdminBatchesTab> {
  final _auth = AuthService();
  final _batchLetterCtrl = TextEditingController();
  final _batchYearCtrl = TextEditingController(text: DateTime.now().year.toString());
  String? _selectedBranchId;
  String? _selectedCoordinatorId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage Batches"), backgroundColor: Colors.indigo, foregroundColor: Colors.white),
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
                    const Text("Create New Batch", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
                    const SizedBox(height: 16),
                    StreamBuilder<QuerySnapshot>(
                      stream: _auth.getBranches(collegeId: widget.collegeId),
                      builder: (context, snap) {
                        if (!snap.hasData) return const LinearProgressIndicator();
                        return DropdownButtonFormField<String>(
                          decoration: const InputDecoration(labelText: "Select Branch", border: OutlineInputBorder()),
                          items: snap.data!.docs.map((doc) => DropdownMenuItem(value: doc.id, child: Text(doc.get('branchId') ?? doc.id))).toList(),
                          onChanged: (val) => _selectedBranchId = val,
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: _batchLetterCtrl, decoration: const InputDecoration(labelText: "Batch Letter (A, B...)", border: OutlineInputBorder()))),
                        const SizedBox(width: 12),
                        Expanded(child: TextField(controller: _batchYearCtrl, decoration: const InputDecoration(labelText: "Year", border: OutlineInputBorder()), keyboardType: TextInputType.number)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    StreamBuilder<List<UserModel>>(
                      stream: _auth.getTeachers(collegeId: widget.collegeId),
                      builder: (context, snap) {
                        if (!snap.hasData) return const LinearProgressIndicator();
                        return DropdownButtonFormField<String>(
                          decoration: const InputDecoration(labelText: "Coordinator (Optional)", border: OutlineInputBorder()),
                          items: snap.data!.map((teacher) => DropdownMenuItem(value: teacher.uid, child: Text(teacher.fullName))).toList(),
                          onChanged: (val) => _selectedCoordinatorId = val,
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          if (_selectedBranchId == null || _batchLetterCtrl.text.isEmpty) return;
                          try {
                            await _auth.createBatch(_selectedBranchId!, _batchLetterCtrl.text.toUpperCase(), int.parse(_batchYearCtrl.text), widget.collegeId, coordinatorId: _selectedCoordinatorId);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Batch Created!")));
                          } catch (e) {
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                        child: const Text("Generate Batch"),
                      ),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('batches').where('collegeId', isEqualTo: widget.collegeId).orderBy('createdAt', descending: true).snapshots(),
                builder: (context, snap) {
                  if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                  final docs = snap.data!.docs;
                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, i) {
                      var data = docs[i].data() as Map<String, dynamic>;
                      String? coordId = data['coordinatorId'];
                      return Card(
                        child: ListTile(
                          title: Text(data['fullName'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                          subtitle: Text("Branch: ${data['branchId']} | Year: ${data['year']}"),
                          trailing: coordId != null 
                            ? IconButton(icon: const Icon(Icons.person_off, color: Colors.red), onPressed: () => _auth.removeCoordinator(docs[i].id))
                            : const Text("No Coord", style: TextStyle(color: Colors.grey, fontSize: 12)),
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
