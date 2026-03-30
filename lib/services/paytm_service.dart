import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PaytmService {
  String? _mid;

  Future<void> _loadConfig() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('settings').doc('payment_config').get();
      if (doc.exists) {
        _mid = doc.data()?['paytm_mid'];
      }
    } catch (e) {
      debugPrint('Error loading Paytm config: $e');
    }
  }

  /// Initiates Paytm Payment
  Future<void> startPayment({
    required BuildContext context,
    required String amount,
    required String orderId,
    required String customerId,
    required Function(Map<String, dynamic>) onPaymentResult,
  }) async {
    if (_mid == null) {
      await _loadConfig();
    }

    if (!context.mounted) return;

    if (_mid == null || _mid!.isEmpty) {
      debugPrint('Paytm MID not found');
      return;
    }

    final String paytmUrl = "https://securegw-stage.paytm.in/theia/api/v1/showPaymentPage?mid=$_mid&orderId=$orderId";

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaytmWebViewPage(
          url: paytmUrl,
          orderId: orderId,
          onResult: (result) {
            Navigator.pop(context);
            onPaymentResult(result);
          },
        ),
      ),
    );
  }
}

class PaytmWebViewPage extends StatefulWidget {
  final String url;
  final String orderId;
  final Function(Map<String, dynamic>) onResult;

  const PaytmWebViewPage({super.key, required this.url, required this.orderId, required this.onResult});

  @override
  State<PaytmWebViewPage> createState() => _PaytmWebViewPageState();
}

class _PaytmWebViewPageState extends State<PaytmWebViewPage> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (url.contains("paytmCallback")) {
              widget.onResult({"status": "check_backend", "orderId": widget.orderId});
            }
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Paytm Secure Payment"),
        backgroundColor: const Color(0xFF00BAF2), // Paytm Blue
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
