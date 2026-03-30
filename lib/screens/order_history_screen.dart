// ignore_for_file: unnecessary_to_list_in_spreads

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/canteen_service.dart';
import '../services/auth_service.dart';
import 'package:intl/intl.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final CanteenService canteenService = CanteenService();
  final AuthService authService = AuthService();
  String _userRole = 'student';

  @override
  void initState() {
    super.initState();
    _loadUserRole();
  }

  Future<void> _loadUserRole() async {
    try {
      final users = await authService.getAllUsers().first;
      final currentUser = users.firstWhere((u) => u.uid == authService.currentUser?.uid);
      if (mounted) {
        setState(() {
          _userRole = currentUser.role;
        });
      }
    } catch (e) {
      debugPrint("Error loading user role: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Order History"),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: (_userRole == 'retailer' || _userRole == 'admin')
            ? canteenService.getAllOrders()
            : canteenService.getMyOrders(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return const Center(
              child: Text("No orders found", style: TextStyle(color: Colors.grey, fontSize: 18)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final order = docs[index].data() as Map<String, dynamic>;
              final orderDocId = docs[index].id;
              final items = List<Map<String, dynamic>>.from(order['items'] ?? []);
              final status = order['status'] ?? 'pending';
              final paymentMethod = order['paymentMethod'] ?? 'Cash';
              final paymentStatus = order['paymentStatus'] ?? 'Pending';
              final transactionId = order['transactionId'];
              final Timestamp? timestamp = order['timestamp'] as Timestamp?;
              final formattedDate = timestamp != null 
                  ? DateFormat('dd MMM yyyy, hh:mm a').format(timestamp.toDate())
                  : 'N/A';

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Order #${order['orderId'] ?? orderDocId.substring(0, 6)}",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          _buildStatusChip(status),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Payment: $paymentMethod", style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          Text(paymentStatus, 
                            style: TextStyle(
                              fontSize: 12, 
                              fontWeight: FontWeight.bold,
                              color: paymentStatus == 'Completed' ? Colors.green : Colors.orange
                            )
                          ),
                        ],
                      ),
                      if (transactionId != null)
                        Text("Txn ID: $transactionId", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      const Divider(height: 24),
                      ...items.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("${item['name']} x ${item['quantity']}"),
                            Text("₹${(double.tryParse(item['price'].toString().replaceAll('₹', '')) ?? 0) * (item['quantity'] ?? 1)}"),
                          ],
                        ),
                      )).toList(),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(formattedDate, style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
                              if (_userRole == 'retailer' || _userRole == 'admin')
                                Text("By: ${order['userName'] ?? 'Unknown'}", style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                          Text(
                            "Total: ₹${order['totalAmount']}",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.blue),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'delivered':
        color = Colors.green;
        break;
      case 'confirmed':
        color = Colors.blue;
        break;
      case 'pending':
        color = Colors.orange;
        break;
      case 'cancelled':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}
