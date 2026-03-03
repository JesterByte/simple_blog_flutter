import 'dart:typed_data';
import 'package:simple_blog_flutter/features/profile/domain/profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileRepository {
  final SupabaseClient _client;

  ProfileRepository(this._client);

  String _extractFilePath(String publicUrl) {
    final uri = Uri.parse(publicUrl);
    final index = uri.pathSegments.indexOf('avatars');
    return uri.pathSegments.sublist(index + 1).join('/');
  }

  Future<Profile?> getProfile(String userId) async {
    final response = await _client
        .from('profiles')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) return null;

    return Profile.fromMap(response);
  }

  Future<void> upsertProfile({
    required String profileId,
    required String displayName,
    required String? avatarUrl,
  }) async {
    await _client
        .from('profiles')
        .update({
          'display_name': displayName,
          'avatar_url': avatarUrl,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('user_id', profileId);
  }

  Future<String> uploadAvatar(
    String userId,
    Uint8List bytes,
    String? oldAvatarUrl,
  ) async {
    final path =
        'avatars/$userId/avatar-${DateTime.now().microsecondsSinceEpoch}.jpg';

    // await _client.storage
    //     .from('avatars')
    //     .upload(path, file, fileOptions: const FileOptions(upsert: true));

    await _client.storage
        .from('avatars')
        .uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(upsert: true),
        );

    final publicUrl = _client.storage.from('avatars').getPublicUrl(path);

    if (oldAvatarUrl != null) {
      final oldPath = _extractFilePath(oldAvatarUrl);
      await _client.storage.from('avatars').remove([oldPath]);
    }

    return publicUrl;
  }

  Future<void> deleteAvatar() async {
    final user = _client.auth.currentUser;

    final profile = await _client
        .from('profiles')
        .select('avatar_url')
        .eq('user_id', user!.id)
        .single();

    final avatarUrl = profile['avatar_url'];

    if (avatarUrl != null) {
      final path = avatarUrl.split('/').last;

      await _client.storage.from('avatars').remove([path]);
    }

    await _client
        .from('profiles')
        .update({'avatar_url': null})
        .eq('user_id', user.id);
  }
}
