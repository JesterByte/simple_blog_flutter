import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:simple_blog_flutter/features/auth/data/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supabaseProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final client = ref.watch(supabaseProvider);
  return AuthRepository(client);
});

final authStateProvider = StreamProvider<User?>((ref) {
  final client = ref.watch(supabaseProvider);
  return client.auth.onAuthStateChange.map((data) => data.session?.user);
});
