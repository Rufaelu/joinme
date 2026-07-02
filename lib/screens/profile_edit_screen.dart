import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/app_state.dart';
import '../widgets/glass_container.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({Key? key}) : super(key: key);

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  late TextEditingController _nameController;
  String? _localImagePath;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<AppState>(context, listen: false).currentUser;
    _nameController = TextEditingController(text: user?.fullName ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) {
      setState(() => _localImagePath = picked.path);
    }
  }

  Future<void> _handleSave() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name cannot be empty'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final appState = context.read<AppState>();
      await appState.updateProfile(fullName: name, imagePath: _localImagePath);
      appState.navigateTo('profile');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final appState = context.watch<AppState>();
    final user = appState.currentUser;
    final photoUrl = user?.photoUrl;

    final avatarInitials = user != null && user.fullName.isNotEmpty
        ? user.fullName.split(' ').map((e) => e[0]).take(2).join().toUpperCase()
        : 'US';

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark 
              ? [const Color(0xFF0d1b1e), const Color(0xFF1a363d)] 
              : [const Color(0xFFf9fafb), const Color(0xFFe5e7eb)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => appState.navigateTo('profile'),
                      child: GlassContainer(
                        borderRadius: 30,
                        padding: const EdgeInsets.all(12),
                        child: Icon(LucideIcons.arrowLeft, color: isDark ? Colors.white : Colors.black),
                      ),
                    ),
                    Text(
                      'Edit Profile',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(width: 48), // balance
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                  child: Column(
                    children: [
                      // Avatar Edit
                      GestureDetector(
                        onTap: _pickImage,
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: (_localImagePath == null && user?.photoUrl == null)
                                    ? LinearGradient(
                                        colors: [Colors.yellow[400]!, Colors.blue[600]!],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      )
                                    : null,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue[600]!.withOpacity(0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                              child: _localImagePath != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(60),
                                      child: Image.file(
                                        File(_localImagePath!),
                                        fit: BoxFit.cover,
                                      ),
                                    )
                                  : photoUrl != null
                                      ? ClipRRect(
                                          borderRadius: BorderRadius.circular(60),
                                          child: CachedNetworkImage(
                                            imageUrl: photoUrl,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) => const CircularProgressIndicator(),
                                            errorWidget: (context, url, error) => Center(
                                              child: Text(
                                                avatarInitials,
                                                style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ),
                                        )
                                      : Center(
                                          child: Text(
                                            avatarInitials,
                                            style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
                                          ),
                                        ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue[500],
                                shape: BoxShape.circle,
                                border: Border.all(color: isDark ? const Color(0xFF1a363d) : Colors.white, width: 4),
                              ),
                              child: const Icon(LucideIcons.camera, color: Colors.white, size: 20),
                            ),
                          ],
                        ),
                      ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
                      
                      const SizedBox(height: 48),
                      
                      // Name Input
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Name', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 8),
                      GlassContainer(
                        padding: EdgeInsets.zero,
                        child: TextField(
                          controller: _nameController,
                          style: TextStyle(color: isDark ? Colors.white : Colors.black),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(16),
                            prefixIcon: Icon(LucideIcons.user, color: Colors.blue[400]),
                          ),
                        ),
                      ).animate().fadeIn(delay: 100.ms).moveY(begin: 20, end: 0, duration: 400.ms),
                      
                      const SizedBox(height: 48),

                      // Save Button
                      GestureDetector(
                        onTap: _isSaving ? null : _handleSave,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: _isSaving ? Colors.grey : Colors.yellow[500],
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: _isSaving ? [] : [
                              BoxShadow(
                                color: Colors.yellow[600]!.withOpacity(0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              )
                            ],
                          ),
                          child: Center(
                            child: _isSaving
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  )
                                : const Text(
                                    'Save Changes',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                          ),
                        ),
                      ).animate().fadeIn(delay: 200.ms).moveY(begin: 20, end: 0, duration: 400.ms),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ).animate().slideX(begin: 1, end: 0, duration: 400.ms, curve: Curves.easeOutQuad),
    );
  }
}
