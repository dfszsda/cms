// ignore_for_file: unnecessary_cast

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../models/leave_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Authentication
  User? get currentUser => _auth.currentUser;

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

  Future<void> changePassword(String newPassword) async {
    User? user = _auth.currentUser;
    if (user != null) {
      await user.updatePassword(newPassword);
      await _firestore.collection('users').doc(user.uid).update({'password': newPassword});
    }
  }

  Future<bool> isFirstTimeLogin(String uid) async {
    DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      return data['firstLogin'] ?? true;
    }
    return true;
  }

  Future<void> markFirstLoginDone(String uid) async {
    await _firestore.collection('users').doc(uid).update({'firstLogin': false});
  }

  Future<void> sendLoginRequest(String email, String type) async {
    await _firestore.collection('requests').add({
      'email': email,
      'type': type,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // User Management
  Future<void> signUp(String fullName, String email, String password, String role) async {
    await signUpUser(fullName: fullName, email: email, password: password, role: role);
  }

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
      'firstLogin': true,
    };
    if (role == 'student') {
      userData['semester'] = 1;
      userData['batch'] = batch;
    }
    await _firestore.collection('users').doc(cred.user!.uid).set(userData);
  }

  // Branch & Batch
  Future<void> addBranch(String id, String name) async {
    await _firestore.collection('branches').doc(id.toUpperCase()).set({
      'name': name,
      'batchCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> createBatch(String branchId, String batchLetter, int year, {String? coordinatorId}) async {
    DocumentReference branchRef = _firestore.collection('branches').doc(branchId);
    
    if (coordinatorId != null) {
      QuerySnapshot teacherBatches = await _firestore.collection('batches')
          .where('coordinatorId', isEqualTo: coordinatorId)
          .get();
      if (teacherBatches.docs.length >= 2) {
        throw "This teacher is already a coordinator for 2 batches.";
      }
    }

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
        'coordinatorId': coordinatorId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      transaction.update(branchRef, {'batchCount': nextBatchNum});
    });
  }

  Future<void> assignCoordinator(String batchId, String teacherId) async {
    // Check if teacher already has 2 batches
    QuerySnapshot teacherBatches = await _firestore.collection('batches')
        .where('coordinatorId', isEqualTo: teacherId)
        .get();
    
    if (teacherBatches.docs.length >= 2) {
      throw "This teacher is already a coordinator for 2 batches.";
    }

    await _firestore.collection('batches').doc(batchId).update({
      'coordinatorId': teacherId,
    });
  }

  Future<void> removeCoordinator(String batchId) async {
    await _firestore.collection('batches').doc(batchId).update({
      'coordinatorId': null,
    });
  }

  Stream<QuerySnapshot> getBatchesWithoutCoordinator() {
    return _firestore.collection('batches').where('coordinatorId', isNull: true).snapshots();
  }

  Stream<QuerySnapshot> getCoordinatorBatches(String teacherId) {
    return _firestore.collection('batches').where('coordinatorId', isEqualTo: teacherId).snapshots();
  }

  Future<void> updateTeacherBranch(String uid, String newBranch) async {
    await _firestore.collection('users').doc(uid).update({'branch': newBranch});
  }

  // Semester Management
  Future<void> updateBatchSemester(String batchName, int newSemester) async {
    QuerySnapshot students = await _firestore.collection('users')
        .where('role', isEqualTo: 'student')
        .where('batch', isEqualTo: batchName)
        .get();
    
    WriteBatch batch = _firestore.batch();
    for (var doc in students.docs) {
      batch.update(doc.reference, {'semester': newSemester});
    }
    await batch.commit();
  }

  Future<void> updateStudentSemester(String studentUid, int newSemester) async {
    await _firestore.collection('users').doc(studentUid).update({'semester': newSemester});
  }

  // Leave Management
  Future<void> requestLeave(LeaveModel leave) async {
    await _firestore.collection('leaves').add(leave.toMap());
  }

  Stream<List<LeaveModel>> getLeaveRequestsForCoordinator(String coordinatorId) {
    return _firestore.collection('leaves')
        .where('coordinatorId', isEqualTo: coordinatorId)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => LeaveModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList());
  }

  Stream<List<LeaveModel>> getStudentLeaves(String studentUid) {
    return _firestore.collection('leaves')
        .where('studentUid', isEqualTo: studentUid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => LeaveModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList());
  }

  Future<void> updateLeaveStatus(String leaveId, String status) async {
    await _firestore.collection('leaves').doc(leaveId).update({'status': status});
  }

  // Attendance Logic
  Stream<List<UserModel>> getStudentsForAttendance(String branch, int semester) {
    return _firestore.collection('users')
        .where('role', isEqualTo: 'student')
        .where('branch', isEqualTo: branch)
        .where('semester', isEqualTo: semester)
        .snapshots().map((snap) => snap.docs.map((doc) => UserModel.fromMap(doc.data(), doc.id)).toList());
  }

  Stream<List<UserModel>> getStudentsByBatch(String batchName) {
    return _firestore.collection('users')
        .where('role', isEqualTo: 'student')
        .where('batch', isEqualTo: batchName)
        .snapshots().map((snap) => snap.docs.map((doc) => UserModel.fromMap(doc.data(), doc.id)).toList());
  }

  Stream<List<UserModel>> getStudentsBySemester(int semester) {
    return _firestore.collection('users')
        .where('role', isEqualTo: 'student')
        .where('semester', isEqualTo: semester)
        .snapshots().map((snap) => snap.docs.map((doc) => UserModel.fromMap(doc.data(), doc.id)).toList());
  }

  Stream<List<UserModel>> getStudentsByCoordinator(String coordinatorId) {
    return _firestore.collection('batches')
        .where('coordinatorId', isEqualTo: coordinatorId)
        .snapshots()
        .asyncMap((batchSnap) async {
          List<String> batchNames = batchSnap.docs.map((doc) => doc['fullName'] as String).toList();
          if (batchNames.isEmpty) return [];
          
          QuerySnapshot studentSnap = await _firestore.collection('users')
              .where('role', isEqualTo: 'student')
              .where('batch', whereIn: batchNames)
              .get();
          
          return studentSnap.docs.map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
        });
  }

  Future<void> submitAttendance({
    required String branch,
    required int semester,
    required String subject,
    required DateTime date,
    required List<String> presentUids,
    List<String>? absentUids,
  }) async {
    String dateStr = "${date.year}-${date.month}-${date.day}";
    await _firestore.collection('attendance').add({
      'branchId': branch,
      'semester': semester,
      'subject': subject,
      'date': Timestamp.fromDate(date),
      'dateString': dateStr,
      'presentStudents': presentUids,
      'absentStudents': absentUids ?? [],
      'teacherId': _auth.currentUser?.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getStudentAttendance(String studentUid, String branchId, int semester) {
    return _firestore.collection('attendance')
        .where('branchId', isEqualTo: branchId)
        .where('semester', isEqualTo: semester)
        .snapshots();
  }

  Future<void> addHoliday({required DateTime date, required String title, String? branchId}) async {
    await _firestore.collection('holidays').add({
      'date': Timestamp.fromDate(date),
      'title': title,
      'branchId': branchId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Timetable
  Stream<DocumentSnapshot> getTimetable(String branch, int semester, String day) {
    return _firestore.collection('timetables').doc('${branch}_${semester}_$day').snapshots();
  }

  Future<void> setTimetable(String branch, int semester, String day, List<Map<String, dynamic>> slots) async {
    await _firestore.collection('timetables').doc('${branch}_${semester}_$day').set({
      'branch': branch,
      'semester': semester,
      'day': day,
      'slots': slots,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Assignments
  Future<void> uploadAssignment(Map<String, dynamic> assignmentData) async {
    await _firestore.collection('assignments').add(assignmentData);
  }

  // ... other methods ...
  Stream<QuerySnapshot> getAllHolidays() => _firestore.collection('holidays').orderBy('date').snapshots();
  Stream<QuerySnapshot> getSubjects(String branch, int semester) => _firestore.collection('subjects').where('branch', isEqualTo: branch).where('semester', isEqualTo: semester).snapshots();
  Future<void> addSubject(String branch, int semester, String subjectName) async => await _firestore.collection('subjects').add({'branch': branch, 'semester': semester, 'name': subjectName, 'createdAt': FieldValue.serverTimestamp()});
  Stream<QuerySnapshot> getBranches() => _firestore.collection('branches').orderBy('createdAt', descending: true).snapshots();
  Stream<QuerySnapshot> getAllBatches() => _firestore.collection('batches').orderBy('fullName').snapshots();
  Stream<QuerySnapshot> getBatchesByBranch(String branchId) => _firestore.collection('batches').where('branchId', isEqualTo: branchId).snapshots();
  Stream<List<UserModel>> getAllUsers() => _firestore.collection('users').snapshots().map((snap) => snap.docs.map((doc) => UserModel.fromMap(doc.data(), doc.id)).toList());
  Stream<List<UserModel>> getTeachers() => _firestore.collection('users').where('role', isEqualTo: 'teacher').snapshots().map((snap) => snap.docs.map((doc) => UserModel.fromMap(doc.data(), doc.id)).toList());
  Future<void> updateProfile(UserModel user) async => await _firestore.collection('users').doc(user.uid).update(user.toMap());
  Future<void> signOut() => _auth.signOut();
  Stream<QuerySnapshot> getPendingRequests() => _firestore.collection('requests').where('status', isEqualTo: 'pending').orderBy('createdAt', descending: true).snapshots();
  Future<void> approveRequest(String requestId, String email) async { await _auth.sendPasswordResetEmail(email: email.trim()); await _firestore.collection('requests').doc(requestId).update({'status': 'completed'}); }
}
