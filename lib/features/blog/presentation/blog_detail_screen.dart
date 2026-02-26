import 'package:flutter/material.dart';
import 'package:simple_blog_flutter/features/blog/domain/blog.dart';

class BlogDetailScreen extends StatelessWidget {
  final Blog blog;

  const BlogDetailScreen({super.key, required this.blog});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(blog.title)),
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
                      .map(
                        (url) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Image.network(url, fit: BoxFit.cover),
                        ),
                      )
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
