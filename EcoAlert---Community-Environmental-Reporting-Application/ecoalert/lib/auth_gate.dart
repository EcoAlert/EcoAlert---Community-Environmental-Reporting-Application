import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:fixalert/admin_screen.dart';
import 'package:fixalert/citizen/citizen_home.dart';
import 'package:fixalert/login.dart';
import 'package:fixalert/volunteer/volunteer_dashboard.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final session = Supabase.instance.client.auth.currentSession;

    if (session == null) {
      return const Login();
    }

    return FutureBuilder(
      future: Supabase.instance.client
          .from('users')
          .select()
          .eq('id', session.user.id)
          .maybeSingle(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = snapshot.data;

        if (user == null) {
          return const Login();
        }

        final role = user['role'];

        if (role == 'admin') {
          return const Admin();
        } else if (role == 'volunteer') {
          return const VolunteerDashboard();
        } else {
          return const CitizenHome();
        }
      },
    );
  }
}