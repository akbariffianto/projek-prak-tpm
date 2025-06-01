import 'package:flutter/material.dart';
import '../services/hive_service.dart';
import '../models/user_model.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});
  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _error;
  File? _profileImage;
  // Hapus _selectedCharacterId dan _selectedCharacterName karena tidak lagi diisi di sini
  // String? _selectedCharacterId;
  // String? _selectedCharacterName;

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 75,
    );
    
    if (image != null) {
      setState(() {
        _profileImage = File(image.path);
      });
    }
  }

  Future<String?> _saveImage() async {
    if (_profileImage == null) return null;
    
    try {
      if (kIsWeb) {
        final bytes = await _profileImage!.readAsBytes();
        return base64Encode(bytes);
      } else {
        final directory = await getApplicationDocumentsDirectory();
        final fileName = 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final savedImage = await _profileImage!.copy('${directory.path}/$fileName');
        return savedImage.path;
      }
    } catch (e) {
      debugPrint('Error saving image: $e');
      return null;
    }
  }

  // Hapus metode _selectFavoriteCharacter() karena tidak lagi digunakan di sini
  // Future<void> _selectFavoriteCharacter() async {
  //   setState(() {
  //     _selectedCharacterId = "1";
  //     _selectedCharacterName = "Mickey Mouse";
  //   });
  // }

  Future<void> _register() async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    final description = _descriptionController.text.trim();

    if (username.isEmpty || password.isEmpty) {
      setState(() {
        _error = 'Username and password must not be empty';
      });
      return;
    }

    // Hapus validasi ini karena favorit karakter tidak lagi diisi saat registrasi
    // if (_selectedCharacterId == null) {
    //   setState(() {
    //     _error = 'Please select your favorite Disney character';
    //   });
    //   return;
    // }

    final existingUser = HiveService().getUserByUsername(username);
    if (existingUser != null) {
      setState(() {
        _error = 'Username already taken';
      });
      return;
    }

    final profilePhotoPath = await _saveImage();

    final newUser = UserModel(
      id: DateTime.now().millisecondsSinceEpoch,
      username: username,
      password: password,
      createdAt: DateTime.now(),
      profilePhotoPath: profilePhotoPath,
      // Hapus favoriteCharacterId dan favoriteCharacterName dari sini
      // favoriteCharacterId: int.tryParse(_selectedCharacterId!),
      // favoriteCharacterName: _selectedCharacterName,
      description: description,
    );

    await HiveService().addUser(newUser);
    // Hapus pemanggilan updateCharacterFavorite di sini
    // if (_selectedCharacterId != null && _selectedCharacterName != null) {
    //   await HiveService().updateCharacterFavorite(
    //     int.parse(_selectedCharacterId!),
    //     _selectedCharacterName!,
    //   );
    // }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration successful! Please login.')),
      );
      await Future.delayed(const Duration(milliseconds: 300));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Create Your Account',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 40),
              
              // Profile Image Selection
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey[200],
                    image: _profileImage != null
                        ? DecorationImage(
                            image: !kIsWeb
                                ? FileImage(_profileImage!)
                                : MemoryImage(base64Decode(_profileImage!.path)) as ImageProvider,
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _profileImage == null
                      ? Icon(
                          Icons.add_a_photo,
                          size: 40,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 20),

              if (_error != null)
                Text(_error!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error)),
              
              TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                  labelText: 'Username',
                  prefixIcon: Icon(Icons.person),
                ),
              ),
              const SizedBox(height: 16),
              
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: 'Password',
                  prefixIcon: Icon(Icons.lock),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 16),

              // Hapus bagian ini karena tidak ada pilihan favorit karakter lagi di sini
              // ListTile(
              //   leading: const Icon(Icons.favorite),
              //   title: Text(_selectedCharacterName ?? 'Select Favorite Character'),
              //   trailing: const Icon(Icons.arrow_forward_ios),
              //   tileColor: Colors.grey[100],
              //   shape: RoundedRectangleBorder(
              //     borderRadius: BorderRadius.circular(8),
              //   ),
              //   onTap: _selectFavoriteCharacter,
              // ),
              // const SizedBox(height: 16),

              // Description Field
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'About Me',
                  hintText: 'Tell us about yourself...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _register,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Text('Register'),
                  ),
                ),
              ),
              
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Already have an account? Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}