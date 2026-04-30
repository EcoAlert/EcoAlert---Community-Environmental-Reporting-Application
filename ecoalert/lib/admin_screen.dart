import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Admin extends StatefulWidget {
  const Admin({super.key});

  @override
  State<StatefulWidget> createState() => AdminState();
}

class AdminState extends State<Admin> {
  int totalIssues = 0;
  int pendingIssues = 0;
  int resolvedIssues = 0;
  double resolutionRate = 0;
  bool isLoadingStats = false;

  List<Map<String, dynamic>> allIssues = [];
  List<Map<String, dynamic>> filteredIssues = [];
  String selectedTab = 'All Issues';
  bool isLoadingIssues = false;

  Future<void> _fetchStats() async {
    setState(() => isLoadingStats = true);
    try {
      //Total Issues
      final total = await Supabase.instance.client
          .from('reports')
          .select()
          .count();

      //Pending Issues
      final pending = await Supabase.instance.client
          .from('reports')
          .select()
          .eq('status', 'pending')
          .count();

      //Resolved Issues
      final resolved = await Supabase.instance.client
          .from('reports')
          .select()
          .eq('status', 'resolved')
          .count();

      if (!mounted) return;

      setState(() {
        totalIssues = total.count;
        pendingIssues = pending.count;
        resolvedIssues = resolved.count;

        resolutionRate = totalIssues == 0
            ? 0
            : (resolvedIssues / totalIssues * 100);
      });
    } catch (e) {
      debugPrint('Error fetching stats: $e');
    } finally {
      if (mounted) setState(() => isLoadingStats = false);
    }
  }

  Future<void> _fetchIssues() async {
    setState(() => isLoadingIssues = true);

    try {
      final response = await Supabase.instance.client
          .from('reports')
          .select('*, users(full_name, member_id)')
          .order('created_at', ascending: false);

      if (!mounted) return;

      setState(() {
        allIssues = List<Map<String, dynamic>>.from(response);
        filteredIssues = allIssues;
      });
    } catch (e) {
      debugPrint('Error fetching issues: $e');
    } finally {
      if (mounted) setState(() => isLoadingIssues = false);
    }
  }

  void _filterIssues(String tab) {
    setState(() {
      selectedTab = tab;
      if (tab == 'All Issues') {
        filteredIssues = allIssues;
      } else if (tab == 'Pending') {
        filteredIssues = allIssues
            .where((i) => i['status'] == 'pending')
            .toList();
      } else if (tab == 'Resolved') {
        filteredIssues = allIssues
            .where((i) => i['status'] == 'resolved')
            .toList();
      }
    });
  }

  Future<void> _markAsResolved(String reportId) async {
    await Supabase.instance.client
        .from('reports')
        .update({'status': 'resolved'})
        .eq('id', reportId);

    if (!mounted) return;
    _fetchIssues(); 
    _fetchStats(); 
  }

  void _assignVolunteer(String reportId) {
    debugPrint('Assign volunteer for report: $reportId');
  }

  @override
  void initState() {
    super.initState();
    _fetchStats();
    _fetchIssues();
  }

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

          //App-Bar
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
                        FontAwesomeIcons.screwdriverWrench,
                        color: Color.fromARGB(255, 1, 143, 82),
                        size: 17,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "FixAlert Admin",
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
            decoration: const BoxDecoration(
              color: Color.fromARGB(255, 245, 255, 251),
            ),

