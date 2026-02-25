class UserModel {
  final String uid;
  final String fullName;
  final String email;
  final String role; // 'student', 'teacher', 'admin'
  String? username;
  int? age;
  String? gender;
  String? hobby;
  String? aadhaar;
  String? abcId;
  String? address;
  String? phone;
  String? furtherPhone;
  bool profileComplete;

  UserModel({
    required this.uid,
    required this.fullName,
    required this.email,
    required this.role,
    this.username,
    this.age,
    this.gender,
    this.hobby,
    this.aadhaar,
    this.abcId,
    this.address,
    this.phone,
    this.furtherPhone,
    this.profileComplete = false,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      fullName: data['fullName'] ?? '',
      email: data['email'] ?? '',
      role: data['role'] ?? 'student',
      username: data['username'],
      age: data['age'],
      gender: data['gender'],
      hobby: data['hobby'],
      aadhaar: data['aadhaar'],
      abcId: data['abcId'],
      address: data['address'],
      phone: data['phone'],
      furtherPhone: data['furtherPhone'],
      profileComplete: data['profileComplete'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'email': email,
      'role': role,
      'username': username,
      'age': age,
      'gender': gender,
      'hobby': hobby,
      'aadhaar': aadhaar,
      'abcId': abcId,
      'address': address,
      'phone': phone,
      'furtherPhone': furtherPhone,
      'profileComplete': profileComplete,
    };
  }
}