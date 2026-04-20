import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/result_model.dart';
import '../models/user_model.dart';

class StudentResultScreen extends StatefulWidget {
  final UserModel student;
  const StudentResultScreen({super.key, required this.student});

  @override
  State<StudentResultScreen> createState() => _StudentResultScreenState();
}

class _StudentResultScreenState extends State<StudentResultScreen> {
  int _selectedSemester = 1;

  @override
  void initState() {
    super.initState();
    _selectedSemester = widget.student.semester ?? 1;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Results"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text("Semester: ", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 10),
                DropdownButton<int>(
                  value: _selectedSemester,
                  items: List.generate(8, (i) => i + 1).map((s) => DropdownMenuItem(value: s, child: Text("Sem $s"))).toList(),
                  onChanged: (val) => setState(() => _selectedSemester = val!),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('results')
                  .where('studentId', isEqualTo: widget.student.uid)
                  .where('semester', isEqualTo: _selectedSemester)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                if (snapshot.data!.docs.isEmpty) return const Center(child: Text("Result not yet uploaded for this semester."));

                final result = ResultModel.fromMap(snapshot.data!.docs.first.data() as Map<String, dynamic>, snapshot.data!.docs.first.id);

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildResultCard(result),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () => _generatePdf(result),
                        icon: const Icon(Icons.download),
                        label: const Text("DOWNLOAD PDF RESULT"),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard(ResultModel result) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text("STATEMENT OF MARKS", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
            const Divider(),
            _infoRow("Name", result.studentName),
            _infoRow("Semester", result.semester.toString()),
            const SizedBox(height: 10),
            Table(
              border: TableBorder.all(color: Colors.grey.shade300),
              children: [
                const TableRow(
                  decoration: BoxDecoration(color: Colors.indigo),
                  children: [
                    Padding(padding: EdgeInsets.all(8), child: Text("Subject", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    Padding(padding: EdgeInsets.all(8), child: Text("Type", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    Padding(padding: EdgeInsets.all(8), child: Text("Grade", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  ],
                ),
                ...result.results.map((r) => TableRow(
                  children: [
                    Padding(padding: const EdgeInsets.all(8), child: Text(r.subjectName)),
                    Padding(padding: const EdgeInsets.all(8), child: Text(r.type)),
                    Padding(padding: const EdgeInsets.all(8), child: Text(r.grade, style: TextStyle(fontWeight: FontWeight.bold, color: r.grade == 'FF' ? Colors.red : Colors.black))),
                  ],
                )),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _summaryBox("SGPA", result.sgpa.toString()),
                _summaryBox("CGPA", result.cgpa.toString()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _summaryBox(String label, String value) {
    return Column(
      children: [
        Text(label, style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold)),
        Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Future<void> _generatePdf(ResultModel result) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Padding(
            padding: const pw.EdgeInsets.all(20),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(child: pw.Text("COLLEGE MANAGEMENT SYSTEM", style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold))),
                pw.Center(child: pw.Text("OFFICIAL STATEMENT OF MARKS", style: pw.TextStyle(fontSize: 16))),
                pw.SizedBox(height: 20),
                pw.Divider(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text("Student Name: ${result.studentName}"),
                        pw.Text("Semester: ${result.semester}"),
                        pw.Text("Branch: ${widget.student.branchName}"),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text("Date: ${result.updatedAt.toString().split(' ')[0]}"),
                        pw.Text("Enrollment: ${result.studentId.substring(0, 8).toUpperCase()}"),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),
                pw.TableHelper.fromTextArray(
                  headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  headers: ['Subject Name', 'Type', 'Credits', 'Grade', 'Status'],
                  data: result.results.map((r) => [
                    r.subjectName,
                    r.type,
                    r.credits.toString(),
                    r.grade,
                    r.isPass ? 'PASS' : 'FAIL'
                  ]).toList(),
                ),
                pw.SizedBox(height: 30),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.end,
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(border: pw.Border.all()),
                      child: pw.Column(
                        children: [
                          pw.Text("SGPA: ${result.sgpa}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          pw.Text("CGPA: ${result.cgpa}", style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          pw.Text("Percentage: ${((result.cgpa - 0.5) * 10).toStringAsFixed(2)}%"),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.Spacer(),
                pw.Divider(),
                pw.Center(child: pw.Text("This is a computer generated document. No signature required.")),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }
}
