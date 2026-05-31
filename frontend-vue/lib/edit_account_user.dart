import 'package:flutter/material.dart';
import 'package:shuttle_bus_fronted/updates_account_user.dart';
import 'package:shuttle_bus_fronted/services/api_service.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  bool usernameError = false;
  bool emailError = false;
  bool passwordError = false;
  bool newPasswordError = false;
  bool showOldPassword = false;
  bool showNewPassword = false;

  String? usernameErrorText;
  String? emailErrorText;
  String? passwordErrorText;
  String? newPasswordErrorText;

  final usernameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final newPasswordController = TextEditingController();

  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    newPasswordController.dispose();
    super.dispose();
  }

  // popup error
  void _showError(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  // if wrong email
  bool isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffffffff),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 10),

                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),

                const SizedBox(height: 10),

                Stack(
                  children: [
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
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.add),
                          onPressed: () {},
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 30),

                // Username input
                buildInputRow(
                  "Username",
                  "Username",
                  usernameController,
                  false,
                  false,
                  null,
                  usernameError,
                  usernameErrorText,
                ),
                // Email input
                buildInputRow(
                  "Email",
                  "example@email.com",
                  emailController,
                  false,
                  false,
                  null,
                  emailError,
                  emailErrorText,
                ),

                buildInputRow(
                  "Old Password",
                  "Enter password",
                  passwordController,
                  true,
                  showOldPassword,
                  () {
                    setState(() {
                      showOldPassword = !showOldPassword;
                    });
                  },
                  passwordError,
                  passwordErrorText,
                ),
                // Password input
                buildInputRow(
                  "New Password",
                  "Enter new password",
                  newPasswordController,
                  true,
                  showNewPassword,
                  () {
                    setState(() {
                      showNewPassword = !showNewPassword;
                    });
                  },
                  newPasswordError,
                  newPasswordErrorText,
                ),

                const SizedBox(height: 40),

                // Confirm Button
                SizedBox(
                  width: 200,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),

                    onPressed: () async {
                      setState(() {
                        usernameError = usernameController.text.isEmpty;
                        emailError =
                            emailController.text.isEmpty ||
                            !isValidEmail(emailController.text);
                        passwordError = passwordController.text.isEmpty;
                        newPasswordError =
                            newPasswordController.text.length < 8;
                        usernameErrorText = usernameError
                            ? "Please enter username"
                            : null;
                        emailErrorText = emailError ? "Invalid email" : null;
                        passwordErrorText = passwordError
                            ? "Enter password"
                            : null;
                        newPasswordErrorText = newPasswordError
                            ? "At least 8 characters"
                            : null;
                      });

                      if (usernameError ||
                          emailError ||
                          passwordError ||
                          newPasswordError) {
                        _showError("Please fill all fields");
                        return;
                      }
                      String? error = await ApiService.updateProfile(
                        usernameController.text,
                        emailController.text,
                        passwordController.text,
                        newPasswordController.text,
                      );

                      if (error == null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const UpdatesAccountUser(),
                          ),
                        );
                      } else {
                        setState(() {
                          passwordErrorText = null;
                          if (error.toLowerCase().contains("password")) {
                            passwordError = true;
                            passwordErrorText = "Wrong password";
                          } else {
                            _showError(error);
                          }
                        });
                      }
                    },

                    child: const Text(
                      "Confirm",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildInputRow(
    String label,
    String hint,
    TextEditingController controller,
    bool isPassword,
    bool obscureText,
    VoidCallback? toggle,
    bool isError,
    String? errorText,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            height: 48,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                  height: 1.2,
                ),
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 45,
                  decoration: BoxDecoration(
                    color: const Color(0xffEDEDED),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isError ? Colors.red : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: TextField(
                    controller: controller,
                    obscureText: isPassword ? obscureText : false,
                    textAlignVertical: TextAlignVertical.center,
                    style: const TextStyle(height: 1.0),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: hint,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 14,
                      ),
                      suffixIcon: isPassword
                          ? IconButton(
                              icon: Icon(
                                obscureText
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: toggle,
                            )
                          : null,
                    ),
                  ),
                ),

                if (errorText != null)
                  Padding(
                    padding: const EdgeInsets.only(left: 12, top: 4),
                    child: Text(
                      errorText,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
