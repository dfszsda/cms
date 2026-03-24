import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/exam_timetable_model.dart';
import '../services/auth_service.dart';
import 'package:intl/intl.dart';

class AdminExamTimetableScreen extends StatefulWidget {
  const AdminExamTimetableScreen({super.key});

  @override
  State<AdminExamTimetableScreen> createState() => _AdminExamTimetableScreenState();
}

class _AdminExamTimetableScreenState extends State<AdminExamTimetableScreen> {
  final _auth = AuthService();
  String? _selectedBranch;
  int _selectedSemester = 1;
  DateTime? _examStartDate;
  List<ExamEvent> _examEvents = [];

  int _currentStep = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Set Exam Timetable"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Stepper(
        type: StepperType.vertical,
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep == 0 && _selectedBranch != null) {
            setState(() => _currentStep++);
          } else if (_currentStep == 1 && _examStartDate != null) {
            setState(() => _currentStep++);
          } else if (_currentStep == 2 && _examEvents.isNotEmpty) {
            _saveTimetable();
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() => _currentStep--);
          }
        },
        controlsBuilder: (context, details) {
          return Padding(
            padding: const EdgeInsets.only(top: 20),
            child: Row(
              children: [
                if (_currentStep < 2)
                  ElevatedButton(
                    onPressed: details.onStepContinue,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                    child: const Text("CONTINUE"),
                  )
                else
                  ElevatedButton(
                    onPressed: _examEvents.isEmpty ? null : _saveTimetable,
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                    child: const Text("PUBLISH TIMETABLE"),
                  ),
                const SizedBox(width: 12),
                if (_currentStep > 0)
                  TextButton(
                    onPressed: details.onStepCancel,
                    child: const Text("BACK"),
                  ),
              ],
            ),
          );
        },
        steps: [
          Step(
            title: const Text("Select Branch & Semester"),
            subtitle: const Text("Which class is this for?"),
            isActive: _currentStep >= 0,
            state: _currentStep > 0 ? StepState.complete : StepState.editing,
            content: Column(
              children: [
                StreamBuilder<QuerySnapshot>(
                  stream: _auth.getBranches(),
                  builder: (context, snap) {
                    if (!snap.hasData) return const LinearProgressIndicator();
                    return DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: "Select Branch", border: OutlineInputBorder()),
                      value: _selectedBranch,
                      items: snap.data!.docs.map((d) => DropdownMenuItem(value: d.id, child: Text(d.id))).toList(),
                      onChanged: (v) => setState(() => _selectedBranch = v),
                    );
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(labelText: "Select Semester", border: OutlineInputBorder()),
                  value: _selectedSemester,
                  items: List.generate(8, (i) => i + 1).map((s) => DropdownMenuItem(value: s, child: Text("Semester $s"))).toList(),
                  onChanged: (v) => setState(() => _selectedSemester = v!),
                ),
              ],
            ),
          ),
          Step(
            title: const Text("Exam Start Date"),
            subtitle: const Text("Must be at least 30 days from now"),
            isActive: _currentStep >= 1,
            state: _currentStep > 1 ? StepState.complete : StepState.editing,
            content: ListTile(
              tileColor: Colors.grey[100],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              leading: const Icon(Icons.calendar_month, color: Colors.indigo),
              title: Text(_examStartDate == null ? "Pick Date" : DateFormat('dd-MM-yyyy').format(_examStartDate!)),
              trailing: const Icon(Icons.edit, size: 18),
              onTap: _pickStartDate,
            ),
          ),
          Step(
            title: const Text("Add Exam Subjects"),
            subtitle: Text("${_examEvents.length} subjects added"),
            isActive: _currentStep >= 2,
            state: _currentStep == 2 ? StepState.editing : StepState.indexed,
            content: Column(
              children: [
                _buildAddExamSection(),
                const SizedBox(height: 10),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _examEvents.length,
                  itemBuilder: (context, index) {
                    final event = _examEvents[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: event.type == 'Theory' ? Colors.indigo : Colors.orange,
                          child: Text(event.type[0], style: const TextStyle(color: Colors.white)),
                        ),
                        title: Text(event.subjectName),
                        subtitle: Text("${DateFormat('dd-MM-yyyy (EEEE)').format(event.date)}\n${event.time} (${event.type})"),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => setState(() => _examEvents.removeAt(index)),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _pickStartDate() async {
    final now = DateTime.now();
    final minDate = now.add(const Duration(days: 30));
    
    final picked = await showDatePicker(
      context: context,
      initialDate: minDate,
      firstDate: minDate,
      lastDate: now.add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        _examStartDate = picked;
        _examEvents = []; // Reset events if start date changes
      });
    }
  }

  Widget _buildAddExamSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: _auth.getSubjects(_selectedBranch ?? '', _selectedSemester),
      builder: (context, snap) {
        if (!snap.hasData) return const LinearProgressIndicator();
        final subjects = snap.data!.docs.map((d) => d['name'] as String).toList();
        
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.indigo.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.indigo.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Add Subject to Timetable", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                isExpanded: true,
                decoration: const InputDecoration(labelText: "Subject", border: OutlineInputBorder()),
                items: subjects.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                onChanged: (val) {
                  if (val != null) _showAddExamDialog(val);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAddExamDialog(String subjectName) async {
    DateTime initialDate = _examStartDate!;
    if (_examEvents.isNotEmpty) {
      initialDate = _examEvents.last.date.add(const Duration(days: 1));
    }

    DateTime selectedDate = initialDate;
    String examType = 'Theory';
    TimeOfDay startTime = const TimeOfDay(hour: 10, minute: 30);
    TimeOfDay endTime = const TimeOfDay(hour: 13, minute: 30);

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text("Schedule: $subjectName"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: examType,
                  decoration: const InputDecoration(labelText: "Exam Type", border: OutlineInputBorder()),
                  items: ['Theory', 'Practical'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (v) => setDialogState(() => examType = v!),
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text("Date"),
                  subtitle: Text(DateFormat('dd-MM-yyyy').format(selectedDate)),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: _examStartDate!,
                      lastDate: _examStartDate!.add(const Duration(days: 60)),
                    );
                    if (d != null) setDialogState(() => selectedDate = d);
                  },
                ),
                ListTile(
                  title: const Text("Start Time"),
                  subtitle: Text(startTime.format(context)),
                  trailing: const Icon(Icons.access_time),
                  onTap: () async {
                    final t = await showTimePicker(context: context, initialTime: startTime);
                    if (t != null) setDialogState(() => startTime = t);
                  },
                ),
                ListTile(
                  title: const Text("End Time"),
                  subtitle: Text(endTime.format(context)),
                  trailing: const Icon(Icons.access_time),
                  onTap: () async {
                    final t = await showTimePicker(context: context, initialTime: endTime);
                    if (t != null) setDialogState(() => endTime = t);
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCEL")),
            ElevatedButton(
              onPressed: () {
                final timeRange = "${startTime.format(context)} - ${endTime.format(context)}";
                setState(() {
                  _examEvents.add(ExamEvent(
                    subjectName: subjectName,
                    date: selectedDate,
                    time: timeRange,
                    type: examType,
                  ));
                });
                Navigator.pop(context);
              },
              child: const Text("ADD"),
            ),
          ],
        ),
      ),
    );
  }

  void _saveTimetable() async {
    _examEvents.sort((a, b) => a.date.compareTo(b.date));

    final timetable = ExamTimetableModel(
      branchId: _selectedBranch!,
      semester: _selectedSemester,
      startDate: _examStartDate!,
      exams: _examEvents,
      createdAt: DateTime.now(),
    );

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      await _auth.setExamTimetable(timetable);
      messenger.showSnackBar(const SnackBar(content: Text("Exam Timetable Published Successfully!")));
      navigator.pop();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }
}
