import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/exam_form_model.dart';
import '../services/auth_service.dart';
import '../services/error_handler.dart';

class AdminExamFormScreen extends StatefulWidget {
  final String? collegeId;
  const AdminExamFormScreen({super.key, this.collegeId});

  @override
  State<AdminExamFormScreen> createState() => _AdminExamFormScreenState();
}

class _AdminExamFormScreenState extends State<AdminExamFormScreen> {
  final _auth = AuthService();
  int _selectedSemester = 1;
  String _searchQuery = "";
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Exam Form Management"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.notification_important, color: Colors.orangeAccent),
            onPressed: () => _showRejectedFormsDialog(),
            tooltip: "Rejected Forms",
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.indigo.withOpacity(0.05),
            child: Row(
              children: [
                const Text("Select Semester: ", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 10),
                DropdownButton<int>(
                  value: _selectedSemester,
                  items: List.generate(8, (i) => i + 1).map((s) => DropdownMenuItem(value: s, child: Text("Sem $s"))).toList(),
                  onChanged: (val) => setState(() => _selectedSemester = val!),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: "Search student name...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                suffixIcon: _searchQuery.isNotEmpty ? IconButton(icon: const Icon(Icons.clear), onPressed: () {
                  _searchCtrl.clear();
                  setState(() => _searchQuery = "");
                }) : null,
              ),
              onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<UserModel>>(
              stream: _auth.getStudentsBySemester(_selectedSemester, collegeId: widget.collegeId),
              builder: (context, snapshot) {
                if (snapshot.hasError) return AppErrorHandler.buildErrorWidget(snapshot.error, () => setState(() {}));
                if (!snapshot.hasData) return AppErrorHandler.buildLoadingWidget();
                
                final students = snapshot.data!.where((s) => 
                  s.fullName.toLowerCase().contains(_searchQuery)
                ).toList();

                if (students.isEmpty) return const Center(child: Text("No students found in this semester."));

                return ListView.builder(
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final student = students[index];
                    return StreamBuilder<ExamFormModel?>(
                      stream: _auth.getStudentExamForm(student.uid),
                      builder: (context, formSnap) {
                        final form = formSnap.data;
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: ListTile(
                            leading: CircleAvatar(child: Text(student.fullName[0])),
                            title: Text(student.fullName),
                            subtitle: Text("Status: ${form?.status ?? 'Not Created'}"),
                            trailing: _getStatusIcon(form?.status),
                            onTap: () => _openStudentExamForm(student, form),
                          ),
                        );
                      },
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

  void _showRejectedFormsDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 10),
            Text("Rejected Forms"),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('exam_forms')
                .where('status', isEqualTo: 'Rejected')
                .where('collegeId', isEqualTo: widget.collegeId)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) return AppErrorHandler.buildErrorWidget(snapshot.error, () => setState(() {}));
              if (!snapshot.hasData) return AppErrorHandler.buildLoadingWidget();
              if (snapshot.data!.docs.isEmpty) return const Text("No rejected forms found.");

              return ListView.builder(
                shrinkWrap: true,
                itemCount: snapshot.data!.docs.length,
                itemBuilder: (context, index) {
                  final formDoc = snapshot.data!.docs[index];
                  final form = ExamFormModel.fromMap(formDoc.data() as Map<String, dynamic>, formDoc.id);
                  return Card(
                    color: Colors.red[50],
                    child: ListTile(
                      title: Text(form.studentName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Reason: ${form.rejectReason ?? 'No reason given'}", style: const TextStyle(color: Colors.red)),
                          Text("Semester: ${form.semester}", style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                      onTap: () async {
                        Navigator.pop(ctx);
                        final userDoc = await FirebaseFirestore.instance.collection('users').doc(form.studentId).get();
                        if (!context.mounted) return;
                        if (userDoc.exists) {
                          final user = UserModel.fromMap(userDoc.data()!, form.studentId);
                          _openStudentExamForm(user, form);
                        }
                      },
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Close")),
        ],
      ),
    );
  }

  Widget _getStatusIcon(String? status) {
    if (status == 'Confirmed') return const Icon(Icons.check_circle, color: Colors.green);
    if (status == 'Rejected') return const Icon(Icons.cancel, color: Colors.red);
    if (status == 'Pending') return const Icon(Icons.hourglass_empty, color: Colors.orange);
    return const Icon(Icons.add_circle_outline, color: Colors.grey);
  }

  void _openStudentExamForm(UserModel student, ExamFormModel? existingForm) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudentFormDetailScreen(student: student, form: existingForm, collegeId: widget.collegeId),
      ),
    );
  }
}

class StudentFormDetailScreen extends StatefulWidget {
  final UserModel student;
  final ExamFormModel? form;
  final String? collegeId;

