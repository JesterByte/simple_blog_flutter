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

  Future<void> updateComment({
    required String commentId,
    required String content,
    List<String>? existingImages,
    List<File>? newImages,
  }) async {
    await _client
        .from('comments')
        .update({
          'content': content,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', commentId);

    final currentImages =
        await _client
                .from('comment_images')
                .select('id, image_url') 
                .eq('comment_id', commentId)
            as List<dynamic>;

    if (existingImages != null) {
      final List<dynamic> toDelete = currentImages
          .where((img) => !existingImages.contains(img['image_url']))
          .map((img) => img['id'])
          .toList();

      if (toDelete.isNotEmpty) {
        await _client.from('comment_images').delete().inFilter('id', toDelete);
      }
    }

    if (newImages != null && newImages.isNotEmpty) {
      for (final file in newImages) {
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
  }

  Future<void> deleteComment(String commentId) async {
    await _client.from('comments').delete().eq('id', commentId);
  }

  Future<List<Comment>> getComments(String blogId) async {
    final response = await _client
        .from('comments')
        .select(''' 
          *, 
          profiles!comments_author_id_fkey(avatar_url, display_name),
          comment_images(image_url)
        ''')
        .eq('blog_id', blogId)
        .order('created_at', ascending: true);

    return (response as List).map((map) => Comment.fromMap(map)).toList();
  }
}
