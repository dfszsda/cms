// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../models/college_model.dart';
import 'login_screen.dart';
import 'holiday_screen.dart';
import 'admin_exam_form_screen.dart';
import 'admin_exam_timetable_screen.dart';
import 'ufm_dashboard_screen.dart';
import 'admin_result_management_screen.dart';
import 'payment_settings_screen.dart';
import 'admin_exam_fee_screen.dart';
import 'admin_college_fee_screen.dart';
import 'library_management_screen.dart';
import 'college_info_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  final _auth = AuthService();
  // ignore: unused_field
  UserModel? _adminUser;
  
  // Scoping
  String? _managedCollegeId;
  String? _managedCollegeName;

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
  String? _selectedCoordinatorId;
  int _selectedSemester = 1;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAdminData();
  }

  Future<void> _loadAdminData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          _adminUser = UserModel.fromMap(doc.data()!, user.uid);
          // Admin can manage any college, start with none selected
          _managedCollegeId = null; 
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return DefaultTabController(
      length: 12,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_managedCollegeName != null ? "Admin: $_managedCollegeName" : "Admin Dashboard"),
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          actions: [
            _buildCollegeSelectorAction(),
            IconButton(
              icon: const Icon(Icons.settings_suggest_outlined),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentSettingsScreen())),
              tooltip: "Payment Settings",
            ),
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
              Tab(icon: Icon(Icons.school), text: "Colleges"),
              Tab(icon: Icon(Icons.sync), text: "Migration"),
              Tab(icon: Icon(Icons.account_tree_rounded), text: "Branches"),
              Tab(icon: Icon(Icons.grid_view_rounded), text: "Batches"),
              Tab(icon: Icon(Icons.local_library), text: "Library"),
              Tab(icon: Icon(Icons.account_balance_wallet_rounded), text: "Fees"),
              Tab(icon: Icon(Icons.warning_amber_rounded), text: "Unassigned"),
              Tab(icon: Icon(Icons.book), text: "Subjects"),
              Tab(icon: Icon(Icons.assignment_ind_rounded), text: "Examination"),
              Tab(icon: Icon(Icons.list), text: "Users"),
              Tab(icon: Icon(Icons.notifications), text: "Requests"),
            ],
          ),
        ),
        body: _managedCollegeId == null 
          ? _buildNoCollegeSelected()
          : TabBarView(
          children: [
            _buildAddUserTab(),
            CollegeInfoScreen(role: 'admin', collegeId: _managedCollegeId),
            _buildMigrationTab(),
            _buildBranchesTab(),
            _buildBatchesTab(),
            _buildLibraryTab(),
            _buildFeesTab(),
            _buildUnassignedBatchesTab(),
            _buildSubjectsTab(),
            _buildExaminationTab(),
            _buildViewUsersTab(),
            _buildRequestsTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildNoCollegeSelected() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.account_balance_rounded, size: 100, color: Colors.indigo),
            const SizedBox(height: 20),
            const Text("Welcome to Admin Panel", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const Text("Please select a college to start managing or add a new one.", 
              textAlign: TextAlign.center, 
              style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 30),
            
            StreamBuilder<List<CollegeModel>>(
              stream: _auth.getColleges(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const CircularProgressIndicator();
                final colleges = snapshot.data!;
                
                return Column(
                  children: [
                    if (colleges.isNotEmpty) ...[
                      const Text("Select College:", style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.indigo),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: DropdownButton<CollegeModel>(
                          hint: const Text("Choose College"),
                          underline: const SizedBox(),
                          isExpanded: true,
                          items: colleges.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
                          onChanged: (col) {
                            setState(() {
                              _managedCollegeId = col!.id;
                              _managedCollegeName = col.name;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text("OR", style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 20),
                    ],
                    ElevatedButton.icon(
                      onPressed: () {
                        // Navigate to a screen or show dialog to add college
                        // For now, we use the CollegeInfoScreen in admin mode
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const CollegeInfoScreen(role: 'admin')));
                      },
                      icon: const Icon(Icons.add_business_rounded),
                      label: const Text("ADD NEW COLLEGE"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.indigo,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(200, 50),
                      ),
                    ),
                  ],
                );
              }
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCollegeSelectorAction() {
    return StreamBuilder<List<CollegeModel>>(
      stream: _auth.getColleges(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();
        final colleges = snapshot.data!;
        return PopupMenuButton<CollegeModel>(
          icon: const Icon(Icons.swap_horiz_rounded, color: Colors.white),
          tooltip: "Switch College",
          onSelected: (col) {
            setState(() {
              _managedCollegeId = col.id;
              _managedCollegeName = col.name;
            });
          },
          itemBuilder: (context) => colleges.map((c) => PopupMenuItem(value: c, child: Text(c.name))).toList(),
        );
      },
    );
  }

  // --- MIGRATION TAB ---
  Widget _buildMigrationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Data Migration Tool", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const Text("Assign existing unassigned data to the currently managed college.", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 30),
          _migrationCard("Users", "users"),
          _migrationCard("Branches", "branches"),
          _migrationCard("Batches", "batches"),
          _migrationCard("Subjects", "subjects"),
          _migrationCard("Canteen Items", "canteen_items"),
          _migrationCard("Library Books", "books"),
        ],
      ),
    );
  }

  Widget _migrationCard(String label, String collection) {
    return FutureBuilder<int>(
      future: _auth.getOrphanCount(collection),
      builder: (context, snapshot) {
        int count = snapshot.data ?? 0;
        return Card(
          child: ListTile(
            title: Text(label),
            subtitle: Text("$count unassigned items found"),
            trailing: count > 0 
              ? ElevatedButton(
                  onPressed: () async {
                    await _auth.migrateDataToCollege(collection, _managedCollegeId!);
                    if (!context.mounted) return;
                    setState(() {}); // Refresh
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Migrated $count $label items")));
                  },
                  child: const Text("Migrate"),
                )
              : const Icon(Icons.check_circle, color: Colors.green),
          ),
        );
      },
    );
  }

  // --- ADD USER TAB --- (Updated with College Scoping)
  Widget _buildAddUserTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Register New User for $_managedCollegeName", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: "Full Name", border: OutlineInputBorder())),
          const SizedBox(height: 16),
          TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: "Email Address", border: OutlineInputBorder())),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedRole,
            decoration: const InputDecoration(labelText: "User Role", border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'student', child: Text("Student")),
              DropdownMenuItem(value: 'teacher', child: Text("Teacher")),
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
              stream: _auth.getBranches(collegeId: _managedCollegeId),
              builder: (context, snap) {
                if (!snap.hasData) return const LinearProgressIndicator();
                var branches = snap.data!.docs;
                return DropdownButtonFormField<String>(
                  value: _selectedBranchId,
                  decoration: const InputDecoration(labelText: "Select Branch", border: OutlineInputBorder()),
                  items: branches.map((doc) => DropdownMenuItem(value: doc.id, child: Text(doc.get('branchId') ?? doc.id))).toList(),
                  onChanged: (val) => setState(() { _selectedBranchId = val; _selectedBatchName = null; }),
                );
              },
            ),
          ],
          if (_selectedRole == 'student' && _selectedBranchId != null) ...[
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: _auth.getBatchesByBranch(_selectedBranchId!, collegeId: _managedCollegeId),
              builder: (context, snap) {
                if (!snap.hasData) return const LinearProgressIndicator();
                var batches = snap.data!.docs;
                return DropdownButtonFormField<String>(
                  value: _selectedBatchName,
                  decoration: const InputDecoration(labelText: "Select Batch", border: OutlineInputBorder()),
                  items: batches.map((doc) => DropdownMenuItem(value: (doc.data() as Map<String, dynamic>)['fullName'].toString(), child: Text((doc.data() as Map<String, dynamic>)['fullName'] ?? ''))).toList(),
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
    if (_nameCtrl.text.isEmpty || _emailCtrl.text.isEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text("Please fill all required fields")));
      return;
    }
    if (_selectedRole != 'retailer' && _selectedRole != 'librarian' && _selectedBranchId == null) {
      messenger.showSnackBar(const SnackBar(content: Text("Please select a branch")));
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
        collegeId: _managedCollegeId,
      );
      
      messenger.showSnackBar(const SnackBar(content: Text("User Created Successfully!")));
      _nameCtrl.clear(); _emailCtrl.clear();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- BRANCHES TAB ---
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
                      if (_branchIdCtrl.text.isEmpty || _managedCollegeId == null) return;
                      await _auth.addBranch(_branchIdCtrl.text, _branchNameCtrl.text, _managedCollegeId!);
                      _branchIdCtrl.clear(); _branchNameCtrl.clear();
                    },
                    child: const Text("Add Branch"),
                  )
                ],
              ),
            ),
          ),
          Expanded(child: _BranchList(collegeId: _managedCollegeId))
        ],
      ),
    );
  }

  // --- BATCHES TAB ---
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
                  const Text("Create New Batch", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  StreamBuilder<QuerySnapshot>(
                    stream: _auth.getBranches(collegeId: _managedCollegeId),
                    builder: (context, snap) {
                      if (!snap.hasData) return const CircularProgressIndicator();
                      return DropdownButtonFormField<String>(
                        hint: const Text("Select Branch"),
                        items: snap.data!.docs.map((doc) => DropdownMenuItem(value: doc.id, child: Text(doc.get('branchId') ?? doc.id))).toList(),
                        onChanged: (val) => _selectedBranchId = val,
                      );
                    },
                  ),
                  TextField(controller: _batchLetterCtrl, decoration: const InputDecoration(labelText: "Batch Letter (A, B, C, D)")),
                  TextField(controller: _batchYearCtrl, decoration: const InputDecoration(labelText: "Year")),
                  const SizedBox(height: 10),
                  StreamBuilder<List<UserModel>>(
                    stream: _auth.getTeachers(collegeId: _managedCollegeId),
                    builder: (context, snap) {
                      if (!snap.hasData) return const LinearProgressIndicator();
                      return DropdownButtonFormField<String>(
                        hint: const Text("Select Coordinator (Optional)"),
                        items: snap.data!.map((teacher) => DropdownMenuItem(value: teacher.uid, child: Text(teacher.fullName))).toList(),
                        onChanged: (val) => _selectedCoordinatorId = val,
                      );
                    },
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      if (_selectedBranchId == null || _batchLetterCtrl.text.isEmpty || _managedCollegeId == null) return;
                      try {
                        await _auth.createBatch(
                          _selectedBranchId!, 
                          _batchLetterCtrl.text.toUpperCase(), 
                          int.parse(_batchYearCtrl.text),
                          _managedCollegeId!,
                          coordinatorId: _selectedCoordinatorId,
                        );
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
          Expanded(child: _BatchListDisplay(collegeId: _managedCollegeId)),
        ],
      ),
    );
  }

  Widget _buildLibraryTab() { 
    return LibraryManagementScreen(collegeId: _managedCollegeId); 
  }

  Widget _buildFeesTab() { 
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          leading: const Icon(Icons.account_balance_wallet, color: Colors.indigo),
          title: const Text("Set College Fees"),
          subtitle: const Text("Manage semester-wise college fees"),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminCollegeFeeScreen())),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.assignment, color: Colors.indigo),
          title: const Text("Set Exam Fees"),
          subtitle: const Text("Manage semester-wise exam fees"),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminExamFeeScreen())),
        ),
      ],
    );
  }

  Widget _buildUnassignedBatchesTab() { 
    return Column(
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
                .where('collegeId', isEqualTo: _managedCollegeId)
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
                    child: ListTile(
                      title: Text(data['fullName'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("Branch: ${data['branchId']} | Year: ${data['year']}"),
                      trailing: ElevatedButton(
                        onPressed: () => _showAssignCoordinatorDialog(snap.data!.docs[i].id),
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
    );
  }

  void _showAssignCoordinatorDialog(String batchId) {
    UserModel? selectedTeacher;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Assign Coordinator"),
        content: StreamBuilder<List<UserModel>>(
          stream: _auth.getTeachers(collegeId: _managedCollegeId),
          builder: (context, snap) {
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
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Coordinator assigned!")));
                } catch (e) {
                  if (ctx.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                }
              }
            },
            child: const Text("Assign"),
          )
        ],
      ),
    );
  }
  
  // --- SUBJECTS TAB ---
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
                          stream: _auth.getBranches(collegeId: _managedCollegeId),
                          builder: (context, snap) {
                            if (!snap.hasData) return const LinearProgressIndicator();
                            return DropdownButtonFormField<String>(
                              hint: const Text("Branch"),
                              items: snap.data!.docs.map((doc) => DropdownMenuItem(value: doc.id, child: Text(doc.get('branchId') ?? doc.id))).toList(),
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
                      if (_selectedBranchId == null || _subjectNameCtrl.text.isEmpty || _managedCollegeId == null) return;
                      await _auth.addSubject(_selectedBranchId!, _selectedSemester, _subjectNameCtrl.text.trim(), _managedCollegeId!);
                      _subjectNameCtrl.clear();
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Subject Added!")));
                    },
                    child: const Text("Add Subject"),
                  )
                ],
              ),
            ),
          ),
          Expanded(child: _SubjectListDisplay(collegeId: _managedCollegeId)),
        ],
      ),
    );
  }

  Widget _buildExaminationTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          leading: const Icon(Icons.assignment_ind_rounded, color: Colors.indigo),
          title: const Text("Manage Exam Forms"),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminExamFormScreen(collegeId: _managedCollegeId))),
        ),
        const Divider(),
        ListTile(
          leading: const Icon(Icons.calendar_month_rounded, color: Colors.indigo),
          title: const Text("Set Exam Timetable"),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminExamTimetableScreen(collegeId: _managedCollegeId))),
        ),
      ],
    );
  }

  // --- VIEW USERS TAB ---
  Widget _buildViewUsersTab() {
    return StreamBuilder<List<UserModel>>(
      stream: _auth.getAllUsers(collegeId: _managedCollegeId),
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
                leading: CircleAvatar(
                  backgroundColor: user.role == 'teacher' ? Colors.orange : (user.role == 'retailer' ? Colors.green : (user.role == 'librarian' ? Colors.indigo : Colors.blue)), 
                  child: Text(user.role[0].toUpperCase(), style: const TextStyle(color: Colors.white)),
                ),
                title: Text(user.fullName),
                subtitle: Text("${user.role.toUpperCase()} | ${user.branch ?? 'No Branch'}"),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.transfer_within_a_station, color: Colors.blue),
                      onPressed: () => _showChangeCollegeDialog(user),
                      tooltip: "Change College",
                    ),
                    if (user.role == 'teacher')
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.indigo),
                      onPressed: () => _showEditTeacherBranchDialog(user),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showChangeCollegeDialog(UserModel user) {
    CollegeModel? selectedCol;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Transfer ${user.fullName} to College"),
        content: StreamBuilder<List<CollegeModel>>(
          stream: _auth.getColleges(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const CircularProgressIndicator();
            return DropdownButtonFormField<CollegeModel>(
              hint: const Text("Select Target College"),
              items: snapshot.data!.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
              onChanged: (val) => selectedCol = val,
            );
          },
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (selectedCol != null) {
                await _auth.updateTeacherCollege(user.uid, selectedCol!.id);
                if (ctx.mounted) Navigator.pop(ctx);
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
        title: Text("Change Branch for ${user.fullName}"),
        content: StreamBuilder<QuerySnapshot>(
          stream: _auth.getBranches(collegeId: _managedCollegeId),
          builder: (context, snap) {
            if (!snap.hasData) return const CircularProgressIndicator();
            return DropdownButtonFormField<String>(
              value: user.branch,
              items: snap.data!.docs.map((doc) => DropdownMenuItem(value: doc.id, child: Text(doc.get('branchId') ?? doc.id))).toList(),
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
      stream: _auth.getPendingRequestsByCollege(_managedCollegeId),
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
  final String? collegeId;
  const _BranchList({this.collegeId});
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: AuthService().getBranches(collegeId: collegeId),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox();
        return ListView.builder(
          itemCount: snap.data!.docs.length,
          itemBuilder: (context, i) {
            var doc = snap.data!.docs[i];
            var data = doc.data() as Map<String, dynamic>;
            return ListTile(
              title: Text(data['branchId'] ?? doc.id, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(data['name'] ?? 'N/A'),
              trailing: Text("Batches: ${data['batchCount'] ?? 0}/20"),
            );
          },
        );
      },
    );
  }
}

class _BatchListDisplay extends StatelessWidget {
  final String? collegeId;
  const _BatchListDisplay({this.collegeId});
  @override
  Widget build(BuildContext context) {
    Query query = FirebaseFirestore.instance.collection('batches').orderBy('createdAt', descending: true);
    if (collegeId != null) query = query.where('collegeId', isEqualTo: collegeId);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox();
        return ListView.builder(
          itemCount: snap.data!.docs.length,
          itemBuilder: (context, i) {
            var doc = snap.data!.docs[i];
            var data = doc.data() as Map<String, dynamic>;
            String? coordId = data.containsKey('coordinatorId') ? data['coordinatorId'] : null;

            return FutureBuilder<DocumentSnapshot>(
              future: coordId != null ? FirebaseFirestore.instance.collection('users').doc(coordId).get() : null,
              builder: (context, userSnap) {
                String coordName = coordId == null ? "No Coordinator" : (userSnap.hasData ? ((userSnap.data!.data() as Map<String, dynamic>?)?['fullName'] ?? "Deleted User") : "Loading...");
                return ListTile(
                  title: Text(data['fullName'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                  subtitle: Text("Branch: ${data['branchId']} | Year: ${data['year']} | Coordinator: $coordName"),
                  trailing: IconButton(
                    icon: const Icon(Icons.person_off, color: Colors.red, size: 20),
                    onPressed: coordId == null ? null : () => AuthService().removeCoordinator(doc.id),
                    tooltip: "Remove Coordinator",
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _SubjectListDisplay extends StatelessWidget {
  final String? collegeId;
  const _SubjectListDisplay({this.collegeId});
  @override
  Widget build(BuildContext context) {
    Query query = FirebaseFirestore.instance.collection('subjects').orderBy('createdAt', descending: true);
    if (collegeId != null) query = query.where('collegeId', isEqualTo: collegeId);
    
    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox();
        return ListView.builder(
          itemCount: snap.data!.docs.length,
          itemBuilder: (context, i) {
            var doc = snap.data!.docs[i];
            var data = doc.data() as Map<String, dynamic>;
            return ListTile(
              title: Text(data['name'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
              subtitle: Text("Branch: ${data['branch']} | Sem: ${data['semester']}"),
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
