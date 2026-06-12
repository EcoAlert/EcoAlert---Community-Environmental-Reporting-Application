import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VolunteerProfile extends StatefulWidget {
  const VolunteerProfile({super.key});

  @override
  State<VolunteerProfile> createState() => _VolunteerProfileState();
}

class _VolunteerProfileState extends State<VolunteerProfile> {
  final supabase = Supabase.instance.client;
  Map<String, dynamic>? userData;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    final user = supabase.auth.currentUser;

    final data = await supabase
        .from('users')
        .select()
        .eq('id', user!.id)
        .single();

    setState(() {
      userData = data;
      loading = false;
    });
  }

  Future<void> uploadAvatar() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);

      if (image == null) return;

      final user = supabase.auth.currentUser!;
      final fileName = "avatar_${user.id}.png";

      await supabase.storage
          .from('avatars')
          .uploadBinary(
            fileName,
            await image.readAsBytes(),
            fileOptions: const FileOptions(upsert: true),
          );

      final imageUrl = supabase.storage.from('avatars').getPublicUrl(fileName);

      await supabase
          .from('users')
          .update({'avatar_url': imageUrl})
          .eq('id', user.id);

      fetchProfile();
    } catch (e) {
      debugPrint("ERROR: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FA),

      appBar: AppBar(
        title: const Text("Volunteer Profile"),
        backgroundColor: const Color(0xFF7ECBA9),
        centerTitle: true,
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : userData == null
          ? const Center(child: Text("No profile found"))
          : Padding(
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // PROFILE IMAGE
                    GestureDetector(
                      onTap: uploadAvatar,
                      child: CircleAvatar(
                        radius: 55,
                        backgroundColor: const Color(0xFFB8E6D5),
                        backgroundImage: userData!['avatar_url'] != null
                            ? NetworkImage(userData!['avatar_url'])
                            : null,
                        child: userData!['avatar_url'] == null
                            ? const Icon(
                                Icons.person,
                                size: 50,
                                color: const Color(0xFF7ECBA9),
                              )
                            : null,
                      ),
                    ),

                    const SizedBox(height: 10),
                    const Text(
                      "Tap to change photo",
                      style: TextStyle(color: Colors.grey),
                    ),

                    const SizedBox(height: 20),

                    // NAME
                    Text(
                      userData!['full_name'] ?? '',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(userData!['role'] ?? ''),
                    Text(userData!['email'] ?? ''),

                    const SizedBox(height: 10),

                    // INFO CARD
                    _infoCard("Member ID", userData!['member_id']),
                    const SizedBox(height: 10),
                    _infoCard("Organization", userData!['organization_id']),

                    SizedBox(height: 10),
                    // LOGOUT BUTTON
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF018F52),
                          padding: const EdgeInsets.all(14),
                        ),
                        onPressed: () async {
                          await supabase.auth.signOut();
                          if (!context.mounted) return;
                          Navigator.pushReplacementNamed(context, '/login');
                        },
                        child: const Text("Logout"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _infoCard(String title, dynamic value) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 12,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 4),
          Text(
            value ?? '',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
