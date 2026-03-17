class UserModel {
  final String uid;
  final String fullName;
  final String email;
  final String role; // 'student', 'teacher', 'admin'
  final String? password; // Added to store password for admin visibility
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
  int? semester; // New field for students
  String? batch; // New field for batch (e.g., 2021-2025)

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
    };
  }
}
