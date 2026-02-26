import 'dart:io';

import 'package:simple_blog_flutter/features/profile/domain/profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileRepository {
  final SupabaseClient _client;

  ProfileRepository(this._client);

  Future<Profile?> getProfile(String userId) async {
    final response = await _client
        .from('profiles')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) return null;

    return Profile.fromMap(response);
  }

  Future<void> upsertProfile(Profile profile) async {
    await _client.from('profiles').upsert(profile.toMap());
  }

  Future<String> uploadAvatar(String userId, File file) async {
    final path = 'avatars/$userId.jpg';

    await _client.storage
        .from('avatars')
        .upload(path, file, fileOptions: const FileOptions(upsert: true));

    return _client.storage.from('avatars').getPublicUrl(path);
  }
}
