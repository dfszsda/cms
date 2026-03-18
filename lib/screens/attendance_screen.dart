// ignore_for_file: prefer_final_fields, deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class AttendanceScreen extends StatefulWidget {
  final String? teacherBranch; // Nullable to detect student vs teacher
  final UserModel? student;
  
  const AttendanceScreen({super.key, this.teacherBranch, this.student});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  final _auth = AuthService();
  int _selectedSemester = 1;
  String? _selectedSubject;
  DateTime _selectedDate = DateTime.now();
  List<String> _presentStudents = [];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.student != null) {
      _selectedSemester = widget.student!.semester ?? 1;
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTeacher = widget.teacherBranch != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isTeacher ? "Take Attendance" : "My Attendance"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: isTeacher ? _buildTeacherView() : _buildStudentView(),
    );
  }

  Widget _buildTeacherView() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _selectedSemester,
                      decoration: const InputDecoration(labelText: "Semester", border: OutlineInputBorder()),
                      items: List.generate(8, (index) => index + 1)
                          .map((sem) => DropdownMenuItem(value: sem, child: Text("Sem $sem")))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() {
                            _selectedSemester = val;
                            _selectedSubject = null;
                            _presentStudents.clear();
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: StreamBuilder<QuerySnapshot>(
                      stream: _auth.getSubjects(widget.teacherBranch!, _selectedSemester),
                      builder: (context, snapshot) {
                        List<String> subjects = [];
                        if (snapshot.hasData) {
                          subjects = snapshot.data!.docs.map((doc) => doc['name'] as String).toList();
                        }
                        return DropdownButtonFormField<String>(
                          value: _selectedSubject,
                          decoration: const InputDecoration(labelText: "Subject", border: OutlineInputBorder()),
                          items: subjects.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                          onChanged: (val) => setState(() => _selectedSubject = val),
                          hint: const Text("Select"),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              InkWell(
                onTap: () => _selectDate(context),
                child: InputDecorator(
                  decoration: const InputDecoration(labelText: "Date", border: OutlineInputBorder()),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(DateFormat('dd-MM-yyyy').format(_selectedDate)),
                      const Icon(Icons.calendar_today),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const Divider(),
        Expanded(
          child: StreamBuilder<List<UserModel>>(
            stream: _auth.getStudentsForAttendance(widget.teacherBranch!, _selectedSemester),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("No students found."));

              final students = snapshot.data!;
              return ListView.builder(
                itemCount: students.length,
                itemBuilder: (context, index) {
                  final student = students[index];
                  final isPresent = _presentStudents.contains(student.uid);

                  return CheckboxListTile(
                    title: Text(student.fullName),
                    subtitle: Text("Batch: ${student.batch ?? 'N/A'}"),
                    value: isPresent,
                    onChanged: (bool? value) {
                      setState(() {
                        if (value == true) {
                          _presentStudents.add(student.uid);
                        } else {
                          _presentStudents.remove(student.uid);
                        }
                      });
                    },
                    secondary: const Icon(Icons.person),
                  );
                },
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: _isSaving 
            ? const CircularProgressIndicator()
            : ElevatedButton(
              onPressed: _handleSaveAttendance,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text("SUBMIT ATTENDANCE", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
        ),
      ],
    );
  }

  Widget _buildStudentView() {
    return StreamBuilder<QuerySnapshot>(
      stream: _auth.getStudentAttendance(widget.student!.uid, widget.student!.semester ?? 1),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        final docs = snapshot.data!.docs;
        int totalClasses = docs.length;
        int presentClasses = 0;

        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final presentList = List<String>.from(data['presentStudents'] ?? []);
          if (presentList.contains(widget.student!.uid)) presentClasses++;
        }

        double percentage = totalClasses == 0 ? 0 : (presentClasses / totalClasses) * 100;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Text("Attendance Summary (Sem ${widget.student!.semester})", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildSummaryItem("Total", totalClasses.toString(), Colors.blue),
                          _buildSummaryItem("Present", presentClasses.toString(), Colors.green),
                          _buildSummaryItem("Percentage", "${percentage.toStringAsFixed(1)}%", percentage >= 75 ? Colors.green : Colors.red),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              const Align(alignment: Alignment.centerLeft, child: Text("History", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18))),
              const SizedBox(height: 10),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final data = docs[index].data() as Map<String, dynamic>;
                  final date = (data['date'] as Timestamp).toDate();
                  final subject = data['subject'] ?? 'N/A';
                  final isPresent = List<String>.from(data['presentStudents']).contains(widget.student!.uid);
                  
                  return Card(
                    child: ListTile(
                      leading: Icon(isPresent ? Icons.check_circle : Icons.cancel, color: isPresent ? Colors.green : Colors.red),
                      title: Text(subject),
                      subtitle: Text(DateFormat('dd-MM-yyyy').format(date)),
                      trailing: Text(isPresent ? "Present" : "Absent", style: TextStyle(color: isPresent ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  Future<void> _handleSaveAttendance() async {
    if (_selectedSubject == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select a subject.")));
      return;
    }
    if (_presentStudents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("No students selected.")));
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _auth.submitAttendance(
        branch: widget.teacherBranch!,
        semester: _selectedSemester,
        subject: _selectedSubject!,
        date: _selectedDate,
        presentUids: _presentStudents,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Attendance recorded successfully!")));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
