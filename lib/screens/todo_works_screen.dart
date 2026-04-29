import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/todo_model.dart';
import '../services/error_handler.dart';
import 'group_projects_screen.dart';

class TodoWorksScreen extends StatefulWidget {
  const TodoWorksScreen({super.key});

  @override
  State<TodoWorksScreen> createState() => _TodoWorksScreenState();
}

class _TodoWorksScreenState extends State<TodoWorksScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  DateTime? _selectedDeadline;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {}); // Update FAB visibility
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      if (!mounted) return;
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (time != null) {
        if (!mounted) return;
        setState(() {
          _selectedDeadline = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _addTask() async {
    if (_titleCtrl.text.isEmpty || _selectedDeadline == null) {
      AppErrorHandler.showError(context, "Please enter title and select deadline");
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    LoadingOverlay.show(context);
    try {
      final task = TodoTask(
        id: '',
        userId: user.uid,
        title: _titleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        deadline: _selectedDeadline!,
        createdAt: DateTime.now(),
      );

      await FirebaseFirestore.instance.collection('todos').add(task.toMap());
      
      if (!mounted) return;
      _titleCtrl.clear();
      _descCtrl.clear();
      setState(() => _selectedDeadline = null);
      Navigator.pop(context);
      AppErrorHandler.showSuccess(context, "Task saved successfully!");
    } catch (e) {
      if (!mounted) return;
      AppErrorHandler.showError(context, e);
    } finally {
      if (mounted) LoadingOverlay.hide(context);
    }
  }

  void _showAddTaskSheet() {
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Add New Task", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: "Task Title", border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descCtrl,
              decoration: const InputDecoration(labelText: "Description", border: OutlineInputBorder()),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text(_selectedDeadline == null 
                ? "Select Deadline" 
                : DateFormat('MMM d, yyyy - hh:mm a').format(_selectedDeadline!)),
              onTap: _pickDeadline,
              tileColor: Colors.grey[100],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _addTask,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text("SAVE TASK"),
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
      appBar: AppBar(
        title: const Text("My Workspace"),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: "Individual Tasks"),
            Tab(text: "Group Projects"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Individual Tasks Tab
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('todos')
                .where('userId', isEqualTo: user?.uid)
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return AppErrorHandler.buildErrorWidget(snapshot.error, () => setState(() {}));
              }
              
              if (snapshot.connectionState == ConnectionState.waiting) {
                return AppErrorHandler.buildLoadingWidget();
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text("No tasks added yet."));
              }
              
              final tasks = snapshot.data!.docs.map((doc) => 
                TodoTask.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: tasks.length,
                itemBuilder: (context, index) {
                  final task = tasks[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    child: ExpansionTile(
                      leading: Checkbox(
                        value: task.isDone,
                        onChanged: (val) {
                          FirebaseFirestore.instance.collection('todos').doc(task.id).update({
                            'isDone': val,
                            'completedAt': val! ? Timestamp.now() : null,
                          });
                        },
                      ),
                      title: Text(
                        task.title,
                        style: TextStyle(
                          decoration: task.isDone ? TextDecoration.lineThrough : null,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text("Deadline: ${DateFormat('MMM d, hh:mm a').format(task.deadline)}"),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (task.description.isNotEmpty) ...[
                                Text("Description: ${task.description}"),
                                const SizedBox(height: 8),
                              ],
                              Text("Created: ${DateFormat('MMM d, hh:mm a').format(task.createdAt)}"),
                              if (task.isDone) ...[
                                const SizedBox(height: 8),
                                Text(
                                  "Completed: ${DateFormat('MMM d, hh:mm a').format(task.completedAt!)}",
                                  style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  "Time Taken: ${task.timeTaken}",
                                  style: const TextStyle(color: Colors.blue),
                                ),
                              ],
                              const SizedBox(height: 8),
                              Align(
                                alignment: Alignment.centerRight,
                                child: IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  onPressed: () async {
                                    try {
                                      await FirebaseFirestore.instance.collection('todos').doc(task.id).delete();
                                      if (!mounted) return;
                                      AppErrorHandler.showSuccess(context, "Task deleted");
                                    } catch (e) {
                                      if (!mounted) return;
                                      AppErrorHandler.showError(context, e);
                                    }
                                  },
                                ),
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  );
                },
              );
            },
          ),
          // Group Projects Tab
          const GroupProjectsScreen(),
        ],
      ),
      floatingActionButton: _tabController.index == 0 
          ? FloatingActionButton(
              onPressed: _showAddTaskSheet,
              child: const Icon(Icons.add),
            )
          : null, // GroupProjectsScreen has its own FAB
    );
  }
}
