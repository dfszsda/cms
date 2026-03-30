import 'package:cloud_firestore/cloud_firestore.dart';

class SubjectResult {
  final String subjectName;
  final String type; // 'Theory' or 'Practical'
  final int credits;
  final String grade; // AA, AB, BB, BC, CC, CD, DD, FF
  final int gradePoint;
  final bool isPass;

  SubjectResult({
    required this.subjectName,
    required this.type,
    required this.credits,
    required this.grade,
    required this.gradePoint,
    required this.isPass,
  });

  Map<String, dynamic> toMap() {
    return {
      'subjectName': subjectName,
      'type': type,
      'credits': credits,
      'grade': grade,
      'gradePoint': gradePoint,
      'isPass': isPass,
    };
  }

  factory SubjectResult.fromMap(Map<String, dynamic> map) {
    return SubjectResult(
      subjectName: map['subjectName'] ?? '',
      type: map['type'] ?? 'Theory',
      credits: map['credits'] ?? 0,
      grade: map['grade'] ?? 'FF',
      gradePoint: map['gradePoint'] ?? 0,
      isPass: map['isPass'] ?? false,
    );
  }

  static int getGradePoint(String grade) {
    switch (grade) {
      case 'AA': return 10;
      case 'AB': return 9;
      case 'BB': return 8;
      case 'BC': return 7;
      case 'CC': return 6;
      case 'CD': return 5;
      case 'DD': return 4;
      case 'FF': return 0;
      default: return 0;
    }
  }
}

class ResultModel {
  final String? id;
  final String studentId;
  final String studentName;
  final int semester;
  final List<SubjectResult> results;
  final double sgpa;
  final double cgpa;
  final DateTime updatedAt;

  ResultModel({
    this.id,
    required this.studentId,
    required this.studentName,
    required this.semester,
    required this.results,
    required this.sgpa,
    required this.cgpa,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'semester': semester,
      'results': results.map((r) => r.toMap()).toList(),
      'sgpa': sgpa,
      'cgpa': cgpa,
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory ResultModel.fromMap(Map<String, dynamic> map, String id) {
    return ResultModel(
      id: id,
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      semester: map['semester'] ?? 1,
      results: (map['results'] as List? ?? [])
          .map((r) => SubjectResult.fromMap(r as Map<String, dynamic>))
          .toList(),
      sgpa: (map['sgpa'] ?? 0.0).toDouble(),
      cgpa: (map['cgpa'] ?? 0.0).toDouble(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
