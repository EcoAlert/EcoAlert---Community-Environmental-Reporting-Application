import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fixalert/auth_service.dart';
import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final supabase = Supabase.instance.client;

  Future<void> uploadAvatar() async {
    try {
      final picker = ImagePicker();

      final image = await picker.pickImage(source: ImageSource.gallery);

      if (image == null) return;

      final fileName = "avatar_${supabase.auth.currentUser!.id}.png";

      await supabase.storage
          .from('avatars')
          .uploadBinary(
            fileName,
            await image.readAsBytes(),
            fileOptions: const FileOptions(upsert: true),
          );

      final imageUrl =
          '${supabase.storage.from('avatars').getPublicUrl(fileName)}?t=${DateTime.now().millisecondsSinceEpoch}';

      await supabase
          .from('users')
          .update({'avatar_url': imageUrl})
          .eq('id', supabase.auth.currentUser!.id);

      setState(() {});
    } catch (e) {
      print("ERROR: $e");

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: FutureBuilder(
          future: supabase
              .from('users')
              .select()
              .eq('id', supabase.auth.currentUser!.id)
              .single(),

          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text(snapshot.error.toString()));
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final user = snapshot.data as Map<String, dynamic>;

            return SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),

                  Material(
                    color: Colors.transparent,
                    shape: const CircleBorder(),

                    child: InkWell(
                      onTap: uploadAvatar,
                      customBorder: const CircleBorder(),

                      splashColor: const Color(0xFF7ECBA9),
                      highlightColor: Colors.transparent,

                      child: Padding(
                        padding: const EdgeInsets.all(4),

                        child: CircleAvatar(
                          radius: 50,

                          backgroundImage: user['avatar_url'] != null
                              ? NetworkImage(user['avatar_url'])
                              : null,

                          backgroundColor: const Color(0xFFB8E6D5),

                          child: user['avatar_url'] == null
                              ? const Icon(
                                  Icons.person,
                                  size: 45,
                                  color: Color(0xFF018F52),
                                )
                              : null,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  const Text(
                    "Tap photo to change",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),

                  const SizedBox(height: 16),

                  Text(
                    user['full_name'] ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Text(
                    user['role'] ?? '',
                    style: const TextStyle(color: Colors.grey),
                  ),

                  const SizedBox(height: 30),

                  _profileTile(
                    icon: Icons.badge_outlined,
                    title: "Member ID",
                    subtitle: user['member_id'] ?? '',
                  ),

                  const SizedBox(height: 14),

                  _profileTile(
                    icon: Icons.email_outlined,
                    title: "Email",
                    subtitle: user['email'] ?? '',
                  ),

                  const SizedBox(height: 14),

                  _profileTile(
                    icon: Icons.person_outline,
                    title: "Role",
                    subtitle: user['role'] ?? '',
                  ),

                  const SizedBox(height: 30),

                  SizedBox(
                    width: double.infinity,

                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF018F52),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),

                      onPressed: () async {
                        await AuthService.logout();

                        if (!context.mounted) return;

                        Navigator.pushNamedAndRemoveUntil(
                          context,
                          '/login',
                          (route) => false,
                        );
                      },

                      child: const Text(
                        "Logout",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _profileTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),

        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),

      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF018F52)),

          const SizedBox(width: 14),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),

              const SizedBox(height: 4),

              Text(
                subtitle,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
