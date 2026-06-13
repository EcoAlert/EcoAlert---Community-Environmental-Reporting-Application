import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'volunteer_task_details.dart';
import 'volunteer_history.dart';
import 'package:intl/intl.dart';

class VolunteerDashboard extends StatefulWidget {
  const VolunteerDashboard({super.key});

  @override
  State<VolunteerDashboard> createState() => _VolunteerDashboardState();
}

class _VolunteerDashboardState extends State<VolunteerDashboard> {
  List tasks = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchTasks();
  }

  Future<void> fetchTasks() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) return;

      final res = await supabase
          .from('tasks')
          .select('*, reports(*)')
          .eq('assigned_to', user.id)
          .order('created_at', ascending: false);

      if (!mounted) return;

      setState(() {
        tasks = List<Map<String, dynamic>>.from(res);
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Fetch error: $e")));
    }
  }

  Future<void> updateStatus(
    String taskId,
    String reportId,
    String status,
  ) async {
    final supabase = Supabase.instance.client;
    await supabase.from('tasks').update({'status': status}).eq('id', taskId);
    await supabase
        .from('reports')
        .update({'status': status})
        .eq('id', reportId);
    fetchTasks();
  }

  // Accept task — sets status to in_progress
  Future<void> acceptTask(String taskId, String reportId) async {
    await updateStatus(taskId, reportId, 'in_progress');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: const Color(0xFF7ECBA9),
        title: const Text(
          "Volunteer Dashboard",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person, size: 22),
            onPressed: () => Navigator.pushNamed(context, '/volunteer_profile'),
          ),
          IconButton(
            icon: const Icon(Icons.history, size: 22),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const VolunteerHistory()),
            ),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ── Stats Cards ──────────────────────────
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _topCard(
                            "Reports",
                            tasks.length.toString(),
                            Icons.list_alt,
                            Colors.purpleAccent,
                          ),
                          const SizedBox(width: 10),
                          _topCard(
                            "Waiting",
                            tasks
                                .where((t) => t['status'] == 'waiting')
                                .length
                                .toString(),
                            Icons.hourglass_empty,
                            Colors.amber,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _topCard(
                            "In Progress",
                            tasks
                                .where((t) => t['status'] == 'in_progress')
                                .length
                                .toString(),
                            Icons.autorenew,
                            Colors.lightBlueAccent,
                          ),
                          const SizedBox(width: 10),
                          _topCard(
                            "Resolved",
                            tasks
                                .where((t) => t['status'] == 'resolved')
                                .length
                                .toString(),
                            Icons.check_circle,
                            Colors.green,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // ── Task List ────────────────────────────
                Expanded(
                  child: tasks.isEmpty
                      ? const Center(
                          child: Text(
                            "No tasks assigned yet.",
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: tasks.length,
                          itemBuilder: (context, index) {
                            final t = tasks[index];
                            final report = (t['reports'] is Map)
                                ? Map<String, dynamic>.from(t['reports'])
                                : {};
                            final imageUrl =
                                report['image_url']?.toString() ?? '';
                            final String status = t['status'] ?? '';
                            final bool isPending = status == 'pending';
                            final String createdAt =
                                report['created_at'] != null
                                ? DateFormat('dd MMM yyyy, hh:mm a').format(
                                    DateTime.parse(
                                      report['created_at'],
                                    ).toLocal(),
                                  )
                                : '';

                            return GestureDetector(
                              onTap: () async {
                                // ✅ Only navigate if status is in_progress or task_completed
                                if (status == 'pending') {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "Accept the task first to view details.",
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                if (status == 'resolved') {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        "This task has already been resolved.",
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                if (status != 'in_progress' &&
                                    status != 'task_completed')
                                  return;

                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        VolunteerTaskDetails(task: t),
                                  ),
                                );
                                if (result == true) fetchTasks();
                              },
                              child: Container(
                                margin: const EdgeInsets.symmetric(vertical: 8),
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.10),
                                      blurRadius: 14,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Report image
                                    if (imageUrl.isNotEmpty)
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(14),
                                        child: SizedBox(
                                          height: 160,
                                          width: double.infinity,
                                          child: Image.network(
                                            imageUrl,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    if (imageUrl.isNotEmpty)
                                      const SizedBox(height: 10),

                                    // Title
                                    Text(
                                      report['title'] ?? 'No Title',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 6),

                                    // Description
                                    Text(
                                      report['description'] ?? "",
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 6),

                                    // Category
                                    Text(
                                      "Category: ${report['category'] ?? ''}",
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                    const SizedBox(height: 6),

                                    // Assigned by
                                    Text("Assigned by: Admin"),
                                    const SizedBox(height: 6),

                                    // Location
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on, size: 18),
                                        const SizedBox(width: 5),
                                        Expanded(
                                          child: Text(
                                            report['location'] ?? "Unknown",
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),

                                    // Date + Status row
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          createdAt,
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 12,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: _statusColor(
                                              status,
                                            ).withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(
                                              30,
                                            ),
                                            border: Border.all(
                                              color: _statusColor(
                                                status,
                                              ).withOpacity(0.4),
                                            ),
                                          ),
                                          child: Text(
                                            status,
                                            style: TextStyle(
                                              color: _statusColor(status),
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),

                                    // ── Accept Task button (only when pending) ──
                                    if (isPending) ...[
                                      const SizedBox(height: 12),
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton.icon(
                                          icon: const Icon(
                                            Icons.handshake,
                                            size: 16,
                                          ),
                                          label: const Text("Accept Task"),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(
                                              0xFF7ECBA9,
                                            ),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 10,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                          ),
                                          onPressed: () => acceptTask(
                                            t['id'].toString(),
                                            t['report_id'].toString(),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _topCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.15),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 0, 3, 0),
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Color.fromARGB(255, 0, 3, 0),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'resolved':
        return const Color.fromARGB(255, 21, 129, 24);
      case 'in_progress':
        return const Color.fromARGB(255, 167, 105, 12);
      case 'task_completed':
        return Colors.purpleAccent;
      default:
        return Colors.red;
    }
  }
}
