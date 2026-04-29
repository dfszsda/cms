// ignore_for_file: unnecessary_underscores

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/error_handler.dart';
import 'student_detail_screen.dart';

class StudentsListScreen extends StatefulWidget {
  final UserModel viewer;
  const StudentsListScreen({super.key, required this.viewer});

  @override
  State<StudentsListScreen> createState() => _StudentsListScreenState();
}

class _StudentsListScreenState extends State<StudentsListScreen> {
  final AuthService _auth = AuthService();
  final TextEditingController _studentSearchController = TextEditingController();
  String _studentSearchQuery = "";
  String _filterType = "Batch";
  dynamic _selectedFilterValue;

  @override
  void initState() {
    super.initState();
    // For students, default to their own semester
    if (widget.viewer.role == 'student') {
      _filterType = "Semester";
      _selectedFilterValue = widget.viewer.semester;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Students Directory", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildFilterHeader(theme),
          _buildSearchField(theme),
          Expanded(
            child: _selectedFilterValue == null ? _buildEmptyState() : _buildStudentList(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterHeader(ThemeData theme) {
    // Students can only see the Semester filter (primarily their own)
    final List<String> filterOptions = widget.viewer.role == 'student' 
        ? ["Semester"] 
        : ["Batch", "Semester", "Coordinator"];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: Column(
        children: [
          if (filterOptions.length > 1) 
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: filterOptions.map((type) {
                  bool isSelected = _filterType == type;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: isSelected,
                      label: Text(type),
                      onSelected: (val) {
                        setState(() {
                          _filterType = type;
                          _selectedFilterValue = null;
                        });
                      },
                      selectedColor: Colors.white,
                      checkmarkColor: theme.colorScheme.primary,
                      labelStyle: TextStyle(
                        color: isSelected ? theme.colorScheme.primary : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                    ),
                  );
                }).toList(),
              ),
            ),
          const SizedBox(height: 16),
          _buildFilterSelector(theme),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown<T>({
    required String label,
    required T? value,
    required List<T> items,
    required String Function(T) itemLabel,
    required ValueChanged<T?> onChanged,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white24),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              dropdownColor: theme.colorScheme.primary,
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
              hint: Text("Select $label", style: const TextStyle(color: Colors.white60)),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              items: items.map((T item) {
                return DropdownMenuItem<T>(
                  value: item,
                  child: Text(itemLabel(item)),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterSelector(ThemeData theme) {
    if (_filterType == "Batch") {
      return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('batches').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text("Error: ${AppErrorHandler.getErrorMessage(snapshot.error)}", style: const TextStyle(color: Colors.white70));
          }
          if (!snapshot.hasData) return const Center(child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)));
          final batches = snapshot.data!.docs;
          return _buildSearchableDropdownField(
            label: "Select Batch",
            hint: "Choose Batch",
            value: _selectedFilterValue is DocumentSnapshot ? _selectedFilterValue['fullName'] : null,
            onTap: () => _showSearchDialog("Select Batch", batches, (batch) => batch['fullName'], (val) => setState(() => _selectedFilterValue = val)),
          );
        },
      );
    } else if (_filterType == "Semester") {
      return _buildFilterDropdown<int>(
        label: "Select Semester",
        value: _selectedFilterValue is int ? _selectedFilterValue : null,
        items: List.generate(8, (index) => index + 1),
        itemLabel: (sem) => "Semester $sem",
        onChanged: (val) => setState(() => _selectedFilterValue = val),
      );
    } else {
      // Coordinator
      return StreamBuilder<List<UserModel>>(
        stream: _auth.getTeachers(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Text("Error: ${AppErrorHandler.getErrorMessage(snapshot.error)}", style: const TextStyle(color: Colors.white70));
          }
          if (!snapshot.hasData) return const Center(child: SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)));
          final teachers = snapshot.data!;
          return _buildSearchableDropdownField(
            label: "Select Coordinator",
            hint: "Choose Teacher",
            value: _selectedFilterValue is UserModel ? _selectedFilterValue.fullName : null,
            onTap: () => _showSearchDialog("Select Coordinator", teachers, (teacher) => teacher.fullName, (val) => setState(() => _selectedFilterValue = val)),
          );
        },
      );
    }
  }

  Widget _buildSearchableDropdownField({required String label, required String hint, required String? value, required VoidCallback onTap}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white24),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    value ?? hint,
                    style: TextStyle(
                      color: value != null ? Colors.white : Colors.white60,
                      fontWeight: FontWeight.w600,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                const Icon(Icons.search, color: Colors.white, size: 18),
              ],
            ),
          ),
        ),
      ],
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        hintText: "Search...",
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      ),
                      onChanged: (query) {
                        setDialogState(() {
                          filteredItems = items
                              .where((item) => itemLabel(item).toLowerCase().contains(query.toLowerCase()))
                              .toList();
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    Flexible(
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: filteredItems.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
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

  Widget _buildSearchField(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: TextField(
          controller: _studentSearchController,
          decoration: InputDecoration(
            hintText: "Search students by name...",
            prefixIcon: Icon(Icons.person_search_rounded, color: theme.colorScheme.primary),
            filled: true,
            fillColor: Colors.white,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
          ),
          onChanged: (val) => setState(() => _studentSearchQuery = val),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.filter_list_rounded, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            "Select a filter to view students",
            style: TextStyle(color: Colors.grey[600], fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentList(ThemeData theme) {
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
        if (snapshot.hasError) {
          return AppErrorHandler.buildErrorWidget(snapshot.error, () => setState(() {}));
        }
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          return AppErrorHandler.buildLoadingWidget();
        }
        
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.people_outline_rounded, size: 80, color: Colors.grey[300]),
                const SizedBox(height: 16),
                const Text("No students found in this category", style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        final students = snapshot.data!.where((s) {
          final query = _studentSearchQuery.toLowerCase();
          return s.fullName.toLowerCase().contains(query) || s.email.toLowerCase().contains(query);
        }).toList();

        if (students.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off_rounded, size: 80, color: Colors.grey[300]),
                const SizedBox(height: 16),
                const Text("No matching students found", style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: students.length,
          itemBuilder: (context, index) {
            final student = students[index];
            return _StudentCard(
              student: student,
              theme: theme,
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
            );
          },
        );
      },
    );
  }
}

class _StudentCard extends StatelessWidget {
  final UserModel student;
  final ThemeData theme;
  final VoidCallback onTap;

  const _StudentCard({required this.student, required this.theme, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2), width: 2),
                  ),
                  child: CircleAvatar(
                    radius: 30,
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                    backgroundImage: student.profilePic != null ? NetworkImage(student.profilePic!) : null,
                    child: student.profilePic == null 
                      ? Icon(Icons.person, color: theme.colorScheme.primary, size: 30) 
                      : null,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student.fullName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _InfoChip(
                            icon: Icons.school_outlined,
                            label: student.batch ?? 'N/A',
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 8),
                          _InfoChip(
                            icon: Icons.calendar_today_outlined,
                            label: "Sem ${student.semester ?? '?'}",
                            color: Colors.orange,
                          ),
                          const SizedBox(width: 8),
                          _InfoChip(
                            icon: Icons.account_tree_outlined,
                            label: student.branchName,
                            color: Colors.teal,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
