import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RazorpayService {
  late Razorpay _razorpay;
  String? _apiKey;

  Future<void> _loadConfig() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('settings').doc('payment_config').get();
      if (doc.exists) {
        _apiKey = doc.data()?['razorpay_key'];
      }
    } catch (e) {
      debugPrint('Error loading Razorpay config: $e');
    }
  }

  void initialize({
    required Function(PaymentSuccessResponse) onSuccess,
    required Function(PaymentFailureResponse) onFailure,
    required Function(ExternalWalletResponse) onExternalWallet,
  }) {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, onSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, onFailure);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, onExternalWallet);
  }

  Future<void> openCheckout({
    required double amount,
    required String contact,
    required String email,
    required String description,
  }) async {
    if (_apiKey == null) {
      await _loadConfig();
    }

    if (_apiKey == null || _apiKey!.isEmpty) {
      debugPrint('Razorpay API Key not found');
      return;
    }

    var options = {
      'key': _apiKey,
      'amount': (amount * 100).toInt(), // Amount in paise
      'name': 'CMS Payment',
      'description': description,
      'prefill': {
        'contact': contact,
        'email': email
      },
      'external': {
        'wallets': ['paytm']
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Error: $e');
    }
  }

  void dispose() {
    _razorpay.clear();
  }
}
