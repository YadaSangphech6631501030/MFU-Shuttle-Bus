import 'package:flutter/material.dart';
import '../../api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/admin_bottom_bar.dart';
import '../../user/pages/signin01.dart';

class Adminaccountpage extends StatefulWidget {
  const Adminaccountpage({super.key});

  @override
  State<Adminaccountpage> createState() => _AdminaccountpageState();
}

class _AdminaccountpageState extends State<Adminaccountpage> {
  int currentIndex = 3;

  String username = "";
  String email = "";

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  Future<void> loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token");

    if (token == null) {
      _logout();
      return;
    }

    try {
      final data = await ApiService.getLatest();

      setState(() {
        username = data["username"] ?? "";
        email = data["email"] ?? "";
      });
    } catch (e) {
      print("LOAD ADMIN ERROR: $e");
    }
  }

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove("token");

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const Signin01()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      bottomNavigationBar: AdminBottomBar(
        currentIndex: currentIndex,
        onTap: (index) {},
      ),

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Profile
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                size: 60,
                color: Colors.white,
              ),
            ),

            const SizedBox(height: 20),

            Text(
              username.isEmpty ? "Loading..." : username,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 5),

            Text(
              email,
              style: const TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 40),

            SizedBox(
              width: 200,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                onPressed: _logout,
                child: const Text(
                  "Sign out",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}