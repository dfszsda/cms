import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/auth_service.dart';
import '../../../models/user_model.dart';

class AdminSubjectsTab extends StatefulWidget {
  final String collegeId;
  const AdminSubjectsTab({super.key, required this.collegeId});

  @override
  State<AdminSubjectsTab> createState() => _AdminSubjectsTabState();
}

class _AdminSubjectsTabState extends State<AdminSubjectsTab> with SingleTickerProviderStateMixin {
  final _auth = AuthService();
  final _subjectNameCtrl = TextEditingController();
  String? _selectedBranchId;
  int _selectedSemester = 1;
  int _allocationSemester = 1; // For Teacher Allocation Tab
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _subjectNameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Subjects"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.library_books), text: "Manage Subjects"),
            Tab(icon: Icon(Icons.person_add_alt_1), text: "Teacher Allocation"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildManageSubjectsTab(),
          _buildTeacherAllocationTab(),
        ],
      ),
    );
  }

  Widget _buildManageSubjectsTab() {
    return Padding(
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
                  const Text("Add New Subject", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: StreamBuilder<QuerySnapshot>(
                          stream: _auth.getBranches(collegeId: widget.collegeId),
                          builder: (context, snap) {
                            if (!snap.hasData) return const LinearProgressIndicator();
                            return DropdownButtonFormField<String>(
                              decoration: const InputDecoration(labelText: "Branch", border: OutlineInputBorder()),
                              items: snap.data!.docs.map((doc) => DropdownMenuItem(value: doc.id, child: Text(doc.get('branchId') ?? doc.id))).toList(),
                              onChanged: (val) => setState(() => _selectedBranchId = val),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<int>(
                          value: _selectedSemester,
                          decoration: const InputDecoration(labelText: "Semester", border: OutlineInputBorder()),
                          items: List.generate(8, (i) => i + 1).map((s) => DropdownMenuItem(value: s, child: Text("Sem $s"))).toList(),
                          onChanged: (val) => setState(() => _selectedSemester = val!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(controller: _subjectNameCtrl, decoration: const InputDecoration(labelText: "Subject Name", border: OutlineInputBorder())),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_selectedBranchId == null || _subjectNameCtrl.text.isEmpty) return;
                        final messenger = ScaffoldMessenger.of(context);
                        await _auth.addSubject(_selectedBranchId!, _selectedSemester, _subjectNameCtrl.text.trim(), widget.collegeId);
                        _subjectNameCtrl.clear();
                        messenger.showSnackBar(const SnackBar(content: Text("Subject Added!")));
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                      child: const Text("Add Subject"),
                    ),
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('subjects').where('collegeId', isEqualTo: widget.collegeId).orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snap.data!.docs;
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    var data = docs[i].data() as Map<String, dynamic>;
                    return Card(
                      child: ListTile(
                        title: Text(data['name'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                        subtitle: Text("Branch: ${data['branch']} | Sem: ${data['semester']}"),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => docs[i].reference.delete(),
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

  Widget _buildTeacherAllocationTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: DropdownButtonFormField<int>(
            value: _allocationSemester,
            decoration: const InputDecoration(
              labelText: "Select Semester to Filter Subjects",
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.filter_list),
            ),
            items: List.generate(8, (i) => i + 1).map((s) => DropdownMenuItem(value: s, child: Text("Semester $s"))).toList(),
            onChanged: (val) => setState(() => _allocationSemester = val!),
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('subjects')
                .where('collegeId', isEqualTo: widget.collegeId)
                .where('semester', isEqualTo: _allocationSemester)
                .orderBy('name')
                .snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (!snap.hasData || snap.data!.docs.isEmpty) return const Center(child: Text("No subjects found for this semester."));
              
              final subjects = snap.data!.docs;
              return ListView.builder(
                itemCount: subjects.length,
                itemBuilder: (context, i) {
                  final subDoc = subjects[i];
                  final data = subDoc.data() as Map<String, dynamic>;
                  final List teachers = data['subjectTeachers'] ?? [];
                  final List assistants = data['assistantSubjectTeachers'] ?? [];

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      title: Text(data['name'], style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                      subtitle: Text("Teachers: ${teachers.length} | Assistants: ${assistants.length}"),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit, color: Colors.indigo),
                        onPressed: () => _showAllocationDialog(subDoc.id, data),
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

  void _showAllocationDialog(String subjectId, Map<String, dynamic> subData) async {
    List<String> selectedTeachers = List<String>.from(subData['subjectTeachers'] ?? []);
    List<String> selectedAssistants = List<String>.from(subData['assistantSubjectTeachers'] ?? []);

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text("Allocate Teachers for ${subData['name']}"),
              content: SizedBox(
                width: double.maxFinite,
                child: StreamBuilder<List<UserModel>>(
                  stream: _auth.getTeachersByCollege(widget.collegeId),
                  builder: (context, snap) {
                    if (!snap.hasData) return const Center(child: CircularProgressIndicator());
                    final teachers = snap.data!;
                    if (teachers.isEmpty) return const Center(child: Text("No teachers found in this college."));
                    
                    return ListView(
                      shrinkWrap: true,
                      children: [
                        const Text("Subject Teachers", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                        const Divider(),
                        ...teachers.map((t) => CheckboxListTile(
                          title: Text(t.fullName),
                          subtitle: Text(t.email),
                          activeColor: Colors.indigo,
                          value: selectedTeachers.contains(t.uid),
                          onChanged: (val) {
                            setDialogState(() {
                              if (val!) {
                                selectedTeachers.add(t.uid);
                                selectedAssistants.remove(t.uid); 
                              } else {
                                selectedTeachers.remove(t.uid);
                              }
                            });
                          },
                        )),
                        const SizedBox(height: 16),
                        const Text("Assistant Subject Teachers", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                        const Divider(),
                        ...teachers.map((t) => CheckboxListTile(
                          title: Text(t.fullName),
                          subtitle: Text(t.email),
                          activeColor: Colors.orange,
                          value: selectedAssistants.contains(t.uid),
                          onChanged: (val) {
                            setDialogState(() {
                              if (val!) {
                                selectedAssistants.add(t.uid);
                                selectedTeachers.remove(t.uid); 
                              } else {
                                selectedAssistants.remove(t.uid);
                              }
                            });
                          },
                        )),
                      ],
                    );
                  },
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                  onPressed: () async {
                    final messenger = ScaffoldMessenger.of(context);
                    final navigator = Navigator.of(context);
                    await _auth.updateSubjectTeachers(subjectId, selectedTeachers, selectedAssistants);
                    navigator.pop();
                    messenger.showSnackBar(const SnackBar(content: Text("Teachers Allocated!")));
                  },
                  child: const Text("Save Changes"),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
