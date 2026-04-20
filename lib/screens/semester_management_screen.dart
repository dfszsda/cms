import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../models/semester_config_model.dart';

class SemesterManagementScreen extends StatefulWidget {
  final String? collegeId;
  const SemesterManagementScreen({super.key, this.collegeId});

  @override
  State<SemesterManagementScreen> createState() => _SemesterManagementScreenState();
}

class _SemesterManagementScreenState extends State<SemesterManagementScreen> {
  final AuthService _auth = AuthService();
  String? _selectedBranchId;
  int _selectedSemester = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text("Semester & Electives Config"),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1E293B),
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildFilters(),
          const Divider(height: 1),
          Expanded(child: _buildBranchConfigList()),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: StreamBuilder<QuerySnapshot>(
              stream: _auth.getBranches(collegeId: widget.collegeId),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const LinearProgressIndicator();
                final branches = snapshot.data!.docs;
                return DropdownButtonFormField<String>(
                  value: _selectedBranchId,
                  decoration: const InputDecoration(
                    labelText: "Select Branch",
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: branches.map((b) {
                    final branchId = b.get('branchId') ?? b.id;
                    final displayName = branchId.toString().contains('_') 
                        ? branchId.toString().split('_').last 
                        : branchId;
                    return DropdownMenuItem(value: b.id, child: Text(displayName));
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedBranchId = val),
                );
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 1,
            child: DropdownButtonFormField<int>(
              value: _selectedSemester,
              decoration: const InputDecoration(
                labelText: "Semester",
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: List.generate(8, (i) => i + 1)
                  .map((s) => DropdownMenuItem(value: s, child: Text("Sem $s")))
                  .toList(),
              onChanged: (val) => setState(() => _selectedSemester = val!),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBranchConfigList() {
    if (_selectedBranchId == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_tree_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text("Please select a branch to configure window", style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }

    return StreamBuilder<SemesterConfigModel?>(
      stream: _auth.getSemesterConfig(widget.collegeId ?? '', _selectedBranchId!, _selectedSemester),
      builder: (context, snapshot) {
        final config = snapshot.data;
        
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.grey[200]!),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.indigo.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.date_range_rounded, color: Colors.indigo),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Elective Selection Window", 
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                              Text("Set the duration for student choice filling", 
                                  style: TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    if (config == null)
                      _buildNoConfigState()
                    else
                      _buildActiveConfigState(config),
                    
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => _showWindowSetupDialog(config),
                        icon: Icon(config == null ? Icons.add : Icons.edit),
                        label: Text(config == null ? "Set Window" : "Edit Window"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.indigo,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            _buildBatchUpdateSection(),
          ],
        );
      },
    );
  }

  Widget _buildNoConfigState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.1)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: Colors.red, size: 20),
          SizedBox(width: 12),
          Text("No window configured for this semester", 
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildActiveConfigState(SemesterConfigModel config) {
    bool isExpired = DateTime.now().isAfter(config.endDate);
    bool isNotStarted = DateTime.now().isBefore(config.startDate);
    bool isCurrentlyActive = config.isSelectionActive && !isExpired && !isNotStarted;

    return Column(
      children: [
        _buildInfoRow("Start Date", "${config.startDate.day}/${config.startDate.month}/${config.startDate.year}"),
        const SizedBox(height: 12),
        _buildInfoRow("End Date", "${config.endDate.day}/${config.endDate.month}/${config.endDate.year}"),
        const SizedBox(height: 12),
        _buildInfoRow(
          "Visibility Status", 
          config.isSelectionActive ? "Visible to Students" : "Hidden",
          valueColor: config.isSelectionActive ? Colors.green : Colors.red,
        ),
        const SizedBox(height: 12),
        _buildInfoRow(
          "Current Live Status", 
          isCurrentlyActive ? "ACTIVE NOW" : (isExpired ? "EXPIRED" : "SCHEDULED"),
          valueColor: isCurrentlyActive ? Colors.green : (isExpired ? Colors.red : Colors.orange),
          isBold: true,
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, {Color? valueColor, bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(value, style: TextStyle(
          fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
          color: valueColor ?? const Color(0xFF1E293B),
        )),
      ],
    );
  }

  Widget _buildBatchUpdateSection() {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Quick Batch Actions", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('batches')
                  .where('collegeId', isEqualTo: widget.collegeId)
                  .where('branchId', isEqualTo: _selectedBranchId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();
                final batches = snapshot.data!.docs;
                if (batches.isEmpty) return const Text("No batches found for this branch", style: TextStyle(fontSize: 12, color: Colors.grey));
                
                return Column(
                  children: batches.map((b) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(b['fullName'], style: const TextStyle(fontSize: 14)),
                    trailing: TextButton(
                      onPressed: () => _showBatchUpdateDialog(b['fullName']),
                      child: const Text("Promote Sem"),
                    ),
                  )).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showWindowSetupDialog(SemesterConfigModel? existingConfig) async {
    DateTimeRange? selectedRange = existingConfig != null 
        ? DateTimeRange(start: existingConfig.startDate, end: existingConfig.endDate)
        : null;
    bool isActive = existingConfig?.isSelectionActive ?? true;
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text("Setup Selection Window"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Configuring Sem $_selectedSemester for selected branch."),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: const Icon(Icons.date_range),
                label: Text(selectedRange == null 
                  ? "Select Timeline (Start - End)" 
                  : "${selectedRange!.start.day}/${selectedRange!.start.month} - ${selectedRange!.end.day}/${selectedRange!.end.month}"),
                onPressed: isSaving ? null : () async {
                  final range = await showDateRangePicker(
                    context: context,
                    initialDateRange: selectedRange,
                    firstDate: DateTime.now().subtract(const Duration(days: 30)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (range != null) setDialogState(() => selectedRange = range);
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text("Card Visibility", style: TextStyle(fontSize: 14)),
                subtitle: const Text("Should students see the choice card?", style: TextStyle(fontSize: 11)),
                value: isActive,
                onChanged: isSaving ? null : (val) => setDialogState(() => isActive = val),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(ctx), 
              child: const Text("Cancel")
            ),
            ElevatedButton(
              onPressed: (selectedRange == null || isSaving) ? null : () async {
                setDialogState(() => isSaving = true);
                try {
                  if (widget.collegeId == null || widget.collegeId!.isEmpty) {
                    throw "College ID is missing. Please re-login.";
                  }
                  
                  final config = SemesterConfigModel(
                    id: '',
                    collegeId: widget.collegeId!,
                    branchId: _selectedBranchId!,
                    semester: _selectedSemester,
                    startDate: selectedRange!.start,
                    endDate: selectedRange!.end,
                    isSelectionActive: isActive,
                  );

                  await _auth.setSemesterConfig(config);
                  
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Configuration saved successfully!"),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  debugPrint("Error saving config: $e");
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(
                        content: Text("Failed to save: $e"),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } finally {
                  if (ctx.mounted) setDialogState(() => isSaving = false);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
              ),
              child: isSaving 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Text("Save Config"),
            ),
          ],
        ),
      ),
    );
  }

  void _showBatchUpdateDialog(String batchName) {
    int? newSem;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text("Promote $batchName"),
        content: DropdownButtonFormField<int>(
          decoration: const InputDecoration(labelText: "Select New Semester"),
          items: List.generate(8, (i) => i + 1).map((s) => DropdownMenuItem(value: s, child: Text("Semester $s"))).toList(),
          onChanged: (val) => newSem = val,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              if (newSem != null) {
                final messenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(dialogContext);
                await _auth.updateBatchSemester(batchName, newSem!);
                if (dialogContext.mounted) navigator.pop();
                if (context.mounted) {
                  messenger.showSnackBar(SnackBar(content: Text("Batch $batchName updated to Sem $newSem")));
                }
              }
            },
            child: const Text("Update All"),
          ),
        ],
      ),
    );
  }
}
