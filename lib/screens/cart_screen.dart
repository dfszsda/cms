import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../services/canteen_service.dart';
import '../models/payment_config_model.dart';

class CartScreen extends StatefulWidget {
  final List<Map<String, dynamic>> cartItems;
  final String userName;
  final String userRole;
  final String collegeId;
  const CartScreen({
    super.key, 
    required this.cartItems, 
    required this.userName,
    required this.userRole,
    required this.collegeId,
  });

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CanteenService _canteenService = CanteenService();
  late Razorpay _razorpay;
  bool _isPlacingOrder = false;
  String _selectedPaymentMethod = 'Cash'; // Default to Cash
  PaymentConfig? _paymentConfig;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    _loadPaymentConfig();
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _loadPaymentConfig() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('settings').doc('payment_config').get();
      if (doc.exists) {
        setState(() {
          _paymentConfig = PaymentConfig.fromFirestore(doc.data()!);
        });
      }
    } catch (e) {
      debugPrint("Error loading payment config: $e");
    }
  }

  double _calculateTotal() {
    double total = 0;
    for (var item in widget.cartItems) {
      String priceString = item['price'].toString().replaceAll('₹', '');
      double price = double.tryParse(priceString) ?? 0;
      total += price * item['quantity'];
    }
    return total;
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    _finalizeOrder(
      paymentMethod: 'Online',
      paymentStatus: 'Completed',
      transactionId: response.paymentId,
    );
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() => _isPlacingOrder = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Payment Failed: ${response.message}")),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("External Wallet: ${response.walletName}")),
    );
  }

  Future<void> _startPayment() async {
    if (_paymentConfig == null || _paymentConfig!.razorpayKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Payment gateway not configured by admin.")),
      );
      setState(() => _isPlacingOrder = false);
      return;
    }

    double total = _calculateTotal();
    
    var options = {
      'key': _paymentConfig!.razorpayKey,
      'amount': (total * 100).toInt(), // Amount in paise
      'name': 'Canteen Order',
      'description': 'Payment for Food Items',
      'prefill': {
        'contact': '', // Could pass user's phone here if available
        'email': ''
      },
      'external': {
        'wallets': ['paytm']
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      setState(() => _isPlacingOrder = false);
      debugPrint('Error: $e');
    }
  }

  Future<void> _finalizeOrder({
    required String paymentMethod,
    required String paymentStatus,
    String? transactionId,
  }) async {
    try {
      await _canteenService.placeOrder(
        items: List<Map<String, dynamic>>.from(widget.cartItems),
        totalAmount: _calculateTotal(),
        userName: widget.userName,
        userRole: widget.userRole,
        paymentMethod: paymentMethod,
        paymentStatus: paymentStatus,
        transactionId: transactionId,
        collegeId: widget.collegeId,
      );
      if (mounted) {
        widget.cartItems.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Order placed successfully!")),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error placing order: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isPlacingOrder = false);
    }
  }

  Future<void> _placeOrder() async {
    if (_selectedPaymentMethod == 'Online') {
      setState(() => _isPlacingOrder = true);
      await _startPayment();
    } else {
      setState(() => _isPlacingOrder = true);
      await _finalizeOrder(
        paymentMethod: 'Cash',
        paymentStatus: 'Pending',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double totalAmount = _calculateTotal();

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Cart"),
        centerTitle: true,
      ),
      body: widget.cartItems.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  const Text("Your cart is empty!", style: TextStyle(fontSize: 18, color: Colors.grey)),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Go Back to Menu"),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: widget.cartItems.length,
                    itemBuilder: (context, index) {
                      final item = widget.cartItems[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.fastfood, color: Colors.orange),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    Text(item['price'].toString(), style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      setState(() {
                                        if (item['quantity'] > 1) {
                                          item['quantity']--;
                                        } else {
                                          widget.cartItems.removeAt(index);
                                        }
                                      });
                                    },
                                    icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                  ),
                                  Text("${item['quantity']}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  IconButton(
                                    onPressed: () {
                                      setState(() {
                                        item['quantity']++;
                                      });
                                    },
                                    icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 10, spreadRadius: 5)],
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Select Payment Method", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text("Cash"),
                              value: 'Cash',
                              groupValue: _selectedPaymentMethod,
                              onChanged: (value) => setState(() => _selectedPaymentMethod = value!),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          Expanded(
                            child: RadioListTile<String>(
                              title: const Text("Online"),
                              value: 'Online',
                              groupValue: _selectedPaymentMethod,
                              onChanged: (value) => setState(() => _selectedPaymentMethod = value!),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ],
                      ),
                      const Divider(),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Total Amount", style: TextStyle(fontSize: 18, color: Colors.grey)),
                          Text("₹$totalAmount", style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue)),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _isPlacingOrder ? null : _placeOrder,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(55),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        ),
                        child: _isPlacingOrder 
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text(_selectedPaymentMethod == 'Online' ? "PAY & PLACE ORDER" : "PLACE ORDER", 
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
