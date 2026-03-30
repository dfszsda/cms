import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
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
  int _selectedSemester = 1;
  String _selectedDay = "Monday";
  List<Map<String, dynamic>> _slots = [];
  bool _isLoading = true;

  final List<String> _days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          _currentUser = UserModel.fromMap(doc.data()!, user.uid);
          _selectedBranch = widget.userBranch ?? _currentUser?.branch;
          _selectedSemester = widget.userSemester ?? _currentUser?.semester ?? 1;
          _isLoading = false;
        });
        _loadTimetable();
      }
    }
  }

  void _loadTimetable() {
    if (_selectedBranch == null || _currentUser?.collegeId == null) return;
    _auth.getTimetable(_selectedBranch!, _selectedSemester, _selectedDay, collegeId: _currentUser!.collegeId).first.then((doc) {
      if (doc.exists) {
        List<dynamic> fetchedSlots = doc.get('slots') ?? [];
        setState(() {
          _slots = List<Map<String, dynamic>>.from(fetchedSlots);
          _slots.sort((a, b) => (a['time'] ?? '').compareTo(b['time'] ?? ''));
        });
      } else {
        setState(() => _slots = []);
      }
    });
  }

  Future<void> _selectTime(int index) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (picked != null) {
      if (!mounted) return;
      setState(() {
        _slots[index]['time'] = picked.format(context);
      });
    }
  }

  void _showAddSubjectDialog() {
    if (widget.userRole == 'student') return;
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Add New Subject"),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: "Enter subject name")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty && _selectedBranch != null && _currentUser?.collegeId != null) {
                await _auth.addSubject(_selectedBranch!, _selectedSemester, controller.text.trim(), _currentUser!.collegeId!);
                if (dialogContext.mounted) Navigator.pop(dialogContext);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Subject Added!")));
                }
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    
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
        onPressed: () => setState(() => _slots.add({'time': '09:00 AM', 'subject': '', 'type': 'Subject'})),
        label: const Text("Add Lecture"),
        icon: const Icon(Icons.add_task_rounded),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      bottomNavigationBar: isReadOnly ? null : _buildSaveButton(),
    );
  }

  Widget _buildTopFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          if (widget.userRole == 'admin' || widget.userRole == 'teacher' || widget.userRole == 'coordinator')
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _auth.getBranches(collegeId: _currentUser?.collegeId),
                builder: (context, snap) {
                  if (!snap.hasData) return const LinearProgressIndicator();
                  var branches = snap.data!.docs.map((d) => d.id).toList();
                  return DropdownButtonFormField<String>(
                    value: _selectedBranch,
                    decoration: const InputDecoration(labelText: "Branch", border: OutlineInputBorder()),
                    items: branches.map((b) => DropdownMenuItem(value: b, child: Text(b))).toList(),
                    onChanged: (v) { setState(() => _selectedBranch = v); _loadTimetable(); },
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
                  Text(_selectedBranch ?? 'N/A', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ),
          const SizedBox(width: 16),
          Expanded(
            child: DropdownButtonFormField<int>(
              value: _selectedSemester,
              decoration: const InputDecoration(labelText: "Semester", border: OutlineInputBorder()),
              items: List.generate(8, (i) => i + 1).map((s) => DropdownMenuItem(value: s, child: Text("Sem $s"))).toList(),
              onChanged: (v) { setState(() => _selectedSemester = v!); _loadTimetable(); },
            ),
          ),
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
    if (_slots.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy_rounded, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text("No lectures scheduled for this day.", style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _slots.length,
      itemBuilder: (context, index) {
        final slot = _slots[index];
        bool isBreak = slot['type'] == 'Break';

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
                              Text(slot['time'] ?? 'N/A', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                            ],
                          ),
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
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectTime(index),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            children: [
                              const Icon(Icons.access_time_rounded, size: 18, color: Colors.indigo),
                              const SizedBox(width: 8),
                              Text(slot['time'] ?? 'Set Time', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    DropdownButton<String>(
                      value: slot['type'],
                      underline: const SizedBox(),
                      items: ["Subject", "Break"].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                      onChanged: (v) => setState(() => _slots[index]['type'] = v),
                    ),
                    IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: () => setState(() => _slots.removeAt(index))),
                  ],
                ),
                const SizedBox(height: 12),
                isBreak 
                  ? TextField(
                      decoration: const InputDecoration(labelText: "Break Name (e.g. Lunch)", border: OutlineInputBorder()),
                      onChanged: (v) => _slots[index]['subject'] = v,
                      controller: TextEditingController.fromValue(TextEditingValue(text: slot['subject'] ?? '', selection: TextSelection.collapsed(offset: (slot['subject'] ?? '').length))),
                    )
                  : StreamBuilder<QuerySnapshot>(
                      stream: _auth.getSubjects(_selectedBranch ?? '', _selectedSemester, collegeId: _currentUser?.collegeId),
                      builder: (context, snap) {
                        List<String> subjects = snap.hasData ? snap.data!.docs.map((d) => d['name'] as String).toList() : [];
                        return DropdownButtonFormField<String>(
                          value: subjects.contains(slot['subject']) ? slot['subject'] : null,
                          decoration: const InputDecoration(labelText: "Select Subject", border: OutlineInputBorder()),
                          items: subjects.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                          onChanged: (v) => _slots[index]['subject'] = v,
                        );
                      }
                    ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSaveButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
      child: ElevatedButton(
        onPressed: (_isLoading || _currentUser?.collegeId == null) ? null : () async {
          setState(() => _isLoading = true);
          await _auth.setTimetable(_selectedBranch!, _selectedSemester, _selectedDay, _slots, _currentUser!.collegeId!);
          if (mounted) {
            setState(() => _isLoading = false);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Timetable Updated Successfully!")));
          }
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _isLoading 
          ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
          : const Text("SAVE CHANGES", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }
}
