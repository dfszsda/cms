import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

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
      // Consider using a logger or a more robust error handling mechanism in production
      if (kDebugMode) {
        print("SignIn Error: $e");
      }
    }
    return null;
  }

  Future<void> signUp(String fullName, String email, String password, String role) async {
    try {
      UserCredential cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await _firestore.collection('users').doc(cred.user!.uid).set({
        'fullName': fullName,
        'email': email,
        'role': role,
        'profileComplete': false,
      });
    } catch (e) {
      if (kDebugMode) {
        print("SignUp Error: $e");
      }
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

  Future<void> changePassword(String newPassword) async {
    await _auth.currentUser?.updatePassword(newPassword);
  }

  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> signOut() => _auth.signOut();
}
