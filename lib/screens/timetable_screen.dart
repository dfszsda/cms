import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class TimetableScreen extends StatefulWidget {
  final String? userRole; 
  final String? userBranch;

  const TimetableScreen({super.key, this.userRole, this.userBranch});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  final _auth = AuthService();
  String? _selectedBranch;
  int _selectedSemester = 1;
  String _selectedDay = "Monday";
  List<Map<String, dynamic>> _slots = [];
  bool _isLoading = false;

  final List<String> _days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"];

  @override
  void initState() {
    super.initState();
    _selectedBranch = widget.userBranch;
    _loadTimetable();
  }

  void _loadTimetable() {
    if (_selectedBranch == null) return;
    _auth.getTimetable(_selectedBranch!, _selectedSemester, _selectedDay).first.then((doc) {
      if (doc.exists) {
        setState(() => _slots = List<Map<String, dynamic>>.from(doc.get('slots') ?? []));
      } else {
        setState(() => _slots = []);
      }
    });
  }

  void _showAddSubjectDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add New Subject"),
        content: TextField(controller: controller, decoration: const InputDecoration(hintText: "Enter subject name")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (controller.text.isNotEmpty && _selectedBranch != null) {
                await _auth.addSubject(_selectedBranch!, _selectedSemester, controller.text.trim());
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Subject Added!")));
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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Timetable"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.menu_book), onPressed: _showAddSubjectDialog, tooltip: "Add Subject"),
        ],
      ),
      body: Column(
        children: [
          _buildTopFilters(),
          _buildDaySelector(),
          Expanded(child: _buildSlotsList()),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => setState(() => _slots.add({'time': '09:00', 'subject': '', 'type': 'Subject'})),
        label: const Text("Add Slot"),
        icon: const Icon(Icons.add),
        backgroundColor: Colors.indigo,
      ),
      bottomNavigationBar: _buildSaveButton(),
    );
  }

  Widget _buildTopFilters() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.indigo.withOpacity(0.05),
      child: Row(
        children: [
          if (widget.userRole == 'admin')
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _auth.getBranches(),
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
            Expanded(child: Text("Branch: ${_selectedBranch ?? 'N/A'}", style: const TextStyle(fontWeight: FontWeight.bold))),
          const SizedBox(width: 10),
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
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _days.length,
        itemBuilder: (context, index) {
          bool isSelected = _selectedDay == _days[index];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 5),
            child: ChoiceChip(
              label: Text(_days[index]),
              selected: isSelected,
              selectedColor: Colors.indigo,
              labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
              onSelected: (val) { if (val) { setState(() => _selectedDay = _days[index]); _loadTimetable(); } },
            ),
          );
        },
      ),
    );
  }

  Widget _buildSlotsList() {
    if (_slots.isEmpty) return const Center(child: Text("No timetable set for this day."));
    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: _slots.length,
      itemBuilder: (context, index) {
        return Card(
          elevation: 4,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 20, color: Colors.indigo),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(hintText: "Time (e.g. 10:00 - 11:00)", border: InputBorder.none),
                        controller: TextEditingController(text: _slots[index]['time']),
                        onChanged: (v) => _slots[index]['time'] = v,
                      ),
                    ),
                    DropdownButton<String>(
                      value: _slots[index]['type'],
                      items: ["Subject", "Break"].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                      onChanged: (v) => setState(() => _slots[index]['type'] = v),
                    ),
                    IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => setState(() => _slots.removeAt(index))),
                  ],
                ),
                const Divider(),
                _slots[index]['type'] == "Break" 
                  ? TextField(
                      decoration: const InputDecoration(labelText: "Break Name", border: OutlineInputBorder()),
                      onChanged: (v) => _slots[index]['subject'] = v,
                    )
                  : StreamBuilder<QuerySnapshot>(
                      stream: _auth.getSubjects(_selectedBranch ?? '', _selectedSemester),
                      builder: (context, snap) {
                        List<String> subjects = snap.hasData ? snap.data!.docs.map((d) => d['name'] as String).toList() : [];
                        return DropdownButtonFormField<String>(
                          value: subjects.contains(_slots[index]['subject']) ? _slots[index]['subject'] : null,
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
      padding: const EdgeInsets.all(12),
      child: ElevatedButton(
        onPressed: _isLoading ? null : () async {
          setState(() => _isLoading = true);
          await _auth.setTimetable(_selectedBranch!, _selectedSemester, _selectedDay, _slots);
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Timetable Saved!")));
        },
        style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(50)),
        child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("SAVE TIMETABLE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }
}
