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

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Row(
        children: [
          if (isDesktop)
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
          Expanded(
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: isDesktop ? 80.0 : 120.0,
                  floating: false,
                  pinned: true,
                  backgroundColor: theme.colorScheme.primary,
                  flexibleSpace: FlexibleSpaceBar(
                    title: Text(isDesktop ? "Control Center" : collegeName, 
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    background: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
                        ),
                      ),
                    ),
                  ),
                  actions: [
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
                            style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text("Managing $collegeName", style: const TextStyle(color: Colors.grey)),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              _buildAdminChip(theme, Icons.people_rounded, "Total Students", "users", collegeId, 'student'),
                              _buildAdminChip(theme, Icons.school_rounded, "Faculty", "users", collegeId, 'teacher'),
                              _buildAdminChip(theme, Icons.pending_actions_rounded, "Requests", "requests", collegeId, null, color: Colors.orange),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Text("Management Console", style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: isDesktop ? (size.width - 1200).clamp(20, double.infinity) / 2 + 20 : 20),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isDesktop ? 4 : 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 1.1,
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
                    ]),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminChip(ThemeData theme, IconData icon, String label, String collection, String collegeId, String? role, {Color? color}) {
    Color mainColor = color ?? theme.colorScheme.primary;
    Query query = FirebaseFirestore.instance.collection(collection).where('collegeId', isEqualTo: collegeId);
    if (role != null) query = query.where('role', isEqualTo: role);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        String count = snapshot.hasData ? snapshot.data!.docs.length.toString() : "...";
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: mainColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: mainColor),
              const SizedBox(width: 6),
              Text("$label: $count", style: TextStyle(color: mainColor, fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
        );
      }
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
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            Text(
              subtitle,
              style: TextStyle(color: Colors.grey[500], fontSize: 11),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
