import 'package:cloud_firestore/cloud_firestore.dart';

class ExamEvent {
  final String subjectName;
  final DateTime date;
  final String time;
  final String type; // 'Theory' or 'Practical'

  ExamEvent({
    required this.subjectName,
    required this.date,
    required this.time,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'subjectName': subjectName,
      'date': Timestamp.fromDate(date),
      'time': time,
      'type': type,
    };
  }

  factory ExamEvent.fromMap(Map<String, dynamic> map) {
    return ExamEvent(
      subjectName: map['subjectName'] ?? '',
      date: (map['date'] as Timestamp).toDate(),
      time: map['time'] ?? '',
      type: map['type'] ?? 'Theory',
    );
  }
}

class ExamTimetableModel {
  final String? id;
  final String branchId;
  final int semester;
  final DateTime startDate;
  final List<ExamEvent> exams;
  final DateTime createdAt;

  ExamTimetableModel({
    this.id,
    required this.branchId,
    required this.semester,
    required this.startDate,
    required this.exams,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'branchId': branchId,
      'semester': semester,
      'startDate': Timestamp.fromDate(startDate),
      'exams': exams.map((e) => e.toMap()).toList(),
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory ExamTimetableModel.fromMap(Map<String, dynamic> map, String id) {
    return ExamTimetableModel(
      id: id,
      branchId: map['branchId'] ?? '',
      semester: map['semester'] ?? 1,
      startDate: (map['startDate'] as Timestamp).toDate(),
      exams: (map['exams'] as List? ?? [])
          .map((e) => ExamEvent.fromMap(e as Map<String, dynamic>))
          .toList(),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
