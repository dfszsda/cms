import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/auth_service.dart';
import '../../../models/user_model.dart';

class AdminUnassignedTab extends StatefulWidget {
  final String collegeId;
  const AdminUnassignedTab({super.key, required this.collegeId});

  @override
  State<AdminUnassignedTab> createState() => _AdminUnassignedTabState();
}

class _AdminUnassignedTabState extends State<AdminUnassignedTab> {
  final _auth = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Unassigned Batches"), backgroundColor: Colors.indigo, foregroundColor: Colors.white),
      body: Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              "Batches without a Coordinator",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('batches')
                  .where('collegeId', isEqualTo: widget.collegeId)
                  .where('coordinatorId', isNull: true)
                  .snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                if (snap.data!.docs.isEmpty) {
                  return const Center(child: Text("All batches have coordinators assigned."));
                }
                return ListView.builder(
                  itemCount: snap.data!.docs.length,
                  itemBuilder: (context, i) {
                    var data = snap.data!.docs[i].data() as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: ListTile(
                        title: Text(data['fullName'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text("Branch: ${data['branchId']} | Year: ${data['year']}"),
                        trailing: ElevatedButton(
                          onPressed: () => _showAssignCoordinatorDialog(snap.data!.docs[i].id),
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                          child: const Text("Assign"),
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
    );
  }

  void _showAssignCoordinatorDialog(String batchId) {
    UserModel? selectedTeacher;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Assign Coordinator"),
        content: StreamBuilder<List<UserModel>>(
          stream: _auth.getTeachers(collegeId: widget.collegeId),
          builder: (ctx, snap) {
            if (!snap.hasData) return const CircularProgressIndicator();
            return DropdownButtonFormField<UserModel>(
              hint: const Text("Select Teacher"),
              items: snap.data!.map((t) => DropdownMenuItem(value: t, child: Text(t.fullName))).toList(),
              onChanged: (val) => selectedTeacher = val,
            );
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (selectedTeacher != null) {
                try {
                  await _auth.assignCoordinator(batchId, selectedTeacher!.uid);
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Coordinator assigned!")));
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              }
            },
            child: const Text("Assign"),
          )
        ],
      ),
    );
  }
}
