import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/result_model.dart';
import '../models/exam_form_model.dart';
import '../models/payment_config_model.dart';
import '../models/exam_timetable_model.dart';
import '../services/error_handler.dart';

class ExamDashboardScreen extends StatefulWidget {
  final UserModel student;
  const ExamDashboardScreen({super.key, required this.student});

  @override
  State<ExamDashboardScreen> createState() => _ExamDashboardScreenState();
}

class _ExamDashboardScreenState extends State<ExamDashboardScreen> {
  int? _selectedSemester;
  List<SubjectResult> _failedSubjects = [];
  bool _isLoading = false;
  PaymentConfig? _paymentConfig;
  bool _isFormSubmitted = false;

  @override
  void initState() {
    super.initState();
    _loadPaymentConfig();
    _loadAllFailedSubjects();
  }

  Future<void> _loadPaymentConfig() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('settings').doc('payment_config').get();
      if (doc.exists && mounted) {
        setState(() {
          _paymentConfig = PaymentConfig.fromFirestore(doc.data()!);
        });
      }
    } catch (e) {
      debugPrint("Error loading payment config: $e");
    }
  }

  Future<void> _loadAllFailedSubjects() async {
    setState(() => _isLoading = true);
    try {
      final resultsSnap = await FirebaseFirestore.instance
          .collection('results')
          .where('studentId', isEqualTo: widget.student.uid)
          .get();

      Map<String, SubjectResult> latestAttempts = {};

      for (var doc in resultsSnap.docs) {
        final resModel = ResultModel.fromMap(doc.data(), doc.id);
        for (var sub in resModel.results) {
          // Use a unique key for each subject to track its latest status
          String key = "${resModel.semester}_${sub.subjectName}";
          latestAttempts[key] = sub;
        }
      }

      if (mounted) {
        setState(() {
          _failedSubjects = latestAttempts.values.where((s) => !s.isPass).toList();
        });
      }
    } catch (e) {
      if (mounted) AppErrorHandler.showError(context, e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitExamForm() async {
    if (_selectedSemester == null) {
      AppErrorHandler.showError(context, "Please select a semester");
      return;
    }

    LoadingOverlay.show(context);

    try {
      final form = ExamFormModel(
        studentId: widget.student.uid,
        studentName: widget.student.fullName,
        semester: _selectedSemester!,
        subjects: _failedSubjects.map((s) => ExamSubject(name: s.subjectName, type: s.type)).toList(),
        status: 'Pending',
        collegeId: widget.student.collegeId,
      );

      await FirebaseFirestore.instance.collection('exam_forms').add(form.toMap());

      if (mounted) {
        setState(() {
          _isFormSubmitted = true;
        });
        AppErrorHandler.showSuccess(context, "Exam Form Submitted! Proceed to Payment.");
      }
    } catch (e) {
      if (mounted) AppErrorHandler.showError(context, e);
    } finally {
      if (mounted) LoadingOverlay.hide(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Exam Dashboard"),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
      ),
      body: _isLoading 
        ? AppErrorHandler.buildLoadingWidget()
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderCard(),
                const SizedBox(height: 20),
                const Text("Select Semester for Exam", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 10),
                _buildSemesterSelector(),
                const SizedBox(height: 20),
                const Text("Your ATKT Subjects", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 10),
                _failedSubjects.isEmpty 
                  ? const Card(child: ListTile(title: Text("No ATKT subjects found!"), leading: Icon(Icons.check_circle, color: Colors.green)))
                  : ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _failedSubjects.length,
                      itemBuilder: (context, index) {
                        final sub = _failedSubjects[index];
                        return Card(
                          child: ListTile(
                            leading: const CircleAvatar(backgroundColor: Colors.red, radius: 5),
                            title: Text(sub.subjectName),
                            subtitle: Text(sub.type),
                            trailing: Text("Grade: ${sub.grade}", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                          ),
                        );
                      },
                    ),
                const SizedBox(height: 24),
                if (!_isFormSubmitted)
                  ElevatedButton.icon(
                    onPressed: _failedSubjects.isEmpty ? null : _submitExamForm,
                    icon: const Icon(Icons.send),
                    label: const Text("SUBMIT EXAM FORM"),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(55),
                      backgroundColor: Colors.deepOrange,
                      foregroundColor: Colors.white,
                    ),
                  )
                else
                  _buildPaymentSection(),
                const SizedBox(height: 20),
                _buildTimetableSection(),
              ],
            ),
          ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.deepOrange, Colors.orange.shade800]),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.student.fullName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          const Text("Academic Backlog Summary", style: TextStyle(color: Colors.white70)),
          const Divider(color: Colors.white30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _headerInfo("Total ATKT", _failedSubjects.length.toString()),
              _headerInfo("Estimated Fee", "₹${_failedSubjects.length * (_paymentConfig?.examFeePerSubject ?? 0)}"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _headerInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildSemesterSelector() {
    return Wrap(
      spacing: 10,
      children: List.generate(8, (index) {
        int sem = index + 1;
        bool isSelected = _selectedSemester == sem;
        return ChoiceChip(
          label: Text("Sem $sem"),
          selected: isSelected,
          onSelected: (selected) {
            setState(() => _selectedSemester = selected ? sem : null);
          },
          selectedColor: Colors.deepOrange,
          labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
        );
      }),
    );
  }

  Widget _buildPaymentSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.green)),
      child: Column(
        children: [
          const Text("Form Submitted Successfully!", style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text("Total Fee: ₹${_failedSubjects.length * (_paymentConfig?.examFeePerSubject ?? 0)}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 15),
          ElevatedButton(
            onPressed: () {
              // Integrate Payment Gateway here
              AppErrorHandler.showSuccess(context, "Redirecting to Payment Gateway...");
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white, minimumSize: const Size.fromHeight(45)),
            child: const Text("PAY EXAM FEE NOW"),
          ),
        ],
      ),
    );
  }

  Widget _buildTimetableSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Exam Timetable", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 10),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('exam_timetables').where('semester', isEqualTo: _selectedSemester).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return AppErrorHandler.buildErrorWidget(snapshot.error, () => setState(() {}));
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return AppErrorHandler.buildLoadingWidget();
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Text("No timetable released for this semester yet.", style: TextStyle(color: Colors.grey));
            }
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: snapshot.data!.docs.length,
              itemBuilder: (context, index) {
                final doc = snapshot.data!.docs[index];
                return ListTile(
                  leading: const Icon(Icons.calendar_today, color: Colors.deepOrange),
                  title: Text(doc['subjectName']),
                  subtitle: Text(doc['date']),
                );
              },
            );
          },
        ),
      ],
    );
  }
}
