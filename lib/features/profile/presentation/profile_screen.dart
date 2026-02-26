import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:simple_blog_flutter/features/auth/auth_provider.dart';
import 'package:simple_blog_flutter/features/profile/domain/profile.dart';
import 'package:simple_blog_flutter/features/profile/profile_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _displayNameController = TextEditingController();
  File? _selectedImage;

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);

    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return;

    final repo = ref.read(profileRepositoryProvider);

    String? avatarUrl;

    if (_selectedImage != null) {
      avatarUrl = await repo.uploadAvatar(user.id, _selectedImage!);
    }

    final profile = Profile(
      id: user.id,
      displayName: _displayNameController.text.trim(),
      avatarUrl: avatarUrl,
    );

    await repo.upsertProfile(profile);

    ref.invalidate(profileProvider);

    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Profile updated')));
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: profileAsync.when(
        data: (profile) {
          _displayNameController.text = profile?.displayName ?? '';

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                if (profile?.avatarUrl != null)
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: NetworkImage(profile!.avatarUrl!),
                  ),
                TextButton(
                  onPressed: _pickImage,
                  child: const Text('Change Avatar'),
                ),
                TextField(
                  controller: _displayNameController,
                  decoration: const InputDecoration(labelText: 'Display Name'),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: _saveProfile,
                  child: const Text('Save'),
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
}
