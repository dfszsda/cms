// ignore_for_file: unnecessary_null_comparison

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';

class CanteenService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Canteen Items Management (Scoped to College)
  Stream<QuerySnapshot> getCanteenItems({String? collegeId}) {
    Query query = _firestore.collection('canteen_items');
    if (collegeId != null) {
      query = query.where('collegeId', isEqualTo: collegeId);
    }
    return query.snapshots();
  }

  Future<void> addCanteenItem(Map<String, dynamic> itemData, String collegeId) async {
    try {
      itemData['collegeId'] = collegeId;
      await _firestore.collection('canteen_items').add(itemData).timeout(const Duration(seconds: 10));
    } catch (e) {
      throw "Failed to add item: $e";
    }
  }

  Future<void> deleteCanteenItem(String itemId) async {
    try {
      await _firestore.collection('canteen_items').doc(itemId).delete().timeout(const Duration(seconds: 10));
    } catch (e) {
      throw "Failed to delete item: $e";
    }
  }

  Future<void> updateCanteenItem(String itemId, Map<String, dynamic> itemData) async {
    try {
      await _firestore.collection('canteen_items').doc(itemId).update(itemData).timeout(const Duration(seconds: 10));
    } catch (e) {
      throw "Failed to update item: $e";
    }
  }

  // Generate Unique Order ID (Short and readable)
  String _generateOrderId() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ123456789';
    Random rnd = Random();
    return String.fromCharCodes(Iterable.generate(
      6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
  }

  // Order Management (Scoped to College)
  Future<void> placeOrder({
    required List<Map<String, dynamic>> items,
    required double totalAmount,
    required String userName,
    required String userRole,
    required String paymentMethod,
    required String paymentStatus,
    required String collegeId,
    String? transactionId,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw "You must be logged in to place an order.";

      if (items.isEmpty) throw "Your cart is empty.";

      String orderId = _generateOrderId();

      await _firestore.collection('orders').add({
        'orderId': orderId,
        'userId': user.uid,
        'userName': userName,
        'userRole': userRole,
        'collegeId': collegeId,
        'items': items,
        'totalAmount': totalAmount,
        'status': 'pending',
        'paymentMethod': paymentMethod,
        'paymentStatus': paymentStatus,
        'transactionId': transactionId,
        'timestamp': FieldValue.serverTimestamp(),
      }).timeout(const Duration(seconds: 15));
    } catch (e) {
      throw "Failed to place order: $e";
    }
  }

  Stream<QuerySnapshot> getAllOrders({String? collegeId}) {
    Query query = _firestore.collection('orders');
    if (collegeId != null) {
      query = query.where('collegeId', isEqualTo: collegeId);
    }
    return query.orderBy('timestamp', descending: true).snapshots();
  }

  Stream<QuerySnapshot> getMyOrders({String? collegeId}) {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();
    Query query = _firestore.collection('orders')
        .where('userId', isEqualTo: user.uid);
    
    if (collegeId != null) {
      query = query.where('collegeId', isEqualTo: collegeId);
    }
    
    return query.orderBy('timestamp', descending: true).snapshots();
  }

  Future<void> updateOrderStatus(String docId, String status) async {
    await _firestore.collection('orders').doc(docId).update({
      'status': status,
    });
  }

  Future<void> markOrderAsDelivered(String docId) async {
    await _firestore.collection('orders').doc(docId).update({
      'status': 'delivered',
    });
  }

  Future<void> cancelOrder(String docId) async {
    await _firestore.collection('orders').doc(docId).update({
      'status': 'cancelled',
    });
  }

  // Sync function to fix old orders (Scoping added)
  Future<void> syncOrders() async {
    try {
      final ordersQuery = await _firestore.collection('orders').get();
      
      for (var doc in ordersQuery.docs) {
        Map<String, dynamic> data = doc.data();
        bool needsUpdate = false;
        Map<String, dynamic> updates = {};

        if (!data.containsKey('orderId') || data['orderId'] == null) {
          updates['orderId'] = _generateOrderId();
          needsUpdate = true;
        }

        if (!data.containsKey('paymentMethod')) {
          updates['paymentMethod'] = 'Cash';
          updates['paymentStatus'] = 'Pending';
          needsUpdate = true;
        }

        if (!data.containsKey('userName') || !data.containsKey('userRole') || !data.containsKey('collegeId')) {
          String userId = data['userId'];
          if (userId != null) {
            DocumentSnapshot userDoc = await _firestore.collection('users').doc(userId).get();
            if (userDoc.exists) {
              Map<String, dynamic> userData = userDoc.data() as Map<String, dynamic>;
              if (!data.containsKey('userName')) {
                updates['userName'] = userData['fullName'] ?? 'Unknown';
              }
              if (!data.containsKey('userRole')) {
                updates['userRole'] = userData['role'] ?? 'student';
              }
              if (!data.containsKey('collegeId')) {
                updates['collegeId'] = userData['collegeId'];
              }
              needsUpdate = true;
            }
          }
        }

        if (needsUpdate) {
          await _firestore.collection('orders').doc(doc.id).update(updates);
        }
      }
    } catch (e) {
      rethrow;
    }
  }
}
