import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Authentication
  Future<UserModel?> signIn(String email, String password) async {
    try {
      UserCredential cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      DocumentSnapshot doc = await _firestore.collection('users').doc(cred.user!.uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, cred.user!.uid);
      } else {
        throw Exception("User profile not found in database.");
      }
    } catch (e) {
      rethrow;
    }
  }

  // User Management
  Future<void> signUpUser({
    required String fullName,
    required String email,
    required String password,
    required String role,
    String? branch,
    String? batch,
  }) async {
    UserCredential cred = await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
    Map<String, dynamic> userData = {
      'fullName': fullName,
      'email': email,
      'role': role,
      'password': password,
      'profileComplete': false,
      'branch': branch,
    };
    if (role == 'student') {
      userData['semester'] = 1;
      userData['batch'] = batch;
    }
    await _firestore.collection('users').doc(cred.user!.uid).set(userData);
  }

  // Compatibility Wrappers
  Future<void> signUp(String fullName, String email, String password, String role) async {
    return signUpUser(fullName: fullName, email: email, password: password, role: role);
  }

  // Branch & Batch
  Future<void> addBranch(String id, String name) async {
    await _firestore.collection('branches').doc(id.toUpperCase()).set({
      'name': name,
      'batchCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> createBatch(String branchId, String batchLetter, int year) async {
    DocumentReference branchRef = _firestore.collection('branches').doc(branchId);
    return _firestore.runTransaction((transaction) async {
      DocumentSnapshot branchSnap = await transaction.get(branchRef);
      if (!branchSnap.exists) throw "Branch does not exist";
      int currentCount = branchSnap.get('batchCount') ?? 0;
      if (currentCount >= 4) throw "Maximum 4 batches allowed per branch";
      int nextBatchNum = currentCount + 1;
      String fullName = "$nextBatchNum$branchId-$batchLetter-$year";
      transaction.set(_firestore.collection('batches').doc(), {
        'branchId': branchId,
        'batchLetter': batchLetter,
        'fullName': fullName,
        'year': year,
        'studentCount': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
      transaction.update(branchRef, {'batchCount': nextBatchNum});
    });
  }

  Future<void> updateTeacherBranch(String uid, String newBranch) async {
    await _firestore.collection('users').doc(uid).update({'branch': newBranch});
  }

  // Attendance Logic
  Stream<List<UserModel>> getStudentsForAttendance(String branch, int semester) {
    return _firestore.collection('users')
        .where('role', isEqualTo: 'student')
        .where('branch', isEqualTo: branch)
        .where('semester', isEqualTo: semester)
        .snapshots().map((snap) => snap.docs.map((doc) => UserModel.fromMap(doc.data(), doc.id)).toList());
  }

  Future<void> submitAttendance({
    required String branch,
    required int semester,
    required String subject,
    required DateTime date,
    required List<String> presentUids,
  }) async {
    String dateStr = "${date.year}-${date.month}-${date.day}";
    await _firestore.collection('attendance').add({
      'branchId': branch,
      'semester': semester,
      'subject': subject,
      'date': Timestamp.fromDate(date),
      'dateString': dateStr,
      'presentStudents': presentUids,
      'teacherId': _auth.currentUser?.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getStudentAttendance(String uid, int semester) {
    return _firestore.collection('attendance')
        .where('semester', isEqualTo: semester)
        .snapshots();
  }

  // Subject Management
  Future<void> addSubject(String branch, int semester, String subjectName) async {
    await _firestore.collection('subjects').add({
      'branch': branch,
      'semester': semester,
      'name': subjectName,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getSubjects(String branch, int semester) {
    return _firestore.collection('subjects')
        .where('branch', isEqualTo: branch)
        .where('semester', isEqualTo: semester)
        .snapshots();
  }

  // Timetable Management
  Future<void> setTimetable(String branch, int semester, String day, List<Map<String, dynamic>> slots) async {
    String docId = "${branch}_${semester}_$day".toUpperCase();
    await _firestore.collection('timetable').doc(docId).set({
      'branch': branch,
      'semester': semester,
      'day': day,
      'slots': slots, 
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<DocumentSnapshot> getTimetable(String branch, int semester, String day) {
    String docId = "${branch}_${semester}_$day".toUpperCase();
    return _firestore.collection('timetable').doc(docId).snapshots();
  }

  // Profile & Compatibility
  Future<void> updateProfile(UserModel user) async {
    await _firestore.collection('users').doc(user.uid).update(user.toMap());
  }

  Future<void> changePassword(String newPassword) async {
    await _auth.currentUser?.updatePassword(newPassword);
    await _firestore.collection('users').doc(_auth.currentUser?.uid).update({'password': newPassword});
  }

  // Requests
  Future<void> sendLoginRequest(String email, String type) async {
    var userQuery = await _firestore.collection('users').where('email', isEqualTo: email).limit(1).get();
    String fullName = userQuery.docs.isNotEmpty ? userQuery.docs.first.get('fullName') : "Unknown User";
    await _firestore.collection('requests').add({
      'email': email, 'fullName': fullName, 'requestType': type, 'status': 'pending', 'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getPendingRequests() => _firestore.collection('requests').where('status', isEqualTo: 'pending').orderBy('createdAt', descending: true).snapshots();
  Future<void> approveRequest(String requestId, String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
    await _firestore.collection('requests').doc(requestId).update({'status': 'completed'});
  }

  // Assignments
  Future<void> uploadAssignment(Map<String, dynamic> data) async {
    await _firestore.collection('assignments').add({
      ...data,
      'teacherId': _auth.currentUser?.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Getters
  Stream<QuerySnapshot> getBranches() => _firestore.collection('branches').orderBy('createdAt', descending: true).snapshots();
  Stream<QuerySnapshot> getBatchesByBranch(String branchId) => _firestore.collection('batches').where('branchId', isEqualTo: branchId).snapshots();
  Stream<List<UserModel>> getAllUsers() => _firestore.collection('users').snapshots().map((snap) => snap.docs.map((doc) => UserModel.fromMap(doc.data(), doc.id)).toList());
  Future<void> signOut() => _auth.signOut();
  Future<bool> isFirstTimeLogin(String uid) async => (await SharedPreferences.getInstance()).getBool('first_login_$uid') ?? true;
  Future<void> markFirstLoginDone(String uid) async => (await SharedPreferences.getInstance()).setBool('first_login_$uid', false);
}
