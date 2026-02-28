import 'dart:io';

import 'package:simple_blog_flutter/features/blog/domain/blog.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class BlogRepository {
  final SupabaseClient _client;
  final _uuid = const Uuid();

  BlogRepository(this._client);

  Future<void> createBlog({
    required String authorId,
    required String title,
    required String content,
    required List<File> images,
  }) async {
    final blogReponse = await _client
        .from('blogs')
        .insert({'author_id': authorId, 'title': title, 'content': content})
        .select()
        .single();

    final blogId = blogReponse['id'];

    for (final file in images) {
      final path = 'blogs/$blogId/${_uuid.v4()}.jpg';

      await _client.storage.from('blog-images').upload(path, file);

      final publicUrl = _client.storage.from('blog-images').getPublicUrl(path);

      await _client.from('blog_images').insert({
        'blog_id': blogId,
        'image_url': publicUrl,
      });
    }
  }

  Future<void> updateBlog({
    required String blogId,
    required String title,
    required String content,
    required List<File> newImages,
  }) async {
    await _client
        .from('blogs')
        .update({
          'title': title,
          'content': content,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', blogId);

    if (newImages.isEmpty) return;

    await _client.from('blog_images').delete().eq('blog_id', blogId);

    for (final file in newImages) {
      final path = 'blogs/$blogId/${_uuid.v4()}.jpg';

      await _client.storage.from('blog-images').upload(path, file);

      final publicUrl = _client.storage.from('blog-images').getPublicUrl(path);

      await _client.from('blog_images').insert({
        'blog_id': blogId,
        'image_url': publicUrl,
      });
    }
  }

  Future<List<Blog>> getBlogs() async {
    final response = await _client
        .from('blogs')
        .select('''
          *,
          blog_images(image_url),
          profiles!blogs_author_id_fkey(avatar_url, display_name),
          comments(count)
        ''')
        .order('created_at', ascending: false);

    return (response as List).map((map) => Blog.fromMap(map)).toList();
  }

  Future<void> deleteBlog(String blogId) async {
    await _client.from('blogs').delete().eq('id', blogId);
  }
}
