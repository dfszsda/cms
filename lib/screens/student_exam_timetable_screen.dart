import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/exam_timetable_model.dart';
import '../models/exam_form_model.dart';
import '../services/auth_service.dart';
import 'package:intl/intl.dart';

class StudentExamTimetableScreen extends StatefulWidget {
  final UserModel student;
  const StudentExamTimetableScreen({super.key, required this.student});

  @override
  State<StudentExamTimetableScreen> createState() => _StudentExamTimetableScreenState();
}

class _StudentExamTimetableScreenState extends State<StudentExamTimetableScreen> {
  String _selectedType = 'Theory';
  final _auth = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Exam Timetable"),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<ExamFormModel?>(
        stream: _auth.getStudentExamForm(widget.student.uid),
        builder: (context, formSnapshot) {
          if (formSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final examForm = formSnapshot.data;

          // Check if exam form is confirmed
          if (examForm == null || examForm.status != 'Confirmed') {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock_clock_rounded, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text(
                      "Timetable Locked",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      examForm == null 
                        ? "Your exam form has not been generated yet." 
                        : "Please confirm your Exam Form to view the timetable.",
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            );
          }

          // If form is confirmed, show the timetable
          return StreamBuilder<ExamTimetableModel?>(
            stream: _auth.getExamTimetable(widget.student.branch ?? '', widget.student.semester ?? 1),
            builder: (context, timetableSnapshot) {
              if (timetableSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final timetable = timetableSnapshot.data;

              if (timetable == null || timetable.exams.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.event_busy_rounded, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text("No exam timetable published yet.", style: TextStyle(fontSize: 18, color: Colors.grey)),
                    ],
                  ),
                );
              }

              // Filter exams: 
              // 1. Match selected type (Theory/Practical)
              // 2. ONLY subjects present in the confirmed Exam Form
              final filteredExams = timetable.exams.where((e) {
                bool matchesType = e.type == _selectedType;
                bool isConfirmedInForm = examForm.subjects.any(
                  (s) => s.name == e.subjectName && s.type == e.type
                );
                return matchesType && isConfirmedInForm;
              }).toList();

              return Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    color: Colors.deepOrange.withOpacity(0.1),
                    child: Column(
                      children: [
                        Text("Semester ${timetable.semester} - ${timetable.branchId}", 
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.deepOrange)),
                        const SizedBox(height: 12),
                        ToggleButtons(
                          borderRadius: BorderRadius.circular(10),
                          selectedColor: Colors.white,
                          fillColor: Colors.deepOrange,
                          constraints: const BoxConstraints(minHeight: 40, minWidth: 100),
                          isSelected: [_selectedType == 'Theory', _selectedType == 'Practical'],
                          onPressed: (index) {
                            setState(() {
                              _selectedType = index == 0 ? 'Theory' : 'Practical';
                            });
                          },
                          children: const [
                            Text("Theory"),
                            Text("Practical"),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: filteredExams.isEmpty 
                      ? Center(
                          child: Text(
                            "No $_selectedType exams found for your confirmed subjects.",
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredExams.length,
                          itemBuilder: (context, index) {
                            final exam = filteredExams[index];
                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: (exam.type == 'Theory' ? Colors.deepOrange : Colors.orange).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Column(
                                        children: [
                                          Text(DateFormat('dd').format(exam.date), style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: exam.type == 'Theory' ? Colors.deepOrange : Colors.orange)),
                                          Text(DateFormat('MMM').format(exam.date), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: exam.type == 'Theory' ? Colors.deepOrange : Colors.orange)),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(exam.subjectName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(Icons.access_time, size: 14, color: Colors.grey),
                                              const SizedBox(width: 4),
                                              Text(exam.time, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                              const SizedBox(width: 12),
                                              const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                                              const SizedBox(width: 4),
                                              Text(DateFormat('EEEE').format(exam.date), style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
