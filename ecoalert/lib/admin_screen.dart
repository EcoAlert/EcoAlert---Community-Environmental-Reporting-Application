import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:google_fonts/google_fonts.dart';

class Admin extends StatefulWidget {
  const Admin({super.key});

  @override
  State<StatefulWidget> createState() => AdminState();
}

class AdminState extends State<Admin> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(55),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(topLeft: Radius.circular(10)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(50),
                blurRadius: 12,
                spreadRadius: 5,
                offset: const Offset(0, 0),
              ),
            ],
          ),
          child: AppBar(
            backgroundColor: Colors.white,
            automaticallyImplyLeading: false,
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Left side — icon + title
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: const Color(0xFFB8E6D5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const FaIcon(
                        FontAwesomeIcons.leaf,
                        color: Color.fromARGB(255, 1, 143, 82),
                        size: 17,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "EcoAlert Admin",
                          style: GoogleFonts.poppins(
                            textStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        Text(
                          "Dashboard",
                          style: GoogleFonts.poppins(
                            textStyle: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Right side — logout button
                IconButton(
                  icon: const Icon(Icons.logout),
                  color: Colors.grey,
                  iconSize: 16,
                  onPressed: () async {
                    await Supabase.instance.client.auth.signOut();
                    if (!mounted) return;
                    Navigator.pushReplacementNamed(context, '/login');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height,
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 75, 16, 20),
            decoration: const BoxDecoration(color: Colors.white),
            child: Column(
              children: [
                Column(
                  children: [
                    _issueContainer(
                      "Total Issues",
                      "5",
                      Colors.blue.shade100,
                      Colors.blue,
                      Icons
                          .error_outline, // 👈 Icons instead of FontAwesomeIcons
                      Icons.trending_up,
                      "All time reports",
                    ),
                    SizedBox(height: 20),
                    _issueContainer(
                      "Pending Issues",
                      "3",
                      Colors.orange.shade100,
                      Colors.orange,
                      Icons.access_time_outlined,
                      Icons.calendar_today_outlined,
                      "Awaiting action",
                    ),
                    SizedBox(height: 20),
                    _issueContainer(
                      "Resolved Issues",
                      "2",
                      Colors.green.shade100,
                      Colors.green,
                      Icons.check_circle_outline,
                      Icons.check_circle_outline,
                      "Successfully completed",
                    ),
                    SizedBox(height: 20),
                    _issueContainer(
                      "Resolution Rate",
                      "40%",
                      Colors.purple.shade100,
                      Colors.purple,
                      Icons.trending_up,
                      Icons.people_outline,
                      "Team performance",
                    ),
                  ],
                ),
                SizedBox(height: 30),
                Column(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _issueContainer(
    String title,
    String total,
    Color iconColor,
    Color iconFontColor,
    IconData icon1,
    IconData icon2,
    String action,
  ) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.9,
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, // 👈 add background color
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(50),
            blurRadius: 8,
            spreadRadius: 3,
            offset: const Offset(0, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    total,
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: iconColor, // 👈 now accepts Color
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon1, // 👈 dynamic icon
                  color: iconFontColor, // 👈 dynamic icon color
                  size: 17,
                ),
              ),
            ],
          ),
          SizedBox(height: 40),
          Row(
            children: [
              Icon(
                icon2, // 👈 dynamic icon
                color: iconFontColor, // 👈 dynamic icon color
                size: 14,
              ),
              SizedBox(width: 8),
              Text(
                action,
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
