import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../models/user_model.dart';
import '../models/payment_config_model.dart';
import '../services/error_handler.dart';

class StudentExamFeeScreen extends StatefulWidget {
  final UserModel student;
  const StudentExamFeeScreen({super.key, required this.student});

  @override
  State<StudentExamFeeScreen> createState() => _StudentExamFeeScreenState();
}

class _StudentExamFeeScreenState extends State<StudentExamFeeScreen> {
  double? _examFee;
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
      final feeDoc = await FirebaseFirestore.instance.collection('settings').doc('exam_fees').get();
      if (feeDoc.exists) {
        final data = feeDoc.data()!;
        final sem = widget.student.semester.toString();
        if (data.containsKey(sem)) {
          _examFee = double.tryParse(data[sem].toString());
        }
      }

      // Load Payment Config
      final configDoc = await FirebaseFirestore.instance.collection('settings').doc('payment_config').get();
      if (configDoc.exists) {
        _paymentConfig = PaymentConfig.fromFirestore(configDoc.data()!);
      }
    } catch (e) {
      if (mounted) AppErrorHandler.showError(context, e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    LoadingOverlay.show(context);
    try {
      await FirebaseFirestore.instance.collection('fee_payments').add({
        'studentId': widget.student.uid,
        'studentName': widget.student.fullName,
        'amount': _examFee,
        'semester': widget.student.semester,
        'paymentId': response.paymentId,
        'orderId': response.orderId,
        'signature': response.signature,
        'type': 'exam_fee',
        'status': 'Success',
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      if (!mounted) return;
      AppErrorHandler.showSuccess(context, "Exam Fee Payment Successful!");
      Navigator.pop(context);
    } catch (e) {
      if (mounted) AppErrorHandler.showError(context, e);
    } finally {
      if (mounted) LoadingOverlay.hide(context);
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (mounted) AppErrorHandler.showError(context, "Payment Failed: ${response.message}");
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (mounted) AppErrorHandler.showSuccess(context, "External Wallet Selected: ${response.walletName}");
  }

  void _handlePayment() {
    if (_paymentConfig == null || _paymentConfig!.razorpayKey.isEmpty) {
      AppErrorHandler.showError(context, "Payment gateway not configured correctly.");
      return;
    }

    if (_paymentConfig!.activeGateway != 'Razorpay') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Currently ${_paymentConfig!.activeGateway} is active. Razorpay logic is being triggered.")),
      );
    }

    var options = {
      'key': _paymentConfig!.razorpayKey,
      'amount': (_examFee! * 100).toInt(),
      'name': 'College Management System',
      'description': 'Exam Fee - Semester ${widget.student.semester}',
      'prefill': {
        'contact': widget.student.phone ?? '',
        'email': widget.student.email,
      },
      'external': {
        'wallets': ['paytm']
      }
    }
;
    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint("Error opening Razorpay: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // ignore: unused_local_variable
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text("Examination Fee"),
        backgroundColor: Colors.deepOrange,
        foregroundColor: Colors.white,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.deepOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.deepOrange.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Semester", style: TextStyle(fontSize: 16, color: Colors.blueGrey)),
                          Text("${widget.student.semester}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Fee Type", style: TextStyle(fontSize: 16, color: Colors.blueGrey)),
                          const Text("Regular Exam Fee", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                        ],
                      ),
                      const Divider(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Total Amount", style: TextStyle(fontSize: 16, color: Colors.blueGrey)),
                          Text(
                            _examFee != null ? "₹ $_examFee" : "Not Set",
                            style: const TextStyle(
                              fontSize: 24, 
                              fontWeight: FontWeight.bold,
                              color: Colors.deepOrange
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blueGrey, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Please ensure you pay the exam fee before the deadline to generate your hall ticket.",
                        style: TextStyle(color: Colors.blueGrey, fontSize: 13),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                if (_examFee != null && _examFee! > 0)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _handlePayment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text("PAY EXAM FEE", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                  )
                else
                  const Center(
                    child: Text("Exam fee details not available for your semester yet."),
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
    );
  }
}
