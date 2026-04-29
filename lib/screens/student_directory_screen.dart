import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cms/screens/student_detail_screen.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/error_handler.dart';

class StudentDirectoryScreen extends StatefulWidget {
  final UserModel viewer;
  const StudentDirectoryScreen({super.key, required this.viewer});

  @override
  State<StudentDirectoryScreen> createState() => _StudentDirectoryScreenState();
}

class _StudentDirectoryScreenState extends State<StudentDirectoryScreen> {
  final _auth = AuthService();
  
  String _filterType = "Batch"; // Options: Batch, Semester, Coordinator
  dynamic _selectedFilterValue; 
  String _studentSearchQuery = "";
  final TextEditingController _studentSearchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Student Directory"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildFilterSection(),
          _buildSearchField(),
          Expanded(
            child: _selectedFilterValue == null
                ? const Center(child: Text("Please select a filter to view students"))
                : _buildStudentList(),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.indigo,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Menu 1: Filter Type
          DropdownButtonFormField<String>(
            initialValue: _filterType,
            dropdownColor: Colors.white,
            style: const TextStyle(color: Colors.black87),
            decoration: _getInputDecoration("Select Filter Type"),
            items: ["Batch", "Semester", "Coordinator"].map((type) {
              return DropdownMenuItem(value: type, child: Text(type));
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                setState(() {
                  _filterType = val;
                  _selectedFilterValue = null;
                });
              }
            },
          ),
          const SizedBox(height: 12),
          // Menu 2: Selection based on Menu 1
          _buildMenu2(),
        ],
      ),
    );
  }

  Widget _buildMenu2() {
    if (_filterType == "Batch") {
      return StreamBuilder<QuerySnapshot>(
        stream: _auth.getAllBatches(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return AppErrorHandler.buildErrorWidget(snapshot.error, () => setState(() {}));
          if (!snapshot.hasData) return const LinearProgressIndicator();
          final batches = snapshot.data!.docs;
          return _buildSearchableDropdown<DocumentSnapshot>(
            hint: "Select Batch",
            items: batches,
            itemLabel: (batch) {
              final fullName = batch['fullName'] ?? '';
              if (fullName.contains('-')) {
                final parts = fullName.split('-');
                if (parts.length >= 2) return parts[1];
              }
              return fullName;
            },
            selectedValue: _selectedFilterValue is DocumentSnapshot ? _selectedFilterValue : null,
            onChanged: (val) => setState(() => _selectedFilterValue = val),
          );
        },
      );
    } else if (_filterType == "Semester") {
      return DropdownButtonFormField<int>(
        initialValue: _selectedFilterValue is int ? _selectedFilterValue : null,
        dropdownColor: Colors.white,
        style: const TextStyle(color: Colors.black87),
        decoration: _getInputDecoration("Select Semester"),
        items: List.generate(8, (index) => index + 1).map((sem) {
          return DropdownMenuItem(value: sem, child: Text("Semester $sem"));
        }).toList(),
        onChanged: (val) => setState(() => _selectedFilterValue = val),
      );
    } else {
      // Coordinator
      return StreamBuilder<List<UserModel>>(
        stream: _auth.getTeachers(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return AppErrorHandler.buildErrorWidget(snapshot.error, () => setState(() {}));
          if (!snapshot.hasData) return const LinearProgressIndicator();
          final teachers = snapshot.data!;
          return _buildSearchableDropdown<UserModel>(
            hint: "Select Coordinator",
            items: teachers,
            itemLabel: (teacher) => teacher.fullName,
            selectedValue: _selectedFilterValue is UserModel ? _selectedFilterValue : null,
            onChanged: (val) => setState(() => _selectedFilterValue = val),
          );
        },
      );
    }
  }

  Widget _buildSearchableDropdown<T>({
    required String hint,
    required List<T> items,
    required String Function(T) itemLabel,
    required T? selectedValue,
    required ValueChanged<T?> onChanged,
  }) {
    return InkWell(
      onTap: () => _showSearchDialog(hint, items, itemLabel, onChanged),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white38),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              selectedValue != null ? itemLabel(selectedValue) : hint,
              style: TextStyle(color: selectedValue != null ? Colors.black87 : Colors.grey[600]),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _showSearchDialog<T>(
    String title,
    List<T> items,
    String Function(T) itemLabel,
    ValueChanged<T?> onChanged,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        List<T> filteredItems = List.from(items);
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(title),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        hintText: "Search...",
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (query) {
                        setDialogState(() {
                          filteredItems = items
                              .where((item) => itemLabel(item).toLowerCase().contains(query.toLowerCase()))
                              .toList();
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    Flexible(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: filteredItems.length,
                        itemBuilder: (context, index) {
                          final item = filteredItems[index];
                          return ListTile(
                            title: Text(itemLabel(item)),
                            onTap: () {
                              onChanged(item);
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        controller: _studentSearchController,
        decoration: InputDecoration(
          hintText: "Search students by name...",
          prefixIcon: const Icon(Icons.search, color: Colors.indigo),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
        onChanged: (val) => setState(() => _studentSearchQuery = val),
      ),
    );
  }

  Widget _buildStudentList() {
    Stream<List<UserModel>> stream;
    if (_filterType == "Batch" && _selectedFilterValue is DocumentSnapshot) {
      stream = _auth.getStudentsByBatch(_selectedFilterValue['fullName']);
    } else if (_filterType == "Semester" && _selectedFilterValue is int) {
      stream = _auth.getStudentsBySemester(_selectedFilterValue);
    } else if (_filterType == "Coordinator" && _selectedFilterValue is UserModel) {
      stream = _auth.getStudentsByCoordinator(_selectedFilterValue.uid);
    } else {
      return const SizedBox();
    }

    return StreamBuilder<List<UserModel>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) return AppErrorHandler.buildErrorWidget(snapshot.error, () => setState(() {}));
        if (snapshot.connectionState == ConnectionState.waiting) return AppErrorHandler.buildLoadingWidget();
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text("No students found."));

        final students = snapshot.data!.where((s) {
          final query = _studentSearchQuery.toLowerCase();
          return s.fullName.toLowerCase().contains(query) || s.email.toLowerCase().contains(query);
        }).toList();

        if (students.isEmpty) return const Center(child: Text("No matching students found."));

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: students.length,
          itemBuilder: (context, index) {
            final student = students[index];
            return Card(
              elevation: 0,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.indigo.withValues(alpha: 0.1),
                  backgroundImage: student.profilePic != null ? NetworkImage(student.profilePic!) : null,
                  child: student.profilePic == null ? const Icon(Icons.person, color: Colors.indigo) : null,
                ),
                title: Text(student.fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Batch: ${student.batch ?? 'N/A'}", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                    Text("Branch: ${student.branchName}", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                    Text("Sem: ${student.semester}", style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                  ],
                ),
                trailing: const Icon(Icons.chevron_right, color: Colors.indigo),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => StudentDetailScreen(
                      student: student,
                      viewer: widget.viewer,
                      batchName: student.batch ?? '',
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  InputDecoration _getInputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    );
  }
}
