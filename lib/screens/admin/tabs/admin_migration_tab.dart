import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';
import '../../../services/error_handler.dart';

class AdminMigrationTab extends StatefulWidget {
  final String collegeId;
  const AdminMigrationTab({super.key, required this.collegeId});

  @override
  State<AdminMigrationTab> createState() => _AdminMigrationTabState();
}

class _AdminMigrationTabState extends State<AdminMigrationTab> {
  final _auth = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Data Migration"), backgroundColor: Colors.indigo, foregroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Migration Tool", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.indigo)),
            const Text("Assign existing unassigned data to this college.", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 30),
            _migrationCard("Users", "users"),
            _migrationCard("Branches", "branches"),
            _migrationCard("Batches", "batches"),
            _migrationCard("Subjects", "subjects"),
            _migrationCard("Canteen Items", "canteen_items"),
            _migrationCard("Library Books", "books"),
          ],
        ),
      ),
    );
  }

  Widget _migrationCard(String label, String collection) {
    return FutureBuilder<int>(
      future: _auth.getOrphanCount(collection),
      builder: (context, snapshot) {
        if (snapshot.hasError) return const SizedBox.shrink(); 
        if (!snapshot.hasData) return const LinearProgressIndicator();
        
        int count = snapshot.data ?? 0;
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            title: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("$count unassigned items found"),
            trailing: count > 0
                ? ElevatedButton(
              onPressed: () async {
                LoadingOverlay.show(context);
                try {
                  await _auth.migrateDataToCollege(collection, widget.collegeId);
                  if (context.mounted) {
                    AppErrorHandler.showSuccess(context, "Migrated $count $label items");
                    setState(() {}); // Refresh
                  }
                } catch (e) {
                  if (context.mounted) AppErrorHandler.showError(context, e);
                } finally {
                  if (context.mounted) LoadingOverlay.hide(context);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
              child: const Text("Migrate"),
            )
                : const Icon(Icons.check_circle, color: Colors.green),
          ),
        );
      },
    );
  }
}
