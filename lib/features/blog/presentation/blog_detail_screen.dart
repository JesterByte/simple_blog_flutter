import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:simple_blog_flutter/features/auth/auth_provider.dart';
import 'package:simple_blog_flutter/features/blog/blog_provider.dart';
import 'package:simple_blog_flutter/features/blog/domain/blog.dart';
import 'package:simple_blog_flutter/features/blog/presentation/create_blog_screen.dart';
import 'package:simple_blog_flutter/features/comment/comment_provider.dart';
import 'package:simple_blog_flutter/features/comment/domain/comment.dart';
import 'package:simple_blog_flutter/core/common_widgets/comment_image_carousel.dart';
import 'package:timeago/timeago.dart' as timeago;

class BlogDetailScreen extends ConsumerStatefulWidget {
  final String blogId;

  const BlogDetailScreen({super.key, required this.blogId});

  @override
  ConsumerState<BlogDetailScreen> createState() => _BlogDetailScreenState();
}

class _BlogDetailScreenState extends ConsumerState<BlogDetailScreen> {
  final _commentController = TextEditingController();
  final List<File> _selectedImages = [];
  bool _posting = false;
  int _currentImageIndex = 0;
  bool _updating = false;

  Future<List<File>?> _pickImages() async {
    final picked = await ImagePicker().pickMultiImage();

    if (picked.isNotEmpty) {
      final List<File> files = picked.map((e) => File(e.path)).toList();

      return files;
    }

    return null;
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
          blogId: widget.blogId,
          authorId: user.id,
          content: _commentController.text.trim(),
          images: _selectedImages,
        );

    _commentController.clear();
    _selectedImages.clear();

    ref.invalidate(commentsProvider(widget.blogId));

