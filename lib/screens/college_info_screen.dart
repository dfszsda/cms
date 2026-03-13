import 'package:flutter/material.dart';

class CollegeInfoScreen extends StatelessWidget {
  final String role;
  const CollegeInfoScreen({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("College Information"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // College Logo
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.3),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Image.asset(
                  'lib/raw/logo.png',
                  height: 120,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.school,
                    size: 80,
                    color: Colors.deepPurple,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // College Details Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    _infoRow(Icons.business, "College Name",
                        "Madhuben & Bhanubhai Patel Institute of Technology"),
                    const Divider(),
                    _infoRow(Icons.account_balance, "University",
                        "The Charutar Vidya Mandal (CVM) University"),
                    const Divider(),
                    _infoRow(Icons.location_city, "City", "New Vidhyanagar"),
                    const Divider(),
                    _infoRow(Icons.map, "District", "Anand"),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Working Hours Card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.access_time, color: Colors.blue),
                        SizedBox(width: 10),
                        Text(
                          "College Working Hours",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _hourRow("Monday - Friday", "9:00 AM to 5:00 PM"),
                    
                    // Show Saturday hours only for teachers
                    if (role == 'teacher' || role == 'admin') ...[
                      const Divider(),
                      _hourRow("Saturday", "9:00 AM to 5:00 PM"),
                      const Padding(
                        padding: EdgeInsets.only(left: 8.0),
                        child: Text(
                          "[1st, 3rd Saturday (and 5th if any)]",
                          style: TextStyle(fontSize: 12, color: Colors.grey, fontStyle: FontStyle.italic),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.deepPurple, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                const SizedBox(height: 4),
                Text(value,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _hourRow(String day, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(day, style: const TextStyle(fontSize: 15)),
          Text(time, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.blue)),
        ],
      ),
    );
  }
}
