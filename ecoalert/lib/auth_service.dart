import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  static final _client = Supabase.instance.client;

  // ─── SIGN UP ───────────────────────────────────────────
  static Future<Map<String, dynamic>> signUp({
    required String memberId,
    required String organizationId,
    required String fullName,
    required String email,
    required String password,
    required String selectedRole,
  }) async {
    try {
      // Step 1: Check if organization_id exists
      final orgCheck = await _client
          .from('organizations')
          .select()
          .eq('id', organizationId)
          .maybeSingle();

      if (orgCheck == null) {
        return {
          'success': false,
          'message':
              'Organization not found. Please check your Organization ID.',
        };
      }

      // Step 2: Check if member_id exists AND belongs to that organization
      final memberCheck = await _client
          .from('organization_members')
          .select()
          .eq('member_id', memberId)
          .eq('organization_id', organizationId)
          .maybeSingle();

      if (memberCheck == null) {
        return {
          'success': false,
          'message': 'Member ID does not belong to this organization.',
        };
      }

      // Step 3: Cross-check selected role with actual role
      if (memberCheck['role'] != selectedRole) {
        return {
          'success': false,
          'message': 'Selected role does not match your Member ID.',
        };
      }

      // Step 4: Check if already registered
      if (memberCheck['is_registered'] == true) {
        return {'success': false, 'message': 'This ID is already registered.'};
      }

      // Step 5: Create auth account
      final authResponse = await _client.auth.signUp(
        email: email,
        password: password,
      );

      if (authResponse.user == null) {
        return {
          'success': false,
          'message': 'Sign up failed. Please try again.',
        };
      }

      // 👈 add this — wait for session to be ready
      await Future.delayed(const Duration(seconds: 1));

      // Step 6: Insert into users table
      await _client.from('users').insert({
        'id': authResponse.user!.id,
        'member_id': memberId,
        'organization_id': organizationId,
        'email': email,
        'role': memberCheck['role'],
        'full_name': fullName,
      });

      // Step 7: Mark member_id as registered
      await _client
          .from('organization_members')
          .update({'is_registered': true})
          .eq('member_id', memberId);

      return {
        'success': true,
        'role': memberCheck['role'],
        'message': 'Account created successfully!',
      };
    } catch (e) {
      return {'success': false, 'message': 'Something went wrong: $e'};
    }
  }

  // ─── LOGIN ─────────────────────────────────────────────
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      // Step 1: Sign in with Supabase Auth
      final authResponse = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (authResponse.user == null) {
        return {'success': false, 'message': 'Invalid email or password.'};
      }

      // Step 2: Fetch role from users table
      final userDetails = await _client
          .from('users')
          .select()
          .eq('id', authResponse.user!.id)
          .maybeSingle();

      if (userDetails == null) {
        return {
          'success': false,
          'message': 'User not found. Please contact your manager.',
        };
      }

      return {
        'success': true,
        'role': userDetails['role'],
        'message': 'Login successful!',
      };
    } catch (e) {
      return {'success': false, 'message': 'Something went wrong: $e'};
    }
  }

  // ─── LOGOUT ────────────────────────────────────────────
  static Future<void> logout() async {
    await _client.auth.signOut();
  }
}
