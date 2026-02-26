import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:simple_blog_flutter/features/auth/auth_provider.dart';
import 'package:simple_blog_flutter/features/blog/blog_provider.dart';
import 'package:simple_blog_flutter/features/blog/domain/blog.dart';

class CreateBlogScreen extends ConsumerStatefulWidget {
  final Blog? blog;

  const CreateBlogScreen({super.key, this.blog});

  @override
  ConsumerState<CreateBlogScreen> createState() => _CreateBlogScreenState();
}

class _CreateBlogScreenState extends ConsumerState<CreateBlogScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  List<File> _selectedImages = [];
  bool _loading = false;
  bool get isEdit => widget.blog != null;

  @override
  void initState() {
    super.initState();
    if (widget.blog != null) {
      _titleController.text = widget.blog!.title;
      _contentController.text = widget.blog!.content;
    }
  }

  Future<void> _pickImages() async {
    final picked = await ImagePicker().pickMultiImage();
    if (picked.isNotEmpty) {
      setState(() {
        _selectedImages = picked.map((e) => File(e.path)).toList();
      });
    }
  }

  Future<void> _saveBlog() async {
    setState(() => _loading = true);

    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    final repo = ref.read(blogRepositoryProvider);

    if (isEdit) {
      await repo.updateBlog(
        blogId: widget.blog!.id,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        newImages: _selectedImages,
      );
    } else {
      await repo.createBlog(
        authorId: user.id,
        title: _titleController.text.trim(),
        content: _contentController.text.trim(),
        images: _selectedImages,
      );
    }

    ref.invalidate(blogListProvider);

    if (!mounted) return;

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Blog')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            TextField(
              controller: _contentController,
              decoration: const InputDecoration(labelText: 'Content'),
              maxLines: 4,
            ),
            const SizedBox(height: 10),
            ElevatedButton(
              onPressed: _pickImages,
              child: const Text('Add Images'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _loading ? null : _saveBlog,
              child: _loading
                  ? const CircularProgressIndicator()
                  : Text(isEdit ? 'Update' : 'Publish'),
            ),
          ],
        ),
      ),
    );
  }
}
