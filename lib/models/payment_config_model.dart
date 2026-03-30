class PaymentConfig {
  final String razorpayKey;
  final String paytmMid;
  final String paytmMkey;
  final String sbiMerchantId;
  final String sbiWorkingKey;
  final String sbiBaseUrl;
  final String activeGateway;

  PaymentConfig({
    required this.razorpayKey,
    required this.paytmMid,
    required this.paytmMkey,
    required this.sbiMerchantId,
    required this.sbiWorkingKey,
    this.sbiBaseUrl = "https://test.sbiepay.sbi/payonline/index",
    this.activeGateway = 'Razorpay',
  });

  factory PaymentConfig.fromFirestore(Map<String, dynamic> data) {
    return PaymentConfig(
      razorpayKey: data['razorpay_key'] ?? '',
      paytmMid: data['paytm_mid'] ?? '',
      paytmMkey: data['paytm_mkey'] ?? '',
      sbiMerchantId: data['sbi_merchant_id'] ?? '',
      sbiWorkingKey: data['sbi_working_key'] ?? '',
      sbiBaseUrl: data['sbi_base_url'] ?? "https://test.sbiepay.sbi/payonline/index",
      activeGateway: data['active_gateway'] ?? 'Razorpay',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'razorpay_key': razorpayKey,
      'paytm_mid': paytmMid,
      'paytm_mkey': paytmMkey,
      'sbi_merchant_id': sbiMerchantId,
      'sbi_working_key': sbiWorkingKey,
      'sbi_base_url': sbiBaseUrl,
      'active_gateway': activeGateway,
    };
  }
}
