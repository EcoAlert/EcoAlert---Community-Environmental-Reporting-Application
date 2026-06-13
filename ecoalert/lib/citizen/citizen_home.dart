import 'package:fixalert/citizen/my_reports_page.dart';
import 'package:fixalert/citizen/profile_page.dart';
import 'package:fixalert/citizen/report_issue_page.dart';
import 'package:fixalert/widgets/impact_card.dart';
import 'package:fixalert/widgets/quick_action_card.dart';
import 'package:fixalert/widgets/report_card.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CitizenHome extends StatefulWidget {
  const CitizenHome({super.key});

  @override
  State<CitizenHome> createState() => _CitizenHomeState();
}

class _CitizenHomeState extends State<CitizenHome> {
  final supabase = Supabase.instance.client;

  int currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [_homePage(), const ProfilePage(), const MyReportsPage()];

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F8),

      body: pages[currentIndex],

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        selectedItemColor: const Color.fromARGB(255, 1, 134, 143),

        onTap: (value) {
          setState(() {
            currentIndex = value;
          });
        },

        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: "Home",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: "Profile",
          ),

          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long_outlined),
            label: "My Reports",
          ),
        ],
      ),
    );
  }

  Widget _homePage() {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: const BoxDecoration(color: Color(0xFFB8E6D5)),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const FaIcon(
                    FontAwesomeIcons.screwdriverWrench,
                    color: Color(0xFF018F52),
                    size: 20,
                  ),
                ),

                const SizedBox(width: 12),

                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "FixAlert",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      "Community Issue Reporting",
                      style: TextStyle(
                        color: Color.fromARGB(255, 138, 138, 138),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: ScrollConfiguration(
              behavior: ScrollConfiguration.of(
                context,
              ).copyWith(scrollbars: false),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),

                    const Text(
                      "Quick Actions",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 14),

                    QuickActionCard(
                      icon: Icons.camera_alt_outlined,
                      title: "Report an Issue",
                      subtitle: "Take photo and submit a report",
                      onTap: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ReportIssuePage(),
                          ),
                        );
                        if (result == true) {
                          setState(() {});
                        }
                      },
                    ),

                    const SizedBox(height: 28),

                    const Text(
                      "Your Impact",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 14),

                    FutureBuilder(
                      future: supabase
                          .from('reports')
                          .select()
                          .eq('user_id', supabase.auth.currentUser!.id),

                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const CircularProgressIndicator();
                        }

                        final reports = snapshot.data as List;
                        final totalReports = reports.length;
                        final verifiedCount = reports
                            .where((r) => r['status'] == 'approved')
                            .length;

                        return Row(
                          children: [
                            Expanded(
                              child: ImpactCard(
                                icon: Icons.description_outlined,
                                title: "Reports",
                                value: totalReports.toString(),
                                color: Colors.blue,
                              ),
                            ),

                            const SizedBox(width: 14),

                            Expanded(
                              child: ImpactCard(
                                icon: Icons.verified_outlined,
                                title: "Verified",
                                value: verifiedCount.toString(),
                                color: Colors.green,
                              ),
                            ),
                          ],
                        );
                      },
                    ),

                    const SizedBox(height: 28),

                    const Text(
                      "Recent Reports",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 14),

                    FutureBuilder(
                      future: supabase
                          .from('reports')
                          .select()
                          .eq('user_id', supabase.auth.currentUser!.id)
                          .order('created_at', ascending: false)
                          .limit(5),

                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        final reports = snapshot.data as List;

                        if (reports.isEmpty) {
                          return const Text("No reports submitted yet.");
                        }

                        return Column(
                          children: reports.map((report) {
                            return ReportCard(
                              title: report['title'] ?? "Untitled Issue",
                              description:
                                  report['description'] ?? "No description",
                              location: report['location'] ?? "Unknown",
                              status: report['status'] ?? "Pending",
                              date: report['created_at'].toString().substring(
                                0,
                                10,
                              ),
                            );
                          }).toList().cast<Widget>(),
                        );
                      },
                    ),

                    const SizedBox(height: 28),

                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF8F1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.tips_and_updates_rounded,
                            color: Color(0xFF018F52),
                            size: 30,
                          ),
                          SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              "FixAlert Tip:\nEvery report you submit helps volunteers take action!",
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
