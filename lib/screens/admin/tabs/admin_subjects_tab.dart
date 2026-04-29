import 'package:cms/services/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/error_handler.dart';
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
  String _selectedType = "General";
  int _selectedSemester = 1;
  int _allocationSemester = 1; // For Teacher Allocation Tab
  late TabController _tabController;

  final List<String> _subjectTypes = [
    "General",
    "Professional Elective",
    "Open Elective",
    "Practical",
    "Seminar",
  ];

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
                            if (snap.hasError) return AppErrorHandler.buildErrorWidget(snap.error, () => setState(() {}));
                            if (!snap.hasData) return const LinearProgressIndicator();
                            return DropdownButtonFormField<String>(
                              decoration: const InputDecoration(labelText: "Branch", border: OutlineInputBorder()),
                              items: snap.data!.docs.map((doc) {
                                final branchId = doc.get('branchId') ?? doc.id;
                                final displayName = branchId.toString().contains('_') ? branchId.toString().split('_').last : branchId;
                                return DropdownMenuItem(value: doc.id, child: Text(displayName));
                              }).toList(),
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
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _subjectNameCtrl,
                          decoration: const InputDecoration(labelText: "Subject Name", border: OutlineInputBorder()),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedType,
                          isExpanded: true, // This will fix the overflow
                          decoration: const InputDecoration(labelText: "Subject Type", border: OutlineInputBorder()),
                          items: _subjectTypes.map((t) => DropdownMenuItem(value: t, child: Text(t, overflow: TextOverflow.ellipsis))).toList(),
                          onChanged: (val) => setState(() => _selectedType = val!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_selectedBranchId == null || _subjectNameCtrl.text.isEmpty) {
                          AppErrorHandler.showError(context, "Branch and Subject Name are required");
                          return;
                        }
                        
                        LoadingOverlay.show(context);
                        try {
                          await _auth.addSubject(
                            _selectedBranchId!,
                            _selectedSemester,
                            _subjectNameCtrl.text.trim(),
                            widget.collegeId,
                            _selectedType,
                          );
                          if (context.mounted) {
                            AppErrorHandler.showSuccess(context, "Subject Added!");
                            _subjectNameCtrl.clear();
                          }
                        } catch (e) {
                          if (context.mounted) AppErrorHandler.showError(context, e);
                        } finally {
                          if (context.mounted) LoadingOverlay.hide(context);
                        }
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
                if (snap.hasError) return AppErrorHandler.buildErrorWidget(snap.error, () => setState(() {}));
                if (!snap.hasData) return AppErrorHandler.buildLoadingWidget();
                final docs = snap.data!.docs;
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    var data = docs[i].data() as Map<String, dynamic>;
                    return Card(
                      child: ListTile(
                        title: Text(data['name'] ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                        subtitle: Text("Branch: ${data['branch'] != null && data['branch'].toString().contains('_') ? data['branch'].toString().split('_').last : data['branch']} | Sem: ${data['semester']} | Type: ${data['type'] ?? 'General'}"),
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
              if (snap.hasError) return AppErrorHandler.buildErrorWidget(snap.error, () => setState(() {}));
              if (snap.connectionState == ConnectionState.waiting) return AppErrorHandler.buildLoadingWidget();
              if (!snap.hasData || snap.data!.docs.isEmpty) return const Center(child: Text("No subjects found for this semester."));
              
              final subjects = snap.data!.docs;
              return ListView.builder(
                itemCount: subjects.length,
                itemBuilder: (context, i) {
                  final subDoc = subjects[i];
                  final data = subDoc.data() as Map<String, dynamic>;
                  final String subName = data['name'] ?? '';
                  final List teachers = data['subjectTeachers'] ?? [];
                  final List assistants = data['assistantSubjectTeachers'] ?? [];

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      title: Text(subName, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
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
    final String subName = subData['name'] ?? '';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text("Allocate Teachers for $subName"),
              content: SizedBox(
                width: double.maxFinite,
                child: StreamBuilder<List<UserModel>>(
                  stream: _auth.getTeachersByCollege(widget.collegeId),
                  builder: (context, snap) {
                    if (snap.hasError) return AppErrorHandler.buildErrorWidget(snap.error, () => setState(() {}));
                    if (!snap.hasData) return AppErrorHandler.buildLoadingWidget();
                    final allTeachers = snap.data!;
                    if (allTeachers.isEmpty) return const Center(child: Text("No teachers found."));

                    return SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildTeacherSelector(
                            title: "Subject Teachers",
                            color: Colors.indigo,
                            allTeachers: allTeachers,
                            selectedIds: selectedTeachers,
                            otherList: selectedAssistants,
                            onAdd: (id) => setDialogState(() {
                              selectedTeachers.add(id);
                              selectedAssistants.remove(id);
                            }),
                            onRemove: (id) => setDialogState(() => selectedTeachers.remove(id)),
                          ),
                          const SizedBox(height: 24),
                          _buildTeacherSelector(
                            title: "Assistant Subject Teachers",
                            color: Colors.orange,
                            allTeachers: allTeachers,
                            selectedIds: selectedAssistants,
                            otherList: selectedTeachers,
                            onAdd: (id) => setDialogState(() {
                              selectedAssistants.add(id);
                              selectedTeachers.remove(id);
                            }),
                            onRemove: (id) => setDialogState(() => selectedAssistants.remove(id)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                  onPressed: () async {
                    LoadingOverlay.show(context);
                    try {
                      await _auth.updateSubjectTeachers(subjectId, selectedTeachers, selectedAssistants);
                      if (context.mounted) {
                        AppErrorHandler.showSuccess(context, "Teachers Allocated Successfully!");
                        Navigator.pop(context);
                      }
                    } catch (e) {
                      if (context.mounted) AppErrorHandler.showError(context, e);
                    } finally {
                      if (context.mounted) LoadingOverlay.hide(context);
                    }
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

  Widget _buildTeacherSelector({
    required String title,
    required Color color,
    required List<UserModel> allTeachers,
    required List<String> selectedIds,
    required List<String> otherList,
    required Function(String) onAdd,
    required Function(String) onRemove,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 16)),
        const Divider(),
        // Dropdown to Add Teacher
        DropdownButtonFormField<String>(
          decoration: InputDecoration(
            hintText: "Select Teacher to Add",
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          items: allTeachers
              .where((t) => !selectedIds.contains(t.uid))
              .map((t) => DropdownMenuItem(
                    value: t.uid,
                    child: Text("${t.fullName} (${t.email})", overflow: TextOverflow.ellipsis),
                  ))
              .toList(),
          onChanged: (val) {
            if (val != null) onAdd(val);
          },
        ),
        const SizedBox(height: 8),
        // Selected Teachers Display
        Wrap(
          spacing: 8,
          children: selectedIds.map((id) {
            final teacher = allTeachers.firstWhere(
              (t) => t.uid == id,
              orElse: () => UserModel(
                uid: id,
                fullName: id, 
                email: "",
                role: "",
              ),
            );
            String displayName = teacher.fullName;

            return Chip(
              label: Text(displayName, style: const TextStyle(fontSize: 12)),
              backgroundColor: color.withOpacity(0.1),
              deleteIcon: const Icon(Icons.close, size: 16),
              onDeleted: () => onRemove(id),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: color)),
            );
          }).toList(),
        ),
      ],
    );
  }
}
