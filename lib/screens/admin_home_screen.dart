// ignore_for_file: deprecated_member_use

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
  
  // Controllers
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _branchIdCtrl = TextEditingController();
  final _branchNameCtrl = TextEditingController();
  final _batchLetterCtrl = TextEditingController();
  final _batchYearCtrl = TextEditingController(text: DateTime.now().year.toString());
  final _subjectNameCtrl = TextEditingController();

  String _selectedRole = 'student';
  String? _selectedBranchId;
  String? _selectedBatchName;
  int _selectedSemester = 1;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Admin Dashboard"),
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                final navigator = Navigator.of(context);
                await _auth.signOut();
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
              Tab(icon: Icon(Icons.account_tree_rounded), text: "Branches"),
              Tab(icon: Icon(Icons.grid_view_rounded), text: "Batches"),
              Tab(icon: Icon(Icons.book), text: "Subjects"),
              Tab(icon: Icon(Icons.list), text: "Users"),
              Tab(icon: Icon(Icons.notifications), text: "Requests"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildAddUserTab(),
            _buildBranchesTab(),
            _buildBatchesTab(),
            _buildSubjectsTab(),
            _buildViewUsersTab(),
            _buildRequestsTab(),
          ],
        ),
      ),
    );
  }

  // --- 1. ADD USER TAB ---
  Widget _buildAddUserTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Register New User", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: "Full Name", border: OutlineInputBorder())),
          const SizedBox(height: 16),
          TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: "Email Address", border: OutlineInputBorder())),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedRole,
            decoration: const InputDecoration(labelText: "User Role", border: OutlineInputBorder()),
            items: const [DropdownMenuItem(value: 'student', child: Text("Student")), DropdownMenuItem(value: 'teacher', child: Text("Teacher"))],
            onChanged: (val) => setState(() { _selectedRole = val!; _selectedBranchId = null; _selectedBatchName = null; }),
          ),
          const SizedBox(height: 16),
          StreamBuilder<QuerySnapshot>(
            stream: _auth.getBranches(),
            builder: (context, snap) {
              if (!snap.hasData) return const LinearProgressIndicator();
              var branches = snap.data!.docs;
              return DropdownButtonFormField<String>(
                value: _selectedBranchId,
                decoration: const InputDecoration(labelText: "Select Branch", border: OutlineInputBorder()),
                items: branches.map((doc) => DropdownMenuItem(value: doc.id, child: Text(doc.id))).toList(),
                onChanged: (val) => setState(() { _selectedBranchId = val; _selectedBatchName = null; }),
              );
            },
          ),
          if (_selectedRole == 'student' && _selectedBranchId != null) ...[
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: _auth.getBatchesByBranch(_selectedBranchId!),
              builder: (context, snap) {
                if (!snap.hasData) return const LinearProgressIndicator();
                var batches = snap.data!.docs;
                return DropdownButtonFormField<String>(
                  value: _selectedBatchName,
                  decoration: const InputDecoration(labelText: "Select Batch", border: OutlineInputBorder()),
                  items: batches.map((doc) => DropdownMenuItem(value: doc['fullName'].toString(), child: Text(doc['fullName']))).toList(),
                  onChanged: (val) => setState(() => _selectedBatchName = val),
                );
              },
            ),
          ],
          const SizedBox(height: 30),
          if (_isLoading) const Center(child: CircularProgressIndicator())
          else ElevatedButton(
            onPressed: _handleCreateUser,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(55)),
            child: const Text("CREATE ACCOUNT"),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCreateUser() async {
    final messenger = ScaffoldMessenger.of(context);
    if (_nameCtrl.text.isEmpty || _emailCtrl.text.isEmpty || _selectedBranchId == null) {
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
      );
      messenger.showSnackBar(const SnackBar(content: Text("User Created Successfully!")));
      _nameCtrl.clear(); _emailCtrl.clear();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- 2. BRANCHES TAB ---
  Widget _buildBranchesTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text("Add New Branch", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  TextField(controller: _branchIdCtrl, decoration: const InputDecoration(labelText: "Branch ID (e.g. IT, CE)")),
                  TextField(controller: _branchNameCtrl, decoration: const InputDecoration(labelText: "Full Name (e.g. Information Tech)")),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () async {
                      if (_branchIdCtrl.text.isEmpty) return;
                      await _auth.addBranch(_branchIdCtrl.text, _branchNameCtrl.text);
                      _branchIdCtrl.clear(); _branchNameCtrl.clear();
                    },
                    child: const Text("Add Branch"),
                  )
                ],
              ),
            ),
          ),
          const Expanded(child: _BranchList())
        ],
      ),
    );
  }

  // --- 3. BATCHES TAB ---
  Widget _buildBatchesTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text("Create New Batch (Max 4 per Branch)", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  StreamBuilder<QuerySnapshot>(
                    stream: _auth.getBranches(),
                    builder: (context, snap) {
                      if (!snap.hasData) return const CircularProgressIndicator();
                      return DropdownButtonFormField<String>(
                        hint: const Text("Select Branch"),
                        items: snap.data!.docs.map((doc) => DropdownMenuItem(value: doc.id, child: Text(doc.id))).toList(),
                        onChanged: (val) => _selectedBranchId = val,
                      );
                    },
                  ),
                  TextField(controller: _batchLetterCtrl, decoration: const InputDecoration(labelText: "Batch Letter (A, B, C, D)")),
                  TextField(controller: _batchYearCtrl, decoration: const InputDecoration(labelText: "Year")),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      if (_selectedBranchId == null || _batchLetterCtrl.text.isEmpty) return;
                      try {
                        await _auth.createBatch(_selectedBranchId!, _batchLetterCtrl.text.toUpperCase(), int.parse(_batchYearCtrl.text));
                        messenger.showSnackBar(const SnackBar(content: Text("Batch Created!")));
                      } catch (e) {
                        messenger.showSnackBar(SnackBar(content: Text(e.toString())));
                      }
                    },
                    child: const Text("Generate Batch"),
                  )
                ],
              ),
            ),
          ),
          const Expanded(child: _BatchListDisplay()),
        ],
      ),
    );
  }

  // --- 4. SUBJECTS TAB ---
  Widget _buildSubjectsTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Text("Add New Subject", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: StreamBuilder<QuerySnapshot>(
                          stream: _auth.getBranches(),
                          builder: (context, snap) {
                            if (!snap.hasData) return const LinearProgressIndicator();
                            return DropdownButtonFormField<String>(
                              hint: const Text("Branch"),
                              items: snap.data!.docs.map((doc) => DropdownMenuItem(value: doc.id, child: Text(doc.id))).toList(),
                              onChanged: (val) => setState(() => _selectedBranchId = val),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _selectedSemester,
                          hint: const Text("Semester"),
                          items: List.generate(8, (i) => i + 1).map((s) => DropdownMenuItem(value: s, child: Text("Sem $s"))).toList(),
                          onChanged: (val) => setState(() => _selectedSemester = val!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(controller: _subjectNameCtrl, decoration: const InputDecoration(labelText: "Subject Name")),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () async {
                      if (_selectedBranchId == null || _subjectNameCtrl.text.isEmpty) return;
                      await _auth.addSubject(_selectedBranchId!, _selectedSemester, _subjectNameCtrl.text.trim());
                      _subjectNameCtrl.clear();
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Subject Added!")));
                    },
                    child: const Text("Add Subject"),
                  )
                ],
              ),
            ),
          ),
          const Expanded(child: _SubjectListDisplay()),
        ],
      ),
    );
  }

  // --- 5. VIEW USERS TAB ---
  Widget _buildViewUsersTab() {
    return StreamBuilder<List<UserModel>>(
      stream: _auth.getAllUsers(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final users = snapshot.data!.where((u) => u.role != 'admin').toList();
        return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: CircleAvatar(backgroundColor: user.role == 'teacher' ? Colors.orange : Colors.blue, child: Text(user.role[0].toUpperCase(), style: const TextStyle(color: Colors.white))),
                title: Text(user.fullName),
                subtitle: Text("${user.role.toUpperCase()} | Branch: ${user.branch ?? 'N/A'} ${user.role == 'student' ? '| Batch: ${user.batch ?? 'N/A'}' : ''}"),
                trailing: user.role == 'teacher' ? IconButton(
                  icon: const Icon(Icons.edit, color: Colors.indigo),
                  onPressed: () => _showEditTeacherBranchDialog(user),
                ) : null,
              ),
            );
          },
        );
      },
    );
  }

  void _showEditTeacherBranchDialog(UserModel user) {
    String? tempBranch;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Change Branch for ${user.fullName}"),
        content: StreamBuilder<QuerySnapshot>(
          stream: _auth.getBranches(),
          builder: (context, snap) {
            if (!snap.hasData) return const CircularProgressIndicator();
            return DropdownButtonFormField<String>(
              value: user.branch,
              items: snap.data!.docs.map((doc) => DropdownMenuItem(value: doc.id, child: Text(doc.id))).toList(),
              onChanged: (val) => tempBranch = val,
            );
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (tempBranch != null) {
                await _auth.updateTeacherBranch(user.uid, tempBranch!);
                if (ctx.mounted) Navigator.pop(ctx);
              }
            },
            child: const Text("Update"),
          )
        ],
      ),
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
                subtitle: Text(data['email']),
                trailing: ElevatedButton(onPressed: () => _auth.approveRequest(doc.id, data['email']), child: const Text("Approve")),
              ),
            );
          },
        );
      },
    );
  }
}

