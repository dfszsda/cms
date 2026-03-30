import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminExamFeeScreen extends StatefulWidget {
  const AdminExamFeeScreen({super.key});

  @override
  State<AdminExamFeeScreen> createState() => _AdminExamFeeScreenState();
}

class _AdminExamFeeScreenState extends State<AdminExamFeeScreen> {
  final Map<int, TextEditingController> _controllers = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    for (int i = 1; i <= 8; i++) {
      _controllers[i] = TextEditingController();
    }
    _loadFees();
  }

  Future<void> _loadFees() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('settings').doc('exam_fees').get();
      if (doc.exists) {
        final data = doc.data()!;
        data.forEach((key, value) {
          int? sem = int.tryParse(key);
          if (sem != null && _controllers.containsKey(sem)) {
            _controllers[sem]!.text = value.toString();
          }
        });
      }
    } catch (e) {
      debugPrint("Error loading fees: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    for (var ctrl in _controllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _saveFees() async {
    setState(() => _isLoading = true);
    try {
      Map<String, dynamic> data = {};
      _controllers.forEach((sem, ctrl) {
        if (ctrl.text.isNotEmpty) {
          data[sem.toString()] = double.tryParse(ctrl.text) ?? 0.0;
        }
      });

      await FirebaseFirestore.instance.collection('settings').doc('exam_fees').set(data);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Fees updated successfully!")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Set Exam Fees"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 8,
            itemBuilder: (context, index) {
              int sem = index + 1;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.indigo,
                        child: Text("S$sem", style: const TextStyle(color: Colors.white)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextField(
                          controller: _controllers[sem],
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: "Exam Fee for Semester $sem",
                            prefixText: "₹ ",
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ElevatedButton(
          onPressed: _saveFees,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            minimumSize: const Size.fromHeight(55),
          ),
          child: const Text("SAVE ALL FEES", style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }
}
