import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/payment_config_model.dart';

class PaymentSettingsScreen extends StatefulWidget {
  const PaymentSettingsScreen({super.key});

  @override
  State<PaymentSettingsScreen> createState() => _PaymentSettingsScreenState();
}

class _PaymentSettingsScreenState extends State<PaymentSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  String _selectedGateway = 'Razorpay';

  final TextEditingController _razorpayController = TextEditingController();
  final TextEditingController _paytmMidController = TextEditingController();
  final TextEditingController _paytmMkeyController = TextEditingController();
  final TextEditingController _sbiMerchantIdController = TextEditingController();
  final TextEditingController _sbiWorkingKeyController = TextEditingController();
  final TextEditingController _sbiBaseUrlController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('settings').doc('payment_config').get();
      if (doc.exists) {
        final config = PaymentConfig.fromFirestore(doc.data()!);
        setState(() {
          _razorpayController.text = config.razorpayKey;
          _paytmMidController.text = config.paytmMid;
          _paytmMkeyController.text = config.paytmMkey;
          _sbiMerchantIdController.text = config.sbiMerchantId;
          _sbiWorkingKeyController.text = config.sbiWorkingKey;
          _sbiBaseUrlController.text = config.sbiBaseUrl;
          _selectedGateway = config.activeGateway;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading settings: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final config = PaymentConfig(
        razorpayKey: _razorpayController.text.trim(),
        paytmMid: _paytmMidController.text.trim(),
        paytmMkey: _paytmMkeyController.text.trim(),
        sbiMerchantId: _sbiMerchantIdController.text.trim(),
        sbiWorkingKey: _sbiWorkingKeyController.text.trim(),
        sbiBaseUrl: _sbiBaseUrlController.text.trim(),
        activeGateway: _selectedGateway,
      );

      await FirebaseFirestore.instance
          .collection('settings')
          .doc('payment_config')
          .set(config.toFirestore());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment settings updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving settings: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Configuration'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Select Active Payment Gateway",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.indigo),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      value: _selectedGateway,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      items: ['Razorpay', 'Paytm', 'SBI ePay']
                          .map((gateway) => DropdownMenuItem(
                                value: gateway,
                                child: Text(gateway),
                              ))
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedGateway = val!;
                        });
                      },
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 24),

                    if (_selectedGateway == 'Razorpay') ...[
                      _buildSectionTitle('Razorpay Settings'),
                      _buildTextField(_razorpayController, 'API Key'),
                    ],

                    if (_selectedGateway == 'Paytm') ...[
                      _buildSectionTitle('Paytm Settings'),
                      _buildTextField(_paytmMidController, 'Merchant ID (MID)'),
                      _buildTextField(_paytmMkeyController, 'Merchant Key (MKey)'),
                    ],

                    if (_selectedGateway == 'SBI ePay') ...[
                      _buildSectionTitle('SBI ePay Settings'),
                      _buildTextField(_sbiMerchantIdController, 'Merchant ID'),
                      _buildTextField(_sbiWorkingKeyController, 'Working Key'),
                      _buildTextField(_sbiBaseUrlController, 'Base URL (Test/Live)'),
                    ],
                    
                    const SizedBox(height: 40),
                    
                    SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: _saveSettings,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('SAVE CONFIGURATION', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueGrey),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        validator: (value) => value == null || value.isEmpty ? 'Required' : null,
      ),
    );
  }
}
