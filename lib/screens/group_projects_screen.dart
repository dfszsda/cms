import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/todo_model.dart';

class GroupProjectsScreen extends StatefulWidget {
  const GroupProjectsScreen({super.key});

  @override
  State<GroupProjectsScreen> createState() => _GroupProjectsScreenState();
}

class _GroupProjectsScreenState extends State<GroupProjectsScreen> {
  final _projectNameCtrl = TextEditingController();

  Future<void> _createProject() async {
    if (_projectNameCtrl.text.isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final project = GroupProject(
        id: '',
        name: _projectNameCtrl.text.trim(),
        leaderId: user.uid,
        memberIds: [user.uid],
        createdAt: DateTime.now(),
      );

      await FirebaseFirestore.instance.collection('projects').add(project.toMap());
      
      if (mounted) {
        _projectNameCtrl.clear();
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Project group created successfully!")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error creating project: $e")),
        );
      }
    }
  }

  void _showCreateProjectSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Create New Project Group", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(
              controller: _projectNameCtrl,
              decoration: const InputDecoration(labelText: "Project Name", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _createProject,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text("CREATE GROUP"),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('projects')
            .where('memberIds', arrayContains: user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }
          
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          final projects = snapshot.data!.docs.map((doc) => 
            GroupProject.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();

          if (projects.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.group_off, size: 60, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text("No project groups yet.", style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _showCreateProjectSheet,
                    icon: const Icon(Icons.group_add),
                    label: const Text("Create a Group"),
                  )
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: projects.length,
            itemBuilder: (context, index) {
              final project = projects[index];
              final isLeader = project.leaderId == user?.uid;

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
                  subtitle: Text(isLeader ? "Leader" : "Member"),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.push(
                    context, 
                    MaterialPageRoute(builder: (_) => ProjectDetailsScreen(project: project))
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateProjectSheet,
        icon: const Icon(Icons.add),
        label: const Text("New Project"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
    );
  }
}

class ProjectDetailsScreen extends StatefulWidget {
  final GroupProject project;
  const ProjectDetailsScreen({super.key, required this.project});

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
      if (!mounted) return;
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all details and select a member")),
      );
      return;
    }

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
      
      if (mounted) {
        _taskTitleCtrl.clear();
        _taskDescCtrl.clear();
        setState(() {
          _selectedDeadline = null;
          _selectedMemberId = null;
          _selectedMemberName = null;
        });
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Task assigned successfully!")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error assigning task: $e")),
        );
      }
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
                  if (!snapshot.hasData) return const LinearProgressIndicator();
                  final members = snapshot.data!.docs;
                  return DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: "Assign To", border: OutlineInputBorder()),
                    // ignore: deprecated_member_use
                    value: _selectedMemberId,
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

  void _addMember() async {
    final emailController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Member"),
        content: TextField(
          controller: emailController,
          decoration: const InputDecoration(hintText: "Enter user email"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
          TextButton(
            onPressed: () async {
              if (emailController.text.isEmpty) return;
              
              final query = await FirebaseFirestore.instance
                  .collection('users')
                  .where('email', isEqualTo: emailController.text.trim())
                  .get();
              
              if (query.docs.isEmpty) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("User not found")));
                return;
              }

              final newUserUid = query.docs.first.id;
              if (widget.project.memberIds.contains(newUserUid)) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("User already in group")));
                return;
              }

              await FirebaseFirestore.instance.collection('projects').doc(widget.project.id).update({
                'memberIds': FieldValue.arrayUnion([newUserUid])
              });
              
              if (!context.mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Member added!")));
            }, 
            child: const Text("Add")
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isLeader = widget.project.leaderId == user?.uid;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.project.name),
        actions: [
          if (isLeader) IconButton(icon: const Icon(Icons.person_add), onPressed: _addMember),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('group_tasks')
            .where('projectId', isEqualTo: widget.project.id)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text("Error: ${snapshot.error}\n\nMake sure Firestore index is created."),
              ),
            );
          }
          
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
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
              final isMyTask = task.assignedTo == user?.uid;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: Checkbox(
                    value: task.isDone,
                    onChanged: (isMyTask || isLeader) ? (val) {
                      FirebaseFirestore.instance.collection('group_tasks').doc(task.id).update({
                        'isDone': val,
                        'completedAt': val! ? Timestamp.now() : null,
                      });
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
                  trailing: isLeader ? IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => FirebaseFirestore.instance.collection('group_tasks').doc(task.id).delete(),
                  ) : null,
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: isLeader ? FloatingActionButton.extended(
        onPressed: _showAssignTaskSheet,
        label: const Text("Assign Task"),
        icon: const Icon(Icons.add_task),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ) : null,
    );
  }
}
