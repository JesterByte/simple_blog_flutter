import 'dart:io';

import 'package:simple_blog_flutter/features/comment/domain/comment.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class CommentRepository {
  final SupabaseClient _client;
  final _uuid = const Uuid();

  CommentRepository(this._client);

  Future<void> createComment({
    required String blogId,
    required String authorId,
    required String content,
    required List<File> images,
  }) async {
    final commentResponse = await _client
        .from('comments')
        .insert({'blog_id': blogId, 'author_id': authorId, 'content': content})
        .select()
        .single();

    final commentId = commentResponse['id'];

    for (final file in images) {
      final path = 'comments/$commentId/${_uuid.v4()}.jpg';

      await _client.storage.from('comment-images').upload(path, file);

      final publicUrl = _client.storage
          .from('comment-images')
          .getPublicUrl(path);

      await _client.from('comment_images').insert({
        'comment_id': commentId,
        'image_url': publicUrl,
      });
    }
  }

  Future<List<Comment>> getComments(String blogId) async {
    final response = await _client
        .from('comments')
        .select('*, comment_images (image_url)')
        .eq('blog_id', blogId)
        .order('created_at', ascending: false);

    return (response as List).map((map) => Comment.fromMap(map)).toList();
  }
}
