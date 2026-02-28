import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:simple_blog_flutter/features/auth/auth_provider.dart';
import 'package:simple_blog_flutter/features/blog/blog_provider.dart';
import 'package:simple_blog_flutter/features/profile/profile_provider.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _displayNameController = TextEditingController();
  File? _selectedImage;
  bool _removeAvatar = false;
  bool _loading = false;

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
      });
    }
  }

  Future<void> _saveProfile(String? currentAvatarUrl) async {
    try {
      setState(() => _loading = true);

      final user = ref.read(authStateProvider).value;
      if (user == null) return;

      final repo = ref.read(profileRepositoryProvider);

      String? avatarUrl = currentAvatarUrl;

      if (_removeAvatar) {
        await repo.deleteAvatar();
        avatarUrl = null;
      }

      if (_selectedImage != null) {
        avatarUrl = await repo.uploadAvatar(
          user.id,
          _selectedImage!,
          currentAvatarUrl,
        );
      }

      await repo.upsertProfile(
        profileId: user.id,
        displayName: _displayNameController.text.trim(),
        avatarUrl: avatarUrl,
      );

      ref.invalidate(profileProvider);
      ref.invalidate(blogListProvider);

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile updated')));
    } catch (e) {
      setState(() => _loading = false);

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: profileAsync.when(
        data: (profile) {
          _displayNameController.text = profile?.displayName ?? '';
          String joinedDate = DateFormat.yMMMd().format(profile!.createdAt);

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    _buildAvatar(profile.avatarUrl),
                    if (!_removeAvatar &&
                        (profile.avatarUrl != null || _selectedImage != null))
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _removeAvatar = true;
                              _selectedImage = null;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              size: 18,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                TextButton(
                  onPressed: _pickImage,
                  child: const Text('Change Avatar'),
                ),
                TextField(
                  controller: _displayNameController,
                  decoration: const InputDecoration(labelText: 'Display Name'),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Joined on: $joinedDate',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () async {
                    _loading
                        ? null
                        : _saveProfile(profileAsync.value?.avatarUrl);
                  },
                  child: _loading
                      ? const CircularProgressIndicator()
                      : const Text('Save'),
                ),
              ],
            ),
          );
        },
        error: (e, _) => Center(child: Text(e.toString())),
        loading: () => const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  Widget _buildAvatar(String? avatarUrl) {
    if (_selectedImage != null) {
      return CircleAvatar(
        radius: 50,
        backgroundImage: FileImage(_selectedImage!),
      );
    }

    if (!_removeAvatar && avatarUrl != null) {
      return CircleAvatar(radius: 50, backgroundImage: NetworkImage(avatarUrl));
    }

    return const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 40));
  }
}
