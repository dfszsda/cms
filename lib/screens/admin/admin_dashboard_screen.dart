import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../login_screen.dart';
import '../payment_settings_screen.dart';
import 'tabs/admin_add_user_tab.dart';
import 'tabs/admin_migration_tab.dart';
import 'tabs/admin_branches_tab.dart';
import 'tabs/admin_batches_tab.dart';
import 'tabs/admin_fees_tab.dart';
import 'tabs/admin_unassigned_tab.dart';
import 'tabs/admin_subjects_tab.dart';
import 'tabs/admin_examination_tab.dart';
import 'tabs/admin_users_list_tab.dart';
import 'tabs/admin_requests_tab.dart';
import '../library_management_screen.dart';
import '../college_info_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  final String collegeId;
  final String collegeName;

  const AdminDashboardScreen({
    super.key,
    required this.collegeId,
    required this.collegeName,
  });

  @override
  Widget build(BuildContext context) {
    final auth = AuthService();

    return Scaffold(
      appBar: AppBar(
        title: Text(collegeName),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_suggest_outlined),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentSettingsScreen())),
            tooltip: "Payment Settings",
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final navigator = Navigator.of(context);
              await auth.signOut();
              navigator.pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Management Console",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.indigo),
            ),
            const SizedBox(height: 8),
            Text(
              "Select a category to manage your institution",
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1,
              children: [
                _buildDashboardCard(
                  context,
                  "Add Users",
                  Icons.person_add_alt_1_rounded,
                  Colors.blue,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminAddUserTab(collegeId: collegeId, collegeName: collegeName))),
                ),
                _buildDashboardCard(
                  context,
                  "Manage College",
                  Icons.account_balance_rounded,
                  Colors.indigo,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => CollegeInfoScreen(role: 'admin', collegeId: collegeId))),
                ),
                _buildDashboardCard(
                  context,
                  "Migration",
                  Icons.sync_rounded,
                  Colors.teal,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminMigrationTab(collegeId: collegeId))),
                ),
                _buildDashboardCard(
                  context,
                  "Branches",
                  Icons.account_tree_rounded,
                  Colors.orange,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminBranchesTab(collegeId: collegeId))),
                ),
                _buildDashboardCard(
                  context,
                  "Batches",
                  Icons.grid_view_rounded,
                  Colors.deepPurple,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminBatchesTab(collegeId: collegeId))),
                ),
                _buildDashboardCard(
                  context,
                  "Library",
                  Icons.local_library_rounded,
                  Colors.brown,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => LibraryManagementScreen(collegeId: collegeId))),
                ),
                _buildDashboardCard(
                  context,
                  "Fees",
                  Icons.account_balance_wallet_rounded,
                  Colors.green,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminFeesTab())),
                ),
                _buildDashboardCard(
                  context,
                  "Unassigned",
                  Icons.warning_amber_rounded,
                  Colors.redAccent,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminUnassignedTab(collegeId: collegeId))),
                ),
                _buildDashboardCard(
                  context,
                  "Subjects",
                  Icons.book_rounded,
                  Colors.cyan,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminSubjectsTab(collegeId: collegeId))),
                ),
                _buildDashboardCard(
                  context,
                  "Examination",
                  Icons.assignment_ind_rounded,
                  Colors.purple,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminExaminationTab(collegeId: collegeId))),
                ),
                _buildDashboardCard(
                  context,
                  "Users List",
                  Icons.groups_rounded,
                  Colors.blueGrey,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminUsersListTab(collegeId: collegeId))),
                ),
                _buildDashboardCard(
                  context,
                  "Requests",
                  Icons.notifications_active_rounded,
                  Colors.amber[800]!,
                  () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminRequestsTab(collegeId: collegeId))),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardCard(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withOpacity(0.8), color],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: Colors.white),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
