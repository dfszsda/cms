import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/auth_service.dart' show AuthService;
import '../../../services/error_handler.dart';
import '../../../models/user_model.dart';
import '../../../models/college_model.dart';

class AdminUsersListTab extends StatefulWidget {
  final String collegeId;
  const AdminUsersListTab({super.key, required this.collegeId});

  @override
  State<AdminUsersListTab> createState() => _AdminUsersListTabState();
}

class _AdminUsersListTabState extends State<AdminUsersListTab> {
  final _auth = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Users Management"), backgroundColor: Colors.indigo, foregroundColor: Colors.white),
      body: StreamBuilder<List<UserModel>>(
        stream: _auth.getAllUsers(collegeId: widget.collegeId),
        builder: (context, snapshot) {
          if (snapshot.hasError) return AppErrorHandler.buildErrorWidget(snapshot.error, () => setState(() {}));
          if (!snapshot.hasData) return AppErrorHandler.buildLoadingWidget();
          final users = snapshot.data!.where((u) => u.role != 'admin').toList();
          
          if (users.isEmpty) return const Center(child: Text("No users found in this college."));

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 10),
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              Color roleColor = _getRoleColor(user.role);
              
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: roleColor,
                    child: Text(user.role[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  title: Text(user.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("${user.role.toUpperCase()} | ${user.branchName}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.transfer_within_a_station, color: Colors.blue),
                        onPressed: () => _showChangeCollegeDialog(user),
                        tooltip: "Transfer College",
                      ),
                      if (user.role == 'teacher' || user.role == 'coordinator')
                        IconButton(
                          icon: const Icon(Icons.edit_note_rounded, color: Colors.indigo),
                          onPressed: () => _showEditTeacherBranchDialog(user),
                          tooltip: "Change Branch",
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'teacher':
      case 'coordinator': return Colors.orange;
      case 'student': return Colors.blue;
      case 'librarian': return Colors.indigo;
      case 'retailer': return Colors.green;
      default: return Colors.grey;
    }
  }

  void _showChangeCollegeDialog(UserModel user) {
    CollegeModel? selectedCol;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Transfer ${user.fullName}"),
        content: StreamBuilder<List<CollegeModel>>(
          stream: _auth.getColleges(),
          builder: (context, snapshot) {
            if (snapshot.hasError) return AppErrorHandler.buildErrorWidget(snapshot.error, () => setState(() {}));
            if (!snapshot.hasData) return const LinearProgressIndicator();
            return DropdownButtonFormField<CollegeModel>(
              decoration: const InputDecoration(labelText: "Select Target College", border: OutlineInputBorder()),
              items: snapshot.data!.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
              onChanged: (val) => selectedCol = val,
            );
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (selectedCol == null) return;
              LoadingOverlay.show(context);
              try {
                await _auth.updateTeacherCollege(user.uid, selectedCol!.id);
                if (context.mounted) {
                  Navigator.pop(ctx);
                  AppErrorHandler.showSuccess(context, "User transferred successfully");
                }
              } catch (e) {
                if (context.mounted) AppErrorHandler.showError(context, e);
              } finally {
                if (context.mounted) LoadingOverlay.hide(context);
              }
            },
            child: const Text("Transfer"),
          )
        ],
      ),
    );
  }

  void _showEditTeacherBranchDialog(UserModel user) {
    String? tempBranch;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Change Branch: ${user.fullName}"),
        content: StreamBuilder<QuerySnapshot>(
          stream: _auth.getBranches(collegeId: widget.collegeId),
          builder: (context, snap) {
            if (snap.hasError) return AppErrorHandler.buildErrorWidget(snap.error, () => setState(() {}));
            if (!snap.hasData) return const LinearProgressIndicator();
            return DropdownButtonFormField<String>(
              value: user.branch,
              decoration: const InputDecoration(labelText: "Select Branch", border: OutlineInputBorder()),
              items: snap.data!.docs.map((doc) {
                final branchId = doc.get('branchId') ?? doc.id;
                final displayName = branchId.toString().contains('_') ? branchId.toString().split('_').last : branchId;
                return DropdownMenuItem(value: doc.id, child: Text(displayName));
              }).toList(),
              onChanged: (val) => tempBranch = val,
            );
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (tempBranch == null) return;
              LoadingOverlay.show(context);
              try {
                await _auth.updateTeacherBranch(user.uid, tempBranch!);
                if (context.mounted) {
                  Navigator.pop(ctx);
                  AppErrorHandler.showSuccess(context, "Branch updated");
                }
              } catch (e) {
                if (context.mounted) AppErrorHandler.showError(context, e);
              } finally {
                if (context.mounted) LoadingOverlay.hide(context);
              }
            },
            child: const Text("Update"),
          )
        ],
      ),
    );
  }
}
