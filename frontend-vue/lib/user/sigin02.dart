import 'package:flutter/material.dart';
import 'homepages.dart';
import 'signup.dart';
import 'package:shuttle_bus_fronted/services/api_service.dart';
import '../admin/admin_homepage.dart';

final usernameController = TextEditingController();
final passwordController = TextEditingController();

class Signin02 extends StatefulWidget {
  const Signin02({super.key});

  @override
  State<Signin02> createState() => _Signin02State();
}

class _Signin02State extends State<Signin02> {
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  bool isPasswordVisible = false;

  String? loginError;

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffffffff),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: Image.asset('assets/mfu_logo.png', height: 90),
                  ),

                  const SizedBox(height: 20),

                  Center(child: Image.asset('assets/bus.png', height: 120)),

                  const SizedBox(height: 40),

                  const Text("Username"),

                  const SizedBox(height: 20),

                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),

                    // Username
                    child: TextFormField(
                      controller: usernameController,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      decoration: InputDecoration(
                        hintText: "Enter your username",
                        prefixIcon: Icon(Icons.person),
                        filled: true,
                        fillColor: Colors.white,

                        errorText: loginError, // if wrong username

                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.black),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.red, width: 2),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.red, width: 2),
                        ),
                      ),

                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Please enter username";
                        }
                        return null;
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text("Password"),

                  const SizedBox(height: 20),

                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),

                    // Password
                    child: TextFormField(
                      controller: passwordController,
                      obscureText: !isPasswordVisible,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      decoration: InputDecoration(
                        hintText: "Enter your password",
                        prefixIcon: Icon(Icons.key),

                        // show + hide password
                        suffixIcon: IconButton(
                          icon: Icon(
                            isPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              isPasswordVisible = !isPasswordVisible;
                            });
                          },
                        ),

                        filled: true,
                        fillColor: Colors.white,

                        errorText: loginError, // if wrong password

                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.black),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.red, width: 2),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.red, width: 2),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "Please enter password";
                        }
                        return null;
                      },
                    ),
                  ),

                  const SizedBox(height: 40),

                  // button Sign in
                  Center(
                    child: SizedBox(
                      width: 200,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFD2232A),
                          elevation: 5,
                          shadowColor: Colors.black.withOpacity(0.1),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: isLoading
                            ? null
                            : () async {
                                if (!_formKey.currentState!.validate()) {
                                  return;
                                }

                                setState(() {
                                  loginError = null;
                                  isLoading = true;
                                });

                                var result = await ApiService.login(
                                  usernameController.text,
                                  passwordController.text,
                                );

                                if (!mounted) return;

                                setState(() => isLoading = false);

                                final role = result?["role"]?.toString();
                                final token = result?["token"]?.toString();

                                if (token != null && role != null) {

                                  if (role == "admin") {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const AdminHomepage(), // 👑 ไปหน้า admin
                                      ),
                                    );
                                  } else {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const Homepages(), // 👤 user ปกติ
                                      ),
                                    );
                                  }
                                } else {
                                  final error =
                                      result?["error"]?.toString() ??
                                      "Invalid username or password";

                                  setState(() {
                                    loginError = error;
                                  });
                                  _showError(error);
                                }
                              },
                        child: isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                "Sign in",
                                style: TextStyle(color: Colors.white),
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Sign up link page
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text("Don't have an account? "),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const Signup(),
                            ),
                          );
                        },
                        child: const Text(
                          "Sign up",
                          style: TextStyle(
                            color: Color(0xFFBC9945),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
