import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import 'login_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final _auth = AuthService();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  
  final _batchNameCtrl = TextEditingController();
  final _studentCountCtrl = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  String _selectedRole = 'student';
  String? _selectedBatchCode;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4, 
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Admin Dashboard"),
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.sync_rounded),
              tooltip: "Sync Old Students",
              onPressed: _showSyncDialog,
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                final navigator = Navigator.of(context);
                await _auth.signOut();
                if (!mounted) return;
                navigator.pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
            )
          ],
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.white,
            isScrollable: true,
            tabs: [
              Tab(icon: Icon(Icons.person_add), text: "Add User"),
              Tab(icon: Icon(Icons.grid_view_rounded), text: "Batches"),
              Tab(icon: Icon(Icons.list), text: "Users"),
              Tab(icon: Icon(Icons.notifications), text: "Requests"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildAddUserTab(),
            _buildBatchesTab(),
            _buildViewUsersTab(),
            _buildRequestsTab(),
          ],
        ),
      ),
    );
  }

  void _showSyncDialog() async {
    String? tempBatchCode;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Sync Old Students"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Select a batch to assign to students who don't have one. Semester will be set to 1."),
            const SizedBox(height: 20),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('batches').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Text("Error: ${snapshot.error}");
                if (!snapshot.hasData) return const CircularProgressIndicator();
                var batches = snapshot.data!.docs;
                if (batches.isEmpty) return const Text("No batches found. Create one first.");
                return DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: "Target Batch", border: OutlineInputBorder()),
                  items: batches.map((doc) => DropdownMenuItem(value: doc.id, child: Text("${doc.id} (${doc['name']})"))).toList(),
                  onChanged: (val) => tempBatchCode = val,
                );
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () {
              if (tempBatchCode != null) {
                Navigator.pop(context);
                _syncUsers(tempBatchCode!);
              }
            },
            child: const Text("Start Sync"),
          ),
        ],
      ),
    );
  }

  Future<void> _syncUsers(String batchCode) async {
    setState(() => _isLoading = true);
    try {
      final usersSnap = await FirebaseFirestore.instance.collection('users').where('role', isEqualTo: 'student').get();
      int updatedCount = 0;
      for (var doc in usersSnap.docs) {
        Map<String, dynamic> updateData = {};
        if (doc.data()['semester'] == null) updateData['semester'] = 1;
        if (doc.data()['batch'] == null) updateData['batch'] = batchCode;
        if (updateData.isNotEmpty) {
          await doc.reference.update(updateData);
          updatedCount++;
        }
      }
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Successfully synced $updatedCount old students")));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Sync Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildAddUserTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Register New User", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: "Full Name", prefixIcon: Icon(Icons.person), border: OutlineInputBorder())),
          const SizedBox(height: 16),
          TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: "Email Address", prefixIcon: Icon(Icons.email), border: OutlineInputBorder())),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedRole,
            decoration: const InputDecoration(labelText: "User Role", prefixIcon: Icon(Icons.category), border: OutlineInputBorder()),
            items: const [DropdownMenuItem(value: 'student', child: Text("Student")), DropdownMenuItem(value: 'teacher', child: Text("Teacher"))],
            onChanged: (val) { if (val != null) setState(() => _selectedRole = val); },
          ),
          if (_selectedRole == 'student') ...[
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('batches').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) return Text("Error loading batches");
                if (!snapshot.hasData) return const CircularProgressIndicator();
                var batches = snapshot.data!.docs;
                return DropdownButtonFormField<String>(
                  value: _selectedBatchCode,
                  decoration: const InputDecoration(labelText: "Select Batch Code", prefixIcon: Icon(Icons.qr_code), border: OutlineInputBorder()),
                  items: batches.map((doc) => DropdownMenuItem(value: doc.id, child: Text("${doc.id} (${doc['name']})"))).toList(),
                  onChanged: (val) => setState(() => _selectedBatchCode = val),
                );
              },
            ),
          ],
          const SizedBox(height: 30),
          if (_isLoading) const Center(child: CircularProgressIndicator())
          else ElevatedButton(
            onPressed: _createUser,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(55)),
            child: const Text("CREATE ACCOUNT", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildBatchesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Create New Auto-Generated Batch", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  TextField(controller: _batchNameCtrl, decoration: const InputDecoration(labelText: "Batch Name", border: OutlineInputBorder())),
                  const SizedBox(height: 16),
                  TextField(controller: _studentCountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Students Count", border: OutlineInputBorder())),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2020), lastDate: DateTime(2035));
                      if (picked != null) setState(() => _selectedDate = picked);
                    },
                    icon: const Icon(Icons.calendar_month),
                    label: Text("Date: ${_selectedDate.month}/${_selectedDate.year}"),
                  ),
                  const SizedBox(height: 20),
                  if (_isLoading) const Center(child: CircularProgressIndicator())
                  else ElevatedButton(
                    onPressed: _generateAndSaveBatch,
                    style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                    child: const Text("Generate Code & Save"),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('batches').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return Center(child: Text("Permission Denied or Error: ${snapshot.error}"));
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              if (snapshot.data!.docs.isEmpty) return const Center(child: Text("No batches created yet."));
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  var doc = snapshot.data!.docs[index];
                  return Card(
                    child: ListTile(
                      title: Text("Code: ${doc.id}", style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("${doc['name']} - ${doc['studentCount']} students"),
                      trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => doc.reference.delete()),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _generateAndSaveBatch() async {
    if (_batchNameCtrl.text.isEmpty || _studentCountCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please fill all details")));
      return;
    }
    setState(() => _isLoading = true);
    try {
      String uniqueCode = "";
      bool isUnique = false;
      for(int i=0; i<5; i++) {
        uniqueCode = (Random().nextInt(9000) + 1000).toString();
        var doc = await FirebaseFirestore.instance.collection('batches').doc(uniqueCode).get();
        if (!doc.exists) { isUnique = true; break; }
      }
      if (!isUnique) throw "Try again, unique code failed.";

      await FirebaseFirestore.instance.collection('batches').doc(uniqueCode).set({
        'name': _batchNameCtrl.text.trim(),
        'studentCount': int.parse(_studentCountCtrl.text.trim()),
        'month': _selectedDate.month,
        'year': _selectedDate.year,
        'createdAt': FieldValue.serverTimestamp(),
      });
      _batchNameCtrl.clear(); _studentCountCtrl.clear();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Batch Created: $uniqueCode")));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _createUser() async {
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    if (_nameCtrl.text.isEmpty || _emailCtrl.text.isEmpty) {
      scaffoldMessenger.showSnackBar(const SnackBar(content: Text("Please fill all fields")));
      return;
    }
    setState(() => _isLoading = true);
    try {
      await _auth.signUpWithBatch(_nameCtrl.text.trim(), _emailCtrl.text.trim(), "Admin@123", _selectedRole, _selectedBatchCode);
      scaffoldMessenger.showSnackBar(SnackBar(content: Text("User created successfully")));
      _nameCtrl.clear(); _emailCtrl.clear();
    } catch (e) {
      scaffoldMessenger.showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildViewUsersTab() {
    return StreamBuilder<List<UserModel>>(
      stream: _auth.getAllUsers(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final users = snapshot.data!.where((u) => u.role != 'admin').toList();
        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: CircleAvatar(child: Text(user.role[0].toUpperCase())),
                title: Text(user.fullName),
                subtitle: Text("Batch: ${user.batch ?? 'N/A'} | Sem: ${user.semester ?? 'N/A'}"),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRequestsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _auth.getPendingRequests(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            var doc = snapshot.data!.docs[index];
            var data = doc.data() as Map<String, dynamic>;
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                title: Text(data['fullName'] ?? 'User'),
                trailing: ElevatedButton(
                  onPressed: () => _auth.approveRequest(doc.id, data['email']),
                  child: const Text("Approve"),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
