import 'package:flutter/material.dart';
import 'package:shuttle_bus_fronted/Signin01.dart';

class UpdatesAccountUser extends StatefulWidget {
  const UpdatesAccountUser({super.key});

  @override
  State<UpdatesAccountUser> createState() => _UpdatesAccountUserState();
}

class _UpdatesAccountUserState extends State<UpdatesAccountUser> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffffffff),

      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Confirm icon
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: const Color(0xff4CAF50),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(Icons.check, color: Colors.white, size: 70),
              ),

              const SizedBox(height: 30),

              // Title
              const Text(
                "Update Complete",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
              ),

              const SizedBox(height: 10),

              // Subtitle
              const Text(
                "Your profile has been successfully updated.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.black54),
              ),

              const SizedBox(height: 40),

              // Return Button
              SizedBox(
                width: 200,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    elevation: 5,
                    shadowColor: Colors.black.withValues(alpha: 0.2),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const Signin01()),
                    );
                  },
                  child: const Text(
                    "Return Home",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
