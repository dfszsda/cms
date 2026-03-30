import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../models/user_model.dart';
import '../models/payment_config_model.dart';

class StudentFeeScreen extends StatefulWidget {
  final UserModel student;
  const StudentFeeScreen({super.key, required this.student});

  @override
  State<StudentFeeScreen> createState() => _StudentFeeScreenState();
}

class _StudentFeeScreenState extends State<StudentFeeScreen> {
  double? _collegeFee;
  bool _isLoading = true;
  late Razorpay _razorpay;
  PaymentConfig? _paymentConfig;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
    _loadData();
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      // Load Fee
      final feeDoc = await FirebaseFirestore.instance.collection('settings').doc('college_fees').get();
      if (feeDoc.exists) {
        final data = feeDoc.data()!;
        final sem = widget.student.semester.toString();
        if (data.containsKey(sem)) {
          _collegeFee = double.tryParse(data[sem].toString());
        }
      }

      // Load Payment Config
      final configDoc = await FirebaseFirestore.instance.collection('settings').doc('payment_config').get();
      if (configDoc.exists) {
        _paymentConfig = PaymentConfig.fromFirestore(configDoc.data()!);
      }
    } catch (e) {
      debugPrint("Error loading data: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    // Save payment details to Firestore
    try {
      await FirebaseFirestore.instance.collection('fee_payments').add({
        'studentId': widget.student.uid,
        'studentName': widget.student.fullName,
        'amount': _collegeFee,
        'semester': widget.student.semester,
        'paymentId': response.paymentId,
        'orderId': response.orderId,
        'signature': response.signature,
        'type': 'college_fee',
        'status': 'Success',
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Payment Successful! Fee record updated.")),
        );
        Navigator.pop(context); // Go back after success
      }
    } catch (e) {
      debugPrint("Error saving payment: $e");
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Payment Failed: ${response.message}")),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("External Wallet Selected: ${response.walletName}")),
    );
  }

  void _handlePayment() {
    if (_paymentConfig == null || _paymentConfig!.razorpayKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Payment gateway not configured correctly.")),
      );
      return;
    }

    if (_paymentConfig!.activeGateway != 'Razorpay') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Currently ${_paymentConfig!.activeGateway} is active. Only Razorpay is supported in this version.")),
      );
      return;
    }

    var options = {
      'key': _paymentConfig!.razorpayKey,
      'amount': (_collegeFee! * 100).toInt(), // Amount in paise
      'name': 'College Management System',
      'description': 'College Fee - Semester ${widget.student.semester}',
      'prefill': {
        'contact': widget.student.phone ?? '',
        'email': widget.student.email,
      },
      'external': {
        'wallets': ['paytm']
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint("Error opening Razorpay: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Fees"),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("Semester", style: TextStyle(fontSize: 16, color: Colors.grey)),
                            Text("${widget.student.semester}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const Divider(height: 30),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text("College Fee", style: TextStyle(fontSize: 16, color: Colors.grey)),
                            Text(
                              _collegeFee != null ? "₹ $_collegeFee" : "Not Set",
                              style: TextStyle(
                                fontSize: 24, 
                                fontWeight: FontWeight.bold,
                                color: theme.colorScheme.primary
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  "Fee status: UNPAID", 
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16)
                ),
                const Spacer(),
                if (_collegeFee != null && _collegeFee! > 0)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _handlePayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("PAY COLLEGE FEE", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  )
                else
                  const Center(
                    child: Text("Fee details not available for your semester yet."),
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
    );
  }
}