            // ─── No. of Issues Section ─────────────────
            child: Column(
              children: [
                isLoadingStats
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF7ECBA9),
                        ),
                      )
                    : Column(
                        children: [
                          _issueContainer(
                            "Total Issues",
                            totalIssues.toString(),
                            Colors.blue.shade100,
                            Colors.blue,
                            Icons
                                .error_outline, 
                            Icons.trending_up,
                            "All time reports",
                          ),
                          SizedBox(height: 20),
                          _issueContainer(
                            "Pending Issues",
                            pendingIssues.toString(),
                            Colors.orange.shade100,
                            Colors.orange,
                            Icons.access_time_outlined,
                            Icons.calendar_today_outlined,
                            "Awaiting action",
                          ),
                          SizedBox(height: 20),
                          _issueContainer(
                            "Resolved Issues",
                            resolvedIssues.toString(),
                            Colors.green.shade100,
                            Colors.green,
                            Icons.check_circle_outline,
                            Icons.check_circle_outline,
                            "Successfully completed",
                          ),
                          SizedBox(height: 20),
                          _issueContainer(
                            "Resolution Rate",
                            resolutionRate.toString(),
                            Colors.purple.shade100,
                            Colors.purple,
                            Icons.trending_up,
                            Icons.people_outline,
                            "Team performance",
                          ),
                        ],
                      ),
                SizedBox(height: 30),

                // ─── Issues Management Section ─────────────────
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(30),
                        blurRadius: 12,
                        spreadRadius: 3,
                        offset: const Offset(0, 0),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Issues Management",
                            style: GoogleFonts.poppins(
                              textStyle: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              children: [
                                Icon(
                                  Icons.filter_list_alt,
                                  size: 14,
                                  color: Colors.black,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Filter',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Tabs
                      Row(
                        children: [
                          _buildTab("All Issues", selectedTab == 'All Issues'),
                          const SizedBox(width: 8),
                          _buildTab("Pending", selectedTab == 'Pending'),
                          const SizedBox(width: 8),
                          _buildTab("Resolved", selectedTab == 'Resolved'),
                        ],
                      ),

                      // Issue Cards
                      isLoadingIssues
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF7ECBA9),
                              ),
                            )
                          : filteredIssues.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Text(
                                  'No issues found',
                                  style: TextStyle(
                                    color: Colors.grey,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: filteredIssues.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 5),
                              itemBuilder: (context, index) {
                                return _issueCard(filteredIssues[index]);
                              },
                            ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  //No. of Issues Container
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
                  color: iconColor, 
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon1, 
                  color: iconFontColor, 
                  size: 17,
                ),
              ),
            ],
          ),
          SizedBox(height: 40),
          Row(
            children: [
              Icon(
                icon2, 
                color: iconFontColor,
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

  //Build-Tab
  Widget _buildTab(String label, bool isActive) {
    return GestureDetector(
      onTap: () => _filterIssues(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFB8E6D5) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? const Color(0xFF7ECBA9) : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            color: isActive ? const Color(0xFF018F52) : Colors.black,
          ),
        ),
      ),
    );
  }

  //Issue-Card
  Widget _issueCard(Map<String, dynamic> issue) {
    final bool isPending =
        issue['status'] == 'pending' || issue['status'] == 'in_progress';
    final bool isResolved = issue['status'] == 'resolved';
    final String userName = issue['users']?['full_name'] ?? 'Unknown';
    final String memberId = issue['users']?['member_id'] ?? '';
    final String createdAt =
        issue['created_at']?.toString().substring(0, 16).replaceAll('T', ' ') ??
        '';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 8,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + Status + Category
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.error_outline, color: Colors.blue, size: 16),
              ),
              const SizedBox(width: 10),

              // Title
              Expanded(
                child: Text(
                  issue['title'] ?? '',
                  style: GoogleFonts.poppins(
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Status + Category badges
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: isResolved
                          ? Colors.green.shade50
                          : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isResolved
                            ? Colors.green.shade200
                            : Colors.orange.shade200,
                      ),
                    ),
                    child: Text(
                      isResolved ? 'Resolved' : 'Pending',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isResolved ? Colors.green : Colors.orange,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Category badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      issue['category'] ?? 'other',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Description
          Text(
            issue['description'] ?? '',
            style: const TextStyle(fontSize: 12, color: Colors.black),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),

          // Location
          Row(
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 13,
                color: Colors.grey,
              ),
              const SizedBox(width: 4),
              Text(
                issue['location'] ?? '',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Reported by
          Row(
            children: [
              const Icon(Icons.person_outline, size: 13, color: Colors.grey),
              const SizedBox(width: 4),
              Text(
                '$userName ($memberId)',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Date
          Row(
            children: [
              const Icon(
                Icons.access_time_outlined,
                size: 13,
                color: Colors.grey,
              ),
              const SizedBox(width: 4),
              Text(
                createdAt,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),

          // Buttons — only show for pending
          if (isPending) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                // Mark as Resolved
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _markAsResolved(issue['id']),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7ECBA9),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Mark as Resolved',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Assign Volunteer
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _assignVolunteer(issue['id']),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Assign Volunteer',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.black,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
