import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/auth_service.dart';
import '../../../services/error_handler.dart';

class AdminBranchesTab extends StatefulWidget {
  final String collegeId;
  const AdminBranchesTab({super.key, required this.collegeId});

  @override
  State<AdminBranchesTab> createState() => _AdminBranchesTabState();
}

class _AdminBranchesTabState extends State<AdminBranchesTab> {
  final _auth = AuthService();
  final _branchIdCtrl = TextEditingController();
  final _branchNameCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Manage Branches"), backgroundColor: Colors.indigo, foregroundColor: Colors.white),
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
                    const Text("Add New Branch", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _branchIdCtrl, 
                      decoration: const InputDecoration(labelText: "Branch ID (e.g. IT, CE)", border: OutlineInputBorder())
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _branchNameCtrl, 
                      decoration: const InputDecoration(labelText: "Full Branch Name", border: OutlineInputBorder())
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          if (_branchIdCtrl.text.isEmpty) {
                            AppErrorHandler.showError(context, "Branch ID is required");
                            return;
                          }
                          LoadingOverlay.show(context);
                          try {
                            await _auth.addBranch(_branchIdCtrl.text, _branchNameCtrl.text, widget.collegeId);
                            if (!context.mounted) return;
                            AppErrorHandler.showSuccess(context, "Branch added successfully");
                            _branchIdCtrl.clear(); 
                            _branchNameCtrl.clear();
                          } catch (e) {
                            if (context.mounted) AppErrorHandler.showError(context, e);
                          } finally {
                            if (context.mounted) LoadingOverlay.hide(context);
                          }
                        },
                        icon: const Icon(Icons.add),
                        label: const Text("Add Branch"),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                      ),
                    )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(" Existing Branches", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _auth.getBranches(collegeId: widget.collegeId),
                builder: (context, snap) {
                  if (snap.hasError) return AppErrorHandler.buildErrorWidget(snap.error, () => setState(() {}));
                  if (!snap.hasData) return AppErrorHandler.buildLoadingWidget();
                  final docs = snap.data!.docs;
                  if (docs.isEmpty) return const Center(child: Text("No branches found."));
                  
                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, i) {
                      var data = docs[i].data() as Map<String, dynamic>;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          leading: const CircleAvatar(backgroundColor: Colors.orange, child: Icon(Icons.account_tree, color: Colors.white)),
                          title: Text(data['branchId'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(data['name'] ?? 'N/A'),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                            child: Text("Batches: ${data['batchCount'] ?? 0}/20", style: const TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 12)),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
