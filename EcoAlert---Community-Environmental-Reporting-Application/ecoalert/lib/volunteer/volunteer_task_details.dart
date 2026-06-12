import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VolunteerTaskDetails extends StatefulWidget {
  final Map<String, dynamic> task;

  const VolunteerTaskDetails({
    super.key,
    required this.task,
  });

  @override
  State<VolunteerTaskDetails> createState() =>
      _VolunteerTaskDetailsState();
}

class _VolunteerTaskDetailsState
    extends State<VolunteerTaskDetails> {

  late Map<String, dynamic> taskData;

  @override
  void initState() {
    super.initState();
    taskData = Map<String, dynamic>.from(widget.task);
  }

  Future<void> updateStatus(BuildContext context, String status) async {
    final supabase = Supabase.instance.client;

    await supabase
        .from('tasks')
        .update({'status': status})
        .eq('id', taskData['id']);

    await supabase
        .from('reports')
        .update({'status': status})
        .eq('id', taskData['report_id']);

    Navigator.pop(context, true);
  }

  Future<void> uploadVerificationImage(BuildContext context) async {
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

      final imageUrl =
          supabase.storage.from('reports').getPublicUrl(fileName);

      await supabase.from('tasks').update({
        'verification_image': imageUrl,
      }).eq('id', taskData['id']);
      setState(() {
  taskData['verification_image'] = imageUrl;
});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Verification image uploaded"),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
        ),
      );
    }
  }

  Future<void> resolveTask(BuildContext context) async {
    final supabase = Supabase.instance.client;

    final res = await supabase
        .from('tasks')
        .select('verification_image')
        .eq('id', taskData['id'])
        .single();

    final image = res['verification_image'];

    if (image == null || image.toString().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please upload verification image first",
          ),
        ),
      );
      return;
    }

    await updateStatus(context, 'resolved');
  }

  Widget buildImageCard({
  required String title,
  required String? imageUrl,
  required IconData icon,
  required Color color,
}) {
  return Container(
    margin: const EdgeInsets.only(bottom: 20),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
  BoxShadow(
    color: color.withOpacity(0.15),
    blurRadius: 18,
    spreadRadius: 1,
    offset: const Offset(0, 6),
  ),
],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (imageUrl != null && imageUrl.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.network(
              imageUrl,
              height: 220,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          )
        else
          Container(
            height: 220,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Center(
              child: Text(
                "No image available",
              ),
            ),
          ),
      ],
    ),
  );
}

  @override
Widget build(BuildContext context) {
  final report = taskData['reports'];

  final beforeImage = report['image_url'];
  final afterImage = taskData['verification_image'];

  return Scaffold(
    backgroundColor: const Color(0xFFF3F6FA),

    appBar: AppBar(
      backgroundColor: const Color(0xFF7ECBA9),
      centerTitle: true,
      elevation: 0,
      title: const Text(
        "Task Details",
        style: TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
    ),

    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // TASK CARD
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
  BoxShadow(
    color: Colors.black.withOpacity(0.12),
    blurRadius: 15,
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
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  report['description'] ?? '',
                  style: const TextStyle(
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 15),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: taskData['status'] == 'resolved'
                        ? Colors.green.withOpacity(0.2)
                        : Colors.orange.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    taskData['status'] ?? 'waiting',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          buildImageCard(
            title: "Before Image",
            imageUrl: beforeImage,
            icon: Icons.image,
            color: Colors.blue,
          ),

          buildImageCard(
            title: "After Image",
            imageUrl: afterImage,
            icon: Icons.check_circle,
            color: Colors.green,
          ),

          const SizedBox(height: 10),

          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.handshake),
              label: const Text("Accept Task"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              onPressed: () =>
                  updateStatus(context, 'in_progress'),
            ),
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.upload),
              label: const Text("Upload Solved Image"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7ECBA9),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              onPressed: () =>
                  uploadVerificationImage(context),
            ),
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.check_circle),
              label: const Text("Mark Resolved"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              onPressed: () =>
                  resolveTask(context),
            ),
          ),
        ],
      ),
    ),
  );
}
}