import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
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
import '../semester_management_screen.dart';
import '../order_history_screen.dart';

import 'tabs/admin_enrollment_settings_tab.dart';

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
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;
    final theme = Theme.of(context);

    Widget content = CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: isDesktop ? 80.0 : 150.0,
          floating: false,
          pinned: true,
          elevation: 0,
          backgroundColor: theme.colorScheme.primary,
          flexibleSpace: FlexibleSpaceBar(
            centerTitle: true,
            titlePadding: EdgeInsets.only(
              left: isDesktop ? 60 : 16, 
              right: isDesktop ? 60 : 16, 
              bottom: 16
            ),
            title: Text(
              isDesktop ? "Control Center" : collegeName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 18,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -20,
                    top: -20,
                    child: Icon(Icons.admin_panel_settings, size: 100, color: Colors.white.withOpacity(0.1)),
                  ),
                ],
              ),
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            _buildNotificationBell(context, auth),
            IconButton(
              icon: const Icon(Icons.logout_rounded, color: Colors.white),
              onPressed: () async {
                await auth.signOut();
                if (context.mounted) {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        SliverToBoxAdapter(
          child: Center(
            child: Container(
              constraints: BoxConstraints(maxWidth: isDesktop ? 1200 : double.infinity),
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Welcome Admin!",
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Managing $collegeName",
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.black54),
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _buildAdminChip(theme, Icons.people_rounded, "Students", "users", collegeId, 'student', color: Colors.deepPurple, status: null),
                      _buildAdminChip(theme, Icons.school_rounded, "Faculty", "users", collegeId, 'teacher', color: Colors.indigo, status: null),
                      _buildAdminChip(theme, Icons.pending_actions_rounded, "Requests", "requests", collegeId, null, color: Colors.orange, status: 'pending'),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Text(
                    "Management Console", 
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: EdgeInsets.symmetric(horizontal: isDesktop ? (size.width - 1200).clamp(20, double.infinity) / 2 + 20 : 16),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isDesktop ? 4 : 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: isDesktop ? 1.1 : 1.0,
            ),
            delegate: SliverChildListDelegate([
              _ModernAdminCard(
                title: "Add Users",
                subtitle: "Registration",
                icon: Icons.person_add_alt_1_rounded,
                color: Colors.blue,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminAddUserTab(collegeId: collegeId, collegeName: collegeName))),
              ),
              _ModernAdminCard(
                title: "Migration",
                subtitle: "Transfers",
                icon: Icons.sync_rounded,
                color: Colors.teal,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminMigrationTab(collegeId: collegeId))),
              ),
              _ModernAdminCard(
                title: "Branches",
                subtitle: "Departments",
                icon: Icons.account_tree_rounded,
                color: Colors.indigo,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminBranchesTab(collegeId: collegeId))),
              ),
              _ModernAdminCard(
                title: "Batches",
                subtitle: "Year Groups",
                icon: Icons.grid_view_rounded,
                color: Colors.orange,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminBatchesTab(collegeId: collegeId))),
              ),
              _ModernAdminCard(
                title: "Library",
                subtitle: "Records",
                icon: Icons.local_library_rounded,
                color: Colors.brown,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LibraryManagementScreen(collegeId: collegeId))),
              ),
              _ModernAdminCard(
                title: "Fees",
                subtitle: "Collection",
                icon: Icons.account_balance_wallet_rounded,
                color: Colors.green,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminFeesTab())),
              ),
              _ModernAdminCard(
                title: "Subjects",
                subtitle: "Curriculum",
                icon: Icons.book_rounded,
                color: Colors.cyan,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminSubjectsTab(collegeId: collegeId))),
              ),
              _ModernAdminCard(
                title: "Examination",
                subtitle: "Results",
                icon: Icons.assignment_ind_rounded,
                color: Colors.purple,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminExaminationTab(collegeId: collegeId))),
              ),
              _ModernAdminCard(
                title: "Users List",
                subtitle: "Directory",
                icon: Icons.groups_rounded,
                color: Colors.blueGrey,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminUsersListTab(collegeId: collegeId))),
              ),
              _ModernAdminCard(
                title: "Electives",
                subtitle: "Window",
                icon: Icons.event_note_rounded,
                color: Colors.pink,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SemesterManagementScreen(collegeId: collegeId))),
              ),
              _ModernAdminCard(
                title: "Unassigned",
                subtitle: "Verification",
                icon: Icons.warning_amber_rounded,
                color: Colors.red,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminUnassignedTab(collegeId: collegeId))),
              ),
              _ModernAdminCard(
                title: "Requests",
                subtitle: "Approval",
                icon: Icons.notifications_active_rounded,
                color: Colors.amber,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminRequestsTab(collegeId: collegeId))),
              ),
              _ModernAdminCard(
                title: "Enrollment",
                subtitle: "ID Settings",
                icon: Icons.app_registration_rounded,
                color: Colors.deepOrange,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AdminEnrollmentSettingsTab(collegeId: collegeId))),
              ),
            ]),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: isDesktop 
          ? Row(
              children: [
                NavigationRail(
                  extended: size.width > 1200,
                  destinations: const [
                    NavigationRailDestination(icon: Icon(Icons.dashboard_rounded), label: Text('Dashboard')),
                    NavigationRailDestination(icon: Icon(Icons.settings_suggest_outlined), label: Text('Settings')),
                    NavigationRailDestination(icon: Icon(Icons.history_rounded), label: Text('Transactions')),
                  ],
                  selectedIndex: 0,
                  onDestinationSelected: (index) {
                    if (index == 1) Navigator.push(context, MaterialPageRoute(builder: (_) => const PaymentSettingsScreen()));
                    if (index == 2) Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderHistoryScreen()));
                  },
                ),
                Expanded(child: content),
              ],
            )
          : content,
    );
  }

  Widget _buildAdminChip(ThemeData theme, IconData icon, String label, String collection, String collegeId, String? role, {Color? color, Object? status}) {
    Color mainColor = color ?? theme.colorScheme.primary;
    Query query = FirebaseFirestore.instance.collection(collection).where('collegeId', isEqualTo: collegeId);
    if (role != null) query = query.where('role', isEqualTo: role);
    if (status != null) query = query.where('status', isEqualTo: status);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        String count = snapshot.hasData ? snapshot.data!.docs.length.toString() : "...";
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: mainColor.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: mainColor.withOpacity(0.1)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: mainColor),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  "$label: $count", 
                  style: TextStyle(color: mainColor, fontWeight: FontWeight.w600, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildNotificationBell(BuildContext context, AuthService auth) {
    return StreamBuilder<QuerySnapshot>(
      stream: auth.getPendingRequestsByCollege(collegeId),
      builder: (context, snapshot) {
        int pendingCount = snapshot.hasData ? snapshot.data!.docs.length : 0;

        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
              onPressed: () {
                if (pendingCount > 0) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AdminRequestsTab(collegeId: collegeId)),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("No pending requests"), duration: Duration(seconds: 1)),
                  );
                }
              },
            ),
            if (pendingCount > 0)
              Positioned(
                right: 12,
                top: 12,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    pendingCount > 9 ? "9+" : pendingCount.toString(),
                    style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ModernAdminCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ModernAdminCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, height: 1.2),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              subtitle,
              style: TextStyle(color: Colors.grey[500], fontSize: 10),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
