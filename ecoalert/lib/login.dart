import 'package:ecoalert/auth_service.dart';
import 'package:ecoalert/text_field.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class Login extends StatefulWidget {
  const Login({super.key});

  @override
  State<StatefulWidget> createState() => LoginState();
}

class LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>(); // 👈 added
  bool isLoading = false;
  bool showPassword = false;
  String errorMessage = ''; // 👈 added
  TextEditingController emailController = TextEditingController();
  TextEditingController passController = TextEditingController();

  // 👈 login function added
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    final result = await AuthService.login(
      email: emailController.text.trim(),
      password: passController.text.trim(),
    );
    if (!mounted) return;

    setState(() => isLoading = false);

    if (result['success']) {
      final role = result['role'];
      if (role == 'admin') {
        Navigator.pushReplacementNamed(context, '/admin');
      } else if (role == 'volunteer') {
        Navigator.pushReplacementNamed(context, '/volunteer');
      } else {
        Navigator.pushReplacementNamed(context, '/citizen');
      }
    } else {
      setState(() => errorMessage = result['message']);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          final content = ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height,
            ),
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(color: Colors.white),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width * 0.9,
                    padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(50),
                          blurRadius: 12,
                          spreadRadius: 5,
                          offset: const Offset(0, 0),
                        ),
                      ],
                    ),
                    child: Form( // 👈 wrapped with Form
                      key: _formKey,
                      child: Column(
                        children: [
                          // Icon
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFB8E6D5),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const FaIcon(
                              FontAwesomeIcons.wrench,
                              color: Color.fromARGB(255, 1, 143, 82),
                            ),
                          ),
                          const SizedBox(height: 15),
                          Text(
                            "FixAlert",
                            style: GoogleFonts.poppins(
                              textStyle: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "Monitor and report environmental issues",
                            style: GoogleFonts.ptSans(
                              textStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),

                          // Email
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.fromLTRB(2, 0, 0, 3),
                                child: Text(
                                  "Email",
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                              InputField(
                                controller: emailController,
                                keyboardType: TextInputType.emailAddress,
                                hint: "your.email@example.com",
                                cursorColor: Colors.black,
                                icon: Icons.email_outlined,
                                validator: (value) {
                                  if (value.isEmpty) return "Field is Empty";
                                  if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                      .hasMatch(value)) {return "Invalid Email";}
                                  return null;
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Password
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(2, 0, 0, 3),
                                child: Text(
                                  "Password",
                                  style: GoogleFonts.poppins(
                                    textStyle: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                              InputField(
                                controller: passController,
                                keyboardType: TextInputType.visiblePassword,
                                hint: "Enter your password",
                                cursorColor: Colors.black,
                                icon: Icons.lock_outlined,
                                validator: (value) {
                                  if (value.isEmpty) return "Field is Empty";
                                  if (!RegExp(
                                    r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[@$_])[A-Za-z\d@$_]{8,}$',
                                  ).hasMatch(value)) {return "Invalid Password";}
                                  return null;
                                },
                                isPassword: true,
                                isVisible: showPassword,
                                onToggle: () {
                                  setState(() => showPassword = !showPassword);
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Forgot Password 👈 updated onPressed
                          TextButton(
                            style: TextButton.styleFrom(
                              overlayColor: Colors.transparent,
                            ),
                            onPressed: () {
                              Navigator.pushNamed(context, '/forgot-password');
                            },
                            child: SizedBox(
                              width: MediaQuery.of(context).size.width * 0.72,
                              child: const Text(
                                "Forgot password?",
                                style: TextStyle(
                                  color: Color(0xFF7ECBA9),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.end,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // 👈 error message added
                          if (errorMessage.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                errorMessage,
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),

                          // Sign In Button 👈 updated
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.72,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF7ECBA9),
                                padding: const EdgeInsets.fromLTRB(
                                    20, 15, 20, 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(7),
                                ),
                              ),
                              child: Center(
                                child: isLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text(
                                        "Sign In",
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 15),

                          // Navigate to Register 👈 updated onPressed
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text("Don't have an account?"),
                              const SizedBox(width: 2),
                              TextButton(
                                style: TextButton.styleFrom(
                                  overlayColor: Colors.transparent,
                                  padding: const EdgeInsets.all(0),
                                ),
                                onPressed: () => Navigator.pushReplacementNamed(
                                    context, '/register'),
                                child: const Text(
                                  "Register",
                                  style:
                                      TextStyle(color: Color(0xFF7ECBA9)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
          if (constraints.maxHeight < 600) {
            return SingleChildScrollView(child: content);
          } else {
            return content;
          }
        },
      ),
    );
  }
}