class _BranchList extends StatelessWidget {
  const _BranchList();
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: AuthService().getBranches(),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox();
        return ListView.builder(
          itemCount: snap.data!.docs.length,
          itemBuilder: (context, i) {
            var doc = snap.data!.docs[i];
            return ListTile(
              title: Text(doc.id, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(doc['name']),
              trailing: Text("Batches: ${doc['batchCount']}/4"),
            );
          },
        );
      },
    );
  }
}

class _BatchListDisplay extends StatelessWidget {
  const _BatchListDisplay();
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('batches').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox();
        return ListView.builder(
          itemCount: snap.data!.docs.length,
          itemBuilder: (context, i) {
            var doc = snap.data!.docs[i];
            return ListTile(
              title: Text(doc['fullName'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
              subtitle: Text("Branch: ${doc['branchId']} | Year: ${doc['year']}"),
            );
          },
        );
      },
    );
  }
}

class _SubjectListDisplay extends StatelessWidget {
  const _SubjectListDisplay();
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('subjects').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox();
        return ListView.builder(
          itemCount: snap.data!.docs.length,
          itemBuilder: (context, i) {
            var doc = snap.data!.docs[i];
            return ListTile(
              title: Text(doc['name'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
              subtitle: Text("Branch: ${doc['branch']} | Sem: ${doc['semester']}"),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => doc.reference.delete(),
              ),
            );
          },
        );
      },
    );
  }
}
