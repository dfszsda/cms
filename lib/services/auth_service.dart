// ignore_for_file: unnecessary_cast

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';
import '../models/leave_model.dart';
import '../models/exam_form_model.dart';
import '../models/exam_timetable_model.dart';
import '../models/ufm_model.dart';
import '../models/college_model.dart';

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
        UserModel user = UserModel.fromMap(doc.data() as Map<String, dynamic>, cred.user!.uid);
        
        // Check if UFM ban has expired
        if (user.isUfmBanned && user.ufmBanUntil != null) {
          if (DateTime.now().isAfter(user.ufmBanUntil!)) {
            // Ban expired, auto-resolve and promote semester
            await _firestore.collection('users').doc(user.uid).update({
              'isUfmBanned': false,
              'ufmBanUntil': null,
              'semester': (user.semester ?? 1) + 1,
            });
            user.isUfmBanned = false;
            user.ufmBanUntil = null;
            user.semester = (user.semester ?? 1) + 1;
          }
        }
        return user;
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
    // Try to find user to get name and collegeId
    String fullName = 'User';
    String? collegeId;
    
    final userSnap = await _firestore.collection('users')
        .where('email', isEqualTo: email.trim())
        .limit(1)
        .get();
        
    if (userSnap.docs.isNotEmpty) {
      final userData = userSnap.docs.first.data();
      fullName = userData['fullName'] ?? 'User';
      collegeId = userData['collegeId'];
    }

    await _firestore.collection('requests').add({
      'email': email.trim(),
      'fullName': fullName,
      'collegeId': collegeId,
      'type': type,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // User Management
  Future<void> signUp(String fullName, String email, String password, String role, {String? collegeId}) async {
    UserCredential cred = await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
    Map<String, dynamic> userData = {
      'fullName': fullName,
      'email': email,
      'role': role,
      'password': password,
      'profileComplete': false,
      'firstLogin': true,
      'isUfmBanned': false,
      'ufmBanUntil': null,
      'collegeId': collegeId,
    };
    if (role == 'student') {
      userData['semester'] = 1;
    }
    await _firestore.collection('users').doc(cred.user!.uid).set(userData);
  }

  Future<void> signUpUser({
    required String fullName,
    required String email,
    required String password,
    required String role,
    String? branch,
    String? batch,
    String? collegeId,
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
      'isUfmBanned': false,
      'ufmBanUntil': null,
      'collegeId': collegeId,
    };
    if (role == 'student') {
      userData['semester'] = 1;
      userData['batch'] = batch;
    }
    await _firestore.collection('users').doc(cred.user!.uid).set(userData);
  }

  // Multi-college Logic
  Future<void> updateTeacherCollege(String uid, String newCollegeId) async {
    await _firestore.collection('users').doc(uid).update({'collegeId': newCollegeId});
  }

  // UFM Management (Scoped to College)
  Future<void> reportUfm(UfmModel ufm) async {
    await _firestore.collection('ufm_cases').add(ufm.toMap());
  }

  Stream<List<UfmModel>> getPendingUfmCases({String? collegeId}) {
    Query query = _firestore.collection('ufm_cases').where('status', isEqualTo: 'pending');
    if (collegeId != null) query = query.where('collegeId', isEqualTo: collegeId);
    
    return query.snapshots().map((snap) => snap.docs.map((doc) => UfmModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList());
  }

  Stream<List<UfmModel>> getAllUfmCases({String? collegeId}) {
    Query query = _firestore.collection('ufm_cases');
    if (collegeId != null) query = query.where('collegeId', isEqualTo: collegeId);
    
    return query.orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => UfmModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList());
  }

  Future<void> confirmUfm(String caseId, String studentId) async {
    final banDuration = const Duration(days: 365);
    final banUntil = DateTime.now().add(banDuration);

    WriteBatch batch = _firestore.batch();
    
    // Update Case
    batch.update(_firestore.collection('ufm_cases').doc(caseId), {
      'status': 'confirmed',
    });

    // Update Student
    batch.update(_firestore.collection('users').doc(studentId), {
      'isUfmBanned': true,
      'ufmBanUntil': Timestamp.fromDate(banUntil),
    });

    await batch.commit();
  }

  Future<void> resolveUfm(String caseId, String studentId, bool promoteSemester) async {
    WriteBatch batch = _firestore.batch();

    // Update Case
    batch.update(_firestore.collection('ufm_cases').doc(caseId), {
      'status': 'resolved',
      'resolvedAt': FieldValue.serverTimestamp(),
    });

    // Update Student
    Map<String, dynamic> updates = {
      'isUfmBanned': false,
      'ufmBanUntil': null,
    };

    if (promoteSemester) {
      DocumentSnapshot userDoc = await _firestore.collection('users').doc(studentId).get();
      Map<String, dynamic>? data = userDoc.data() as Map<String, dynamic>?;
      int currentSem = data?['semester'] ?? 1;
      updates['semester'] = currentSem + 1;
    }

    batch.update(_firestore.collection('users').doc(studentId), updates);

    await batch.commit();
  }

  // Branch & Batch (Scoped to College)
  Future<void> addBranch(String id, String name, String collegeId) async {
    await _firestore.collection('branches').doc('${collegeId}_$id'.toUpperCase()).set({
      'name': name,
      'branchId': id.toUpperCase(),
      'collegeId': collegeId,
      'batchCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> createBatch(String branchId, String batchLetter, int year, String collegeId, {String? coordinatorId}) async {
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
      
      Map<String, dynamic>? data = branchSnap.data() as Map<String, dynamic>?;
      int currentCount = data?['batchCount'] ?? 0;
      if (currentCount >= 20) throw "Maximum 20 batches (5 classes) allowed per branch";
      
      int nextBatchNum = currentCount + 1;
      int classNum = (currentCount / 4).floor() + 1;
      
      String branchCode = data?['branchId'] ?? '';
      String fullName = "1$branchCode$classNum-${batchLetter.toUpperCase()}-$year";
      
      transaction.set(_firestore.collection('batches').doc(), {
        'branchId': branchId,
        'collegeId': collegeId,
        'batchLetter': batchLetter.toUpperCase(),
        'fullName': fullName,
        'year': year,
        'classNum': classNum,
        'studentCount': 0,
        'coordinatorId': coordinatorId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      transaction.update(branchRef, {'batchCount': nextBatchNum});
    });
  }

  Stream<QuerySnapshot> getBranches({String? collegeId}) {
    Query query = _firestore.collection('branches');
    if (collegeId != null) query = query.where('collegeId', isEqualTo: collegeId);
    return query.orderBy('createdAt', descending: true).snapshots();
  }

  Stream<QuerySnapshot> getBatchesByBranch(String branchId, {String? collegeId}) {
    Query query = _firestore.collection('batches').where('branchId', isEqualTo: branchId);
    if (collegeId != null) query = query.where('collegeId', isEqualTo: collegeId);
    return query.snapshots();
  }

  Stream<QuerySnapshot> getAllBatches({String? collegeId}) {
    Query query = _firestore.collection('batches');
    if (collegeId != null) query = query.where('collegeId', isEqualTo: collegeId);
    return query.snapshots();
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

  // Attendance Logic (Scoped)
  Stream<List<UserModel>> getStudentsForAttendance(String branch, int semester, String collegeId) {
    return _firestore.collection('users')
        .where('role', isEqualTo: 'student')
        .where('branch', isEqualTo: branch)
        .where('semester', isEqualTo: semester)
        .where('collegeId', isEqualTo: collegeId)
        .snapshots().map((snap) => snap.docs.map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList());
  }

  Stream<List<UserModel>> getStudentsByBatch(String batchName, {String? collegeId}) {
    Query query = _firestore.collection('users')
        .where('role', isEqualTo: 'student')
        .where('batch', isEqualTo: batchName);
    if (collegeId != null) query = query.where('collegeId', isEqualTo: collegeId);
    
    return query.snapshots().map((snap) => snap.docs.map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList());
  }

  Stream<List<UserModel>> getStudentsBySemester(int semester, {String? collegeId}) {
    Query query = _firestore.collection('users')
        .where('role', isEqualTo: 'student')
        .where('semester', isEqualTo: semester);
    if (collegeId != null) query = query.where('collegeId', isEqualTo: collegeId);

    return query.snapshots().map((snap) => snap.docs.map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList());
  }

  Stream<List<UserModel>> getStudentsByCoordinator(String coordinatorId) {
    return _firestore.collection('batches')
        .where('coordinatorId', isEqualTo: coordinatorId)
        .snapshots()
        .asyncMap((batchSnap) async {
          List<String> batchNames = batchSnap.docs.map((doc) => (doc.data() as Map<String, dynamic>)['fullName'] as String).toList();
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
    required String collegeId,
    List<String>? absentUids,
  }) async {
    String dateStr = "${date.year}-${date.month}-${date.day}";
    await _firestore.collection('attendance').add({
      'branchId': branch,
      'semester': semester,
      'subject': subject,
      'collegeId': collegeId,
      'date': Timestamp.fromDate(date),
      'dateString': dateStr,
      'presentStudents': presentUids,
      'absentStudents': absentUids ?? [],
      'teacherId': _auth.currentUser?.uid,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getStudentAttendance(String studentUid, String branchId, int semester, {String? collegeId}) {
    Query query = _firestore.collection('attendance')
        .where('branchId', isEqualTo: branchId)
        .where('semester', isEqualTo: semester);
    if (collegeId != null) query = query.where('collegeId', isEqualTo: collegeId);
    
    return query.snapshots();
  }

  // Holiday Management
  Future<void> addHoliday({required DateTime date, required String title, required String branchId, required String collegeId}) async {
    await _firestore.collection('holidays').add({
      'date': Timestamp.fromDate(date),
      'title': title,
      'branchId': branchId,
      'collegeId': collegeId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getAllHolidays({String? collegeId}) {
    Query query = _firestore.collection('holidays').orderBy('date');
    if (collegeId != null) query = query.where('collegeId', isEqualTo: collegeId);
    return query.snapshots();
  }

  // Timetable
  Stream<DocumentSnapshot> getTimetable(String branch, int semester, String day, {String? collegeId}) {
    // Unique ID for scoped timetable
    String id = '${branch}_${semester}_$day';
    if (collegeId != null) id = '${collegeId}_$id';
    return _firestore.collection('timetables').doc(id).snapshots();
  }

  Future<void> setTimetable(String branch, int semester, String day, List<Map<String, dynamic>> slots, String collegeId) async {
    String id = '${collegeId}_${branch}_${semester}_$day';
    await _firestore.collection('timetables').doc(id).set({
      'branch': branch,
      'semester': semester,
      'day': day,
      'collegeId': collegeId,
      'slots': slots,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Subject Management
  Future<void> addSubject(String branch, int semester, String name, String collegeId) async {
    await _firestore.collection('subjects').add({
      'branch': branch,
      'semester': semester,
      'name': name,
      'collegeId': collegeId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getSubjects(String branch, int semester, {String? collegeId}) {
    Query query = _firestore.collection('subjects').where('branch', isEqualTo: branch).where('semester', isEqualTo: semester);
    if (collegeId != null) query = query.where('collegeId', isEqualTo: collegeId);
    return query.snapshots();
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

  // Examination Management
  Future<void> createOrUpdateExamForm(ExamFormModel form) async {
    if (form.id == null) {
      await _firestore.collection('exam_forms').add(form.toMap());
    } else {
      await _firestore.collection('exam_forms').doc(form.id).update(form.toMap());
    }
  }

  Future<void> updateExamFormStatus(String formId, String status, {String? reason}) async {
    Map<String, dynamic> updates = {'status': status};
    if (reason != null) updates['rejectionReason'] = reason;
    await _firestore.collection('exam_forms').doc(formId).update(updates);
  }

  Stream<ExamFormModel?> getStudentExamForm(String studentId) {
    return _firestore.collection('exam_forms')
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map((snap) => snap.docs.isEmpty ? null : ExamFormModel.fromMap(snap.docs.first.data() as Map<String, dynamic>, snap.docs.first.id));
  }

  // Exam Timetable
  Stream<ExamTimetableModel?> getExamTimetable(String branchId, int semester, {String? collegeId}) {
    String id = '${branchId}_$semester';
    if (collegeId != null) id = '${collegeId}_$id';
    return _firestore.collection('exam_timetables')
        .doc(id)
        .snapshots()
        .map((doc) => doc.exists ? ExamTimetableModel.fromMap(doc.data() as Map<String, dynamic>, doc.id) : null);
  }

  Future<void> setExamTimetable(ExamTimetableModel timetable, String collegeId) async {
    String id = '${collegeId}_${timetable.branchId}_${timetable.semester}';
    await _firestore.collection('exam_timetables')
        .doc(id)
        .set(timetable.toMap()..['collegeId'] = collegeId);
  }

  // Assignment Management
  Future<void> uploadAssignment(Map<String, dynamic> data) async {
    await _firestore.collection('assignments').add(data);
  }

  // College Management
  Future<void> addCollege(CollegeModel college) async {
    await _firestore.collection('colleges').add(college.toMap());
  }

  Future<void> updateCollege(CollegeModel college) async {
    await _firestore.collection('colleges').doc(college.id).update(college.toMap());
  }

  Future<void> deleteCollege(String id) async {
    await _firestore.collection('colleges').doc(id).delete();
  }

  Stream<List<CollegeModel>> getColleges() {
    return _firestore.collection('colleges').snapshots().map((snap) =>
        snap.docs.map((doc) => CollegeModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList());
  }

  // --- MIGRATION TOOL LOGIC ---
  Future<int> getOrphanCount(String collectionName) async {
    final snap = await _firestore.collection(collectionName).where('collegeId', isNull: true).get();
    return snap.docs.length;
  }

  Future<void> migrateDataToCollege(String collectionName, String collegeId) async {
    final snap = await _firestore.collection(collectionName).where('collegeId', isNull: true).get();
    WriteBatch batch = _firestore.batch();
    for (var doc in snap.docs) {
      batch.update(doc.reference, {'collegeId': collegeId});
    }
    await batch.commit();
  }

  Stream<List<UserModel>> getAllUsers({String? collegeId}) {
    Query query = _firestore.collection('users');
    if (collegeId != null) query = query.where('collegeId', isEqualTo: collegeId);
    return query.snapshots().map((snap) => snap.docs.map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList());
  }

  Stream<List<UserModel>> getTeachers({String? collegeId}) {
    Query query = _firestore.collection('users').where('role', whereIn: ['teacher', 'coordinator']);
    if (collegeId != null) query = query.where('collegeId', isEqualTo: collegeId);
    return query.snapshots().map((snap) => snap.docs.map((doc) => UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList());
  }

  Stream<QuerySnapshot> getCoordinatorBatches(String teacherId) {
    return _firestore.collection('batches').where('coordinatorId', isEqualTo: teacherId).snapshots();
  }

  Future<void> updateProfile(UserModel user) async => await _firestore.collection('users').doc(user.uid).update(user.toMap());
  Future<void> signOut() => _auth.signOut();
  Stream<QuerySnapshot> getPendingRequests() => _firestore.collection('requests').where('status', isEqualTo: 'pending').orderBy('createdAt', descending: true).snapshots();
  Future<void> approveRequest(String requestId, String email) async { await _auth.sendPasswordResetEmail(email: email.trim()); await _firestore.collection('requests').doc(requestId).update({'status': 'completed'}); }

  Future<void> assignCoordinator(String batchId, String teacherId) async {
    try {
      QuerySnapshot teacherBatches = await _firestore.collection('batches')
          .where('coordinatorId', isEqualTo: teacherId)
          .get();
      
      if (teacherBatches.docs.length >= 2) {
        throw "This teacher is already a coordinator for 2 batches.";
      }

      await _firestore.collection('batches').doc(batchId).set({
        'coordinatorId': teacherId,
      }, SetOptions(merge: true));

      DocumentSnapshot userDoc = await _firestore.collection('users').doc(teacherId).get();
      if (userDoc.exists) {
        Map<String, dynamic>? data = userDoc.data() as Map<String, dynamic>?;
        String currentRole = data?['role'] ?? 'teacher';
        if (currentRole == 'teacher') {
          await _firestore.collection('users').doc(teacherId).update({
            'role': 'coordinator',
          });
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> removeCoordinator(String batchId) async {
    await _firestore.collection('batches').doc(batchId).update({
      'coordinatorId': null,
    });
  }

  Future<void> updateTeacherBranch(String uid, String newBranch) async {
    await _firestore.collection('users').doc(uid).update({'branch': newBranch});
  }

  Stream<QuerySnapshot> getPendingRequestsByCollege(String? collegeId) {
    Query query = _firestore.collection('requests').where('status', isEqualTo: 'pending');
    if (collegeId != null) query = query.where('collegeId', isEqualTo: collegeId);
    return query.orderBy('createdAt', descending: true).snapshots();
  }
}
