import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SbiEPayService {
  String? _merchantId;
  String? _workingKey;
  String _basePayUrl = "https://test.sbiepay.sbi/payonline/index";

  Future<void> _loadConfig() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('settings').doc('payment_config').get();
      if (doc.exists) {
        final data = doc.data()!;
        _merchantId = data['sbi_merchant_id'];
        _workingKey = data['sbi_working_key'];
        _basePayUrl = data['sbi_base_url'] ?? "https://test.sbiepay.sbi/payonline/index";
      }
    } catch (e) {
      debugPrint('Error loading SBI config: $e');
    }
  }

  /// Generates the Checksum for SBI ePay
  String _generateChecksum(Map<String, String> params) {
    String queryString = params.entries.map((e) => "${e.key}=${e.value}").join('|');
    var bytes = utf8.encode(queryString + (_workingKey ?? ''));
    return sha256.convert(bytes).toString().toUpperCase();
  }

  /// Opens the SBI Payment Gateway in a WebView
  Future<void> processPayment({
    required BuildContext context,
    required String amount,
    required String orderId,
    required String customerName,
    required Function(Map<String, dynamic>) onPaymentResult,
  }) async {
    if (_merchantId == null || _workingKey == null) {
      await _loadConfig();
    }

    if (!context.mounted) return;

    if (_merchantId == null || _workingKey == null) {
      debugPrint('SBI Merchant ID or Working Key not found');
      return;
    }

    final Map<String, String> paymentParams = {
      'merchantId': _merchantId!,
      'amount': amount,
      'orderId': orderId,
      'currency': 'INR',
      'returnUrl': 'https://your-app-callback.com/payment-response',
      'otherDetails': customerName,
    };

    String checksum = _generateChecksum(paymentParams);
    paymentParams['checksum'] = checksum;

    final String postData = paymentParams.entries
        .map((e) => "${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}")
        .join('&');

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SbiWebViewPage(
          baseUrl: _basePayUrl,
          postData: postData,
          onResult: (result) {
            Navigator.pop(context);
            onPaymentResult(result);
          },
        ),
      ),
    );
  }
}

class SbiWebViewPage extends StatefulWidget {
  final String baseUrl;
  final String postData;
  final Function(Map<String, dynamic>) onResult;

  const SbiWebViewPage({
    super.key,
    required this.baseUrl,
    required this.postData,
    required this.onResult,
  });

  @override
  State<SbiWebViewPage> createState() => _SbiWebViewPageState();
}

class _SbiWebViewPageState extends State<SbiWebViewPage> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (url.contains("payment-response")) {
              final uri = Uri.parse(url);
              widget.onResult(uri.queryParameters);
            }
          },
        ),
      )
      ..loadRequest(
        Uri.parse(widget.baseUrl),
        method: LoadRequestMethod.post,
        body: utf8.encode(widget.postData),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("SBI ePay Secure Payment"),
        backgroundColor: const Color(0xFF20409A),
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
