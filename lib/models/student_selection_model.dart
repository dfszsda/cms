import 'package:cloud_firestore/cloud_firestore.dart';

class StudentSelectionModel {
  final String id;
  final String studentId;
  final String collegeId;
  final String branchId;
  final int semester;
  final List<String> selectedSubjectIds;
  final DateTime timestamp;

  StudentSelectionModel({
    required this.id,
    required this.studentId,
    required this.collegeId,
    required this.branchId,
    required this.semester,
    required this.selectedSubjectIds,
    required this.timestamp,
  });

  factory StudentSelectionModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return StudentSelectionModel(
      id: doc.id,
      studentId: data['studentId'] ?? '',
      collegeId: data['collegeId'] ?? '',
      branchId: data['branchId'] ?? '',
      semester: data['semester'] ?? 0,
      selectedSubjectIds: List<String>.from(data['selectedSubjectIds'] ?? []),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentId': studentId,
      'collegeId': collegeId,
      'branchId': branchId,
      'semester': semester,
      'selectedSubjectIds': selectedSubjectIds,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
