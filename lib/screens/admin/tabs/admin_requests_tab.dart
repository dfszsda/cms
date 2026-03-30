import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/auth_service.dart';

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
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          
          if (docs.isEmpty) return const Center(child: Text("No pending requests."));

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var doc = docs[index];
              var data = doc.data() as Map<String, dynamic>;
              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: const CircleAvatar(backgroundColor: Colors.amber, child: Icon(Icons.person_pin_rounded, color: Colors.white)),
                  title: Text(data['fullName'] ?? 'New User', style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(data['email'] ?? 'No email'),
                  trailing: ElevatedButton(
                    onPressed: () => auth.approveRequest(doc.id, data['email']),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                    child: const Text("Approve"),
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
