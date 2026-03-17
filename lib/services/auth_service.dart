import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Sign In
  Future<UserModel?> signIn(String email, String password) async {
    try {
      UserCredential cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      DocumentSnapshot doc = await _firestore.collection('users').doc(cred.user!.uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, cred.user!.uid);
      }
    } catch (e) {
      if (kDebugMode) print("SignIn Error: $e");
    }
    return null;
  }

  // Sign Up with Batch (For Admin)
  Future<void> signUpWithBatch(String fullName, String email, String password, String role, String? batchCode) async {
    try {
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      Map<String, dynamic> userData = {
        'fullName': fullName,
        'email': email,
        'role': role,
        'password': password,
        'profileComplete': false,
      };

      if (role == 'student') {
        userData['semester'] = 1;
        userData['batch'] = batchCode;
      }

      await _firestore.collection('users').doc(cred.user!.uid).set(userData);
    } catch (e) {
      if (kDebugMode) print("SignUp Error: $e");
      rethrow;
    }
  }

  // Original Sign Up
  Future<void> signUp(String fullName, String email, String password, String role) async {
    try {
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      Map<String, dynamic> userData = {
        'fullName': fullName,
        'email': email,
        'role': role,
        'password': password,
        'profileComplete': false,
      };

      if (role == 'student') {
        userData['semester'] = 1;
      }

      await _firestore.collection('users').doc(cred.user!.uid).set(userData);
    } catch (e) {
      if (kDebugMode) print("SignUp Error: $e");
    }
  }

  // Change Password
  Future<void> changePassword(String newPassword) async {
    try {
      await _auth.currentUser?.updatePassword(newPassword);
      await _firestore.collection('users').doc(_auth.currentUser?.uid).update({
        'password': newPassword,
      });
    } catch (e) {
      if (kDebugMode) print("Change Password Error: $e");
      rethrow;
    }
  }

  // Get All Users
  Stream<List<UserModel>> getAllUsers() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return UserModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  // Send Login Request from Login Screen
  Future<void> sendLoginRequest(String email, String type) async {
    var userQuery = await _firestore.collection('users').where('email', isEqualTo: email).limit(1).get();
    String fullName = "Unknown User";
    if (userQuery.docs.isNotEmpty) {
      fullName = userQuery.docs.first.get('fullName') ?? "Unknown User";
    }

    await _firestore.collection('requests').add({
      'email': email,
      'fullName': fullName,
      'requestType': type,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Admin gets pending requests
  Stream<QuerySnapshot> getPendingRequests() {
    return _firestore
        .collection('requests')
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Admin approves and sends reset email
  Future<void> approveRequest(String requestId, String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      await _firestore.collection('requests').doc(requestId).update({
        'status': 'completed',
      });
    } catch (e) {
      if (kDebugMode) print("Approve Error: $e");
      rethrow;
    }
  }

  Future<bool> isFirstTimeLogin(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('first_login_$uid') ?? true;
  }

  Future<void> markFirstLoginDone(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('first_login_$uid', false);
  }

  Future<void> updateProfile(UserModel user) async {
    await _firestore.collection('users').doc(user.uid).update(user.toMap());
  }

  Future<void> signOut() => _auth.signOut();
}
