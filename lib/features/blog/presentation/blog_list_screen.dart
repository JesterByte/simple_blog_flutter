import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:simple_blog_flutter/features/blog/blog_provider.dart';
import 'package:simple_blog_flutter/features/blog/presentation/blog_detail_screen.dart';
import 'package:simple_blog_flutter/features/blog/presentation/create_blog_screen.dart';

class BlogListScreen extends ConsumerWidget {
  const BlogListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blogAsync = ref.watch(blogListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Blogs')),
      body: blogAsync.when(
        data: (blogs) {
          if (blogs.isEmpty) {
            return const Center(
              child: Text('No blogs yet. Be brave. Write something.'),
            );
          }

          return ListView.builder(
            itemCount: blogs.length,
            itemBuilder: (context, index) {
              final blog = blogs[index];

              return ListTile(
                title: Text(blog.title),
                subtitle: Text(
                  blog.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BlogDetailScreen(blog: blog),
                    ),
                  );
                },
              );
            },
          );
        },
        error: (e, _) => Center(child: Text(e.toString())),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateBlogScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
