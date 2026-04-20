import 'package:flutter/material.dart';
import '../models/ufm_model.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

class UfmDashboardScreen extends StatefulWidget {
  final UserModel? user;
  const UfmDashboardScreen({super.key, this.user});

  @override
  State<UfmDashboardScreen> createState() => _UfmDashboardScreenState();
}

class _UfmDashboardScreenState extends State<UfmDashboardScreen> {
  final _auth = AuthService();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          title: const Text("UFM Management", style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.red[700],
          foregroundColor: Colors.white,
          bottom: const TabBar(
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(text: "Pending Cases"),
              Tab(text: "All History"),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildCasesList(true),
            _buildCasesList(false),
          ],
        ),
      ),
    );
  }

  Widget _buildCasesList(bool onlyPending) {
    return StreamBuilder<List<UfmModel>>(
      stream: onlyPending ? _auth.getPendingUfmCases() : _auth.getAllUfmCases(),
      builder: (ctx, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.gavel_rounded, size: 80, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text("No UFM cases found", style: TextStyle(color: Colors.grey[600])),
              ],
            ),
          );
        }

        final cases = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: cases.length,
          itemBuilder: (itemCtx, index) {
            final ufmCase = cases[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: ExpansionTile(
                title: Text(ufmCase.studentName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("${ufmCase.subjectName} | Sem ${ufmCase.studentSemester}"),
                leading: CircleAvatar(
                  backgroundColor: _getStatusColor(ufmCase.status).withOpacity(0.1),
                  child: Icon(Icons.warning_rounded, color: _getStatusColor(ufmCase.status)),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _infoRow("Reported by", ufmCase.teacherName),
                        _infoRow("Branch", ufmCase.branchName),
                        _infoRow("Reason", ufmCase.reason),
                        _infoRow("Date", ufmCase.createdAt.toString().split('.')[0]),
                        const SizedBox(height: 16),
                        if (ufmCase.status == 'pending')
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => _confirmCase(ufmCase),
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                  child: const Text("Confirm & Ban (1yr)"),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => _resolveCase(itemCtx, ufmCase, false),
                                  child: const Text("Reject/Ignore"),
                                ),
                              ),
                            ],
                          )
                        else if (ufmCase.status == 'confirmed')
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () => _showResolveDialog(ufmCase),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                              child: const Text("Resolve & Unban Now"),
                            ),
                          ),
                      ],
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("$label: ", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'confirmed': return Colors.red;
      case 'resolved': return Colors.green;
      default: return Colors.grey;
    }
  }

  void _confirmCase(UfmModel ufm) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text("Confirm UFM?"),
        content: Text("This will ban ${ufm.studentName} for 1 year. The student will be failed in ${ufm.subjectName}."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text("Cancel")),
          ElevatedButton(
            onPressed: () async {
              await _auth.confirmUfm(ufm.id!, ufm.studentId);
              if (dialogCtx.mounted) {
                Navigator.pop(dialogCtx);
                ScaffoldMessenger.of(dialogCtx).showSnackBar(const SnackBar(content: Text("Student banned for 1 year")));
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }

  void _showResolveDialog(UfmModel ufm) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text("Resolve UFM?"),
        content: const Text("Do you want to promote the student to the next semester after unbanning?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text("Cancel")),
          TextButton(
            onPressed: () => _resolveCase(dialogCtx, ufm, false),
            child: const Text("Unban (Same Sem)"),
          ),
          ElevatedButton(
            onPressed: () => _resolveCase(dialogCtx, ufm, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
            child: const Text("Unban & Promote"),
          ),
        ],
      ),
    );
  }

  Future<void> _resolveCase(BuildContext ctx, UfmModel ufm, bool promote) async {
    await _auth.resolveUfm(ufm.id!, ufm.studentId, promote);
    if (!ctx.mounted) return;
    Navigator.pop(ctx);
    ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text("Case resolved. Student ${promote ? 'promoted' : 'unbanned'}.")));
  }
}
