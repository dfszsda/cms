import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/ufm_model.dart';
import '../services/auth_service.dart';

class StudentDetailScreen extends StatefulWidget {
  final UserModel student;
  final UserModel viewer; 
  final String batchName;

  const StudentDetailScreen({
    super.key,
    required this.student,
    required this.viewer,
    required this.batchName,
  });

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  final _auth = AuthService();
  late int _selectedSem;

  @override
  void initState() {
    super.initState();
    _selectedSem = widget.student.semester ?? 1;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    bool canEdit = widget.viewer.role == 'teacher' || widget.viewer.role == 'coordinator' || widget.viewer.role == 'admin';
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          _buildAppBar(theme),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.student.isUfmBanned) _buildUfmWarning(theme),
                  _buildQuickStats(theme),
                  const SizedBox(height: 24),
                  _buildDetailSection(theme),
                  const SizedBox(height: 24),
                  if (canEdit) ...[
                    _buildCoordinatorActions(theme),
                    const SizedBox(height: 16),
                    _buildUfmAction(theme),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUfmWarning(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.red),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "This student is currently banned due to UFM until ${widget.student.ufmBanUntil?.day}/${widget.student.ufmBanUntil?.month}/${widget.student.ufmBanUntil?.year}",
              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUfmAction(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _showUfmReportDialog(),
        icon: const Icon(Icons.report_problem_outlined, color: Colors.red),
        label: const Text("Report UFM Case", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.red),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  void _showUfmReportDialog() {
    final reasonCtrl = TextEditingController();
    final subjectCtrl = TextEditingController();
    
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text("Report UFM Case"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: subjectCtrl,
              decoration: const InputDecoration(labelText: "Subject Name"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              maxLines: 3,
              decoration: const InputDecoration(labelText: "Reason/Description of Unfair Means"),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              if (subjectCtrl.text.isEmpty || reasonCtrl.text.isEmpty) return;
              
              final ufm = UfmModel(
                studentId: widget.student.uid,
                studentName: widget.student.fullName,
                studentBranch: widget.student.branchName,
                studentSemester: widget.student.semester ?? 1,
                teacherId: widget.viewer.uid,
                teacherName: widget.viewer.fullName,
                subjectName: subjectCtrl.text,
                reason: reasonCtrl.text,
                status: 'pending',
                createdAt: DateTime.now(),
              );

              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(dialogCtx);

              await _auth.reportUfm(ufm);
              if (mounted) {
                navigator.pop();
                messenger.showSnackBar(const SnackBar(content: Text("UFM Case reported to coordinator")));
              }
            },
            child: const Text("Report Student"),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(ThemeData theme) {
    return SliverAppBar(
      expandedHeight: 250.0,
      pinned: true,
      stretch: true,
      backgroundColor: theme.colorScheme.primary,
      foregroundColor: Colors.white,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          widget.student.fullName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            shadows: [Shadow(color: Colors.black45, blurRadius: 10)],
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [theme.colorScheme.primary, theme.colorScheme.primary.withValues(alpha: 0.7)],
                ),
              ),
            ),
            Center(
              child: Hero(
                tag: 'student_profile_${widget.student.uid}',
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 10))],
                  ),
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: widget.student.profilePic != null ? NetworkImage(widget.student.profilePic!) : null,
                    child: widget.student.profilePic == null ? Icon(Icons.person, size: 70, color: theme.colorScheme.primary) : null,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickStats(ThemeData theme) {
    return Row(
      children: [
        _statItem("Semester", widget.student.semester?.toString() ?? 'N/A', Icons.layers_outlined, Colors.orange),
        const SizedBox(width: 12),
        _statItem("Batch", widget.student.batch ?? 'N/A', Icons.school_outlined, Colors.blue),
        const SizedBox(width: 12),
        _statItem("Role", "Student", Icons.person_outline, Colors.teal),
      ],
    );
  }

  Widget _statItem(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 11)),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Personal Information", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Column(
            children: [
              _detailRow(Icons.email_outlined, "Email Address", widget.student.email),
              _divider(),
              _detailRow(Icons.phone_outlined, "Phone Number", widget.student.phone ?? 'N/A'),
              _divider(),
              _detailRow(Icons.account_tree_outlined, "Department / Branch", widget.student.branchName),
              _divider(),
              _detailRow(Icons.location_on_outlined, "Residential Address", widget.student.address ?? 'N/A'),
              _divider(),
              _detailRow(Icons.cake_outlined, "Age", widget.student.age?.toString() ?? 'N/A'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.indigo.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: Colors.indigo, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Divider(height: 1, indent: 64, color: Colors.grey.withValues(alpha: 0.1));

  Widget _buildCoordinatorActions(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Coordinator Controls", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Colors.indigo[900]!, Colors.indigo[700]!], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [BoxShadow(color: Colors.indigo.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 8))],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.admin_panel_settings_outlined, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text("Management Tools", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
              const SizedBox(height: 20),
              const Text("Update Semester", style: TextStyle(color: Colors.white70, fontSize: 13)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.white24)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _selectedSem,
                    isExpanded: true,
                    dropdownColor: Colors.indigo[800],
                    icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    items: List.generate(8, (i) => i + 1).map((s) => DropdownMenuItem(value: s, child: Text("Semester $s"))).toList(),
                    onChanged: (val) => setState(() => _selectedSem = val!),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _updateIndividualSem(),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.indigo[900], padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                      child: const Text("Update Student", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _confirmBatchSemUpdate(),
                      style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white70), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                      child: const Text("Entire Batch", style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _updateIndividualSem() async {
    showDialog(context: context, barrierDismissible: false, builder: (ctx) => const Center(child: CircularProgressIndicator(color: Colors.white)));
    try {
      final messenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);
      await _auth.updateStudentSemester(widget.student.uid, _selectedSem);
      if (mounted) {
        navigator.pop();
        messenger.showSnackBar(SnackBar(content: Text("Semester updated for ${widget.student.fullName}"), backgroundColor: Colors.green, behavior: SnackBarBehavior.floating));
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to update semester")));
      }
    }
  }

  void _confirmBatchSemUpdate() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(children: [Icon(Icons.warning_amber_rounded, color: Colors.orange), SizedBox(width: 10), Text("Bulk Update")]),
        content: Text("This will update ALL students in \"${widget.batchName}\" to Semester $_selectedSem. This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(ctx);
              navigator.pop();
              showDialog(context: context, barrierDismissible: false, builder: (context) => const Center(child: CircularProgressIndicator()));
              
              final messenger = ScaffoldMessenger.of(context);
              final outerNavigator = Navigator.of(context);
              
              await _auth.updateBatchSemester(widget.batchName, _selectedSem);
              if (mounted) {
                outerNavigator.pop();
                messenger.showSnackBar(const SnackBar(content: Text("Batch semester updated successfully!"), backgroundColor: Colors.indigo, behavior: SnackBarBehavior.floating));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text("Update All"),
          ),
        ],
      ),
    );
  }
}
