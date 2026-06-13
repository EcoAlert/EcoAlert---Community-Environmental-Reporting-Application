import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fixalert/widgets/category_chip.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';

class ReportIssuePage extends StatefulWidget {
  final Map<String, dynamic>? report;

  const ReportIssuePage({super.key, this.report});

  @override
  State<ReportIssuePage> createState() => _ReportIssuePageState();
}

class _ReportIssuePageState extends State<ReportIssuePage> {
  final supabase = Supabase.instance.client;

  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final locationController = TextEditingController();

  double? latitude;
  double? longitude;

  XFile? selectedImage;
  String selectedCategory = "";
  final picker = ImagePicker();

  final categories = [
    {"title": "waste", "display": "Garbage", "icon": Icons.delete_outline},
    {
      "title": "drainage",
      "display": "Water Pollution",
      "icon": Icons.water_drop_outlined,
    },
    {"title": "pollution", "display": "Air Pollution", "icon": Icons.air},
    {
      "title": "electrical",
      "display": "Electrical",
      "icon": Icons.electrical_services_outlined,
    },
    {
      "title": "complaint",
      "display": "Illegal Dumping",
      "icon": Icons.warning_amber_outlined,
    },
    {"title": "other", "display": "Recycling Issue", "icon": Icons.recycling},
  ];

  @override
  void initState() {
    super.initState();

    if (widget.report != null) {
      titleController.text = widget.report!['title'] ?? '';
      descriptionController.text = widget.report!['description'] ?? '';
      locationController.text = widget.report!['location'] ?? '';
      selectedCategory = widget.report!['category'] ?? '';
    }
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose(); // dispose controllers
    locationController.dispose();
    super.dispose();
  }

  Future<void> pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        selectedImage = picked;
      });
    }
  }

  Future<void> getCurrentLocation() async {
    // 1. Check if location service is on
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Location services are disabled.")),
      );
      return;
    }

    // 2. Check permission
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Location permission denied.")),
        );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Location permission permanently denied."),
        ),
      );
      return;
    }

    // 3. Get GPS position
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    // 4. Set coordinates immediately as fallback text
    if (!mounted) return;
    setState(() {
      latitude = position.latitude;
      longitude = position.longitude;
      locationController.text = "${position.latitude}, ${position.longitude}";
    });

    // 5. Reverse geocode using Nominatim (web-safe, no API key needed)
    try {
      final url = Uri.parse(
        "https://nominatim.openstreetmap.org/reverse"
        "?lat=${position.latitude}&lon=${position.longitude}&format=json",
      );

      final response = await http.get(
        url,
        headers: {'Accept': 'application/json', 'User-Agent': 'FixAlert/1.0'},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final address = data['display_name'];

        if (address != null && address.toString().isNotEmpty) {
          setState(() {
            locationController.text = address;
          });
        }
      }
    } catch (e) {
      // Coordinates already set in step 4, so safe to silently ignore
    }
  }

  Future<void> submitReport() async {
    // Validate fields before submitting
    if (selectedCategory.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a category.")),
      );
      return;
    }

    if (titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please enter a title.")));
      return;
    }

    if (descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a description.")),
      );
      return;
    }

    if (locationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please enter a location.")));
      return;
    }

    try {
      String? imageUrl;

      if (selectedImage != null) {
        final fileName = "${DateTime.now().millisecondsSinceEpoch}.png";

        await supabase.storage
            .from('reports')
            .uploadBinary(fileName, await selectedImage!.readAsBytes());

        imageUrl = supabase.storage.from('reports').getPublicUrl(fileName);
      }

      if (widget.report == null) {
        await supabase.from('reports').insert({
          'user_id': supabase.auth.currentUser!.id,
          'organization_id': 'SFD-001',
          'title': titleController.text.trim(),
          'reported_by': supabase.auth.currentUser?.id,

          'category': selectedCategory,
          'description': descriptionController.text.trim(),
          'location': locationController.text.trim(),
          'latitude': latitude,
          'longitude': longitude,
          'image_url': imageUrl,
          'status': 'waiting',
        });
      } else {
        await supabase
            .from('reports')
            .update({
              'title': titleController.text.trim(),
              'category': selectedCategory,
              'description': descriptionController.text.trim(),
              'location': locationController.text.trim(),
            })
            .eq('id', widget.report!['id']);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Report submitted successfully.")),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: ${e.toString()}")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9F8),

      appBar: AppBar(
        backgroundColor: const Color(0xFF7ECBA9),
        titleSpacing: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20), // ✅ rounded appbar
          ),
        ),
        title: const Text(
          "Report Any Issue Near You",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const Text(
              "Help us keep our community safe by reporting issues in your area.",
              style: TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 24),

            const Text(
              "Photo Evidence",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),

            const SizedBox(height: 12),

            InkWell(
              onTap: pickImage,

              child: Container(
                height: 180,
                width: double.infinity,

                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.grey.shade400),
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
              "Title",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: titleController,
              decoration: InputDecoration(
                hintText: "Enter issue title",
                filled: true,
                fillColor: Colors.white,

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),

                prefixIcon: const Icon(Icons.edit_note),
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              "Category",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),

            const SizedBox(height: 12),

            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,

              children: categories.map((category) {
                final width = (MediaQuery.of(context).size.width - 55) / 2;

                return SizedBox(
                  width: width,
                  height: width * 0.9,

                  child: CategoryChip(
                    icon: category['icon'] as IconData,
                    label: category['title'] as String,
                    selected: selectedCategory == category['title'],
                    onTap: () {
                      setState(() {
                        selectedCategory = category['title'] as String;
                      });
                    },
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            const Text(
              "Location",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
                      color: const Color(0xFF7ECBA9),
                      borderRadius: BorderRadius.circular(14),
                    ),

                    child: const Icon(Icons.my_location, color: Colors.white),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24), // ✅ missing SizedBox added

            const Text(
              "Description",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: descriptionController,
              maxLines: 5,

              decoration: InputDecoration(
                hintText: "Describe the issue in detail...",
                filled: true,
                fillColor: Colors.white,

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
                ),

                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: Colors.grey.shade300,
                    width: 1,
                  ), // ← thin border
                ),

                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: Color(0xFF7ECBA9),
                    width: 1.5,
                  ), // ← green when focused
                ),

                contentPadding: const EdgeInsets.all(16),
              ),
            ),

            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,

              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF7ECBA9),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    // rounded button
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),

                onPressed: submitReport,

                child: Text(
                  widget.report == null ? "Submit Report" : "Update Report",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
