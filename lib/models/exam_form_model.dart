import 'package:cloud_firestore/cloud_firestore.dart';

class ExamSubject {
  final String name;
  final String type; // 'Theory' or 'Practical'

  ExamSubject({required this.name, required this.type});

  Map<String, dynamic> toMap() {
    return {'name': name, 'type': type};
  }

  factory ExamSubject.fromMap(Map<String, dynamic> map) {
    return ExamSubject(
      name: map['name'] ?? '',
      type: map['type'] ?? 'Theory',
    );
  }
}

class ExamFormModel {
  final String? id;
  final String studentId;
  final String studentName;
  final int semester;
  final List<ExamSubject> subjects;
  final String status; // 'Pending', 'Confirmed', 'Rejected'
  final String? rejectReason;
  final String? collegeId;
  final DateTime? updatedAt;

  ExamFormModel({
    this.id,
    required this.studentId,
    required this.studentName,
    required this.semester,
    required this.subjects,
    this.status = 'Pending',
    this.rejectReason,
    this.collegeId,
    this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'semester': semester,
      'subjects': subjects.map((s) => s.toMap()).toList(),
      'status': status,
      'rejectReason': rejectReason,
      'collegeId': collegeId,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  factory ExamFormModel.fromMap(Map<String, dynamic> map, String id) {
    return ExamFormModel(
      id: id,
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      semester: map['semester'] ?? 1,
      subjects: (map['subjects'] as List? ?? [])
          .map((s) => ExamSubject.fromMap(s as Map<String, dynamic>))
          .toList(),
      status: map['status'] ?? 'Pending',
      rejectReason: map['rejectReason'],
      collegeId: map['collegeId'],
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
    );
  }
}
