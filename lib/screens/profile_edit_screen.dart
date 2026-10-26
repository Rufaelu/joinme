import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/app_state.dart';
import '../widgets/glass_container.dart';
import '../widgets/avatar.dart';
import '../theme/app_theme.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({Key? key}) : super(key: key);

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  bool _saving = false;
  bool _uploading = false;
  String? _avatarUrl;
  
  @override
  void initState() {
    super.initState();
    final me = context.read<AppState>().me;
    _nameController = TextEditingController(text: me?.name ?? '');
    _bioController = TextEditingController(text: me?.bio ?? '');
    _avatarUrl = me?.avatarUrl;
  }

  Future<void> _pickPhoto() async {
    final storage = context.read<AppState>().storage;
    final file = await storage.pickPhoto();
    if (file == null || !mounted) return;
    setState(() => _uploading = true);
    try {
      final url = await storage.upload(bucket: 'avatars', kind: 'avatar', file: file);
      if (mounted) setState(() => _avatarUrl = url);
    } catch (e) {
      debugPrint('Avatar upload failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not upload the photo. Try a smaller image.')));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name cannot be empty')));
      return;
    }
    final appState = context.read<AppState>();
    setState(() => _saving = true);
    try {
      await appState.updateProfile(name: _nameController.text, bio: _bioController.text, avatarUrl: _avatarUrl);
      appState.navigateTo('profile');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not save. Try again.')));
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark 
              ? [AppTheme.darkBg, AppTheme.darkBg2] 
              : [AppTheme.lightBg, AppTheme.lightBg2],
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
                      onTap: () => context.read<AppState>().navigateTo('profile'),
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
                      // Avatar Edit — tap to choose a photo
                      GestureDetector(
                        onTap: _uploading ? null : _pickPhoto,
                        child: Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            Avatar(name: _nameController.text, url: _avatarUrl, size: 120),
                            if (_uploading)
                              const Positioned.fill(
                                child: Center(child: CircularProgressIndicator(color: Colors.white)),
                              ),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppTheme.accent,
                                shape: BoxShape.circle,
                                border: Border.all(color: isDark ? AppTheme.darkBg2 : Colors.white, width: 4),
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
                          onChanged: (_) => setState(() {}),
                          style: TextStyle(color: isDark ? Colors.white : Colors.black),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(16),
                            prefixIcon: Icon(LucideIcons.user, color: AppTheme.accentLight),
                          ),
                        ),
                      ).animate().fadeIn(delay: 100.ms).moveY(begin: 20, end: 0, duration: 400.ms),

                      const SizedBox(height: 24),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Bio', style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 8),
                      GlassContainer(
                        padding: EdgeInsets.zero,
                        child: TextField(
                          controller: _bioController,
                          maxLines: 3,
                          maxLength: 200,
                          style: TextStyle(color: isDark ? Colors.white : Colors.black),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(16),
                            hintText: 'A line about you — what you like to do',
                            hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 48),

                      // Save Button
                      GestureDetector(
                        onTap: _saving || _uploading ? null : _save,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.primaryDark.withOpacity(0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              )
                            ],
                          ),
                          child: Center(
                            child: _saving
                                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
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
