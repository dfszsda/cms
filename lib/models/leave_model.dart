import 'package:cloud_firestore/cloud_firestore.dart';

class LeaveModel {
  final String id;
  final String studentUid;
  final String studentName;
  final String batch;
  final String branch;
  final DateTime startDate;
  final DateTime endDate;
  final String reason;
  final String? proofUrl;
  final String? proofType; // 'image' or 'pdf'
  final String status; // 'pending', 'approved', 'rejected'
  final String? coordinatorId;
  final DateTime createdAt;

  String get branchName {
    if (branch.contains('_')) {
      return branch.split('_').last;
    }
    return branch;
  }

  LeaveModel({
    required this.id,
    required this.studentUid,
    required this.studentName,
    required this.batch,
    required this.branch,
    required this.startDate,
    required this.endDate,
    required this.reason,
    this.proofUrl,
    this.proofType,
    required this.status,
    this.coordinatorId,
    required this.createdAt,
  });

  factory LeaveModel.fromMap(Map<String, dynamic> data, String id) {
    return LeaveModel(
      id: id,
      studentUid: data['studentUid'] ?? '',
      studentName: data['studentName'] ?? '',
      batch: data['batch'] ?? '',
      branch: data['branch'] ?? '',
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      reason: data['reason'] ?? '',
      proofUrl: data['proofUrl'],
      proofType: data['proofType'],
      status: data['status'] ?? 'pending',
      coordinatorId: data['coordinatorId'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'studentUid': studentUid,
      'studentName': studentName,
      'batch': batch,
      'branch': branch,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'reason': reason,
      'proofUrl': proofUrl,
      'proofType': proofType,
      'status': status,
      'coordinatorId': coordinatorId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
