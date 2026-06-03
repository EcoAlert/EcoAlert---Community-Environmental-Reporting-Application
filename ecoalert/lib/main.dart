import 'package:fixalert/admin_screen.dart';
import 'package:fixalert/auth_gate.dart';
import 'package:fixalert/login.dart';
import 'package:fixalert/register.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fixalert/citizen/citizen_home.dart';


void main() async {

  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: "https://udrqnstfeaaifrvypjsu.supabase.co",
    anonKey: "sb_publishable_0Ec01f2Zv4esOUl28af9Dg_fKONm2Kt",
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      home: const AuthGate(),

      routes: {
        '/login': (context) => const Login(),
        '/register': (context) => const Register(),
        '/admin': (context) => const Admin(),
        '/citizen': (context) => const CitizenHome(),
      },
    );
  }
}