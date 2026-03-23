import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../services/canteen_service.dart';

class OrderManagementScreen extends StatefulWidget {
  const OrderManagementScreen({super.key});

  @override
  State<OrderManagementScreen> createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends State<OrderManagementScreen> {
  final CanteenService _canteenService = CanteenService();
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Manage Orders"),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: "Search Order ID or Name...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _canteenService.getAllOrders(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No orders found."));
                }

                final orders = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final String orderId = (data['orderId'] ?? '').toString().toLowerCase();
                  final String userName = (data['userName'] ?? '').toString().toLowerCase();
                  final String query = _searchQuery.toLowerCase();
                  return orderId.contains(query) || userName.contains(query);
                }).toList();

                if (orders.isEmpty) return const Center(child: Text("No matching orders found."));

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    final orderData = order.data() as Map<String, dynamic>;
                    final List items = orderData['items'] ?? [];
                    final String status = orderData['status'] ?? 'pending';
                    final String orderId = orderData['orderId'] ?? 'N/A';
                    final Timestamp? timestamp = orderData['timestamp'] as Timestamp?;
                    final String dateStr = timestamp != null 
                        ? DateFormat('dd MMM, hh:mm a').format(timestamp.toDate()) 
                        : 'N/A';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 4,
                      child: ExpansionTile(
                        title: Text(
                          "ID: #$orderId",
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                        ),
                        subtitle: Text("From: ${orderData['userName']}\nTotal: ₹${orderData['totalAmount']} | $dateStr"),
                        trailing: _buildStatusChip(status),
                        children: [
                          const Divider(),
                          ...items.map((item) => ListTile(
                            title: Text(item['name']),
                            trailing: Text("x${item['quantity']}"),
                            subtitle: Text(item['price']),
                          )),
                          if (status == 'pending')
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                              child: Column(
                                children: [
                                  ElevatedButton(
                                    onPressed: () async {
                                      final messenger = ScaffoldMessenger.of(context);
                                      await _canteenService.markOrderAsDelivered(order.id);
                                      messenger.showSnackBar(
                                        const SnackBar(content: Text("Order marked as delivered")),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size.fromHeight(45),
                                    ),
                                    child: const Text("MARK AS DELIVERED"),
                                  ),
                                  const SizedBox(height: 8),
                                  OutlinedButton(
                                    onPressed: () => _showCancelDialog(context, order.id),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.red,
                                      side: const BorderSide(color: Colors.red),
                                      minimumSize: const Size.fromHeight(45),
                                    ),
                                    child: const Text("CANCEL ORDER"),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(BuildContext context, String docId) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text("Cancel Order"),
        content: const Text("Are you sure you want to cancel this order?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text("No")),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(dialogCtx);
              final messenger = ScaffoldMessenger.of(context);
              await _canteenService.cancelOrder(docId);
              if (mounted) {
                navigator.pop();
                messenger.showSnackBar(
                  const SnackBar(content: Text("Order cancelled successfully")),
                );
              }
            },
            child: const Text("Yes, Cancel", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    if (status == 'delivered') {
      color = Colors.green;
    } else if (status == 'cancelled') {
      color = Colors.red;
    } else {
      color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}
