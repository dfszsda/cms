import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/auth_service.dart';
import '../../../services/error_handler.dart';

class AdminRequestsTab extends StatelessWidget {
  final String collegeId;
  const AdminRequestsTab({super.key, required this.collegeId});

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();
    return Scaffold(
      appBar: AppBar(title: const Text("Pending Requests"), backgroundColor: Colors.indigo, foregroundColor: Colors.white),
      body: StreamBuilder<QuerySnapshot>(
        stream: auth.getPendingRequestsByCollege(collegeId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return AppErrorHandler.buildErrorWidget(snapshot.error, () => (context as Element).markNeedsBuild());
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return AppErrorHandler.buildLoadingWidget();
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const Center(child: Text("No pending requests."));
          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var doc = docs[index];
              var data = doc.data() as Map<String, dynamic>;
              String email = data['email'] ?? '';
              
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: const CircleAvatar(backgroundColor: Colors.amber, child: Icon(Icons.person_pin_rounded, color: Colors.white)),
                  title: Text(data['fullName'] ?? 'New User', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(email.isEmpty ? 'No email' : email),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _RejectButton(auth: auth, requestId: doc.id, email: email),
                      const SizedBox(width: 8),
                      _ApproveButton(auth: auth, requestId: doc.id, email: email),
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
}

class _ApproveButton extends StatelessWidget {
  final AuthService auth;
  final String requestId;
  final String email;

  const _ApproveButton({required this.auth, required this.requestId, required this.email});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: email.isEmpty ? null : () async {
        LoadingOverlay.show(context);
        try {
          await auth.approveRequest(requestId, email);
          if (context.mounted) {
            AppErrorHandler.showSuccess(context, "Request approved and reset email sent.");
          }
        } catch (e) {
          if (context.mounted) AppErrorHandler.showError(context, e);
        } finally {
          if (context.mounted) LoadingOverlay.hide(context);
        }
      },
      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12)),
      child: const Text("Approve"),
    );
  }
}

class _RejectButton extends StatelessWidget {
  final AuthService auth;
  final String requestId;
  final String email;

  const _RejectButton({required this.auth, required this.requestId, required this.email});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => _showRejectDialog(context),
      style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12)),
      child: const Text("Reject"),
    );
  }

  void _showRejectDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Reject Request"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: "Enter reason for rejection"),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              String reason = controller.text.trim();
              if (reason.isEmpty) return;
              Navigator.pop(context);
              LoadingOverlay.show(context);
              try {
                await auth.rejectRequest(requestId, email, reason);
                if (context.mounted) AppErrorHandler.showSuccess(context, "Request rejected.");
              } catch (e) {
                if (context.mounted) AppErrorHandler.showError(context, e);
              } finally {
                if (context.mounted) LoadingOverlay.hide(context);
              }
            },
            child: const Text("Confirm Reject"),
          ),
        ],
      ),
    );
  }
}
