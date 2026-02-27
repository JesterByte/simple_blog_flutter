import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:simple_blog_flutter/features/auth/auth_provider.dart';
import 'package:simple_blog_flutter/features/comment/data/comment_repository.dart';
import 'package:simple_blog_flutter/features/comment/domain/comment.dart';

final commentRepositoryProvider = Provider<CommentRepository>((ref) {
  final client = ref.watch(supabaseProvider);
  return CommentRepository(client);
});

final commentsProvider = FutureProvider.family<List<Comment>, String>((
  ref,
  blogId,
) async {
  final repo = ref.watch(commentRepositoryProvider);
  return repo.getComments(blogId);
});
