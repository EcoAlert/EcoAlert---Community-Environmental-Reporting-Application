import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';

class VolunteerTaskDetails extends StatefulWidget {
  final Map<String, dynamic> task;

  const VolunteerTaskDetails({super.key, required this.task});

  @override
  State<VolunteerTaskDetails> createState() => _VolunteerTaskDetailsState();
}

class _VolunteerTaskDetailsState extends State<VolunteerTaskDetails> {
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
      final double? reportLat = (taskData['reports']['latitude'] as num?)
          ?.toDouble();

      final double? reportLng = (taskData['reports']['longitude'] as num?)
          ?.toDouble();
      debugPrint("REPORT LAT: $reportLat");
      debugPrint("REPORT LNG: $reportLng");
      debugPrint("REPORT DATA: ${taskData['reports']}");

      if (reportLat != null && reportLng != null) {
        // 👈 Step 1: Check if location service is enabled
        bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
        if (!serviceEnabled) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Location services are disabled. Please enable GPS.',
              ),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // 👈 Step 2: Check permission
        LocationPermission permission = await Geolocator.checkPermission();
        if (permission == LocationPermission.denied) {
          permission = await Geolocator.requestPermission();
          if (permission == LocationPermission.denied) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Location permission denied.'),
                backgroundColor: Colors.red,
              ),
            );
            return;
          }
        }

        if (permission == LocationPermission.deniedForever) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission permanently denied.'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }

        // 👈 Step 3: Get current position with high accuracy
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.bestForNavigation, // 👈 highest accuracy
            distanceFilter: 0,
          ),
        );
        debugPrint("CURRENT LAT: ${position.latitude}");
        debugPrint("CURRENT LNG: ${position.longitude}");

        final double distance = Geolocator.distanceBetween(
          reportLat,
          reportLng,
          position.latitude,
          position.longitude,
        );

        debugPrint("DISTANCE: $distance");

        if (distance > 10) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "You are ${distance.toStringAsFixed(0)}m away from the report site. Please go to the location first.",
              ),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      // 3. Force camera for both GPS and manual/indoor reports
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.camera,
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

      final imageUrl = supabase.storage.from('reports').getPublicUrl(fileName);
      await supabase
          .from('tasks')
          .update({'verification_image': imageUrl})
          .eq('id', taskData['id']);

      setState(() => taskData['verification_image'] = imageUrl);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Verification image uploaded ✅"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  // Submit Task Completion — requires verification image first
  Future<void> submitTaskCompletion(BuildContext context) async {
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
          content: Text("Please upload the verification image first."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    await updateStatus(context, 'task_completed');
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
              child: const Center(child: Text("No image available")),
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
    final String status = taskData['status'] ?? '';
    final bool isCompleted = status == 'task_completed' || status == 'resolved';

    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF7ECBA9),
        centerTitle: true,
        elevation: 0,
        title: const Text(
          "Task Details",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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

            // Take Photo Of Solved Issue button
            if (!isCompleted) ...[
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.upload),
                  label: const Text("Take Photo Of Solved Issue"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7ECBA9),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: () => uploadVerificationImage(context),
                ),
              ),
              const SizedBox(height: 12),

              // Submit Task Completion button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.task_alt),
                  label: const Text("Submit Task Completion"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.teal,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  onPressed: () => submitTaskCompletion(context),
                ),
              ),
            ],

            // Show completed message
            if (isCompleted)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.teal.shade100),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.teal),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Task submitted. Waiting for admin review.",
                        style: TextStyle(color: Colors.teal),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
