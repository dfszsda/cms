// ignore_for_file: unused_element

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HolidayScreen extends StatefulWidget {
  final bool isAdmin;
  const HolidayScreen({super.key, this.isAdmin = false});

  @override
  State<HolidayScreen> createState() => _HolidayScreenState();
}

class _HolidayScreenState extends State<HolidayScreen> {
  final _titleController = TextEditingController();
  final _reasonController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _addHoliday() async {
    if (_titleController.text.isEmpty || _reasonController.text.isEmpty) return;

    await FirebaseFirestore.instance.collection('holidays').add({
      'title': _titleController.text.trim(),
      'reason': _reasonController.text.trim(),
      'date': Timestamp.fromDate(_selectedDate),
      'createdAt': FieldValue.serverTimestamp(),
    });

    if (mounted) {
      _titleController.clear();
      _reasonController.clear();
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Holiday added successfully!")),
      );
    }
  }

  void _showAddHolidayDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Add Holiday"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: "Holiday Title (e.g. Diwali)", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _reasonController,
                  decoration: const InputDecoration(labelText: "Reason", border: OutlineInputBorder()),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                ListTile(
                  title: Text("Date: ${DateFormat('dd-MM-yyyy').format(_selectedDate)}"),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2024),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      setDialogState(() => _selectedDate = picked);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
            ElevatedButton(onPressed: _addHoliday, child: const Text("Add")),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("College Holidays"),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('holidays').orderBy('date').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final holidays = snapshot.data!.docs;
          
          if (holidays.isEmpty) {
            return const Center(child: Text("No holidays listed yet."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: holidays.length,
            itemBuilder: (context, index) {
              final holiday = holidays[index];
              final DateTime date = (holiday['date'] as Timestamp).toDate();
              
              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: Colors.red[50], borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(DateFormat('dd').format(date), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.red)),
                        Text(DateFormat('MMM').format(date), style: const TextStyle(fontSize: 12, color: Colors.red)),
                      ],
                    ),
                  ),
                  title: Text(holiday['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(holiday['reason']),
                  trailing: widget.isAdmin 
                    ? IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => holiday.reference.delete(),
                      )
                    : null,
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: widget.isAdmin 
        ? FloatingActionButton(
            onPressed: _showAddHolidayDialog,
            backgroundColor: Colors.redAccent,
            child: const Icon(Icons.add, color: Colors.white),
          )
        : null,
    );
  }
}
