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
  List<Map<String, dynamic>> volunteers = [];
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
  // ─── FETCH ISSUES ────────────────────────────────────
  Future<void> _fetchIssues() async {
    setState(() => isLoadingIssues = true);
    try {
      final response = await Supabase.instance.client
          .from('reports')
          .select('*, users(full_name, member_id)')
          .neq('status', 'rejected') // exclude rejected
          .order('created_at', ascending: false);

      if (!mounted) return;

      setState(() {
        allIssues = List<Map<String, dynamic>>.from(response);
        _applyFilter();
      });
    } catch (e) {
      debugPrint('Error fetching issues: $e');
    } finally {
      if (mounted) setState(() => isLoadingIssues = false);
    }
  }
  // ─── FILTER ISSUES ────────────────────────────────────
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

  // ─── FETCH VOLUNTEERS ──────────────────────────────────
  Future<void> _fetchVolunteers() async {
    try {
      final response = await Supabase.instance.client
          .from('users')
          .select()
          .eq('role', 'volunteer')
          .eq('organization_id', 'SFD-001');
      List<Map<String, dynamic>> volunteerList =
          List<Map<String, dynamic>>.from(response);

      for (int i = 0; i < volunteerList.length; i++) {
        final taskCount = await Supabase.instance.client
            .from('tasks')
            .select()
            .eq('assigned_to', volunteerList[i]['id'])
            .count();

        volunteerList[i] = {...volunteerList[i], 'task_count': taskCount.count};
      }

      if (!mounted) return;

      setState(() {
        volunteers = volunteerList;
      });
    } catch (e) {
      debugPrint('Error fetching volunteers: $e');
    }
  }

  // ─── FILTER ISSUES ─────────────────────────────────────
  void _applyFilter() {
    if (selectedTab == 'All Issues') {
      filteredIssues = allIssues;
    } else if (selectedTab == 'Waiting') {
      filteredIssues = allIssues
          .where((i) => i['status'] == 'waiting')
          .toList();
    } else if (selectedTab == 'Approved') {
      filteredIssues = allIssues
          .where((i) => i['status'] == 'approved')
          .toList();
    } else if (selectedTab == 'Pending') {
      filteredIssues = allIssues
          .where((i) => i['status'] == 'pending')
          .toList();
    } else if (selectedTab == 'Resolved') {
      filteredIssues = allIssues
          .where((i) => i['status'] == 'resolved')
          .toList();
    }
  }

  // ─── ASSIGN VOLUNTEER ──────────────────────────────────
  void _assignVolunteer(String reportId) async {
    await _fetchVolunteers();

    if (!mounted) return;
    String? selectedVolunteerId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Assign Volunteer",
                    style: GoogleFonts.poppins(
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                "Select a volunteer to assign this issue:",
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 12),

              // Volunteer List
              volunteers.isEmpty
                  ? const Center(
                      child: Text(
                        'No volunteers available',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: volunteers.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final volunteer = volunteers[index];
                        final bool isSelected =
                            selectedVolunteerId == volunteer['id'];

                        return GestureDetector(
                          onTap: () {
                            setModalState(() {
                              selectedVolunteerId = volunteer['id'];
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFB8E6D5)
                                  : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF7ECBA9)
                                    : Colors.grey.shade200,
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: isSelected
                                      ? const Color(0xFF7ECBA9)
                                      : Colors.grey.shade300,
                                  child: Text(
                                    volunteer['full_name']?[0].toUpperCase() ??
                                        'V',
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.grey,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        volunteer['full_name'] ?? '',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: isSelected
                                              ? const Color(0xFF018F52)
                                              : Colors.black,
                                        ),
                                      ),
                                      Text(
                                        volunteer['member_id'] ?? '',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFF018F52)
                                        : Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${volunteer['task_count'] ?? 0} tasks', // use task_count
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.grey,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(
                                    Icons.check_circle,
                                    color: Color(0xFF018F52),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
              const SizedBox(height: 16),

              // Confirm Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: selectedVolunteerId == null
                      ? null
                      : () async {
                          Navigator.pop(context);
                          await _confirmAssign(reportId, selectedVolunteerId!);
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7ECBA9),
                    disabledBackgroundColor: Colors.grey.shade300,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Confirm Assignment',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  // ─── CONFIRM ASSIGN ────────────────────────────────────
  Future<void> _confirmAssign(String reportId, String volunteerId) async {
    try {
      final currentUser = Supabase.instance.client.auth.currentUser;

      if (currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session expired. Please login again.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Insert task as pending
      await Supabase.instance.client.from('tasks').insert({
        'report_id': reportId,
        'assigned_to': volunteerId,
        'assigned_by': currentUser.id,
        'status': 'pending', // pending until volunteer accepts
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Volunteer assigned successfully!'),
          backgroundColor: Color(0xFF7ECBA9),
        ),
      );

      _fetchIssues();
      _fetchStats();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to assign: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ─── APPROVE ISSUE ─────────────────────────────────────
  Future<void> _approveIssue(String reportId) async {
    try {
      await Supabase.instance.client
          .from('reports')
          .update({'status': 'approved'})
          .eq('id', reportId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Issue approved successfully!'),
          backgroundColor: Color(0xFF7ECBA9),
        ),
      );

      _fetchIssues();
      _fetchStats();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to approve: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  // ─── REJECT ISSUE ─────────────────────────────────────
  Future<void> _rejectIssue(String reportId) async {
    try {
      await Supabase.instance.client
          .from('reports')
          .update({'status': 'rejected'}) // 👈 store as rejected
          .eq('id', reportId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Issue rejected.'),
          backgroundColor: Colors.red,
        ),
      );

      _fetchIssues();
      _fetchStats();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to reject: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchStats();
    _fetchIssues();
    _fetchVolunteers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(55),
        child: Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
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
                        borderRadius: BorderRadius.circular(10),
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
      // Body
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height,
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
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
                            Icons.error_outline,
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
                  width: MediaQuery.of(context).size.width * 0.9,
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
                      SizedBox(height: 20),
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
                                  const SizedBox(height: 10),
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
        color: Colors.white,
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
                child: Icon(icon1, color: iconFontColor, size: 17),
              ),
            ],
          ),
          SizedBox(height: 40),
          Row(
            children: [
              Icon(icon2, color: iconFontColor, size: 14),
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

  // ─── ISSUE CARD ────────────────────────────────────────
  Widget _issueCard(Map<String, dynamic> issue) {
    final String status = issue['status'] ?? 'waiting';
    final bool isWaiting = status == 'waiting';
    final bool isApproved = status == 'approved';
    final bool isPending = status == 'pending';
    final bool isInProgress = status == 'in_progress';
    final bool isResolved = status == 'resolved';
    final String userName = issue['users']?['full_name'] ?? 'Unknown';
    final String memberId = issue['users']?['member_id'] ?? '';
    final String createdAt =
        issue['created_at']?.toString().substring(0, 16).replaceAll('T', ' ') ??
        '';

    Color statusColor;
    Color statusBgColor;
    String statusLabel;

    if (isWaiting) {
      statusColor = Colors.grey;
      statusBgColor = Colors.grey.shade100;
      statusLabel = 'Waiting';
    } else if (isApproved) {
      statusColor = Colors.teal;
      statusBgColor = Colors.teal.shade50;
      statusLabel = 'Approved';
    } else if (isPending) {
      statusColor = Colors.orange;
      statusBgColor = Colors.orange.shade50;
      statusLabel = 'Pending';
    } else if (isInProgress) {
      statusColor = Colors.blue;
      statusBgColor = Colors.blue.shade50;
      statusLabel = 'In Progress';
    } else {
      statusColor = Colors.green;
      statusBgColor = Colors.green.shade50;
      statusLabel = 'Resolved';
    }

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
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: statusBgColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.error_outline, color: statusColor, size: 16),
              ),
              const SizedBox(width: 10),
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: statusBgColor,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
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

          Text(
            issue['description'] ?? '',
            style: const TextStyle(fontSize: 12, color: Colors.black),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),

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
          const SizedBox(height: 12),

          // ─── Waiting — Approve + Reject ───────────
          if (isWaiting)
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _approveIssue(issue['id']),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7ECBA9),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Approve',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _rejectIssue(issue['id']),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Reject',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),

          // ─── Approved — Assign Volunteer ──────────
          if (isApproved)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _assignVolunteer(issue['id']),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  side: const BorderSide(color: Color(0xFF7ECBA9)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Assign Volunteer',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF018F52),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

          // ─── Pending — waiting for volunteer ──────
          if (isPending)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade100),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.hourglass_empty_outlined,
                    color: Colors.orange,
                    size: 14,
                  ),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Waiting for volunteer to accept the task.',
                      style: TextStyle(fontSize: 11, color: Colors.orange),
                    ),
                  ),
                ],
              ),
            ),

          // ─── In Progress — volunteer working ──────
          if (isInProgress)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.shade100),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.engineering_outlined,
                    color: Colors.blue,
                    size: 14,
                  ),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Volunteer is working on this issue.',
                      style: TextStyle(fontSize: 11, color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),

          // ─── Resolved ─────────────────────────────
          if (isResolved)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.shade100),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.check_circle_outline,
                    color: Colors.green,
                    size: 14,
                  ),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Issue has been successfully resolved.',
                      style: TextStyle(fontSize: 11, color: Colors.green),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
