import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:simple_blog_flutter/features/auth/auth_provider.dart';
import 'package:simple_blog_flutter/features/blog/data/blog_repository.dart';
import 'package:simple_blog_flutter/features/blog/domain/blog.dart';

final blogRepositoryProvider = Provider<BlogRepository>((ref) {
  final client = ref.watch(supabaseProvider);
  return BlogRepository(client);
});

final blogListProvider = FutureProvider<List<Blog>>((ref) async {
  final repo = ref.watch(blogRepositoryProvider);
  return repo.getBlogs();
});
