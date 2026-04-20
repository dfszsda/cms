import 'package:cloud_firestore/cloud_firestore.dart';

class UfmModel {
  final String? id;
  final String studentId;
  final String studentName;
  final String studentBranch;
  final int studentSemester;
  final String teacherId;
  final String teacherName;
  final String subjectName;
  final String reason;
  final String status; // 'pending', 'confirmed', 'resolved'
  final DateTime createdAt;
  final DateTime? resolvedAt;

  String get branchName {
    if (studentBranch.contains('_')) {
      return studentBranch.split('_').last;
    }
    return studentBranch;
  }

  UfmModel({
    this.id,
    required this.studentId,
    required this.studentName,
    required this.studentBranch,
    required this.studentSemester,
    required this.teacherId,
    required this.teacherName,
    required this.subjectName,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.resolvedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'studentBranch': studentBranch,
      'studentSemester': studentSemester,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'subjectName': subjectName,
      'reason': reason,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
    };
  }

  factory UfmModel.fromMap(Map<String, dynamic> map, String id) {
    return UfmModel(
      id: id,
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      studentBranch: map['studentBranch'] ?? '',
      studentSemester: map['studentSemester'] ?? 1,
      teacherId: map['teacherId'] ?? '',
      teacherName: map['teacherName'] ?? '',
      subjectName: map['subjectName'] ?? '',
      reason: map['reason'] ?? '',
      status: map['status'] ?? 'pending',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      resolvedAt: map['resolvedAt'] != null ? (map['resolvedAt'] as Timestamp).toDate() : null,
    );
  }
}
