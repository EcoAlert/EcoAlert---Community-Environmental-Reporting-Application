import 'package:ecoalert/login.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {

        // Show loading while checking session
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF7ECBA9),
              ),
            ),
          );
        }

        // Check if user is already logged in
        final session = snapshot.data?.session;

        if (session != null) {
          // User is logged in — but we need their role
          // So we fetch it and redirect accordingly
          return FutureBuilder(
            future: Supabase.instance.client
                .from('users')
                .select('role')
                .eq('id', session.user.id)
                .maybeSingle(),
            builder: (context, roleSnapshot) {
              if (roleSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF7ECBA9),
                    ),
                  ),
                );
              }

              final role = roleSnapshot.data?['role'];

              if (role == 'admin') {
                // return const AdminScreen();
              } else if (role == 'volunteer') {
                // return const VolunteerScreen();
              } else if (role == 'citizen') {
                // return const CitizenScreen();
              }
              return const Login(); // fallback
              
            },
          );
        }

        // No session — show login
        return const Login();
      },
    );
  }
}