import 'package:cloud_firestore/cloud_firestore.dart';

class SemesterConfigModel {
  final String id;
  final String collegeId;
  final String branchId;
  final int semester;
  final DateTime startDate;
  final DateTime endDate;
  final bool isSelectionActive;

  SemesterConfigModel({
    required this.id,
    required this.collegeId,
    required this.branchId,
    required this.semester,
    required this.startDate,
    required this.endDate,
    this.isSelectionActive = true,
  });

  factory SemesterConfigModel.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return SemesterConfigModel(
      id: doc.id,
      collegeId: data['collegeId'] ?? '',
      branchId: data['branchId'] ?? '',
      semester: data['semester'] ?? 0,
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: data['endDate'] != null 
          ? (data['endDate'] as Timestamp).toDate() 
          : (data['startDate'] as Timestamp).toDate().add(const Duration(days: 5)),
      isSelectionActive: data['isSelectionActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'collegeId': collegeId,
      'branchId': branchId,
      'semester': semester,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'isSelectionActive': isSelectionActive,
    };
  }
}
