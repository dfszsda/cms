import 'package:cloud_firestore/cloud_firestore.dart';

class MembershipModel {
  final String userId;
  final String status; // 'Active', 'Inactive', 'Pending'
  final DateTime? joinDate;
  final DateTime? expiryDate;

  MembershipModel({
    required this.userId,
    required this.status,
    this.joinDate,
    this.expiryDate,
  });

  factory MembershipModel.fromFirestore(Map<String, dynamic> data) {
    return MembershipModel(
      userId: data['userId'] ?? '',
      status: data['status'] ?? 'Inactive',
      joinDate: (data['joinDate'] as Timestamp?)?.toDate(),
      expiryDate: (data['expiryDate'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'status': status,
      'joinDate': joinDate != null ? Timestamp.fromDate(joinDate!) : null,
      'expiryDate': expiryDate != null ? Timestamp.fromDate(expiryDate!) : null,
    };
  }
}
