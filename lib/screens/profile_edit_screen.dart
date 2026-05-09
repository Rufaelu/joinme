import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/app_state.dart';
import '../widgets/glass_container.dart';
import '../data/mock_data.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({Key? key}) : super(key: key);

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  late TextEditingController _nameController;
  
  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: currentUser['name'] as String);
  }
  
  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
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
                      // Avatar Edit
                      Stack(
                        alignment: Alignment.bottomRight,
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [Colors.yellow[400]!, Colors.blue[600]!],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                currentUser['avatar'] as String,
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
                        onTap: () => context.read<AppState>().navigateTo('profile'),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.yellow[500],
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.yellow[600]!.withOpacity(0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
                              )
                            ],
                          ),
                          child: const Center(
                            child: Text(
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
