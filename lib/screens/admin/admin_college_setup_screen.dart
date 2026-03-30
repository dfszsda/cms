import 'package:flutter/material.dart';
import '../../models/college_model.dart';
import '../../services/auth_service.dart';
import '../college_info_screen.dart';
import 'admin_dashboard_screen.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Panel"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Icon(Icons.account_balance_rounded, size: 60, color: Colors.indigo),
              const SizedBox(height: 10),
              const Text("Welcome Admin", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const Text("Manage your colleges here", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 30),

              // --- 1. Add New College Button ---
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CollegeInfoScreen(role: 'admin'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_business_rounded),
                  label: const Text("ADD NEW COLLEGE"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(height: 25),

              // --- 2. Search College Bar ---
              TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value.toLowerCase();
                  });
                },
                decoration: InputDecoration(
                  hintText: "Search College Name or City...",
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
              ),
              const SizedBox(height: 20),

              const Align(
                alignment: Alignment.centerLeft,
                child: Text("Select College to Manage:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              const SizedBox(height: 10),

              StreamBuilder<List<CollegeModel>>(
                stream: _auth.getColleges(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  
                  final colleges = snapshot.data!.where((c) => 
                    c.name.toLowerCase().contains(_searchQuery) || 
                    c.city.toLowerCase().contains(_searchQuery)
                  ).toList();

                  if (colleges.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.only(top: 20),
                      child: Text("No colleges found matching your search."),
                    );
                  }

                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: colleges.length,
                    separatorBuilder: (ctx, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final college = colleges[index];
                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Colors.indigo,
                            child: Icon(Icons.business, color: Colors.white),
                          ),
                          title: Text(college.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text("${college.city}, ${college.university}"),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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
                        ),
                      );
                    },
                  );
                }
              ),
            ],
          ),
        ),
      ),
    );
  }
}
