import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/college_model.dart';
import '../models/leave_model.dart';
import '../services/auth_service.dart';
import '../services/error_handler.dart';
import 'login_screen.dart';
import 'profile_screen.dart';
import 'teachers_list_screen.dart';
import 'canteen_screen.dart';
import 'coming_soon_screen.dart';
import 'materials_screen.dart';
import 'attendance_screen.dart';
import 'teacher_assignments_screen.dart';
import 'timetable_screen.dart';
import 'todo_works_screen.dart';
import 'order_history_screen.dart';
import 'coordinator_leave_screen.dart';
import 'student_directory_screen.dart';
import 'ufm_dashboard_screen.dart';
import 'admin_result_management_screen.dart';
import 'college_info_screen.dart';

class TeacherHomeScreen extends StatefulWidget {
  const TeacherHomeScreen({super.key});

  @override
  State<TeacherHomeScreen> createState() => _TeacherHomeScreenState();
}

class _TeacherHomeScreenState extends State<TeacherHomeScreen> {
  final _auth = AuthService();
  UserModel? _currentUser;
  bool _isLoading = true;
  bool _isCoordinator = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) {
          final userData = UserModel.fromMap(doc.data()!, user.uid);
          
          final isCoordinatorRole = userData.role == 'coordinator';
          final batchSnap = await FirebaseFirestore.instance
              .collection('batches')
              .where('coordinatorId', isEqualTo: user.uid)
              .limit(1)
              .get();

          if (mounted) {
            setState(() {
              _currentUser = userData;
              _isCoordinator = isCoordinatorRole || batchSnap.docs.isNotEmpty;
              _isLoading = false;
            });
          }
        } else {
          if (mounted) setState(() => _isLoading = false);
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppErrorHandler.showError(context, e);
      }
    }
  }

  Future<void> _handleLogout() async {
    try {
      await _auth.signOut();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) AppErrorHandler.showError(context, e);
    }
  }

  Widget _buildNotificationBell() {
    if (_currentUser == null) return const SizedBox.shrink();

    // If Admin, show requests notification. If Coordinator, show leave requests.
    bool isAdmin = _currentUser?.role == 'admin';
    bool isCoordinator = _isCoordinator;

    if (!isAdmin && !isCoordinator) return const SizedBox.shrink();

    return StreamBuilder<int>(
      stream: isAdmin 
        ? _auth.getPendingRequestsByCollege(_currentUser?.collegeId).map((snap) => snap.docs.length)
        : _auth.getLeaveRequestsForCoordinator(_currentUser!.uid).map((list) => list.where((l) => l.status == 'pending').length),
      builder: (context, snapshot) {
        final pendingCount = snapshot.data ?? 0;

        return Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none_rounded, color: Colors.white),
              onPressed: () {
                if (pendingCount > 0) {
                  if (isAdmin) {
                    // Admin usually goes to Requests screen, but here we are in TeacherHomeScreen
                    // If the user is Admin but using TeacherHomeScreen, they might want to see requests.
                    // However, normally Admin uses AdminDashboardScreen.
                    // For now, let's keep it consistent.
                  } else if (isCoordinator) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => CoordinatorLeaveScreen(coordinator: _currentUser!)));
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("No new notifications"), duration: Duration(seconds: 1)),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;
    
    Widget content = CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: isDesktop ? 80.0 : 130.0,
          floating: false,
          pinned: true,
          elevation: 0,
          backgroundColor: theme.colorScheme.primary,
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: EdgeInsets.only(
              left: isDesktop ? 20 : 16,
              bottom: 16,
            ),
            title: Text(isDesktop ? "Teacher Portal" : "Teacher Portal", 
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 18)),
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [const Color(0xFF1E3A8A), theme.colorScheme.primary],
                ),
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -20,
                    top: -20,
                    child: Icon(Icons.school, size: 100, color: Colors.white.withOpacity(0.1)),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            _buildNotificationBell(),
            if (!isDesktop)
              IconButton(
                icon: const Icon(Icons.history_rounded, color: Colors.white),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderHistoryScreen())),
              ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.account_circle_outlined, color: Colors.white),
              onSelected: (value) {
                if (value == 'edit') {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(user: _currentUser!))).then((_) => _loadUserData());
                } else if (value == 'logout') {
                  _handleLogout();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text("Edit Profile")),
                const PopupMenuItem(value: 'logout', child: Text("Logout")),
              ],
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
                    "Welcome back, ${_currentUser?.fullName.split(' ')[0] ?? 'Professor'}",
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const Text("Academic & Examination Dashboard", style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 20),
                  
                  StreamBuilder<List<CollegeModel>>(
                    stream: _auth.getColleges(),
                    builder: (context, snapshot) {
                      if (snapshot.hasError) return const SizedBox.shrink();
                      if (snapshot.connectionState == ConnectionState.waiting) return const SizedBox.shrink();
                      if (!snapshot.hasData || snapshot.data!.isEmpty) return const SizedBox.shrink();
                      final college = snapshot.data!.first;
                      return InkWell(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CollegeInfoScreen(role: 'teacher', college: college))),
                        child: Card(
                          color: Colors.indigo[50],
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              children: [
                                const Icon(Icons.school, size: 40, color: Colors.indigo),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(college.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      Text(college.university, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                                    ],
                                  ),
                                ),
                                const Icon(Icons.arrow_forward_ios, size: 16),
                              ],
                            ),
                          ),
                        ),
                      );
                    }
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
              childAspectRatio: isDesktop ? 1.1 : 1.05,
            ),
            delegate: SliverChildListDelegate([
              if (_isCoordinator)
                _ModernTeacherCard(
                  title: "UFM Management",
                  icon: Icons.gavel_rounded,
                  color: Colors.red[700]!,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => UfmDashboardScreen(user: _currentUser!))),
                ),
              _ModernTeacherCard(
                title: "Attendance",
                icon: Icons.checklist_rounded,
                color: Colors.green,
                onTap: () {
                  if (_currentUser?.branch != null) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => AttendanceScreen(teacherBranch: _currentUser!.branch!, collegeId: _currentUser?.collegeId)));
                  }
                },
              ),
              if (_isCoordinator)
                _ModernTeacherCard(
                  title: "Manage Results",
                  icon: Icons.assessment_rounded,
                  color: Colors.blueAccent,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminResultManagementScreen())),
                ),
              if (_isCoordinator)
                _ModernTeacherCard(
                  title: "Leave Requests",
                  icon: Icons.assignment_turned_in_rounded,
                  color: Colors.deepPurple,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CoordinatorLeaveScreen(coordinator: _currentUser!))),
                ),
              _ModernTeacherCard(
                title: "Student Directory",
                icon: Icons.contact_page_rounded,
                color: Colors.teal,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => StudentDirectoryScreen(viewer: _currentUser!))),
              ),
              _ModernTeacherCard(
                title: "Timetable",
                icon: Icons.calendar_today_rounded,
                color: Colors.indigo,
                onTap: () {
                  if (_currentUser?.branch != null) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => TimetableScreen(userRole: 'teacher', userBranch: _currentUser!.branch)));
                  }
                },
              ),
              _ModernTeacherCard(
                title: "Assignments",
                icon: Icons.assignment_rounded,
                color: Colors.orange,
                onTap: () {
                  if (_currentUser?.branch != null) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => TeacherAssignmentsScreen(user: _currentUser!)));
                  }
                },
              ),
              _ModernTeacherCard(
                title: "Study Materials",
                icon: Icons.auto_stories_rounded,
                color: Colors.teal,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MaterialsScreen(role: 'teacher'))),
              ),
              _ModernTeacherCard(
                title: "Staff List",
                icon: Icons.people_outline_rounded,
                color: Colors.blueGrey,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TeachersListScreen())),
              ),
              _ModernTeacherCard(
                title: "Canteen",
                icon: Icons.restaurant_rounded,
                color: Colors.red,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CanteenScreen())),
              ),
            ]),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 30)),
      ],
    );

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _isLoading 
        ? AppErrorHandler.buildLoadingWidget()
        : isDesktop 
            ? Row(
                children: [
                  NavigationRail(
                    extended: size.width > 1200,
                    destinations: const [
                      NavigationRailDestination(icon: Icon(Icons.dashboard), label: Text('Dashboard')),
                      NavigationRailDestination(icon: Icon(Icons.history), label: Text('Orders')),
                      NavigationRailDestination(icon: Icon(Icons.person), label: Text('Profile')),
                    ],
                    selectedIndex: 0,
                    onDestinationSelected: (index) {
                      if (index == 1) Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderHistoryScreen()));
                      if (index == 2) Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(user: _currentUser!))).then((_) => _loadUserData());
                    },
                  ),
                  Expanded(child: content),
                ],
              )
            : content,
    );
  }
}

class _ModernTeacherCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ModernTeacherCard({required this.title, required this.icon, required this.color, required this.onTap});

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
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              title, 
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, height: 1.2), 
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
