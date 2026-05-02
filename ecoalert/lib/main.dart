import 'package:fixalert/admin_screen.dart';
// import 'package:fixalert/auth_gate.dart';
import 'package:fixalert/login.dart';
import 'package:fixalert/register.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async{
  runApp(const MyApp());
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: "https://udrqnstfeaaifrvypjsu.supabase.co", 
    anonKey: "sb_publishable_0Ec01f2Zv4esOUl28af9Dg_fKONm2Kt",
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData.light(),
      debugShowCheckedModeBanner: false,
      home: Admin(),
      routes: {
    '/login': (context) => const Login(),
    '/register': (context) => const Register(), // 👈 make sure this exists
    // '/admin': (context) => const AdminScreen(),
    // '/volunteer': (context) => const VolunteerScreen(),
    // '/citizen': (context) => const CitizenScreen(),
  },
    );
  }
}

