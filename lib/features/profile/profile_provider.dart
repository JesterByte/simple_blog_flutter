import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:simple_blog_flutter/features/auth/auth_provider.dart';
import 'package:simple_blog_flutter/features/profile/data/profile_repository.dart';
import 'package:simple_blog_flutter/features/profile/domain/profile.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final client = ref.watch(supabaseProvider);
  return ProfileRepository(client);
});

final profileProvider = FutureProvider<Profile?>((ref) async {
  final user = ref.watch(authStateProvider).value;
  if (user == null) return null;

  final repo = ref.watch(profileRepositoryProvider);
  return repo.getProfile(user.id);
});
