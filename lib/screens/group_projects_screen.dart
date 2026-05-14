import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/todo_model.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/error_handler.dart';

class GroupProjectsScreen extends StatefulWidget {
  final UserModel? user;
  const GroupProjectsScreen({super.key, this.user});

  @override
  State<GroupProjectsScreen> createState() => _GroupProjectsScreenState();
}

class _GroupProjectsScreenState extends State<GroupProjectsScreen> {
  final _auth = AuthService();
  
  UserModel? _internalUser;

  @override
  void initState() {
    super.initState();
    if (widget.user == null) {
      _loadUserData();
    } else {
      _internalUser = widget.user;
    }
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) {
          setState(() {
            _internalUser = UserModel.fromMap(doc.data()!, user.uid);
          });
        }
      }
    } catch (e) {
      if (context.mounted) AppErrorHandler.showError(context, e);
    }
  }

  void _showCreateProjectSheet() {
    if (_internalUser == null) return;
    
    int selectedSem = _internalUser!.semester ?? 1;
    List<UserModel> selectedStudents = [];
    UserModel? selectedLeader;
    final projectNameCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Create New Project Group", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(
                controller: projectNameCtrl,
                decoration: const InputDecoration(labelText: "Project Name", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: selectedSem,
                decoration: const InputDecoration(labelText: "Semester", border: OutlineInputBorder()),
                items: List.generate(8, (index) => index + 1)
                    .map((sem) => DropdownMenuItem(value: sem, child: Text("Semester $sem")))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setModalState(() {
                      selectedSem = val;
                      selectedStudents = [];
                      selectedLeader = null;
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              const Text("Select Members:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              SizedBox(
                height: 200,
                child: StreamBuilder<List<UserModel>>(
                  stream: _auth.getStudentsForAttendance(_internalUser!.branch ?? '', selectedSem, _internalUser!.collegeId ?? ''),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) return AppErrorHandler.buildErrorWidget(snapshot.error, () => setState(() {}));
                    if (!snapshot.hasData) return AppErrorHandler.buildLoadingWidget();
                    final students = snapshot.data!;
                    if (students.isEmpty) return const Center(child: Text("No students found in this semester"));
                    
                    return ListView.builder(
                      itemCount: students.length,
                      itemBuilder: (context, index) {
                        final student = students[index];
                        final isSelected = selectedStudents.any((s) => s.uid == student.uid);
                        return CheckboxListTile(
                          title: Text(student.fullName),
                          subtitle: Text(student.email),
                          value: isSelected,
                          onChanged: (val) {
                            setModalState(() {
                              if (val == true) {
                                selectedStudents.add(student);
                              } else {
                                selectedStudents.removeWhere((s) => s.uid == student.uid);
                                if (selectedLeader?.uid == student.uid) selectedLeader = null;
                              }
                            });
                          },
                        );
                      },
                    );
                  },
                ),
              ),
              if (selectedStudents.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text("Select Leader:", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<UserModel>(
                  initialValue: selectedLeader,
                  decoration: const InputDecoration(labelText: "Leader", border: OutlineInputBorder()),
                  items: selectedStudents.map((s) => DropdownMenuItem(value: s, child: Text(s.fullName))).toList(),
                  onChanged: (val) => setModalState(() => selectedLeader = val),
                ),
              ],
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  if (projectNameCtrl.text.isEmpty || selectedStudents.isEmpty || selectedLeader == null) {
                    AppErrorHandler.showError(context, "Please fill all fields and select leader");
                    return;
                  }

                  LoadingOverlay.show(context);
                  try {
                    final project = GroupProject(
                      id: '',
                      name: projectNameCtrl.text.trim(),
                      leaderId: selectedLeader!.uid,
                      memberIds: selectedStudents.map((s) => s.uid).toList(),
                      teacherId: _internalUser!.uid,
                      semester: selectedSem,
                      branch: _internalUser!.branch ?? '',
                      createdAt: DateTime.now(),
                    );

                    await FirebaseFirestore.instance.collection('projects').add(project.toMap());
                    
                    if (context.mounted) {
                      Navigator.pop(context);
                      AppErrorHandler.showSuccess(context, "Group created successfully!");
                    }
                  } catch (e) {
                    if (context.mounted) {
                      AppErrorHandler.showError(context, e);
                    }
                  } finally {
                    if (context.mounted) LoadingOverlay.hide(context);
                  }
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text("CREATE PROJECT GROUP"),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_internalUser == null) return const Center(child: CircularProgressIndicator());

    final isTeacher = _internalUser!.role == 'teacher';

    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: isTeacher 
          ? FirebaseFirestore.instance.collection('projects').where('teacherId', isEqualTo: _internalUser!.uid).snapshots()
          : FirebaseFirestore.instance.collection('projects').where('memberIds', arrayContains: _internalUser!.uid).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return AppErrorHandler.buildErrorWidget(snapshot.error, () => setState(() {}));
          if (snapshot.connectionState == ConnectionState.waiting) return AppErrorHandler.buildLoadingWidget();
          
          final projects = snapshot.data!.docs.map((doc) => 
            GroupProject.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();

          if (projects.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.group_off, size: 60, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(isTeacher ? "You haven't created any groups yet." : "No project groups assigned to you.", style: const TextStyle(color: Colors.grey)),
                  if (isTeacher) ...[
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _showCreateProjectSheet,
                      icon: const Icon(Icons.group_add),
                      label: const Text("Create a Group"),
                    )
                  ]
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: projects.length,
            itemBuilder: (context, index) {
              final project = projects[index];
              final isLeader = project.leaderId == _internalUser?.uid;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.blue,
                    child: Icon(Icons.groups, color: Colors.white),
                  ),
                  title: Text(project.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(isTeacher ? "Semester ${project.semester}" : (isLeader ? "Leader" : "Member")),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (_) => ProjectDetailsScreen(project: project, currentUser: _internalUser!))
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: isTeacher ? FloatingActionButton.extended(
        onPressed: _showCreateProjectSheet,
        icon: const Icon(Icons.add),
        label: const Text("New Group"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ) : null,
    );
  }
}

class ProjectDetailsScreen extends StatefulWidget {
  final GroupProject project;
  final UserModel currentUser;
  const ProjectDetailsScreen({super.key, required this.project, required this.currentUser});

  @override
  State<ProjectDetailsScreen> createState() => _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends State<ProjectDetailsScreen> {
  final _taskTitleCtrl = TextEditingController();
  final _taskDescCtrl = TextEditingController();
  DateTime? _selectedDeadline;
  String? _selectedMemberId;
  String? _selectedMemberName;

  Future<void> _pickDeadline() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      if (!context.mounted) return;
      final time = await showTimePicker(context: context, initialTime: TimeOfDay.now());
      if (time != null) {
        setState(() {
          _selectedDeadline = DateTime(date.year, date.month, date.day, time.hour, time.minute);
        });
      }
    }
  }

  Future<void> _assignTask() async {
    if (_taskTitleCtrl.text.isEmpty || _selectedDeadline == null || _selectedMemberId == null) {
      AppErrorHandler.showError(context, "Please fill all details and select a member");
      return;
    }

    LoadingOverlay.show(context);
    try {
      final task = GroupTask(
        id: '',
        projectId: widget.project.id,
        title: _taskTitleCtrl.text.trim(),
        description: _taskDescCtrl.text.trim(),
        assignedTo: _selectedMemberId!,
        assignedToName: _selectedMemberName!,
        deadline: _selectedDeadline!,
        createdAt: DateTime.now(),
      );

      await FirebaseFirestore.instance.collection('group_tasks').add(task.toMap());
      
      if (context.mounted) {
        _taskTitleCtrl.clear();
        _taskDescCtrl.clear();
        setState(() {
          _selectedDeadline = null;
          _selectedMemberId = null;
          _selectedMemberName = null;
        });
        Navigator.pop(context);
        AppErrorHandler.showSuccess(context, "Task assigned successfully!");
      }
    } catch (e) {
      if (context.mounted) {
        AppErrorHandler.showError(context, e);
      }
    } finally {
      if (context.mounted) LoadingOverlay.hide(context);
    }
  }

  void _showAssignTaskSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20, right: 20, top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Assign New Task", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              TextField(
                controller: _taskTitleCtrl,
                decoration: const InputDecoration(labelText: "Task Title", border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .where(FieldPath.documentId, whereIn: widget.project.memberIds)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) return Text("Error loading members");
                  if (!snapshot.hasData) return const LinearProgressIndicator();
                  final members = snapshot.data!.docs;
                  return DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: "Assign To", border: OutlineInputBorder()),
                    initialValue: _selectedMemberId,
                    items: members.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return DropdownMenuItem(
                        value: doc.id,
                        child: Text(data['fullName'] ?? 'User'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      final memberDoc = members.firstWhere((doc) => doc.id == val);
                      final data = memberDoc.data() as Map<String, dynamic>;
                      setModalState(() {
                        _selectedMemberId = val;
                        _selectedMemberName = data['fullName'];
                      });
                      setState(() {
                        _selectedMemberId = val;
                        _selectedMemberName = data['fullName'];
                      });
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: Text(_selectedDeadline == null ? "Select Deadline" : DateFormat('MMM d, hh:mm a').format(_selectedDeadline!)),
                onTap: () async {
                  await _pickDeadline();
                  setModalState(() {});
                },
                tileColor: Colors.grey[100],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _assignTask,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
                child: const Text("ASSIGN TASK"),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLeader = widget.project.leaderId == widget.currentUser.uid;
    final isTeacher = widget.currentUser.role == 'teacher';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.project.name),
        actions: [
          if (isTeacher) IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Delete Group"),
                  content: const Text("Are you sure you want to delete this project group? All tasks will also be deleted."),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
                    TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("Delete", style: TextStyle(color: Colors.red))),
                  ],
                ),
              );
              
              if (confirm == true) {
                if (!context.mounted) return;
                LoadingOverlay.show(context);
                try {
                  await FirebaseFirestore.instance.collection('projects').doc(widget.project.id).delete();
                  // Also delete related tasks
                  final tasks = await FirebaseFirestore.instance.collection('group_tasks').where('projectId', isEqualTo: widget.project.id).get();
                  for (var doc in tasks.docs) {
                    await doc.reference.delete();
                  }
                  if (context.mounted) {
                    Navigator.pop(context);
                    AppErrorHandler.showSuccess(context, "Project group deleted");
                  }
                } catch (e) {
                  if (context.mounted) AppErrorHandler.showError(context, e);
                } finally {
                  if (context.mounted) LoadingOverlay.hide(context);
                }
              }
            },
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('group_tasks')
            .where('projectId', isEqualTo: widget.project.id)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) return AppErrorHandler.buildErrorWidget(snapshot.error, () => setState(() {}));
          if (snapshot.connectionState == ConnectionState.waiting) return AppErrorHandler.buildLoadingWidget();
          
          final tasks = snapshot.data!.docs.map((doc) => 
            GroupTask.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();

          if (tasks.isEmpty) {
            return const Center(child: Text("No tasks assigned yet."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tasks.length,
            itemBuilder: (context, index) {
              final task = tasks[index];
              final isMyTask = task.assignedTo == widget.currentUser.uid;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: Checkbox(
                    value: task.isDone,
                    onChanged: (isMyTask || isLeader || isTeacher) ? (val) async {
                      try {
                        await FirebaseFirestore.instance.collection('group_tasks').doc(task.id).update({
                          'isDone': val,
                          'completedAt': val! ? Timestamp.now() : null,
                        });
                      } catch (e) {
                        if (context.mounted) AppErrorHandler.showError(context, e);
                      }
                    } : null,
                  ),
                  title: Text(
                    task.title, 
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      decoration: task.isDone ? TextDecoration.lineThrough : null
                    )
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Assigned to: ${task.assignedToName}"),
                      Text("Deadline: ${DateFormat('MMM d, hh:mm a').format(task.deadline)}"),
                      if (task.isDone && task.completedAt != null) 
                        Text("Completed: ${DateFormat('MMM d, hh:mm a').format(task.completedAt!)}", style: const TextStyle(color: Colors.green)),
                    ],
                  ),
                  trailing: (isLeader || isTeacher) ? IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () async {
                      try {
                        await FirebaseFirestore.instance.collection('group_tasks').doc(task.id).delete();
                      } catch (e) {
                        if (context.mounted) AppErrorHandler.showError(context, e);
                      }
                    },
                  ) : null,
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: (isLeader || isTeacher) ? FloatingActionButton.extended(
        onPressed: _showAssignTaskSheet,
        label: const Text("Assign Task"),
        icon: const Icon(Icons.add_task),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ) : null,
    );
  }
}
