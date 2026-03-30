import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/result_model.dart';
import '../models/exam_form_model.dart';
import '../services/auth_service.dart';

class AdminResultManagementScreen extends StatefulWidget {
  const AdminResultManagementScreen({super.key});

  @override
  State<AdminResultManagementScreen> createState() => _AdminResultManagementScreenState();
}

class _AdminResultManagementScreenState extends State<AdminResultManagementScreen> {
  final _auth = AuthService();
  int _selectedSemester = 1;
  String _searchQuery = "";
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Results"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
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
              ),
              onChanged: (val) => setState(() => _searchQuery = val.trim().toLowerCase()),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<UserModel>>(
              stream: _auth.getStudentsBySemester(_selectedSemester),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                final students = snapshot.data!.where((s) => 
                  s.fullName.toLowerCase().contains(_searchQuery)
                ).toList();

                if (students.isEmpty) return const Center(child: Text("No students found."));

                return ListView.builder(
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final student = students[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListTile(
                        leading: CircleAvatar(child: Text(student.fullName[0])),
                        title: Text(student.fullName),
                        subtitle: Text("ID: ${student.uid.substring(0, 8)}"),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => StudentResultEntryScreen(student: student, semester: _selectedSemester),
                          ),
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
}

class StudentResultEntryScreen extends StatefulWidget {
  final UserModel student;
  final int semester;

  const StudentResultEntryScreen({super.key, required this.student, required this.semester});

  @override
  State<StudentResultEntryScreen> createState() => _StudentResultEntryScreenState();
}

class _StudentResultEntryScreenState extends State<StudentResultEntryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<SubjectResult> _enteredResults = [];
  bool _isLoading = true;
  double _sgpa = 0.0;
  double _cgpa = 0.0;

  final List<String> _grades = ['AA', 'AB', 'BB', 'BC', 'CC', 'CD', 'DD', 'FF'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    // 1. Try to load existing result
    final resultDoc = await FirebaseFirestore.instance
        .collection('results')
        .where('studentId', isEqualTo: widget.student.uid)
        .where('semester', isEqualTo: widget.semester)
        .get();

    if (resultDoc.docs.isNotEmpty) {
      final res = ResultModel.fromMap(resultDoc.docs.first.data(), resultDoc.docs.first.id);
      _enteredResults.addAll(res.results);
      _sgpa = res.sgpa;
      _cgpa = res.cgpa;
    } else {
      // 2. If no result, load subjects from Exam Form or default subjects
      final examFormSnap = await FirebaseFirestore.instance
          .collection('exam_forms')
          .where('studentId', isEqualTo: widget.student.uid)
          .where('semester', isEqualTo: widget.semester)
          .where('status', isEqualTo: 'Confirmed')
          .get();

      if (examFormSnap.docs.isNotEmpty) {
        final form = ExamFormModel.fromMap(examFormSnap.docs.first.data(), examFormSnap.docs.first.id);
        for (var sub in form.subjects) {
          _enteredResults.add(SubjectResult(
            subjectName: sub.name,
            type: sub.type,
            credits: 4, // Default credits, can be customized
            grade: 'FF',
            gradePoint: 0,
            isPass: false,
          ));
        }
      }
    }

    setState(() => _isLoading = false);
  }

  void _updateGrade(SubjectResult sub, String grade) {
    int index = _enteredResults.indexOf(sub);
    if (index != -1) {
      int gp = SubjectResult.getGradePoint(grade);
      setState(() {
        _enteredResults[index] = SubjectResult(
          subjectName: sub.subjectName,
          type: sub.type,
          credits: sub.credits,
          grade: grade,
          gradePoint: gp,
          isPass: grade != 'FF',
        );
        _calculateSgpa();
      });
    }
  }

  void _calculateSgpa() {
    if (_enteredResults.isEmpty) return;
    int totalCredits = 0;
    int weightedPoints = 0;
    for (var r in _enteredResults) {
      totalCredits += r.credits;
      weightedPoints += (r.credits * r.gradePoint);
    }
    _sgpa = totalCredits > 0 ? weightedPoints / totalCredits : 0.0;
    _cgpa = _sgpa; // Simplified for now, in a real app fetch previous semesters
  }

  Future<void> _saveResult() async {
    final result = ResultModel(
      studentId: widget.student.uid,
      studentName: widget.student.fullName,
      semester: widget.semester,
      results: _enteredResults,
      sgpa: double.parse(_sgpa.toStringAsFixed(2)),
      cgpa: double.parse(_cgpa.toStringAsFixed(2)),
      updatedAt: DateTime.now(),
    );

    final existing = await FirebaseFirestore.instance
        .collection('results')
        .where('studentId', isEqualTo: widget.student.uid)
        .where('semester', isEqualTo: widget.semester)
        .get();

    if (existing.docs.isNotEmpty) {
      await FirebaseFirestore.instance.collection('results').doc(existing.docs.first.id).update(result.toMap());
    } else {
      await FirebaseFirestore.instance.collection('results').add(result.toMap());
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Result Saved Successfully!")));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.student.fullName),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Theory"),
            Tab(text: "Practical"),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildSubjectList('Theory'),
                      _buildSubjectList('Practical'),
                    ],
                  ),
                ),
                _buildSummaryCard(),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    onPressed: _saveResult,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text("UPLOAD RESULT"),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSubjectList(String type) {
    final filtered = _enteredResults.where((r) => r.type == type).toList();
    if (filtered.isEmpty) return Center(child: Text("No $type subjects found."));

    return ListView.builder(
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final res = filtered[index];
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(res.subjectName, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text("Credits: ${res.credits}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<String>(
                    value: res.grade,
                    underline: const SizedBox(),
                    items: _grades.map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
                    onChanged: (val) => _updateGrade(res, val!),
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  res.grade == 'FF' ? Icons.cancel : Icons.check_circle,
                  color: res.grade == 'FF' ? Colors.red : Colors.green,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _summaryItem("SGPA", _sgpa.toStringAsFixed(2)),
          _summaryItem("CGPA", _cgpa.toStringAsFixed(2)),
          _summaryItem("Percentage", "${((_cgpa - 0.5) * 10).toStringAsFixed(1)}%"),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
