import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'canteen_screen.dart';
import 'order_management_screen.dart';
import 'profile_screen.dart';

class RetailerHomeScreen extends StatelessWidget {
  const RetailerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Canteen Admin"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await authService.signOut();
              if (context.mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Welcome, Retailer!",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text(
              "Manage your canteen and orders from here.",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildMenuCard(
                    context,
                    "Manage Menu",
                    Icons.restaurant_menu,
                    Colors.orange,
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CanteenScreen())),
                  ),
                  _buildMenuCard(
                    context,
                    "Orders",
                    Icons.list_alt,
                    Colors.blue,
                    () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderManagementScreen())),
                  ),
                  _buildMenuCard(
                    context,
                    "My Profile",
                    Icons.person,
                    Colors.green,
                    () async {
                       // We need to fetch user model or use current user
                       final users = await authService.getAllUsers().first;
                       final currentUser = users.firstWhere((u) => u.uid == authService.currentUser?.uid);
                       if (context.mounted) {
                         Navigator.push(context, MaterialPageRoute(builder: (_) => ProfileScreen(user: currentUser)));
                       }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context, String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 48, color: color),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }
}
