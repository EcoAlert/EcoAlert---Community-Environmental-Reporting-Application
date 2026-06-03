import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fixalert/widgets/category_chip.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
final supabase = Supabase.instance.client;

double? latitude;
double? longitude;
class ReportIssuePage extends StatefulWidget {

  final Map<String, dynamic>? report;

  const ReportIssuePage({
    super.key,
    this.report,
  });

  @override
  State<ReportIssuePage> createState() => _ReportIssuePageState();
}

class _ReportIssuePageState extends State<ReportIssuePage> {

  final descriptionController = TextEditingController();
  final locationController = TextEditingController();
  @override
void initState() {
  super.initState();

  if (widget.report != null) {

    descriptionController.text =
        widget.report!['description'] ?? '';

    locationController.text =
        widget.report!['location'] ?? '';

    selectedCategory =
        widget.report!['category'] ?? '';
  }
}

  XFile? selectedImage;
  

  String selectedCategory = "";

  final picker = ImagePicker();

  Future<void> pickImage() async {

    final picked = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (picked != null) {
      setState(() {
        selectedImage = picked;
      });
    }
  }
  Future<void> getCurrentLocation() async {

  bool serviceEnabled;
  LocationPermission permission;

  serviceEnabled = await Geolocator.isLocationServiceEnabled();

  if (!serviceEnabled) {
    return;
  }

  permission = await Geolocator.checkPermission();

  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }

  Position position = await Geolocator.getCurrentPosition(
  desiredAccuracy: LocationAccuracy.high,
);

setState(() {
  latitude = position.latitude;
  longitude = position.longitude;

  locationController.text =
      "${position.latitude}, ${position.longitude}";
});
}
Future<void> submitReport() async {

  try {

    String? imageUrl;

    if (selectedImage != null) {

      final fileName =
          "${DateTime.now().millisecondsSinceEpoch}.png";

      await supabase.storage
          .from('reports')
          .uploadBinary(
  fileName,
  await selectedImage!.readAsBytes(),
);

      imageUrl = supabase.storage
          .from('reports')
          .getPublicUrl(fileName);
    }
    print("===========");
    print("Current User:");
    print(supabase.auth.currentUser);
    print("User ID:");
    print(supabase.auth.currentUser?.id);
    print("Email:");
    print(supabase.auth.currentUser?.email);
    print("===========");

    if (widget.report == null) {

  await supabase.from('reports').insert({
    'user_id': supabase.auth.currentUser?.id,
    'category': selectedCategory,
    'description': descriptionController.text,
    'location': locationController.text,
    'latitude': latitude,
    'longitude': longitude,
    'image_url': imageUrl,
    'status': 'pending',
  });

} else {

  await supabase
      .from('reports')
      .update({
    'category': selectedCategory,
    'description':
        descriptionController.text,
    'location':
        locationController.text,
  })
      .eq(
    'id',
    widget.report!['id'],
  );
}
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(

      const SnackBar(
        content: Text("Report submitted successfully"),
      ),
    );

    Navigator.pop(context, true);

  } catch (e) {

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(e.toString())),
    );
  }
}

  final categories = [
  {
    "title": "waste",
    "icon": Icons.delete_outline,
  },

  {
    "title": "drainage",
    "icon": Icons.water_drop_outlined,
  },

  {
    "title": "pollution",
    "icon": Icons.air,
  },

  {
    "title": "electrical",
    "icon": Icons.electrical_services_outlined,
  },

  {
    "title": "plumbing",
    "icon": Icons.plumbing_outlined,
  },

  {
    "title": "complaint",
    "icon": Icons.warning_amber_outlined,
  },

  {
    "title": "other",
    "icon": Icons.more_horiz,
  },
];

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F8),

      appBar: AppBar(
        backgroundColor: const Color(0xFF7ECBA9),
        title: const Text("Report Any Issue Near You"),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            const Text(
              "Help us keep our community safe by reporting issues in your area.",
              style: TextStyle(
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              "Photo Evidence",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 12),

            GestureDetector(
              onTap: pickImage,

              child: Container(
                height: 180,
                width: double.infinity,

                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.grey.shade400,
                  ),
                ),

                child: selectedImage == null
    ? const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [

          Icon(
            Icons.cloud_upload_outlined,
            size: 42,
            color: Colors.grey,
          ),

          SizedBox(height: 10),

          Text("Click to upload image"),
        ],
      )
    : ClipRRect(
        borderRadius: BorderRadius.circular(18),

        child: kIsWeb
            ? Image.network(
                selectedImage!.path,
                fit: BoxFit.cover,
                width: double.infinity,
              )
            : Image.file(
                File(selectedImage!.path),
                fit: BoxFit.cover,
                width: double.infinity,
              ),
      ),
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              "Category",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),

            const SizedBox(height: 12),

            Wrap(
              spacing: 10,
              runSpacing: 10,

              children: categories.map((category) {

                return CategoryChip(
                  icon: category['icon'] as IconData,
                  label: category['title'] as String,
                  selected: selectedCategory == category['title'],
                  onTap: () {
                    setState(() {
                      selectedCategory = category['title'] as String;
                    });
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            const Text(
  "Location",
  style: TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 16,
  ),
),

const SizedBox(height: 12),

Row(
  children: [

    Expanded(
      child: TextField(
        controller: locationController,

        decoration: InputDecoration(
          hintText: "Enter location",

          filled: true,
          fillColor: Colors.white,

          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),

          prefixIcon: const Icon(Icons.location_on_outlined),
        ),
      ),
    ),

    const SizedBox(width: 10),

    GestureDetector(
      onTap: getCurrentLocation,

      child: Container(
        padding: const EdgeInsets.all(14),

        decoration: BoxDecoration(
          color: const Color(0xFF018F52),
          borderRadius: BorderRadius.circular(14),
        ),

        child: const Icon(
          Icons.my_location,
          color: Colors.white,
        ),
      ),
    )
  ],
),
            const Text(
  "Description",
  style: TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 16,
  ),
),

const SizedBox(height: 12),

TextField(
  controller: descriptionController,
  maxLines: 5,

  decoration: InputDecoration(
    hintText:
        "Describe the issue in detail...",

    filled: true,
    fillColor: Colors.white,

    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),

    contentPadding: const EdgeInsets.all(16),
  ),
),
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,

              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF018F52),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),

                onPressed: submitReport,

                child: Text(
  widget.report == null
      ? "Submit Report"
      : "Update Report",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}