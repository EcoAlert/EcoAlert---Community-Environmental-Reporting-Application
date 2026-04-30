import 'package:ecoalert/auth_service.dart';
import 'package:ecoalert/text_field.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';

class Register extends StatefulWidget {
  const Register({super.key});

  @override
  State<Register> createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final _formKey = GlobalKey<FormState>();
  bool isLoading = false;
  bool showPassword = false;
  String? selectedRole;
  String errorMessage = '';
  bool showError = false;
  String _passwordValue = '';

  final orgIdController = TextEditingController();
  final memberIdController = TextEditingController();
  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  int _getPasswordStrength(String password) {
    int strength = 0;
    if (password.length >= 8) strength++;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength++;
    if (RegExp(r'[0-9]').hasMatch(password)) strength++;
    if (RegExp(r'[@$_!]').hasMatch(password)) strength++;
    return strength; // 0 to 4
  }

  String _getStrengthLabel(int strength) {
    switch (strength) {
      case 1:
        return 'Weak';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Strong';
      default:
        return '';
    }
  }

  Color _getStrengthColor(int strength) {
    switch (strength) {
      case 1:
        return Colors.red;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.yellow.shade700;
      case 4:
        return Colors.green;
      default:
        return Colors.transparent;
    }
  }

  Future<void> _handleRegister() async {
    setState(() => showError = true);
    if (!_formKey.currentState!.validate()) return;
    if (selectedRole == null) return;

    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    final result = await AuthService.signUp(
      memberId: memberIdController.text.trim(),
      organizationId: orgIdController.text.trim(),
      fullName: fullNameController.text.trim(),
      email: emailController.text.trim(),
      password: passwordController.text.trim(),
      selectedRole: selectedRole!,
    );

    if (!mounted) return;

    setState(() => isLoading = false);

    if (result['success']) {
      // Show success message then go to login
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Account created! Please login.'),
          backgroundColor: Color(0xFF7ECBA9),
        ),
      );
      Navigator.pushReplacementNamed(context, '/login'); // 👈 go to login
    } else {
      setState(() => errorMessage = result['message']);
    }
  }

  @override
  void initState() {
    super.initState();
    passwordController.addListener(() {
      setState(() => _passwordValue = passwordController.text);
    });
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
                children: [
                  Container(
                    width: MediaQuery.of(context).size.width * 0.9,
                    margin: EdgeInsetsGeometry.fromLTRB(0, 30, 0, 30),
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
                    child: Form(
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
                              FontAwesomeIcons.screwdriverWrench,
                              color: Color.fromARGB(255, 1, 143, 82),
                            ),
                          ),
                          const SizedBox(height: 15),
                          Text(
                            "Create Account",
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
                            "Join FixAlert and start making a difference",
                            style: GoogleFonts.ptSans(
                              textStyle: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),

                          // Organization ID
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Organization ID'),
                              InputField(
                                controller: orgIdController,
                                keyboardType: TextInputType.text,
                                hint: 'e.g. SFD-001',
                                icon: Icons.business_outlined,
                                cursorColor: Colors.black,
                                validator: (value) {
                                  if (value.isEmpty) return 'Field is Empty';
                                  return null;
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Member ID
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Member ID'),
                              InputField(
                                controller: memberIdController,
                                keyboardType: TextInputType.text,
                                hint: 'e.g. SFD-VOL-001',
                                icon: Icons.badge_outlined,
                                cursorColor: Colors.black,
                                validator: (value) {
                                  if (value.isEmpty) return 'Field is Empty';
                                  return null;
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Full Name
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Full Name'),
                              InputField(
                                controller: fullNameController,
                                keyboardType: TextInputType.name,
                                hint: 'Enter your full name',
                                icon: Icons.person_outline,
                                cursorColor: Colors.black,
                                validator: (value) {
                                  if (value.isEmpty) return 'Field is Empty';
                                  return null;
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          // Email
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildLabel('Email'),
                              InputField(
                                controller: emailController,
                                keyboardType: TextInputType.emailAddress,
                                hint: 'your.email@example.com',
                                icon: Icons.email_outlined,
                                cursorColor: Colors.black,
                                validator: (value) {
                                  if (value.isEmpty) {
                                    return 'Field is Empty';
                                  }
                                  if (!RegExp(
                                    r'^[^\s@]+@[^\s@]+\.[^\s@]+$',
                                  ).hasMatch(value)) {
                                    return 'Invalid Email';
                                  }
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
                              _buildLabel('Password'),
                              InputField(
                                controller: passwordController,
                                keyboardType: TextInputType.visiblePassword,
                                hint: 'Enter your password',
                                icon: Icons.lock_outlined,
                                cursorColor: Colors.black,
                                isPassword: true,
                                isVisible: showPassword,
                                onToggle: () {
                                  setState(() => showPassword = !showPassword);
                                },
                                validator: (value) {
                                  if (value.isEmpty) {
                                    return 'Field is Empty';
                                  }
                                  if (!RegExp(
                                    r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[@$_])[A-Za-z\d@$_]{8,}$',
                                  ).hasMatch(value)) {
                                    return 'Invalid Password';
                                  }
                                  return null;
                                },
                              ),
                              if (_passwordValue.isNotEmpty)
                                SizedBox(
                                  width: MediaQuery.of(context).size.width * 0.72,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 8),
                                      Row(
                                        children: List.generate(4, (index) {
                                          final strength = _getPasswordStrength(
                                            _passwordValue,
                                          );
                                          final isActive = index < strength;
                                          return Expanded(
                                            child: Container(
                                              margin: const EdgeInsets.only(
                                                right: 4,
                                              ),
                                              height: 4,
                                              decoration: BoxDecoration(
                                                color: isActive
                                                    ? _getStrengthColor(strength)
                                                    : Colors.grey.shade300,
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                            ),
                                          );
                                        }),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Password strength: ${_getStrengthLabel(_getPasswordStrength(_passwordValue))}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: _getStrengthColor(
                                            _getPasswordStrength(_passwordValue),
                                          ),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,

                            children: [
                              _buildLabel('Role'),
                              SizedBox(
                                width: MediaQuery.of(context).size.width * 0.72,
                                height: 30, // 👈 match height
                                child: Row(
                                  children: [
                                    _buildRoleCard(
                                      'citizen',
                                      'Citizen',
                                      Icons.person_outline,
                                    ),
                                    const SizedBox(width: 10),
                                    _buildRoleCard(
                                      'volunteer',
                                      'Volunteer',
                                      Icons.handshake_outlined,
                                    ),
                                  ],
                                ),
                              ),
                              if (selectedRole == null && showError)
                                const Padding(
                                  padding: EdgeInsets.only(left: 4, top: 4),
                                  child: Text(
                                    'Please select a role',
                                    style: TextStyle(
                                      color: Colors.red,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),

                          const SizedBox(height: 15),

                          // Error Message
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

                          const SizedBox(height: 15),
                          // Register Button
                          SizedBox(
                            width: MediaQuery.of(context).size.width * 0.72,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : _handleRegister,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF7ECBA9),
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  15,
                                  20,
                                  15,
                                ),
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
                                        'Register',
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

                          // Navigate to Login
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('Already have an account?'),
                              SizedBox(width: 1),
                              TextButton(
                                style: TextButton.styleFrom(
                                  overlayColor: Colors.transparent,
                                  padding: const EdgeInsets.all(0),
                                ),
                                onPressed: () => {
                                  Navigator.pushReplacementNamed(
                                    context,
                                    '/login',
                                  ),
                                },
                                child: const Text(
                                  'Login',
                                  style: TextStyle(color: Color(0xFF7ECBA9)),
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

          if (constraints.maxHeight < 700) {
            return SingleChildScrollView(child: content);
          }
          return content;
        },
      ),
    );
  }

  // Helper for labels
  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 0, 0, 3),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildRoleCard(String role, String label, IconData icon) {
    final isSelected = selectedRole == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => selectedRole = role),
        child: Container(
          height: 30, // 👈 fixed height
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFB8E6D5) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? const Color(0xFF7ECBA9) : Colors.grey,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? const Color(0xFF018F52) : Colors.grey,
                size: 14, // 👈 smaller icon to fit height
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11, // 👈 smaller text to fit height
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? const Color(0xFF018F52) : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
