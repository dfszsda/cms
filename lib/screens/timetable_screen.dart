import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/auth_service.dart';
import '../services/error_handler.dart';
import '../models/user_model.dart';

class TimetableScreen extends StatefulWidget {
  final String? userRole;
  final String? userBranch;
  final int? userSemester;

  const TimetableScreen({super.key, this.userRole, this.userBranch, this.userSemester});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  final _auth = AuthService();
  UserModel? _currentUser;
  String? _selectedBranch;
  String? _selectedBatch;
  int _selectedSemester = 1;
  String _selectedDay = "Monday";
  List<Map<String, dynamic>> _slots = [];
  bool _isLoading = true;
  StreamSubscription? _timetableSub;

  final List<String> _days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];
  final List<String> _batchOptions = ["All", "Batch A", "Batch B", "Batch C", "Batch D"];

  @override
  void dispose() {
    _timetableSub?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _initializeCurrentDay();
    _loadUserData();
  }

  void _initializeCurrentDay() {
    final String today = DateFormat('EEEE').format(DateTime.now());
    if (_days.contains(today)) {
      _selectedDay = today;
    } else {
      // If today is Sunday or unknown, default to Monday
      _selectedDay = "Monday";
    }
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (!mounted) return;
        if (doc.exists) {
          setState(() {
            _currentUser = UserModel.fromMap(doc.data()!, user.uid);
            _selectedBranch = widget.userBranch ?? _currentUser?.branch;
            _selectedSemester = widget.userSemester ?? _currentUser?.semester ?? 1;
            _selectedBatch = _currentUser?.batch;
            _isLoading = false;
          });
          _loadTimetable();
        }
      } catch (e) {
        if (!mounted) return;
        AppErrorHandler.showError(context, e);
        setState(() => _isLoading = false);
      }
    }
  }

  void _loadTimetable() {
    _timetableSub?.cancel();
    if (_selectedBranch == null || _currentUser?.collegeId == null) return;
    
    _timetableSub = _auth.getTimetable(
      _selectedBranch!, 
      _selectedSemester, 
      _selectedDay, 
      batch: null, // Always load the "All" / Common timetable document
      collegeId: _currentUser!.collegeId
    ).listen((doc) {
      if (!mounted) return;
      if (doc.exists) {
        List<dynamic> fetchedSlots = doc.get('slots') ?? [];
        setState(() {
          _slots = List<Map<String, dynamic>>.from(fetchedSlots);
          _slots.sort((a, b) => _timeToMinutes(a['startTime'] ?? a['time']).compareTo(_timeToMinutes(b['startTime'] ?? b['time'])));
        });
      } else {
        setState(() => _slots = []);
      }
    }, onError: (e) {
      if (!mounted) return;
      AppErrorHandler.showError(context, e);
    });
  }

  int _timeToMinutes(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return 0;
    try {
      final parts = timeStr.split(' ');
      if (parts.length < 2) return 0;
      final timeParts = parts[0].split(':');
      int hour = int.parse(timeParts[0]);
      int minute = int.parse(timeParts[1]);
      String ampm = parts[1].toUpperCase();
      
      if (ampm == 'PM' && hour != 12) hour += 12;
      if (ampm == 'AM' && hour == 12) hour = 0;
      
      return hour * 60 + minute;
    } catch (e) {
      return 0;
    }
  }

  Future<void> _selectTime(int index, bool isStartTime) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      if (!context.mounted) return;
      setState(() {
        if (isStartTime) {
          _slots[index]['startTime'] = picked.format(context);
        } else {
          _slots[index]['endTime'] = picked.format(context);
        }
      });
    }
  }

  void _showAddSubjectDialog() {
    if (widget.userRole == 'student') return;
    final controller = TextEditingController();
    String selectedType = "Theory"; // Default type
    
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Add New Subject"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller, 
                decoration: const InputDecoration(hintText: "Enter subject name", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: const InputDecoration(labelText: "Subject Type", border: OutlineInputBorder()),
                items: ["Theory", "Practical"].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                onChanged: (v) => setDialogState(() => selectedType = v!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("Cancel")),
            ElevatedButton(
              onPressed: () async {
                if (controller.text.isNotEmpty && _selectedBranch != null && _currentUser?.collegeId != null) {
                  LoadingOverlay.show(context);
                  try {
                    await _auth.addSubject(
                      _selectedBranch!,
                      _selectedSemester,
                      controller.text.trim(),
                      _currentUser!.collegeId!,
                      selectedType,
                    );
                    
                    if (!context.mounted) return;
                    if (dialogContext.mounted) Navigator.pop(dialogContext);
                    
                    // Use context.Mounted check again if needed, or use the context from State
                    if (!mounted) return;
                    AppErrorHandler.showSuccess(this.context, "Subject Added!");
                  } catch (e) {
                    if (!context.mounted) return;
                    AppErrorHandler.showError(context, e);
                  } finally {
                    if (context.mounted) LoadingOverlay.hide(context);
                  }
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
    if (_isLoading) return Scaffold(body: AppErrorHandler.buildLoadingWidget());
    
    bool isReadOnly = widget.userRole == 'student';
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(isReadOnly ? "My Timetable" : "Manage Timetable"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          if (!isReadOnly)
            IconButton(icon: const Icon(Icons.library_add_rounded), onPressed: _showAddSubjectDialog, tooltip: "Add Subject"),
        ],
      ),
      body: Column(
        children: [
          _buildTopFilters(),
          _buildDaySelector(),
          Expanded(child: _buildSlotsList(isReadOnly, theme)),
        ],
      ),
      floatingActionButton: isReadOnly ? null : FloatingActionButton.extended(
        onPressed: () => setState(() => _slots.add({
          'startTime': '09:00 AM', 
          'endTime': '10:00 AM',
          'batch': 'All',
          'subject': '', 
          'type': 'Subject', 
          'roomNumber': ''
        })),
        label: const Text("Add Lecture"),
        icon: const Icon(Icons.add_task_rounded),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      bottomNavigationBar: isReadOnly ? null : _buildSaveButton(),
    );
  }

  Widget _buildTopFilters() {
    bool isTeacher = widget.userRole == 'admin' || widget.userRole == 'teacher' || widget.userRole == 'coordinator';
    
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              if (isTeacher)
                Expanded(
                  child: _currentUser?.collegeId == null 
                    ? const SizedBox.shrink()
                    : StreamBuilder<QuerySnapshot>(
                        stream: _auth.getBranches(collegeId: _currentUser?.collegeId),
                        builder: (context, snap) {
                          if (snap.hasError) return Text("Error: ${snap.error}");
                          if (!snap.hasData) return const LinearProgressIndicator();
                          var branchDocs = snap.data!.docs;
                          return DropdownButtonFormField<String>(
                            value: _selectedBranch,
                            isExpanded: true,
                            decoration: const InputDecoration(labelText: "Branch", border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0)),
                            items: branchDocs.map((doc) {
                              final branchId = doc.get('branchId') ?? doc.id;
                              final displayName = branchId.toString().contains('_') ? branchId.toString().split('_').last : branchId;
                              return DropdownMenuItem(
                                value: doc.id, 
                                child: Text(displayName.toString(), overflow: TextOverflow.ellipsis)
                              );
                            }).toList(),
                            onChanged: (v) { setState(() { _selectedBranch = v; _selectedBatch = null; }); _loadTimetable(); },
                          );
                        }
                      ),
                )
              else
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Branch", style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text(
                        _selectedBranch != null && _selectedBranch!.contains('_') 
                            ? _selectedBranch!.split('_').last 
                            : (_selectedBranch ?? 'N/A'), 
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                      ),
                    ],
                  ),
                ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<int>(
                  value: _selectedSemester,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: "Semester", border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0)),
                  items: List.generate(8, (i) => i + 1).map((s) => DropdownMenuItem(value: s, child: Text("Sem $s"))).toList(),
                  onChanged: (v) { setState(() => _selectedSemester = v!); _loadTimetable(); },
                ),
              ),
            ],
          ),
          if (isTeacher) ...[
            const SizedBox(height: 8),
            _selectedBranch == null 
            ? const SizedBox.shrink()
            : StreamBuilder<QuerySnapshot>(
                stream: _auth.getBatchesByBranch(_selectedBranch!, collegeId: _currentUser?.collegeId),
                builder: (context, snap) {
                  if (!snap.hasData) return const SizedBox.shrink();
                  var batches = snap.data!.docs.map((d) => d.get('fullName').toString()).toList();
                  return DropdownButtonFormField<String>(
                    value: _selectedBatch,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: "Batch (Optional - Leave empty for common)", border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 0)),
                    items: [
                      const DropdownMenuItem<String>(value: null, child: Text("Common (All Batches)")),
                      ...batches.map((b) => DropdownMenuItem(value: b, child: Text(b))),
                    ],
                    onChanged: (v) { setState(() => _selectedBatch = v); _loadTimetable(); },
                  );
                }
              ),
          ] else if (_selectedBatch != null) ...[
             const SizedBox(height: 4),
             Row(
               children: [
                 const Text("Batch: ", style: TextStyle(fontSize: 12, color: Colors.grey)),
                 Text(_selectedBatch!, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
               ],
             ),
          ]
        ],
      ),
    );
  }

  Widget _buildDaySelector() {
    return Container(
      height: 55,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _days.length,
        itemBuilder: (context, index) {
          bool isSelected = _selectedDay == _days[index];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(_days[index]),
              selected: isSelected,
              selectedColor: Colors.indigo,
              labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
              onSelected: (val) { if (val) { setState(() => _selectedDay = _days[index]); _loadTimetable(); } },
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              showCheckmark: false,
            ),
          );
        },
      ),
    );
  }

  Widget _buildSlotsList(bool isReadOnly, ThemeData theme) {
    // Filter slots based on selected batch for students or for viewing preference
    List<Map<String, dynamic>> displayedSlots = _slots;
    if (_selectedBatch != null) {
      displayedSlots = _slots.where((slot) {
        final slotBatch = slot['batch'] ?? 'All';
        if (slotBatch == 'All') return true;
        if (slotBatch == _selectedBatch) return true;
        
        // Intelligent matching for "Batch A" against full names like "1CE1-A-2024"
        if (slotBatch.startsWith("Batch ")) {
          String letter = slotBatch.split(" ").last;
          return _selectedBatch!.contains("-$letter-");
        }
        return false;
      }).toList();
    }

    if (displayedSlots.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy_rounded, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text("No lectures scheduled for this selection.", style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: displayedSlots.length,
      itemBuilder: (context, index) {
        final slot = displayedSlots[index];
        bool isBreak = slot['type'] == 'Break';
        final originalIndex = _slots.indexOf(slot);

        if (isReadOnly) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  Container(
                    width: 6,
                    decoration: BoxDecoration(
                      color: isBreak ? Colors.orange : theme.colorScheme.primary,
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(slot['subject'] ?? 'Untitled', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(Icons.access_time_rounded, size: 14, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text(
                                "${slot['startTime'] ?? slot['time'] ?? 'N/A'} - ${slot['endTime'] ?? 'N/A'}", 
                                style: TextStyle(color: Colors.grey[600], fontSize: 13)
                              ),
                              if (slot['roomNumber'] != null && slot['roomNumber'].toString().isNotEmpty) ...[
                                const SizedBox(width: 12),
                                Icon(Icons.location_on_rounded, size: 14, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text("Room: ${slot['roomNumber']}", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                              ],
                            ],
                          ),
                          if (slot['batch'] != null && slot['batch'] != 'All')
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text("Batch: ${slot['batch']}", style: const TextStyle(fontSize: 12, color: Colors.indigo, fontWeight: FontWeight.bold)),
                            ),
                          if (!isBreak && slot['subject'] != null)
                             _buildTeacherInfo(slot['subject']),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: (isBreak ? Colors.orange : Colors.green).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      slot['type'] ?? 'Subject',
                      style: TextStyle(color: isBreak ? Colors.orange : Colors.green, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Teacher View: Editable Cards
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey[200]!)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectTime(originalIndex, true),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Start Time", style: TextStyle(fontSize: 10, color: Colors.grey)),
                              Text(slot['startTime'] ?? slot['time'] ?? 'Set Time', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectTime(originalIndex, false),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("End Time", style: TextStyle(fontSize: 10, color: Colors.grey)),
                              Text(slot['endTime'] ?? 'Set Time', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: _batchOptions.contains(slot['batch']) ? slot['batch'] : "All",
                      underline: const SizedBox(),
                      items: _batchOptions.map((b) => DropdownMenuItem(value: b, child: Text(b, style: const TextStyle(fontSize: 12)))).toList(),
                      onChanged: (v) => setState(() => _slots[originalIndex]['batch'] = v),
                    ),
                    IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20), onPressed: () => setState(() => _slots.removeAt(originalIndex))),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    DropdownButton<String>(
                      value: ["Subject", "Practical", "Break"].contains(slot['type']) ? slot['type'] : "Subject",
                      underline: const SizedBox(),
                      items: ["Subject", "Practical", "Break"].map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 12)))).toList(),
                      onChanged: (v) {
                        setState(() {
                          _slots[originalIndex]['type'] = v;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: isBreak 
                        ? TextField(
                            decoration: const InputDecoration(labelText: "Break Name", border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                            onChanged: (v) => _slots[originalIndex]['subject'] = v,
                            controller: TextEditingController.fromValue(TextEditingValue(text: slot['subject'] ?? '', selection: TextSelection.collapsed(offset: (slot['subject'] ?? '').length))),
                          )
                        : _currentUser?.collegeId == null
                            ? const SizedBox.shrink()
                            : StreamBuilder<QuerySnapshot>(
                                stream: _auth.getSubjects(_selectedBranch ?? '', _selectedSemester, collegeId: _currentUser?.collegeId),
                                builder: (context, snap) {
                                  if (snap.hasError) return const Text("Error");
                                  List<QueryDocumentSnapshot> subjectDocs = snap.hasData ? snap.data!.docs : [];
                                  List<String> subjects = subjectDocs.map((d) => d['name'] as String).toList();
                                  
                                  return DropdownButtonFormField<String>(
                                    value: subjects.contains(slot['subject']) ? slot['subject'] : null,
                                    isExpanded: true,
                                    decoration: const InputDecoration(labelText: "Subject", border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                                    items: subjects.map((s) => DropdownMenuItem(value: s, child: Text(s, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis))).toList(),
                                    onChanged: (v) {
                                      setState(() {
                                        _slots[originalIndex]['subject'] = v;
                                        try {
                                          var subDoc = subjectDocs.firstWhere((d) => d['name'] == v);
                                          String subType = subDoc['type'] ?? 'Theory';
                                          if (subType.toLowerCase().contains('practical')) {
                                            _slots[originalIndex]['type'] = 'Practical';
                                          } else {
                                            _slots[originalIndex]['type'] = 'Subject';
                                          }
                                        } catch (_) {}
                                      });
                                    },
                                  );
                                }
                              ),
                    ),
                    if (!isBreak) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          decoration: const InputDecoration(labelText: "Room", border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                          onChanged: (v) => _slots[originalIndex]['roomNumber'] = v,
                          controller: TextEditingController.fromValue(TextEditingValue(text: slot['roomNumber'] ?? '', selection: TextSelection.collapsed(offset: (slot['roomNumber'] ?? '').length))),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTeacherInfo(String subjectName) {
    if (_currentUser?.collegeId == null) return const SizedBox.shrink();
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('subjects')
          .where('name', isEqualTo: subjectName)
          .where('branch', isEqualTo: _selectedBranch)
          .where('semester', isEqualTo: _selectedSemester)
          .where('collegeId', isEqualTo: _currentUser?.collegeId)
          .limit(1)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) return const SizedBox.shrink();
        
        var subjectData = snap.data!.docs.first.data() as Map<String, dynamic>;
        List<dynamic> mainTeachers = subjectData['subjectTeachers'] ?? [];
        List<dynamic> assistantTeachers = subjectData['assistantSubjectTeachers'] ?? [];
        String type = subjectData['type'] ?? 'General';
        bool isPractical = type.toLowerCase().contains('practical');
        bool isTheory = !isPractical;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // If Theory, show Main Teacher
            if (isTheory && mainTeachers.isNotEmpty)
              _buildTeacherNamesRow("Subject Teacher:", mainTeachers),
            // If Practical, show Assistant Teachers
            if (isPractical && assistantTeachers.isNotEmpty)
              _buildTeacherNamesRow("Assistant Teachers:", assistantTeachers),
          ],
        );
      },
    );
  }

  Widget _buildTeacherNamesRow(String label, List<dynamic> uids) {
    return FutureBuilder<List<String>>(
      future: _getTeacherNames(uids),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("$label ", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.indigo)),
              Expanded(
                child: Text(snap.data!.join(", "), style: TextStyle(fontSize: 12, color: Colors.grey[700])),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<List<String>> _getTeacherNames(List<dynamic> uids) async {
    List<String> names = [];
    for (var uid in uids) {
      var doc = await FirebaseFirestore.instance.collection('users').doc(uid.toString()).get();
      if (doc.exists) {
        var user = UserModel.fromMap(doc.data()!, doc.id);
        names.add(user.fullName);
      }
    }
    return names;
  }

  Widget _buildSaveButton() {
    bool isTeacher = widget.userRole == 'admin' || widget.userRole == 'teacher' || widget.userRole == 'coordinator';
    if (!isTeacher) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: (_isLoading || _currentUser?.collegeId == null) ? null : () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text("Delete Timetable?"),
                    content: Text("Are you sure you want to delete the entire timetable for $_selectedDay?"),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("Cancel")),
                      TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
                    ],
                  ),
                );

                if (confirm == true) {
                  if (!mounted) return;
                  LoadingOverlay.show(context);
                  try {
                    await _auth.deleteTimetable(
                      _selectedBranch!, 
                      _selectedSemester, 
                      _selectedDay, 
                      _currentUser!.collegeId!,
                      batch: null,
                    );
                    if (!mounted) return;
                    AppErrorHandler.showSuccess(context, "Timetable Deleted");
                  } catch (e) {
                    if (!mounted) return;
                    AppErrorHandler.showError(context, e);
                  } finally {
                    if (mounted) LoadingOverlay.hide(context);
                  }
                }
              },
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              label: const Text("DELETE ALL", style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              onPressed: (_isLoading || _currentUser?.collegeId == null) ? null : () async {
                if (!mounted) return;
                LoadingOverlay.show(context);
                try {
                  await _auth.setTimetable(
                    _selectedBranch!, 
                    _selectedSemester, 
                    _selectedDay, 
                    _slots, 
                    _currentUser!.collegeId!,
                    batch: null, // Always save to the Common document
                  );
                  if (!mounted) return;
                  AppErrorHandler.showSuccess(context, "Timetable Saved Successfully!");
                } catch (e) {
                  if (!mounted) return;
                  AppErrorHandler.showError(context, e);
                } finally {
                  if (mounted) LoadingOverlay.hide(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading 
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                : const Text("SAVE CHANGES", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}
