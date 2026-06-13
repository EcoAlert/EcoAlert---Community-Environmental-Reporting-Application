import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'volunteer_task_details.dart';
import 'volunteer_history.dart';

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

  // FIXED FETCH TASKS
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

  // FIXED STATUS UPDATE
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

  // FIXED IMAGE UPLOAD (USING WORKING CITIZEN STYLE)
  Future<void> uploadVerificationImage(String taskId) async {
    try {
      final picker = ImagePicker();

      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70,
      );

      if (pickedFile == null) return;

      final bytes = await pickedFile.readAsBytes();

      final fileName =
          "verification_${DateTime.now().millisecondsSinceEpoch}.jpg";

      final supabase = Supabase.instance.client;

      // SAME AS CITIZEN (SAFE BUCKET)
      await supabase.storage
          .from('reports')
          .uploadBinary(
            fileName,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'image/jpeg',
              upsert: true,
            ),
          );

      final imageUrl = supabase.storage.from('reports').getPublicUrl(fileName);

      await supabase
          .from('tasks')
          .update({'verification_image': imageUrl})
          .eq('id', taskId);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Verification image uploaded")),
      );

      fetchTasks();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Upload error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),

      appBar: AppBar(
        backgroundColor: const Color(0xFF7ECBA9),
        centerTitle: true,
        title: const Text(
          "Volunteer Dashboard",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.pushNamed(context, '/volunteer_profile');
            },
          ),

          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const VolunteerHistory()),
              );
            },
          ),
        ],
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
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
                            Colors.blue,
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
                            Colors.orange,
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

                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      final t = tasks[index];

                      final report = (t['reports'] is Map)
                          ? Map<String, dynamic>.from(t['reports'])
                          : {};

                      final imageUrl = report['image_url']?.toString() ?? '';

                      return GestureDetector(
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => VolunteerTaskDetails(task: t),
                            ),
                          );

                          if (result == true) {
                            fetchTasks();
                          }
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

                              Text(
                                report['title'] ?? 'No Title',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              const SizedBox(height: 6),
                              Text(report['description'] ?? ""),
                              const SizedBox(height: 6),
                              Text("Category: ${report['category'] ?? ''}"),
                              const SizedBox(height: 6),
                              Text(
                                "Assigned by: ${t['assigned_by'] ?? 'Admin'}",
                              ),

                              const SizedBox(height: 6),
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

                              Align(
                                alignment: Alignment.centerRight,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _statusColor(
                                      t['status'] ?? '',
                                    ).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(
                                      color: _statusColor(
                                        t['status'] ?? '',
                                      ).withOpacity(0.4),
                                    ),
                                  ),
                                  child: Text(
                                    t['status'] ?? 'pending',
                                    style: TextStyle(
                                      color: _statusColor(t['status'] ?? ''),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
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
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08), // 👈 soft background like teammate UI
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.10),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: color.withOpacity(0.15),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 0, 3, 0),
                  ),
                ),
                Text(title),
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
      default:
        return Colors.red;
    }
  }
}
