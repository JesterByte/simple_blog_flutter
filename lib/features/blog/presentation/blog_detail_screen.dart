import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:simple_blog_flutter/features/auth/auth_provider.dart';
import 'package:simple_blog_flutter/features/blog/blog_provider.dart';
import 'package:simple_blog_flutter/features/blog/domain/blog.dart';
import 'package:simple_blog_flutter/features/blog/presentation/create_blog_screen.dart';
import 'package:simple_blog_flutter/features/comment/comment_provider.dart';

class BlogDetailScreen extends ConsumerStatefulWidget {
  final Blog blog;

  const BlogDetailScreen({super.key, required this.blog});

  @override
  ConsumerState<BlogDetailScreen> createState() => _BlogDetailScreenState();
}

class _BlogDetailScreenState extends ConsumerState<BlogDetailScreen> {
  final _commentController = TextEditingController();
  List<File> _selectedImages = [];
  bool _posting = false;

  Future<void> _pickImages() async {
    final picked = await ImagePicker().pickMultiImage();

    if (picked.isNotEmpty) {
      setState(() {
        _selectedImages = picked.map((e) => File(e.path)).toList();
      });
    }
  }

  Future<void> _postComment() async {
    if (_commentController.text.trim().isEmpty && _selectedImages.isEmpty) {
      return;
    }

    setState(() => _posting = true);

    final user = ref.watch(authStateProvider).value;
    if (user == null) return;

    await ref
        .read(commentRepositoryProvider)
        .createComment(
          blogId: widget.blog.id,
          authorId: user.id,
          content: _commentController.text.trim(),
          images: _selectedImages,
        );

    _commentController.clear();
    _selectedImages.clear();

    ref.invalidate(commentsProvider(widget.blog.id));

    setState(() => _posting = false);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authStateProvider).value;
    final isAuthor = user?.id == widget.blog.authorId;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.blog.title),
        actions: [
          if (isAuthor)
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CreateBlogScreen(blog: widget.blog),
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
                await ref
                    .read(blogRepositoryProvider)
                    .deleteBlog(widget.blog.id);

                ref.invalidate(blogListProvider);

                if (!context.mounted) return;

                Navigator.pop(context);
              }
            },
            icon: const Icon(Icons.delete),
          ),
        ],
      ),
      body: _buildScrollableContent(ref),
      bottomNavigationBar: _buildCommentInput(ref),
    );
  }

  Widget _buildScrollableContent(WidgetRef ref) {
    final commentsAsync = ref.watch(commentsProvider(widget.blog.id));

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.blog.images.isNotEmpty)
              SizedBox(
                height: 200,
                child: PageView(
                  children: widget.blog.images
                      .map((url) => Image.network(url, fit: BoxFit.cover))
                      .toList(),
                ),
              ),
            const SizedBox(height: 16),
            Text(widget.blog.content, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 24),
            const Text(
              'Comments',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            commentsAsync.when(
              data: (comments) {
                if (comments.isEmpty) {
                  return const Text('No comments yet.');
                }

                return Column(
                  children: comments.map((comment) {
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(comment.content),
                            if (comment.images.isNotEmpty)
                              SizedBox(
                                height: 150,
                                child: PageView(
                                  children: comment.images
                                      .map(
                                        (url) => Image.network(
                                          url,
                                          fit: BoxFit.cover,
                                        ),
                                      )
                                      .toList(),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
              error: (e, _) => Text(e.toString()),
              loading: () => const CircularProgressIndicator(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCommentInput(WidgetRef ref) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_selectedImages.isNotEmpty)
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedImages.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.all(4),
                      child: Image.file(
                        _selectedImages[index],
                        width: 60,
                        fit: BoxFit.cover,
                      ),
                    );
                  },
                ),
              ),
            Row(
              children: [
                IconButton(
                  onPressed: _pickImages,
                  icon: const Icon(Icons.image),
                ),
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: const InputDecoration(
                      hintText: 'Write a comment...',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _posting ? null : _postComment,
                  icon: _posting
                      ? const CircularProgressIndicator()
                      : const Icon(Icons.send),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
