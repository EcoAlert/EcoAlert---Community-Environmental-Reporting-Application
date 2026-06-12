import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static final _client = Supabase.instance.client;

  // ─── SIGN UP ───────────────────────────────
  static Future<Map<String, dynamic>> signUp({
    required String memberId,
    required String organizationId,
    required String fullName,
    required String email,
    required String password,
    required String selectedRole,
  }) async {
    try {
      final orgCheck = await _client
          .from('organizations')
          .select()
          .eq('id', organizationId)
          .maybeSingle();

      if (orgCheck == null) {
        return {'success': false, 'message': 'Organization not found'};
      }

      final memberCheck = await _client
          .from('organization_members')
          .select()
          .eq('member_id', memberId)
          .eq('organization_id', organizationId)
          .maybeSingle();

      if (memberCheck == null) {
        return {'success': false, 'message': 'Invalid member ID'};
      }

      final authResponse = await _client.auth.signUp(
        email: email,
        password: password,
      );

      final user = authResponse.user;

      if (user == null) {
        return {'success': false, 'message': 'Signup failed'};
      }

      // 🔥 IMPORTANT FIX: store AUTH ID correctly
      await _client.from('users').insert({
        'id': user.id, // THIS IS CRITICAL
        'member_id': memberId,
        'organization_id': organizationId,
        'email': email,
        'role': memberCheck['role'],
        'full_name': fullName,
      });

      return {
        'success': true,
        'role': memberCheck['role'],
        'message': 'Signup success',
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ─── LOGIN ───────────────────────────────
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final authResponse = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = authResponse.user;

      if (user == null) {
        return {'success': false, 'message': 'Invalid login'};
      }

      // 🔥 FIXED QUERY (IMPORTANT)
      final userDetails = await _client
          .from('users')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (userDetails == null) {
        return {'success': false, 'message': 'User not found in DB'};
      }

      return {
        'success': true,
        'role': userDetails['role'],
      };
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<void> logout() async {
    await _client.auth.signOut();
  }
}