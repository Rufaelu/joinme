import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/app_state.dart';
import '../widgets/glass_container.dart';
import '../theme/app_theme.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

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
          child: Stack(
            children: [
              // Theme Toggle
              Positioned(
                top: 16,
                right: 16,
                child: GestureDetector(
                  onTap: () => context.read<AppState>().toggleTheme(),
                  child: GlassContainer(
                    borderRadius: 30,
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      isDark ? LucideIcons.sun : LucideIcons.moon,
                      color: isDark ? AppTheme.primaryLight : AppTheme.accent,
                      size: 24,
                    ),
                  ),
                ).animate().scale(delay: 200.ms, duration: 400.ms),
              ),

              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo Animation
                    Stack(
                      alignment: Alignment.topRight,
                      children: [
                        Image.asset('assets/logo/joinme_mark.png', width: 120, height: 120).animate(onPlay: (controller) => controller.repeat())
                         .moveY(begin: 0, end: -10, duration: 1.5.seconds, curve: Curves.easeInOut)
                         .then().moveY(begin: -10, end: 0, duration: 1.5.seconds, curve: Curves.easeInOut),
                        
                        Positioned(
                          top: -8,
                          right: -8,
                          child: Icon(
                            LucideIcons.sparkles,
                            color: AppTheme.primaryLight,
                            size: 32,
                            shadows: [Shadow(color: AppTheme.primaryLight.withOpacity(0.8), blurRadius: 8)],
                          ).animate(onPlay: (controller) => controller.repeat())
                           .rotate(begin: 0, end: 1, duration: 4.seconds),
                        ),
                      ],
                    ),

                    // App Name
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [AppTheme.primaryLight, AppTheme.accentLight],
                      ).createShader(bounds),
                      child: const Text(
                        'JoinMe',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -1,
                        ),
                      ),
                    ).animate().fadeIn(delay: 200.ms).moveY(begin: 20, end: 0, duration: 600.ms),

                    const SizedBox(height: 12),

                    // Tagline
                    Text(
                      'Turn free time into shared moments.',
                      style: TextStyle(
                        fontSize: 18,
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                      textAlign: TextAlign.center,
                    ).animate().fadeIn(delay: 300.ms).moveY(begin: 20, end: 0, duration: 600.ms),

                    const SizedBox(height: 64),

                    // Illustration
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (index) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: index == 0 
                                  ? [AppTheme.primary, AppTheme.primaryDark]
                                  : index == 1
                                    ? [AppTheme.accentLight, AppTheme.accentDark]
                                    : [AppTheme.accent, AppTheme.accentDark],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                )
                              ],
                            ),
                            child: const Icon(LucideIcons.users, color: Colors.white, size: 32),
                          ).animate(onPlay: (controller) => controller.repeat())
                           .moveY(begin: 0, end: -8, duration: 1.seconds, delay: (index * 200).ms, curve: Curves.easeInOut)
                           .then().moveY(begin: -8, end: 0, duration: 1.seconds, curve: Curves.easeInOut),
                        );
                      }),
                    ).animate().scale(delay: 400.ms, duration: 600.ms).fadeIn(delay: 400.ms),

                    const SizedBox(height: 64),

                    // Get Started Button
                    GestureDetector(
                      onTap: () => context.read<AppState>().navigateTo('map'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryDark.withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            )
                          ],
                        ),
                        child: const Text(
                          'Get Started',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ).animate().fadeIn(delay: 800.ms).moveY(begin: 20, end: 0, duration: 600.ms),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
