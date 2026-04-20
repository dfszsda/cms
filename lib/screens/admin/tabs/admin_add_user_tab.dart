import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/auth_service.dart';

class AdminAddUserTab extends StatefulWidget {
  final String collegeId;
  final String collegeName;

  const AdminAddUserTab({super.key, required this.collegeId, required this.collegeName});

  @override
  State<AdminAddUserTab> createState() => _AdminAddUserTabState();
}

class _AdminAddUserTabState extends State<AdminAddUserTab> {
  final _auth = AuthService();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  
  String _selectedRole = 'student';
  String? _selectedBranchId;
  String? _selectedBatchName;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add New User"), backgroundColor: Colors.indigo, foregroundColor: Colors.white),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Register New User for ${widget.collegeName}", 
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo)),
            const SizedBox(height: 24),
            TextField(
              controller: _nameCtrl, 
              decoration: InputDecoration(
                labelText: "Full Name", 
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
              )
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emailCtrl, 
              decoration: InputDecoration(
                labelText: "Email Address", 
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
              )
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedRole,
              decoration: InputDecoration(
                labelText: "User Role", 
                prefixIcon: const Icon(Icons.security_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
              ),
              items: const [
                DropdownMenuItem(value: 'student', child: Text("Student")),
                DropdownMenuItem(value: 'teacher', child: Text("Teacher")),
                DropdownMenuItem(value: 'coordinator', child: Text("Coordinator")),
                DropdownMenuItem(value: 'librarian', child: Text("Librarian")),
                DropdownMenuItem(value: 'retailer', child: Text("Retailer (Canteen)")),
              ],
              onChanged: (val) => setState(() {
                _selectedRole = val!;
                _selectedBranchId = null;
                _selectedBatchName = null;
              }),
            ),
            if (_selectedRole != 'retailer' && _selectedRole != 'librarian') ...[
              const SizedBox(height: 16),
              StreamBuilder<QuerySnapshot>(
                stream: _auth.getBranches(collegeId: widget.collegeId),
                builder: (context, snap) {
                  if (!snap.hasData) return const LinearProgressIndicator();
                  var branches = snap.data!.docs;
                  return DropdownButtonFormField<String>(
                    value: _selectedBranchId,
                    decoration: InputDecoration(
                      labelText: "Select Branch", 
                      prefixIcon: const Icon(Icons.account_tree_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
                    ),
                    items: branches.map((doc) {
                      final name = doc.get('branchId') ?? doc.get('name') ?? doc.id;
                      return DropdownMenuItem(value: doc.id, child: Text(name.toString()));
                    }).toList(),
                    onChanged: (val) => setState(() { _selectedBranchId = val; _selectedBatchName = null; }),
                  );
                },
              ),
            ],
            if (_selectedRole == 'student' && _selectedBranchId != null) ...[
              const SizedBox(height: 16),
              StreamBuilder<QuerySnapshot>(
                stream: _auth.getBatchesByBranch(_selectedBranchId!, collegeId: widget.collegeId),
                builder: (context, snap) {
                  if (!snap.hasData) return const LinearProgressIndicator();
                  var batches = snap.data!.docs;
                  return DropdownButtonFormField<String>(
                    value: _selectedBatchName,
                    decoration: InputDecoration(
                      labelText: "Select Batch", 
                      prefixIcon: const Icon(Icons.groups_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))
                    ),
                    items: batches.map((doc) {
                      final fullName = (doc.data() as Map<String, dynamic>)['fullName'] ?? '';
                      String displayName = fullName;
                      if (fullName.contains('-')) {
                        final parts = fullName.split('-');
                        if (parts.length >= 2) {
                          displayName = parts[1]; // e.g. "IT" from "1ID_IT1-IT-2024"
                        }
                      }
                      return DropdownMenuItem(value: fullName.toString(), child: Text(displayName));
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedBatchName = val),
                  );
                },
              ),
            ],
            const SizedBox(height: 40),
            if (_isLoading) 
              const Center(child: CircularProgressIndicator())
            else 
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _handleCreateUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo, 
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                  ),
                  child: const Text("CREATE ACCOUNT", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleCreateUser() async {
    final messenger = ScaffoldMessenger.of(context);
    if (_nameCtrl.text.isEmpty || _emailCtrl.text.isEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text("Please fill all required fields")));
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _auth.signUpUser(
        fullName: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: "Admin@123",
        role: _selectedRole,
        branch: _selectedBranchId,
        batch: _selectedBatchName,
        collegeId: widget.collegeId,
      );
      messenger.showSnackBar(const SnackBar(content: Text("User Created Successfully! Default password: Admin@123")));
      _nameCtrl.clear(); _emailCtrl.clear();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
