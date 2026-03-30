import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String fullName;
  final String email;
  final String role; // 'student', 'teacher', 'admin', 'coordinator', 'system_admin'
  final String? password;
  String? username;
  int? age;
  String? gender;
  String? hobby;
  String? aadhaar;
  String? abcId;
  String? address;
  String? phone;
  String? furtherPhone;
  String? profilePic;
  bool profileComplete;
  int? semester;
  String? batch; 
  String? branch; 
  String? collegeId; // NEW: Multi-college isolation
  
  // UFM Fields
  bool isUfmBanned;
  DateTime? ufmBanUntil;

  UserModel({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.role,
    this.password,
    this.username,
    this.age,
    this.gender,
    this.hobby,
    this.aadhaar,
    this.abcId,
    this.address,
    this.phone,
    this.furtherPhone,
    this.profilePic,
    this.profileComplete = false,
    this.semester,
    this.batch,
    this.branch,
    this.collegeId,
    this.isUfmBanned = false,
    this.ufmBanUntil,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      fullName: data['fullName'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'student',
      password: data['password'],
      username: data['username'],
      age: data['age'],
      gender: data['gender'],
      hobby: data['hobby'],
      aadhaar: data['aadhaar'],
      abcId: data['abcId'],
      address: data['address'],
      phone: data['phone'],
      furtherPhone: data['furtherPhone'],
      profilePic: data['profilePic'],
      profileComplete: data['profileComplete'] ?? false,
      semester: data['semester'],
      batch: data['batch'],
      branch: data['branch'],
      collegeId: data['collegeId'],
      isUfmBanned: data['isUfmBanned'] ?? false,
      ufmBanUntil: data['ufmBanUntil'] != null ? (data['ufmBanUntil'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'email': email,
      'role': role,
      'password': password,
      'username': username,
      'age': age,
      'gender': gender,
      'hobby': hobby,
      'aadhaar': aadhaar,
      'abcId': abcId,
      'address': address,
      'phone': phone,
      'furtherPhone': furtherPhone,
      'profilePic': profilePic,
      'profileComplete': profileComplete,
      'semester': semester,
      'batch': batch,
      'branch': branch,
      'collegeId': collegeId,
      'isUfmBanned': isUfmBanned,
      'ufmBanUntil': ufmBanUntil != null ? Timestamp.fromDate(ufmBanUntil!) : null,
    };
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel && runtimeType == other.runtimeType && uid == other.uid;

  @override
  int get hashCode => uid.hashCode;
}
