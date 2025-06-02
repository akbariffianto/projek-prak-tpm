import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'dart:convert';
import 'bookmark_page.dart';
import 'login_page.dart';
import '../services/hive_service.dart';
import 'package:image_picker/image_picker.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _hiveService = HiveService();
  String _loggedInUsername = 'Guest';
  String? _profilePhotoPath;
  String? _userDescription;
  int? _userId;
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadLoggedInUsernameAndProfile();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadLoggedInUsernameAndProfile() async {
    try {
      final userId = await _hiveService.getUserSession();
      if (userId != null) {
        final user = _hiveService.userBox.values.firstWhere(
          (u) => u.id == userId,
          orElse: () => throw Exception('User not found'),
        );
        if (mounted) {
          setState(() {
            _loggedInUsername = user.username;
            _profilePhotoPath = user.profilePhotoPath;
            _userDescription = user.description;
            _userId = user.id; // No need for toString()
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading username or profile: $e');
      if (mounted) {
        setState(() {
          _loggedInUsername = 'Guest';
          _profilePhotoPath = null;
          _userDescription = null;
          _userId = null;
        });
      }
    }
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _hiveService.logout();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null && _userId != null) {
        final imageBytes = await pickedFile.readAsBytes();
        final base64Image = base64Encode(imageBytes);

        await _hiveService.updateUser(
          _userId!, // Now passing int directly
          profilePhotoPath: base64Image,
        );
        await _loadLoggedInUsernameAndProfile();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile photo updated successfully')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile photo: $e')),
        );
      }
    }
  }

  Future<void> _editProfile() async {
    try {
      _usernameController.text = _loggedInUsername;
      _descriptionController.text = _userDescription ?? '';

      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Edit Profile'),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Username',
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                  ),
                  validator: (value) =>
                      value?.isEmpty == true ? 'Username required' : null,
                ),
                const SizedBox(height: 16), // Spacing between fields
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    contentPadding: EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    alignLabelWithHint: true, // Align label with first line
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0), // Adjust dialog padding
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState?.validate() == true) {
                  Navigator.pop(context, true);
                }
              },
              child: const Text('Save'),
            ),
          ],
        ),
      );

      if (result == true && _userId != null) {
        await _hiveService.updateUser(
          _userId!, // Now passing int directly
          username: _usernameController.text,
          description: _descriptionController.text,
        );
        await _loadLoggedInUsernameAndProfile();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile updated successfully')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e')),
        );
      }
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Account'),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && _userId != null && mounted) {
      await _hiveService.deleteUser(_userId!);
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    ImageProvider? profileImageProvider;
    if (_profilePhotoPath != null) {
      if (kIsWeb) {
        try {
          profileImageProvider = MemoryImage(base64Decode(_profilePhotoPath!));
        } catch (e) {
          debugPrint('Error decoding Base64 image: $e');
          profileImageProvider = null;
        }
      } else {
        profileImageProvider = FileImage(File(_profilePhotoPath!));
      }
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey,
                backgroundImage: profileImageProvider,
                child: profileImageProvider == null
                    ? const Icon(Icons.person, size: 50, color: Colors.white)
                    : null,
              ),
              Positioned(
                right: -16,
                bottom: -16,
                child: IconButton(
                  icon: const Icon(Icons.camera_alt),
                  onPressed: _pickImage,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _loggedInUsername,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (_userDescription != null && _userDescription!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                _userDescription!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              ),
            ),
          const SizedBox(height: 32),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Edit Profile'),
            onTap: _editProfile,
          ),
          ListTile(
            leading: const Icon(Icons.bookmark),
            title: const Text('My Bookmarks'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const BookmarkPage()),
            ).then((_) => _loadLoggedInUsernameAndProfile()),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _deleteAccount,
              icon: const Icon(Icons.delete_forever),
              label: const Text('Delete Account'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _handleLogout,
              icon: const Icon(Icons.logout),
              label: const Text('Logout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}