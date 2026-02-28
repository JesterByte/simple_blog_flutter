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
  String _appBarTitle = 'Create Blog';
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final List<File> _selectedImages = [];
  bool _loading = false;
  bool get isEdit => widget.blog != null;
  List<String> _existingImages = [];
  final List<File> _newImages = [];

  @override
  void initState() {
    super.initState();
    if (widget.blog != null) {
      _titleController.text = widget.blog!.title;
      _contentController.text = widget.blog!.content;
      _appBarTitle = 'Edit Blog';
      _existingImages = List.from(widget.blog!.images);
    }
  }

  Future<List<File>?> _pickImages() async {
    final picked = await ImagePicker().pickMultiImage();
    final List<File> files = picked.map((e) => File(e.path)).toList();

    if (picked.isNotEmpty) {
      return files;
    }

    return null;
  }

  Future<void> _saveBlog() async {
    try {
      setState(() => _loading = true);

      final user = ref.read(authStateProvider).value;
      if (user == null) return;

      final repo = ref.read(blogRepositoryProvider);

      if (isEdit) {
        await repo.updateBlog(
          blogId: widget.blog!.id,
          title: _titleController.text.trim(),
          content: _contentController.text.trim(),
          existingImages: _existingImages,
          newImages: _newImages,
        );

        ref.invalidate(blogProvider(widget.blog!.id));
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
    } catch (e) {
      setState(() => _loading = false);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_appBarTitle)),
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
            if (isEdit && (_existingImages.isNotEmpty || _newImages.isNotEmpty))
              SizedBox(
                height: 120,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    ..._existingImages.map(
                      (url) => _buildImageItem(
                        child: Image.network(
                          url,
                          width: 110,
                          height: 110,
                          fit: BoxFit.cover,
                        ),
                        onDelete: () => setState(() {
                          _existingImages.remove(url);
                        }),
                      ),
                    ),
                    ..._newImages.asMap().entries.map(
                      (entry) => _buildImageItem(
                        child: Image.file(
                          entry.value,
                          width: 110,
                          height: 110,
                          fit: BoxFit.cover,
                        ),
                        onDelete: () => setState(() {
                          _newImages.removeAt(entry.key);
                        }),
                      ),
                    ),
                  ],
                ),
              ),
            if (!isEdit && _selectedImages.isNotEmpty)
              SizedBox(
                height: 120,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    ..._selectedImages.asMap().entries.map(
                      (entry) => _buildImageItem(
                        child: Image.file(
                          entry.value,
                          width: 110,
                          height: 110,
                          fit: BoxFit.cover,
                        ),
                        onDelete: () => setState(() {
                          _selectedImages.removeAt(entry.key);
                        }),
                      ),
                    ),
                  ],
                ),
              ),
            ElevatedButton(
              onPressed: () async {
                final picked = await _pickImages();
                if (picked != null) {
                  setState(() {
                    if (isEdit) {
                      _newImages.addAll(picked);
                    } else {
                      _selectedImages.addAll(picked);
                    }
                  });
                }
              },
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

  Widget _buildImageItem({
    required Widget child,
    required VoidCallback onDelete,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          margin: const EdgeInsets.only(right: 12, top: 8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
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
              child: const Icon(Icons.close, size: 18, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}
