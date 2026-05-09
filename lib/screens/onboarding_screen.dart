import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/app_state.dart';
import '../widgets/glass_container.dart';

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
              ? [const Color(0xFF0d1b1e), const Color(0xFF1a363d)] 
              : [const Color(0xFFf9fafb), const Color(0xFFe5e7eb)],
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
                      color: isDark ? Colors.yellow[400] : Colors.blue[500],
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
                        Container(
                          width: 96,
                          height: 96,
                          margin: const EdgeInsets.only(bottom: 32),
                          decoration: BoxDecoration(
                            color: Colors.yellow[500],
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.yellow[600]!.withOpacity(0.5),
                                blurRadius: 20,
                                spreadRadius: 0,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Icon(LucideIcons.mapPin, color: Colors.white, size: 48),
                        ).animate(onPlay: (controller) => controller.repeat())
                         .moveY(begin: 0, end: -10, duration: 1.5.seconds, curve: Curves.easeInOut)
                         .then().moveY(begin: -10, end: 0, duration: 1.5.seconds, curve: Curves.easeInOut),
                        
                        Positioned(
                          top: -8,
                          right: -8,
                          child: Icon(
                            LucideIcons.sparkles,
                            color: Colors.yellow[300],
                            size: 32,
                            shadows: [Shadow(color: Colors.yellow[300]!.withOpacity(0.8), blurRadius: 8)],
                          ).animate(onPlay: (controller) => controller.repeat())
                           .rotate(begin: 0, end: 1, duration: 4.seconds),
                        ),
                      ],
                    ),

                    // App Name
                    ShaderMask(
                      shaderCallback: (bounds) => LinearGradient(
                        colors: [Colors.blue[300]!, Colors.blue[400]!],
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
                                  ? [Colors.yellow[500]!, Colors.yellow[600]!]
                                  : index == 1
                                    ? [Colors.blue[400]!, Colors.blue[600]!]
                                    : [Colors.blue[500]!, Colors.blue[700]!],
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
                          color: Colors.yellow[500],
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.yellow[600]!.withOpacity(0.3),
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