    setState(() => _posting = false);
  }

  Future<void> _editComment(Comment comment) async {
    final controller = TextEditingController(text: comment.content);
    List<File> newImages = [];
    List<String> existingImages = List.from(comment.images);

    final updated = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[400],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Edit Comment',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    maxLines: null,
                    decoration: const InputDecoration(
                      hintText: 'Update your comment...',
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (existingImages.isNotEmpty || newImages.isNotEmpty)
                    SizedBox(
                      height: 120,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          ...existingImages.map(
                            (url) => _buildImageItem(
                              child: Image.network(
                                url,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                              onDelete: () => setModalState(
                                () => existingImages.remove(url),
                              ),
                            ),
                          ),
                          ...newImages.asMap().entries.map(
                            (entry) => _buildImageItem(
                              child: Image.file(
                                entry.value,
                                width: 100,
                                height: 100,
                                fit: BoxFit.cover,
                              ),
                              onDelete: () => setModalState(
                                () => newImages.removeAt(entry.key),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () async {
                          final picked = await _pickImages();
                          if (picked != null) {
                            setModalState(() {
                              newImages.addAll(picked);
                            });
                          }
                        },
                        icon: const Icon(Icons.add_photo_alternate),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _updating
                              ? null
                              : () async {
                                  if (controller.text.trim() ==
                                          comment.content &&
                                      newImages.isEmpty &&
                                      existingImages.length ==
                                          comment.images.length) {
                                    Navigator.pop(context, false);
                                    return;
                                  }

                                  try {
                                    setState(() => _updating = true);

                                    await ref
                                        .read(commentRepositoryProvider)
                                        .updateComment(
                                          commentId: comment.id,
                                          content: controller.text.trim(),
                                          existingImages: existingImages,
                                          newImages: newImages,
                                        );

                                    setState(
                                      () => setModalState(
                                        () => _updating = false,
                                      ),
                                    );

                                    if (!context.mounted) return;

                                    Navigator.pop(context, true);

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Comment updated'),
                                      ),
                                    );
                                  } catch (e) {
                                    setState(() => _updating = false);

                                    if (!context.mounted) return;

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(e.toString())),
                                    );
                                  }
                                },
                          child: const Text('Save Changes'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );

    if (updated == true) {
      ref.invalidate(commentsProvider(widget.blogId));
    }
  }

  Future<void> _deleteComment(String commentId) async {
    final shouldDelete = await showModalBottomSheet<bool>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Delete Comment',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        'Delete',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (shouldDelete == true) {
      try {
        setState(() => _updating = true);
        await ref.read(commentRepositoryProvider).deleteComment(commentId);
        ref.invalidate(commentsProvider(widget.blogId));

        if (!mounted) return;

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Comment deleted')));
      } catch (e) {
        setState(() => _updating = false);

        if (!mounted) return;

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _deleteBlog(String blogId) async {
    final shouldDelete = await showModalBottomSheet<bool>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Delete Blog',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                      child: const Text(
                        'Delete',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (shouldDelete == true) {
      try {
        setState(() => _updating = true);
        await ref.read(blogRepositoryProvider).deleteBlog(blogId);
        ref.invalidate(blogListProvider);

        if (!mounted) return;

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Blog deleted')));

        Navigator.pop(context);
      } catch (e) {
        setState(() => _updating = false);

        if (!mounted) return;

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final blogAsync = ref.watch(blogProvider(widget.blogId));
    final commentsAsync = ref.watch(commentsProvider(widget.blogId));

    return blogAsync.when(
      data: (blog) {
        final user = ref.watch(authStateProvider).value;
        final isAuthor = user?.id == blog.authorId;

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundImage: blog.authorAvatar != null
                      ? NetworkImage(blog.authorAvatar!)
                      : null,
                  child: blog.authorAvatar == null
                      ? const Icon(Icons.person)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        blog.authorName ?? 'User',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        timeago.format(blog.createdAt),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              if (isAuthor) ...[
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
                    _deleteBlog(blog.id);
                  },
                  icon: const Icon(Icons.delete),
                ),
              ],
            ],
          ),
          body: _buildScrollableContent(ref, blog, commentsAsync),
          bottomNavigationBar: _buildCommentInput(ref),
        );
      },
      error: (e, _) => Scaffold(body: Center(child: Text(e.toString()))),
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
    );
  }

  Widget _buildScrollableContent(
    WidgetRef ref,
    Blog blog,
    AsyncValue<List<Comment>> commentsAsync,
  ) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              blog.title,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            if (blog.images.isNotEmpty) ...[
              const SizedBox(height: 16),
              SizedBox(
                height: 250,
                child: Stack(
                  children: [
                    PageView.builder(
                      physics: const BouncingScrollPhysics(),
                      itemCount: blog.images.length,
                      onPageChanged: (index) {
                        setState(() {
                          _currentImageIndex = index;
                        });
                      },
                      itemBuilder: (context, index) {
                        return ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            blog.images[index],
                            fit: BoxFit.cover,
                            width: double.infinity,
                          ),
                        );
                      },
                    ),
                    if (blog.images.isNotEmpty && blog.images.length > 1)
                      Positioned(
                        bottom: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_currentImageIndex + 1} / ${blog.images.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text(blog.content, style: const TextStyle(fontSize: 16)),
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
                    final currentUserId = ref.read(authStateProvider).value?.id;
                    final isOwner = comment.authorId == currentUserId;

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 18,
                                  backgroundImage: comment.authorAvatar != null
                                      ? NetworkImage(comment.authorAvatar!)
                                      : null,
                                  child: comment.authorAvatar == null
                                      ? const Icon(Icons.person)
                                      : null,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        comment.authorName ?? 'User',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        timeago.format(comment.createdAt),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (isOwner)
                                  PopupMenuButton<String>(
                                    onSelected: (value) {
                                      if (value == 'edit') {
                                        _editComment(comment);
                                      } else if (value == 'delete') {
                                        _deleteComment(comment.id);
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(
                                        value: 'edit',
                                        child: Text('Edit'),
                                      ),
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Text('Delete'),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(comment.content),
                            if (comment.images.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              CommentImageCarousel(images: comment.images),
                            ],
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
              error: (e, _) => Text(e.toString()),
              loading: () => const Center(child: CircularProgressIndicator()),
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
                  onPressed: () async {
                    final picked = await _pickImages();
                    if (picked != null) {
                      setState(() => _selectedImages.addAll(picked));
                    }
                  },
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

  Widget _buildImageItem({
    required Widget child,
    required VoidCallback onDelete,
  }) {
    return Stack(
      children: [
        Container(
          margin: const EdgeInsets.only(right: 12, top: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: child,
          ),
        ),
        Positioned(
          top: 0,
          right: 4,
          child: GestureDetector(
            onTap: onDelete,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
              ),
              child: const Icon(Icons.close, size: 20, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
