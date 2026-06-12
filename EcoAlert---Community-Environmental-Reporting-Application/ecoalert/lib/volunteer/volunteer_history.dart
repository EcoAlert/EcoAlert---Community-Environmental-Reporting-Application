import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VolunteerHistory extends StatefulWidget {
  const VolunteerHistory({super.key});

  @override
  State<VolunteerHistory> createState() => _VolunteerHistoryState();
}

class _VolunteerHistoryState extends State<VolunteerHistory> {
  List tasks = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchHistory();
  }

  Future<void> fetchHistory() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;

      final response = await Supabase.instance.client
          .from('tasks')
          .select('*, reports(*)')
          .eq('assigned_to', user!.id)
          .eq('status', 'resolved')
          .order('created_at', ascending: false);

      setState(() {
        tasks = response;
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
      });
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
          "Completed Tasks",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : tasks.isEmpty
          ? const Center(
              child: Text(
                "No completed tasks yet",
                style: TextStyle(fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: tasks.length,
              itemBuilder: (context, index) {
                final task = tasks[index];
                final report = task['reports'];

                final beforeImage = report['image_url']?.toString() ?? '';

                final afterImage = task['verification_image']?.toString() ?? '';

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.12),
                        blurRadius: 16,
                        spreadRadius: 2,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        report['title'] ?? '',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 6),

                      Text(report['description'] ?? ''),

                      const SizedBox(height: 12),

                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: Colors.green.withOpacity(0.3),
                          ),
                        ),
                        child: const Text(
                          "Resolved",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      const Text(
                        "Before Image",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),

                      const SizedBox(height: 8),

                      if (beforeImage.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            beforeImage,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),

                      const SizedBox(height: 16),

                      const Text(
                        "After Image",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),

                      const SizedBox(height: 8),

                      if (afterImage.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.network(
                            afterImage,
                            height: 180,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        )
                      else
                        const Text("No verification image"),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
