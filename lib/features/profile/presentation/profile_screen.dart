import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:simple_blog_flutter/features/auth/auth_provider.dart';
import 'package:simple_blog_flutter/features/blog/blog_provider.dart';
import 'package:simple_blog_flutter/features/profile/profile_provider.dart';
import 'package:intl/intl.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  final String? userId;

  const ProfileScreen({super.key, this.userId});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;

  final _displayNameController = TextEditingController();
  bool _removeAvatar = false;
  bool _loading = false;
  bool _isInitialized = false;

  Future<void> _pickImage() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);

    if (picked != null) {
      final bytes = await picked.readAsBytes();

      setState(() {
        _selectedImage = picked;
        _selectedImageBytes = bytes;
        _removeAvatar = false;
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

      if (_selectedImageBytes != null) {
        avatarUrl = await repo.uploadAvatar(
          user.id,
          _selectedImageBytes!,
          currentAvatarUrl,
        );
      }

      await repo.upsertProfile(
        profileId: user.id,
        displayName: _displayNameController.text.trim(),
        avatarUrl: avatarUrl,
      );

      ref.invalidate(profileProvider(user.id));
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
  void didUpdateWidget(ProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.userId != oldWidget.userId) {
      _displayNameController.clear();
      _selectedImage = null;
      _removeAvatar = false;
      _isInitialized = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authStateProvider).value;
    final displayUserId = widget.userId ?? currentUser?.id;

    if (displayUserId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final profileAsync = ref.watch(profileProvider(displayUserId));

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('This user has no profile'));
          }

          if (!_isInitialized) {
            _displayNameController.text = profile.displayName ?? '';
            _isInitialized = true;
          }

          // _displayNameController.text = profile.displayName ?? '';
          String joinedDate = DateFormat.yMMMd().format(profile.createdAt);

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    _buildAvatar(profile.avatarUrl),
                    if (displayUserId == currentUser?.id &&
                        !_removeAvatar &&
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
                displayUserId == currentUser?.id
                    ? TextButton(
                        onPressed: _pickImage,
                        child: const Text('Change Avatar'),
                      )
                    : const SizedBox(height: 10),
                displayUserId == currentUser?.id
                    ? TextField(
                        controller: _displayNameController,
                        decoration: const InputDecoration(
                          labelText: 'Display Name',
                        ),
                      )
                    : Text(
                        profile.displayName ?? 'User',
                        style: TextStyle(fontWeight: FontWeight.bold),
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
                if (displayUserId == currentUser?.id) ...[
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
    if (_selectedImageBytes != null) {
      return CircleAvatar(
        radius: 50,
        backgroundImage: MemoryImage(_selectedImageBytes!),
      );
    }

    if (!_removeAvatar && avatarUrl != null) {
      return CircleAvatar(radius: 50, backgroundImage: NetworkImage(avatarUrl));
    }

    return const CircleAvatar(radius: 50, child: Icon(Icons.person, size: 40));
  }
}
