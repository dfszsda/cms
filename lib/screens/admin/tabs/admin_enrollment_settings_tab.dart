import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/auth_service.dart';
import '../../../services/error_handler.dart';

class AdminEnrollmentSettingsTab extends StatefulWidget {
  final String collegeId;

  const AdminEnrollmentSettingsTab({super.key, required this.collegeId});

  @override
  State<AdminEnrollmentSettingsTab> createState() => _AdminEnrollmentSettingsTabState();
}

class _AdminEnrollmentSettingsTabState extends State<AdminEnrollmentSettingsTab> {
  final _auth = AuthService();
  String? _selectedBranchId;

  final _prefixCtrl = TextEditingController(text: "1230");
  final _branchCodeCtrl = TextEditingController(text: "01");
  final _collegeCodeCtrl = TextEditingController(text: "01");
  final _seqLenCtrl = TextEditingController(text: "3");
  bool _includeYear = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Enrollment Settings"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Configure Enrollment Number Format",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo),
            ),
            const SizedBox(height: 8),
            const Text(
              "Settings are per branch. Choose a branch to configure its format.",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            StreamBuilder<QuerySnapshot>(
              stream: _auth.getBranches(collegeId: widget.collegeId),
              builder: (context, snap) {
                if (!snap.hasData) return const LinearProgressIndicator();
                var branches = snap.data!.docs;
                return DropdownButtonFormField<String>(
                  value: _selectedBranchId,
                  decoration: InputDecoration(
                    labelText: "Select Branch",
                    prefixIcon: const Icon(Icons.account_tree_outlined),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: branches.map((doc) {
                    final name = doc.get('branchId') ?? doc.get('name') ?? doc.id;
                    return DropdownMenuItem(value: doc.id, child: Text(name.toString()));
                  }).toList(),
                  onChanged: (val) {
                    setState(() {
                      _selectedBranchId = val;
                    });
                    _loadConfig(val!);
                  },
                );
              },
            ),
            if (_selectedBranchId != null) ...[
              const SizedBox(height: 32),
              _buildConfigForm(),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _saveConfig,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("SAVE SETTINGS", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConfigForm() {
    return Column(
      children: [
        TextField(
          controller: _prefixCtrl,
          decoration: InputDecoration(
            labelText: "Prefix",
            hintText: "e.g., 1230",
            helperText: "Fixed digits at the start",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text("Include Current Year"),
          subtitle: Text("Current: ${DateTime.now().year}"),
          value: _includeYear,
          onChanged: (val) => setState(() => _includeYear = val),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey[300]!)),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _branchCodeCtrl,
                decoration: InputDecoration(
                  labelText: "Branch Code",
                  hintText: "e.g., 01",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: _collegeCodeCtrl,
                decoration: InputDecoration(
                  labelText: "College Code",
                  hintText: "e.g., 01",
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _seqLenCtrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: "Sequence Length",
            hintText: "e.g., 3 for 001, 002...",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        const SizedBox(height: 24),
        _buildPreview(),
      ],
    );
  }

  Widget _buildPreview() {
    String year = _includeYear ? DateTime.now().year.toString() : "";
    String seq = "1".padLeft(int.tryParse(_seqLenCtrl.text) ?? 3, '0');
    String preview = "${_prefixCtrl.text}$year${_branchCodeCtrl.text}${_collegeCodeCtrl.text}$seq";

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.indigo.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.indigo.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Format Preview:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.indigo)),
          const SizedBox(height: 4),
          Text(preview, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        ],
      ),
    );
  }

  Future<void> _loadConfig(String branchId) async {
    String configId = "${widget.collegeId}_$branchId";
    var doc = await FirebaseFirestore.instance.collection('enrollment_configs').doc(configId).get();
    if (doc.exists) {
      var data = doc.data()!;
      setState(() {
        _prefixCtrl.text = data['prefix'] ?? "1230";
        _branchCodeCtrl.text = data['branchCode'] ?? "01";
        _collegeCodeCtrl.text = data['collegeCode'] ?? "01";
        _seqLenCtrl.text = (data['sequenceLength'] ?? 3).toString();
        _includeYear = data['includeYear'] ?? true;
      });
    } else {
      setState(() {
        _prefixCtrl.text = "1230";
        if (branchId.contains('_')) {
           _branchCodeCtrl.text = branchId.split('_').last.substring(0, 2).padLeft(2, '0');
        } else {
          _branchCodeCtrl.text = "01";
        }
        _collegeCodeCtrl.text = "01";
        _seqLenCtrl.text = "3";
        _includeYear = true;
      });
    }
  }

  Future<void> _saveConfig() async {
    if (_selectedBranchId == null) return;
    
    LoadingOverlay.show(context);
    try {
      String configId = "${widget.collegeId}_$_selectedBranchId";
      await FirebaseFirestore.instance.collection('enrollment_configs').doc(configId).set({
        'prefix': _prefixCtrl.text,
        'branchCode': _branchCodeCtrl.text,
        'collegeCode': _collegeCodeCtrl.text,
        'sequenceLength': int.tryParse(_seqLenCtrl.text) ?? 3,
        'includeYear': _includeYear,
        'collegeId': widget.collegeId,
        'branchId': _selectedBranchId,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      if (mounted) AppErrorHandler.showSuccess(context, "Settings saved successfully!");
    } catch (e) {
      if (mounted) AppErrorHandler.showError(context, e);
    } finally {
      if (mounted) LoadingOverlay.hide(context);
    }
  }
}
