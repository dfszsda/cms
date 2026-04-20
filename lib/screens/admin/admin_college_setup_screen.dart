import 'package:flutter/material.dart';
import '../../models/college_model.dart';
import '../../services/auth_service.dart';
import '../college_info_screen.dart';
import 'admin_dashboard_screen.dart';
import '../login_screen.dart';

class AdminCollegeSetupScreen extends StatefulWidget {
  const AdminCollegeSetupScreen({super.key});

  @override
  State<AdminCollegeSetupScreen> createState() => _AdminCollegeSetupScreenState();
}

class _AdminCollegeSetupScreenState extends State<AdminCollegeSetupScreen> {
  final _auth = AuthService();
  String _searchQuery = "";

  @override
  Widget build(BuildContext context) {
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
                NavigationRailDestination(
                    icon: Icon(Icons.business_rounded), label: Text('Colleges')),
                NavigationRailDestination(
                    icon: Icon(Icons.settings_rounded), label: Text('Settings')),
              ],
              selectedIndex: 0,
              onDestinationSelected: (index) {},
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
                    title: const Text("College Administration", 
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
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
                        await _auth.signOut();
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
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Welcome Admin",
                                    style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                                  ),
                                  const Text("Manage your colleges here", style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                              ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => const CollegeInfoScreen(role: 'admin')),
                                  );
                                },
                                icon: const Icon(Icons.add_business_rounded),
                                label: const Text("ADD COLLEGE"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green[700],
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),
                          TextField(
                            onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
                            decoration: InputDecoration(
                              hintText: "Search College Name or City...",
                              prefixIcon: const Icon(Icons.search_rounded),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 30),
                          const Text("Colleges", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          const SizedBox(height: 15),
                        ],
                      ),
                    ),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: isDesktop ? (size.width - 1200).clamp(20, double.infinity) / 2 + 24 : 24),
                  sliver: StreamBuilder<List<CollegeModel>>(
                    stream: _auth.getColleges(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator()));
                      final colleges = snapshot.data!
                          .where((c) => c.name.toLowerCase().contains(_searchQuery) || c.city.toLowerCase().contains(_searchQuery))
                          .toList();

                      if (colleges.isEmpty) return const SliverToBoxAdapter(child: Center(child: Text("No colleges found matching your search.")));

                      return SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: isDesktop ? 3 : 1,
                          childAspectRatio: isDesktop ? 1.5 : 3.5,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final college = colleges[index];
                            return Card(
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                                side: BorderSide(color: Colors.grey[200]!),
                              ),
                              child: InkWell(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => AdminDashboardScreen(
                                        collegeId: college.id,
                                        collegeName: college.name,
                                      ),
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(15),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 30,
                                        backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                                        child: Icon(Icons.business_rounded, color: theme.colorScheme.primary, size: 30),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(college.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                                            Text("${college.city}, ${college.university}", style: const TextStyle(fontSize: 12, color: Colors.grey), maxLines: 2, overflow: TextOverflow.ellipsis),
                                          ],
                                        ),
                                      ),
                                      const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                          childCount: colleges.length,
                        ),
                      );
                    },
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
}
