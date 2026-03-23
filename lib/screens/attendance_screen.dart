// ignore_for_file: prefer_final_fields, deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';
import '../models/leave_model.dart';

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
  List<String> _absentStudents = [];
  bool _isSaving = false;

  // Calendar properties
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedCalendarDay;

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

  void _showAddHolidayDialog() {
    final titleController = TextEditingController();
    DateTime holidayDate = DateTime.now();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Set Holiday / Special Day"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: "Event Title (e.g. Diwali / Working Saturday)"),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: Text("Date: ${DateFormat('dd-MM-yyyy').format(holidayDate)}"),
                trailing: const Icon(Icons.calendar_today),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: holidayDate,
                    firstDate: DateTime.now().subtract(const Duration(days: 30)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setDialogState(() => holidayDate = picked);
                  }
                },
              ),
              if (holidayDate.weekday == DateTime.saturday)
                const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Text(
                    "Note: This Saturday will be marked as a Working Day if you add a title like 'Working Day'.",
                    style: TextStyle(fontSize: 12, color: Colors.blue, fontStyle: FontStyle.italic),
                  ),
                ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isNotEmpty) {
                  final messenger = ScaffoldMessenger.of(context);
                  final navigator = Navigator.of(context);
                  
                  // If it's a Saturday and contains "Working", we can flag it differently or just store it in a special collection
                  bool isWorkingSaturday = holidayDate.weekday == DateTime.saturday && 
                                           titleController.text.toLowerCase().contains("working");

                  if (isWorkingSaturday) {
                    await FirebaseFirestore.instance.collection('working_saturdays').add({
                      'date': Timestamp.fromDate(DateTime(holidayDate.year, holidayDate.month, holidayDate.day)),
                      'title': titleController.text.trim(),
                      'branchId': widget.teacherBranch,
                      'teacherId': _auth.currentUser?.uid,
                      'createdAt': FieldValue.serverTimestamp(),
                    });
                  } else {
                    await _auth.addHoliday(
                      date: holidayDate,
                      title: titleController.text.trim(),
                      branchId: widget.teacherBranch,
                    );
                  }
                  
                  navigator.pop();
                  messenger.showSnackBar(SnackBar(content: Text(isWorkingSaturday ? "Working Saturday Announced!" : "Holiday Added!")));
                }
              },
              child: const Text("Add"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTeacher = widget.teacherBranch != null;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(isTeacher ? "Take Attendance" : "My Attendance"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (isTeacher)
            IconButton(
              icon: const Icon(Icons.event_note),
              onPressed: _showAddHolidayDialog,
              tooltip: "Set Special Day",
            ),
        ],
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
                            _absentStudents.clear();
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
                  bool isPresent = _presentStudents.contains(student.uid);
                  bool isAbsent = _absentStudents.contains(student.uid);

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.person, color: Colors.indigo),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(student.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text("Batch: ${student.batch ?? 'N/A'}", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                        // Present Option
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text("P", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.green)),
                            Radio<bool>(
                              value: true,
                              groupValue: isPresent ? true : (isAbsent ? false : null),
                              activeColor: Colors.green,
                              onChanged: (val) {
                                setState(() {
                                  _presentStudents.add(student.uid);
                                  _absentStudents.remove(student.uid);
                                });
                              },
                            ),
                          ],
                        ),
                        // Absent Option
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text("A", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.red)),
                            Radio<bool>(
                              value: false,
                              groupValue: isPresent ? true : (isAbsent ? false : null),
                              activeColor: Colors.red,
                              onChanged: (val) {
                                setState(() {
                                  _absentStudents.add(student.uid);
                                  _presentStudents.remove(student.uid);
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
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
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("SUBMIT ATTENDANCE", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
        ),
      ],
    );
  }

  Widget _buildStudentView() {
    return StreamBuilder<QuerySnapshot>(
      stream: _auth.getStudentAttendance(widget.student!.uid, widget.student!.branch ?? '', widget.student!.semester ?? 1),
      builder: (context, attendanceSnap) {
        return StreamBuilder<QuerySnapshot>(
          stream: _auth.getAllHolidays(),
          builder: (context, holidaySnap) {
            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('working_saturdays').snapshots(),
              builder: (context, workingSatSnap) {
                return StreamBuilder<List<LeaveModel>>(
                  stream: _auth.getStudentLeaves(widget.student!.uid),
                  builder: (context, leaveSnap) {
                    if (attendanceSnap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                    
                    final attendanceDocs = attendanceSnap.data?.docs ?? [];
                    final holidayDocs = holidaySnap.data?.docs ?? [];
                    final workingSatDocs = workingSatSnap.data?.docs ?? [];
                    final leaveDocs = leaveSnap.data ?? [];
                    
                    Map<DateTime, String> statusMap = {};
                    Map<DateTime, String> holidayTitles = {};
                    Set<DateTime> workingSaturdays = {};
                    int presentClasses = 0;
                    int totalClasses = 0;

                    // 1. Process Working Saturdays (Exceptions)
                    for (var doc in workingSatDocs) {
                      final data = doc.data() as Map<String, dynamic>;
                      final date = (data['date'] as Timestamp).toDate();
                      final day = DateTime(date.year, date.month, date.day);
                      workingSaturdays.add(day);
                      holidayTitles[day] = "Working Saturday: ${data['title']}";
                    }

                    // 2. Process Approved Leaves
                    Set<DateTime> leaveDates = {};
                    for (var leave in leaveDocs) {
                      if (leave.status == 'approved') {
                        DateTime current = DateTime(leave.startDate.year, leave.startDate.month, leave.startDate.day);
                        DateTime end = DateTime(leave.endDate.year, leave.endDate.month, leave.endDate.day);
                        while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
                          leaveDates.add(current);
                          current = current.add(const Duration(days: 1));
                        }
                      }
                    }

                    // 3. Process Holidays (Manual)
                    Set<DateTime> manualHolidayDates = {};
                    for (var doc in holidayDocs) {
                      final data = doc.data() as Map<String, dynamic>;
                      final date = (data['date'] as Timestamp).toDate();
                      final day = DateTime(date.year, date.month, date.day);
                      statusMap[day] = 'holiday';
                      holidayTitles[day] = data['title'] ?? 'Holiday';
                      manualHolidayDates.add(day);
                    }

                    // 4. Process Attendance
                    for (var doc in attendanceDocs) {
                      final data = doc.data() as Map<String, dynamic>;
                      final date = (data['date'] as Timestamp).toDate();
                      final day = DateTime(date.year, date.month, date.day);
                      
                      // Skip manual holidays in total attendance calculation per user request
                      if (manualHolidayDates.contains(day)) continue;

                      final presentList = List<String>.from(data['presentStudents'] ?? []);
                      final absentList = List<String>.from(data['absentStudents'] ?? []);
                      
                      if (presentList.contains(widget.student!.uid)) {
                        statusMap[day] = 'present';
                        presentClasses++;
                        totalClasses++;
                      } else {
                        // Count as absent if in absent list OR if student is on approved leave (gher hajar)
                        if (absentList.contains(widget.student!.uid) || leaveDates.contains(day)) {
                          statusMap[day] = 'absent';
                          totalClasses++;
                        }
                      }
                    }

                    // 5. Final pass for Calendar Display: show Leave color for approved leaves
                    // We do this last so 'leave' status overrides 'absent'/'present' for the calendar view
                    for (var day in leaveDates) {
                      statusMap[day] = 'leave';
                    }

                    double percentage = totalClasses == 0 ? 0 : (presentClasses / totalClasses) * 100;

                    return SingleChildScrollView(
                      child: Column(
                        children: [
                          // Summary Section
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: const BoxDecoration(
                              color: Colors.indigo,
                              borderRadius: BorderRadius.only(
                                bottomLeft: Radius.circular(30),
                                bottomRight: Radius.circular(30),
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  "${percentage.toStringAsFixed(1)}%",
                                  style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold),
                                ),
                                const Text("Attendance Percentage", style: TextStyle(color: Colors.white70)),
                                const SizedBox(height: 20),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    _buildSummaryStat("Total", totalClasses.toString()),
                                    _buildSummaryStat("Present", presentClasses.toString()),
                                    _buildSummaryStat("Absent", (totalClasses - presentClasses).toString()),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Calendar Section
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Card(
                              elevation: 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              child: Column(
                                children: [
                                  TableCalendar(
                                    firstDay: DateTime.utc(2020, 1, 1),
                                    lastDay: DateTime.now().add(const Duration(days: 365)),
                                    focusedDay: _focusedDay,
                                    calendarFormat: _calendarFormat,
                                    selectedDayPredicate: (day) => isSameDay(_selectedCalendarDay, day),
                                    onDaySelected: (selectedDay, focusedDay) {
                                      setState(() {
                                        _selectedCalendarDay = selectedDay;
                                        _focusedDay = focusedDay;
                                      });
                                    },
                                    onFormatChanged: (format) {
                                      setState(() {
                                        _calendarFormat = format;
                                      });
                                    },
                                    calendarBuilders: CalendarBuilders(
                                      defaultBuilder: (context, day, focusedDay) {
                                        final dateOnly = DateTime(day.year, day.month, day.day);
                                        final status = statusMap[dateOnly];
                                        
                                        // Default Holiday Rules
                                        bool isDefaultHoliday = day.weekday == DateTime.sunday || day.weekday == DateTime.saturday;
                                        
                                        // Exception: Working Saturday
                                        if (day.weekday == DateTime.saturday && workingSaturdays.contains(dateOnly)) {
                                          isDefaultHoliday = false;
                                        }

                                        if (status == 'leave') {
                                          return _buildCalendarDay(day, Colors.deepPurple);
                                        }

                                        if (isDefaultHoliday) {
                                          return _buildCalendarDay(day, Colors.orange);
                                        }
                                        
                                        if (status == 'present') {
                                          return _buildCalendarDay(day, Colors.green);
                                        } else if (status == 'absent') {
                                          return _buildCalendarDay(day, Colors.red);
                                        } else if (status == 'holiday') {
                                          return _buildCalendarDay(day, Colors.orange);
                                        }
                                        return null;
                                      },
                                      todayBuilder: (context, day, focusedDay) {
                                        final dateOnly = DateTime(day.year, day.month, day.day);
                                        if (statusMap[dateOnly] == 'leave') {
                                          return _buildCalendarDay(day, Colors.deepPurple, isToday: true);
                                        }
                                        return _buildCalendarDay(day, Colors.blue, isToday: true);
                                      },
                                    ),
                                    headerStyle: const HeaderStyle(
                                      formatButtonVisible: false,
                                      titleCentered: true,
                                      titleTextStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                    ),
                                  ),
                                  if (_selectedCalendarDay != null) _buildSelectedDayInfo(statusMap, holidayTitles, workingSaturdays),
                                ],
                              ),
                            ),
                          ),

                          // Legend
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 15,
                              children: [
                                _buildLegendItem(Colors.green, "Present"),
                                _buildLegendItem(Colors.red, "Absent"),
                                _buildLegendItem(Colors.orange, "Holiday/Sat/Sun"),
                                _buildLegendItem(Colors.deepPurple, "On Leave"),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildSelectedDayInfo(Map<DateTime, String> statusMap, Map<DateTime, String> holidayTitles, Set<DateTime> workingSaturdays) {
    final day = DateTime(_selectedCalendarDay!.year, _selectedCalendarDay!.month, _selectedCalendarDay!.day);
    String? title;

    if (statusMap[day] == 'leave') {
      title = "On Approved Leave";
    } else if (workingSaturdays.contains(day)) {
      title = holidayTitles[day] ?? "Working Saturday";
    } else if (day.weekday == DateTime.sunday) {
      title = "Weekly Holiday (Sunday)";
    } else if (day.weekday == DateTime.saturday) {
      title = "Weekly Holiday (Saturday)";
    } else if (statusMap[day] == 'holiday') {
      title = holidayTitles[day] ?? 'Holiday';
    }

    if (title != null) {
      bool isWorking = workingSaturdays.contains(day);
      bool isLeave = statusMap[day] == 'leave';
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          isLeave ? title : (isWorking ? "Notice: $title" : "Holiday: $title"),
          style: TextStyle(fontWeight: FontWeight.bold, color: isLeave ? Colors.deepPurple : (isWorking ? Colors.blue : Colors.orange)),
          textAlign: TextAlign.center,
        ),
      );
    }
    return const SizedBox();
  }

  Widget _buildCalendarDay(DateTime day, Color color, {bool isToday = false}) {
    return Container(
      margin: const EdgeInsets.all(4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
        border: isToday ? Border.all(color: Colors.blue, width: 2) : null,
      ),
      child: Text(
        day.day.toString(),
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildSummaryStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white60, fontSize: 12)),
      ],
    );
  }

  Future<void> _handleSaveAttendance() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    if (_selectedSubject == null) {
      messenger.showSnackBar(const SnackBar(content: Text("Please select a subject.")));
      return;
    }
    
    if (_presentStudents.isEmpty && _absentStudents.isEmpty) {
      messenger.showSnackBar(const SnackBar(content: Text("Please mark attendance for students.")));
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
        absentUids: _absentStudents,
      );
      
      messenger.showSnackBar(const SnackBar(content: Text("Attendance recorded successfully!")));
      navigator.pop();
    } catch (e) {
      messenger.showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
