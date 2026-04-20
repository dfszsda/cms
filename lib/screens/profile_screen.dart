import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import 'student_home_screen.dart';
import 'teacher_home_screen.dart';

class ProfileScreen extends StatefulWidget {
  final UserModel user;
  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _auth = AuthService();

  late TextEditingController ageCtrl;
  late TextEditingController genderCtrl;
  late TextEditingController hobbyCtrl;
  late TextEditingController aadhaarCtrl;
  late TextEditingController abcCtrl;
  late TextEditingController addressCtrl;
  late TextEditingController phoneCtrl;
  late TextEditingController extraPhoneCtrl;
  late TextEditingController profilePicCtrl;

  @override
  void initState() {
    super.initState();
    ageCtrl = TextEditingController(text: widget.user.age?.toString() ?? '');
    genderCtrl = TextEditingController(text: widget.user.gender ?? '');
    hobbyCtrl = TextEditingController(text: widget.user.hobby ?? '');
    aadhaarCtrl = TextEditingController(text: widget.user.aadhaar ?? '');
    abcCtrl = TextEditingController(text: widget.user.abcId ?? '');
    addressCtrl = TextEditingController(text: widget.user.address ?? '');
    phoneCtrl = TextEditingController(text: widget.user.phone ?? '');
    extraPhoneCtrl = TextEditingController(text: widget.user.furtherPhone ?? '');
    profilePicCtrl = TextEditingController(text: widget.user.profilePic ?? '');
  }

  Future<void> _save() async {
    widget.user
      ..age = int.tryParse(ageCtrl.text)
      ..gender = genderCtrl.text.trim()
      ..hobby = hobbyCtrl.text.trim()
      ..address = addressCtrl.text.trim()
      ..phone = phoneCtrl.text.trim()
      ..furtherPhone = extraPhoneCtrl.text.trim()
      ..profilePic = profilePicCtrl.text.trim()
      ..profileComplete = true;

    if (widget.user.role != 'teacher') {
      widget.user
        ..aadhaar = aadhaarCtrl.text.trim()
        ..abcId = abcCtrl.text.trim();
    }

    await _auth.updateProfile(widget.user);

    if (mounted) {
      if (widget.user.role == 'student') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const StudentHomeScreen()),
        );
      } else if (widget.user.role == 'teacher') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const TeacherHomeScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Complete Your Profile")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: TextEditingController(text: widget.user.fullName),
              decoration: const InputDecoration(labelText: "Full Name"),
              enabled: false,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: TextEditingController(text: widget.user.email),
              decoration: const InputDecoration(labelText: "Email"),
              enabled: false,
            ),
            const SizedBox(height: 16),
            TextField(controller: profilePicCtrl, decoration: const InputDecoration(labelText: "Profile Photo URL")),
            const SizedBox(height: 16),
            TextField(controller: ageCtrl, decoration: const InputDecoration(labelText: "Age"), keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            TextField(controller: genderCtrl, decoration: const InputDecoration(labelText: "Gender")),
            const SizedBox(height: 16),
            TextField(controller: hobbyCtrl, decoration: const InputDecoration(labelText: "Hobby")),
            const SizedBox(height: 16),
            if (widget.user.role != 'teacher') ...[
              TextField(controller: aadhaarCtrl, decoration: const InputDecoration(labelText: "Aadhaar Number")),
              const SizedBox(height: 16),
              TextField(controller: abcCtrl, decoration: const InputDecoration(labelText: "ABC ID")),
              const SizedBox(height: 16),
            ],
            TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: "Home Address")),
            const SizedBox(height: 16),
            TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: "Phone Number"), keyboardType: TextInputType.phone),
            const SizedBox(height: 16),
            TextField(controller: extraPhoneCtrl, decoration: const InputDecoration(labelText: "Alternative Phone"), keyboardType: TextInputType.phone),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              child: const Text("SAVE & CONTINUE"),
            ),
          ],
        ),
      ),
    );
  }
}