  const StudentFormDetailScreen({super.key, required this.student, this.form, this.collegeId});

  @override
  State<StudentFormDetailScreen> createState() => _StudentFormDetailScreenState();
}

class _StudentFormDetailScreenState extends State<StudentFormDetailScreen> with SingleTickerProviderStateMixin {
  final _auth = AuthService();
  List<ExamSubject> _subjects = [];
  late TabController _tabController;
  String? _selectedTheorySubject;
  String? _selectedPracticalSubject;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    if (widget.form != null) {
      _subjects = List.from(widget.form!.subjects);
    } else {
      _loadDefaultSubjects();
    }
  }

  Future<void> _loadDefaultSubjects() async {
    // 1. Get all subjects for this branch and semester
    final subSnap = await _auth.getSubjects(widget.student.branch ?? '', widget.student.semester ?? 1, collegeId: widget.collegeId).first;
    
    // 2. Get student's elective selections
    final selectionSnap = await _auth.getStudentElectiveSelection(widget.student.uid, widget.student.semester ?? 1).first;
    List<String> selectedIds = selectionSnap?.selectedSubjectIds ?? [];

    List<ExamSubject> defaultSubjects = [];

    for (var doc in subSnap.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final String type = data['type'] ?? 'General';
      final String name = data['name'] ?? '';

      // Add if General OR if it's a selected elective
      if (type == 'General' || type == 'Practical' || selectedIds.contains(doc.id)) {
        defaultSubjects.add(ExamSubject(name: name, type: type == 'Practical' ? 'Practical' : 'Theory'));
      }
    }

    setState(() {
      _subjects = defaultSubjects;
    });
  }

  void _addSubject(String name, String type) {
    if (_subjects.any((s) => s.name == name && s.type == type)) return;
    setState(() {
      _subjects.add(ExamSubject(name: name, type: type));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.student.fullName),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.menu_book), text: "Theory"),
            Tab(icon: Icon(Icons.science), text: "Practical"),
          ],
        ),
      ),
      body: Column(
        children: [
          if (widget.form?.status == 'Rejected')
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: Colors.red[100],
              child: Text("REJECTED REASON: ${widget.form?.rejectReason}", 
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
          
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.grey[100],
            child: StreamBuilder<QuerySnapshot>(
              stream: _auth.getSubjects(widget.student.branch ?? '', widget.student.semester ?? 1, collegeId: widget.collegeId),
              builder: (context, snap) {
                if (!snap.hasData) return const LinearProgressIndicator();
                final availableSubjects = snap.data!.docs.map((d) => d['name'] as String).toList();
                
                return Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        isExpanded: true,
                        hint: const Text("Select Subject"),
                        value: _tabController.index == 0 ? _selectedTheorySubject : _selectedPracticalSubject,
                        items: availableSubjects.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                        onChanged: (val) {
                          setState(() {
                            if (_tabController.index == 0) {
                              _selectedTheorySubject = val;
                            } else {
                              _selectedPracticalSubject = val;
                            }
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: () {
                        String? selected = _tabController.index == 0 ? _selectedTheorySubject : _selectedPracticalSubject;
                        if (selected != null) {
                          _addSubject(selected, _tabController.index == 0 ? 'Theory' : 'Practical');
                        }
                      },
                      child: const Text("Add"),
                    ),
                  ],
                );
              },
            ),
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildSubjectList('Theory'),
                _buildSubjectList('Practical'),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () async {
                final newForm = ExamFormModel(
                  id: widget.form?.id,
                  studentId: widget.student.uid,
                  studentName: widget.student.fullName,
                  semester: widget.student.semester ?? 1,
                  subjects: _subjects,
                  status: 'Pending',
                  collegeId: widget.collegeId,
                );
                
                LoadingOverlay.show(context);
                try {
                  await _auth.createOrUpdateExamForm(newForm);
                  if (context.mounted) {
                    AppErrorHandler.showSuccess(context, "Exam Form Updated!");
                    Navigator.pop(context);
                  }
                } catch (e) {
                  if (context.mounted) AppErrorHandler.showError(context, e);
                } finally {
                  if (context.mounted) LoadingOverlay.hide(context);
                }
              },
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50), backgroundColor: Colors.indigo, foregroundColor: Colors.white),
              child: Text(widget.form == null ? "CREATE EXAM FORM" : "UPDATE EXAM FORM"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectList(String type) {
    final filtered = _subjects.where((s) => s.type == type).toList();
    if (filtered.isEmpty) return Center(child: Text("No $type subjects added."));
    
    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final sub = filtered[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: ListTile(
            title: Text(sub.name),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => setState(() => _subjects.remove(sub)),
            ),
          ),
        );
      },
    );
  }
}
