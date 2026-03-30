import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/college_model.dart';
import '../services/auth_service.dart';

class CollegeInfoScreen extends StatefulWidget {
  final String role;
  final CollegeModel? college;
  final String? collegeId;
  const CollegeInfoScreen({super.key, required this.role, this.college, this.collegeId});

  @override
  State<CollegeInfoScreen> createState() => _CollegeInfoScreenState();
}

class _CollegeInfoScreenState extends State<CollegeInfoScreen> {
  final _auth = AuthService();
  late TextEditingController _nameCtrl;
  late TextEditingController _univCtrl;
  late TextEditingController _cityCtrl;
  late TextEditingController _distCtrl;
  late TextEditingController _weekCtrl;
  late TextEditingController _satCtrl;

  bool _isEditing = false;
  CollegeModel? _selectedCollege;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedCollege = widget.college;
    if (_selectedCollege == null && widget.collegeId != null) {
      _loadCollegeData();
    }
    _initControllers();
  }

  Future<void> _loadCollegeData() async {
    setState(() => _isLoading = true);
    final doc = await FirebaseFirestore.instance.collection('colleges').doc(widget.collegeId).get();
    if (doc.exists) {
      setState(() {
        _selectedCollege = CollegeModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        _initControllers();
      });
    }
    setState(() => _isLoading = false);
  }

  void _initControllers() {
    _nameCtrl = TextEditingController(text: _selectedCollege?.name ?? "");
    _univCtrl = TextEditingController(text: _selectedCollege?.university ?? "");
    _cityCtrl = TextEditingController(text: _selectedCollege?.city ?? "");
    _distCtrl = TextEditingController(text: _selectedCollege?.district ?? "");
    _weekCtrl = TextEditingController(text: _selectedCollege?.workingHoursWeekday ?? "");
    _satCtrl = TextEditingController(text: _selectedCollege?.workingHoursSaturday ?? "");
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _univCtrl.dispose();
    _cityCtrl.dispose();
    _distCtrl.dispose();
    _weekCtrl.dispose();
    _satCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveCollege() async {
    if (_nameCtrl.text.isEmpty) return;

    final updatedCollege = CollegeModel(
      id: _selectedCollege?.id ?? "",
      name: _nameCtrl.text,
      university: _univCtrl.text,
      city: _cityCtrl.text,
      district: _distCtrl.text,
      workingHoursWeekday: _weekCtrl.text,
      workingHoursSaturday: _satCtrl.text,
    );

    if (_selectedCollege == null) {
      await _auth.addCollege(updatedCollege);
    } else {
      await _auth.updateCollege(updatedCollege);
    }

    setState(() {
      _isEditing = false;
      _selectedCollege = updatedCollege;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("College information updated!")));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    bool canEdit = widget.role == 'admin';

    return Scaffold(
      appBar: AppBar(
        title: const Text("College Information"),
        centerTitle: true,
        actions: [
          if (canEdit && _selectedCollege != null)
            IconButton(
              icon: Icon(_isEditing ? Icons.close : Icons.edit),
              onPressed: () => setState(() => _isEditing = !_isEditing),
            ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveCollege,
            )
        ],
      ),
      body: widget.role == 'admin' && _selectedCollege == null && !_isEditing
          ? _buildCollegeSelector()
          : _buildContent(),
      floatingActionButton: (widget.role == 'admin' && _selectedCollege == null && !_isEditing)
          ? FloatingActionButton(
              onPressed: () => setState(() {
                _isEditing = true;
                _selectedCollege = null;
                _initControllers();
              }),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Widget _buildCollegeSelector() {
    return StreamBuilder<List<CollegeModel>>(
      stream: _auth.getColleges(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        final colleges = snapshot.data!;
        if (colleges.isEmpty) return const Center(child: Text("No colleges added yet. Click + to add."));

        return ListView.builder(
          itemCount: colleges.length,
          itemBuilder: (context, index) {
            final col = colleges[index];
            return ListTile(
              title: Text(col.name),
              subtitle: Text(col.university),
              onTap: () => setState(() {
                _selectedCollege = col;
                _initControllers();
              }),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () async {
                  await _auth.deleteCollege(col.id);
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildContent() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // College Logo
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                Icons.school,
                size: 80,
                color: Colors.deepPurple,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // College Details Card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  _infoRow(Icons.business, "College Name", _nameCtrl, _isEditing),
                  const Divider(),
                  _infoRow(Icons.account_balance, "University", _univCtrl, _isEditing),
                  const Divider(),
                  _infoRow(Icons.location_city, "City", _cityCtrl, _isEditing),
                  const Divider(),
                  _infoRow(Icons.map, "District", _distCtrl, _isEditing),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Working Hours Card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.access_time, color: Colors.blue),
                      SizedBox(width: 10),
                      Text(
                        "College Working Hours",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _hourRow("Monday - Friday", _weekCtrl, _isEditing),
                  
                  // Show Saturday hours only for teachers or admin
                  if (widget.role == 'teacher' || widget.role == 'admin') ...[
                    const Divider(),
                    _hourRow("Saturday", _satCtrl, _isEditing),
                    if (!_isEditing)
                    const Padding(
                      padding: EdgeInsets.only(left: 8.0),
                      child: Text(
                        "[1st, 3rd Saturday (and 5th if any)]",
                        style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (_isEditing) ...[
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveCollege,
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              child: const Text("SAVE CHANGES"),
            ),
          ]
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, TextEditingController ctrl, bool isEditing) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.deepPurple, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                const SizedBox(height: 4),
                if (isEditing)
                  TextField(controller: ctrl, decoration: const InputDecoration(isDense: true))
                else
                  Text(ctrl.text.isEmpty ? "Not set" : ctrl.text,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _hourRow(String day, TextEditingController ctrl, bool isEditing) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(day, style: const TextStyle(fontSize: 15)),
          if (isEditing)
            SizedBox(width: 150, child: TextField(controller: ctrl, decoration: const InputDecoration(isDense: true)))
          else
            Text(ctrl.text.isEmpty ? "Not set" : ctrl.text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.blue)),
        ],
      ),
    );
  }
}
