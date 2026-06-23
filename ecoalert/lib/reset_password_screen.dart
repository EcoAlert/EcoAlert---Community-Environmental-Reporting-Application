import 'package:fixalert/text_field.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _showPassword = false;
  String _passwordValue = '';

  int _getPasswordStrength(String password) {
    int strength = 0;
    if (password.length >= 8) strength++;
    if (RegExp(r'[A-Z]').hasMatch(password) && RegExp(r'[a-z]').hasMatch(password)) strength++;
    if (RegExp(r'[0-9]').hasMatch(password)) strength++;
    if (RegExp(r'[@$_!]').hasMatch(password)) strength++;
    return strength;
  }

  String _getStrengthLabel(int strength) {
    switch (strength) {
      case 1: return 'Weak';
      case 2: return 'Fair';
      case 3: return 'Good';
      case 4: return 'Strong';
      default: return '';
    }
  }

  Color _getStrengthColor(int strength) {
    switch (strength) {
      case 1: return Colors.red;
      case 2: return Colors.orange;
      case 3: return Colors.yellow.shade700;
      case 4: return Colors.green;
      default: return Colors.transparent;
    }
  }

  Future<void> _updatePassword() async {
    final newPassword = _passwordController.text.trim();

    if (!RegExp(
      r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[@$_])[A-Za-z\d@$_]{8,}$',
    ).hasMatch(newPassword)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a strong password.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password updated successfully!'),
          backgroundColor: Color(0xFF7ECBA9),
        ),
      );
      Navigator.pushReplacementNamed(context, '/login');
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(() {
      setState(() => _passwordValue = _passwordController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: Center(
          child: Container(
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFB8E6D5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const FaIcon(
                    FontAwesomeIcons.lock,
                    color: Color.fromARGB(255, 1, 143, 82),
                  ),
                ),
                const SizedBox(height: 15),
                Text(
                  "Set New Password",
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
                  "Enter your new password below",
                  style: GoogleFonts.ptSans(
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Password field
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(2, 0, 0, 3),
                      child: Text(
                        'New Password',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    InputField(
                      controller: _passwordController,
                      keyboardType: TextInputType.visiblePassword,
                      hint: 'Enter new password',
                      icon: Icons.lock_outlined,
                      cursorColor: Colors.black,
                      isPassword: true,
                      isVisible: _showPassword,
                      onToggle: () {
                        setState(() => _showPassword = !_showPassword);
                      },
                      validator: (value) {
                        if (value.isEmpty) return 'Field is Empty';
                        if (!RegExp(
                          r'^(?=.*[A-Z])(?=.*[a-z])(?=.*\d)(?=.*[@$_])[A-Za-z\d@$_]{8,}$',
                        ).hasMatch(value)) return 'Invalid Password';
                        return null;
                      },
                    ),

                    // Password strength indicator
                    if (_passwordValue.isNotEmpty)
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.72,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Row(
                              children: List.generate(4, (index) {
                                final strength =
                                    _getPasswordStrength(_passwordValue);
                                final isActive = index < strength;
                                return Expanded(
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 4),
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: isActive
                                          ? _getStrengthColor(strength)
                                          : Colors.grey.shade300,
                                      borderRadius: BorderRadius.circular(4),
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
                                    _getPasswordStrength(_passwordValue)),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),

                // Update Button
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.72,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _updatePassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7ECBA9),
                      padding: const EdgeInsets.fromLTRB(20, 15, 20, 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(7),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Update Password',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}