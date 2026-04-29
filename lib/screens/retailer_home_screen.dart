import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'canteen_screen.dart';
import 'order_management_screen.dart';
import 'profile_screen.dart';
import 'order_history_screen.dart';

class RetailerHomeScreen extends StatelessWidget {
  const RetailerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 900;
    final theme = Theme.of(context);

    Widget content = CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: isDesktop ? 80.0 : 120.0,
          floating: false,
          pinned: true,
          elevation: 0,
          backgroundColor: theme.colorScheme.primary,
          flexibleSpace: FlexibleSpaceBar(
            title: const Text("Canteen Admin", 
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.orange[800]!, Colors.orange[500]!],
                ),
              ),
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout_rounded, color: Colors.white),
              onPressed: () async {
                await authService.signOut();
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
                    "Welcome, Retailer!",
                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const Text("Manage your canteen and orders", style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 24),
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
              childAspectRatio: isDesktop ? 1.1 : 1.0,
            ),
            delegate: SliverChildListDelegate([
              _ModernRetailerCard(
                title: "Manage Menu",
                subtitle: "Food Items",
                icon: Icons.restaurant_menu_rounded,
                color: Colors.orange,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CanteenScreen())),
              ),
              _ModernRetailerCard(
                title: "Live Orders",
                subtitle: "Pending & Active",
                icon: Icons.list_alt_rounded,
                color: Colors.blue,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderManagementScreen())),
              ),
              _ModernRetailerCard(
                title: "Sales History",
                subtitle: "Past Orders",
                icon: Icons.history_rounded,
                color: Colors.green,
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderHistoryScreen())),
              ),
              _ModernRetailerCard(
                title: "My Profile",
                subtitle: "Account Details",
                icon: Icons.person_rounded,
                color: Colors.purple,
                onTap: () async {
                  final users = await authService.getAllUsers().first;
                  final currentUser = users.firstWhere((u) => u.uid == authService.currentUser?.uid);
                  if (context.mounted) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(user: currentUser)));
                  }
                },
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
                    NavigationRailDestination(icon: Icon(Icons.history_rounded), label: Text('Orders')),
                    NavigationRailDestination(icon: Icon(Icons.person_outline_rounded), label: Text('Profile')),
                  ],
                  selectedIndex: 0,
                  onDestinationSelected: (index) async {
                    if (index == 1) Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderHistoryScreen()));
                    if (index == 2) {
                       final users = await authService.getAllUsers().first;
                       final currentUser = users.firstWhere((u) => u.uid == authService.currentUser?.uid);
                       if (context.mounted) {
                         Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(user: currentUser)));
                       }
                    }
                  },
                ),
                Expanded(child: content),
              ],
            )
          : content,
    );
  }
}

class _ModernRetailerCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ModernRetailerCard({
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
