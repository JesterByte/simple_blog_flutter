import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:simple_blog_flutter/features/auth/auth_provider.dart';
import 'package:simple_blog_flutter/features/blog/blog_provider.dart';
import 'package:simple_blog_flutter/features/blog/domain/blog.dart';
import 'package:simple_blog_flutter/features/blog/presentation/create_blog_screen.dart';

class BlogDetailScreen extends ConsumerWidget {
  final Blog blog;

  const BlogDetailScreen({super.key, required this.blog});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider).value;
    final isAuthor = user?.id == blog.authorId;

    return Scaffold(
      appBar: AppBar(
        title: Text(blog.title),
        actions: [
          if (isAuthor)
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreateBlogScreen(blog: blog),
                  ),
                );
              },
              icon: const Icon(Icons.edit),
            ),
          IconButton(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('Delete Blog'),
                  content: const Text(
                    'Are you sure you want to delete this blog?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await ref.read(blogRepositoryProvider).deleteBlog(blog.id);

                ref.invalidate(blogListProvider);

                if (!context.mounted) return;

                Navigator.pop(context);
              }
            },
            icon: const Icon(Icons.delete),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (blog.images.isNotEmpty)
              SizedBox(
                height: 200,
                child: PageView(
                  children: blog.images
                      .map((url) => Image.network(url, fit: BoxFit.cover))
                      .toList(),
                ),
              ),
            const SizedBox(height: 16),
            Text(blog.content, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
