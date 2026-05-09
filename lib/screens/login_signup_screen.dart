import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/app_state.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_container.dart';

class LoginSignupScreen extends StatefulWidget {
  const LoginSignupScreen({Key? key}) : super(key: key);

  @override
  State<LoginSignupScreen> createState() => _LoginSignupScreenState();
}

class _LoginSignupScreenState extends State<LoginSignupScreen> {
  bool _isLogin = true;
  bool _showPassword = false;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    // In a real app, do auth here.
    context.read<AppState>().navigateTo('map');
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
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark 
              ? [const Color(0xFF0d1b1e), const Color(0xFF1a363d)] 
              : [const Color(0xFFf9fafb), const Color(0xFFe5e7eb)],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Theme Toggle Button
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

              Column(
                children: [
                  // Header Section
                  Padding(
                    padding: const EdgeInsets.only(top: 48.0, bottom: 32.0, left: 24.0, right: 24.0),
                    child: Column(
                      children: [
                        // Logo
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: Colors.yellow[500],
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.yellow[600]!.withOpacity(0.5),
                                blurRadius: 20,
                                spreadRadius: 0,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: const Icon(LucideIcons.mapPin, color: Colors.white, size: 32),
                        ).animate(onPlay: (controller) => controller.repeat())
                         .moveY(begin: 0, end: -8, duration: 1.5.seconds, curve: Curves.easeInOut)
                         .then().moveY(begin: -8, end: 0, duration: 1.5.seconds, curve: Curves.easeInOut),
                        
                        const SizedBox(height: 24),
                        
                        // Hero Text
                        ShaderMask(
                          shaderCallback: (bounds) => LinearGradient(
                            colors: [Colors.blue[300]!, Colors.blue[400]!, Colors.blue[300]!],
                          ).createShader(bounds),
                          child: Text(
                            _isLogin ? 'Welcome Back!' : 'Join the Community',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isLogin ? 'Sign in to discover nearby activities' : 'Create spontaneous moments with people nearby',
                          style: TextStyle(
                            color: isDark ? Colors.white54 : Colors.black54,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ).animate().fadeIn(duration: 600.ms).moveY(begin: -20, end: 0, duration: 600.ms),
                  ),

                  // Scrollable Form Section
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                      child: Column(
                        children: [
                          // Social Login Buttons
                          _buildSocialButton(
                            icon: LucideIcons.chrome,
                            iconColor: Colors.blue[500]!,
                            text: 'Continue with Google',
                            onTap: _handleSubmit,
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildSocialButton(
                                  icon: LucideIcons.apple,
                                  iconColor: isDark ? Colors.white : Colors.black,
                                  text: 'Apple',
                                  onTap: _handleSubmit,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildSocialButton(
                                  icon: LucideIcons.facebook,
                                  iconColor: Colors.blue[600]!,
                                  text: 'Facebook',
                                  onTap: _handleSubmit,
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Divider
                          Row(
                            children: [
                              Expanded(child: Divider(color: isDark ? Colors.white10 : Colors.black12)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  'OR CONTINUE WITH EMAIL',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isDark ? Colors.white54 : Colors.black54,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                              Expanded(child: Divider(color: isDark ? Colors.white10 : Colors.black12)),
                            ],
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Login/Signup Tabs
                          GlassContainer(
                            padding: const EdgeInsets.all(4),
                            child: Row(
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(() => _isLogin = true),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      decoration: BoxDecoration(
                                        color: _isLogin ? Colors.yellow[500] : Colors.transparent,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: _isLogin ? [
                                          BoxShadow(
                                            color: Colors.yellow[600]!.withOpacity(0.3),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          )
                                        ] : [],
                                      ),
                                      child: Center(
                                        child: Text(
                                          'Login',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: _isLogin ? Colors.white : (isDark ? Colors.white54 : Colors.black54),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () => setState(() => _isLogin = false),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 300),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      decoration: BoxDecoration(
                                        color: !_isLogin ? Colors.yellow[500] : Colors.transparent,
                                        borderRadius: BorderRadius.circular(12),
                                        boxShadow: !_isLogin ? [
                                          BoxShadow(
                                            color: Colors.yellow[600]!.withOpacity(0.3),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          )
                                        ] : [],
                                      ),
                                      child: Center(
                                        child: Text(
                                          'Sign Up',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: !_isLogin ? Colors.white : (isDark ? Colors.white54 : Colors.black54),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Form
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Column(
                              key: ValueKey<bool>(_isLogin),
                              children: [
                                if (!_isLogin) ...[
                                  _buildTextField(
                                    controller: _nameController,
                                    icon: LucideIcons.user,
                                    iconBgColor: Colors.blue[500]!.withOpacity(0.2),
                                    iconColor: Colors.blue[400]!,
                                    placeholder: 'Full Name',
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                _buildTextField(
                                  controller: _emailController,
                                  icon: LucideIcons.mail,
                                  iconBgColor: Colors.yellow[500]!.withOpacity(0.2),
                                  iconColor: Colors.yellow[400]!,
                                  placeholder: 'Email Address',
                                ),
                                const SizedBox(height: 16),
                                _buildTextField(
                                  controller: _passwordController,
                                  icon: LucideIcons.lock,
                                  iconBgColor: Colors.blue[500]!.withOpacity(0.2),
                                  iconColor: Colors.blue[400]!,
                                  placeholder: 'Password',
                                  obscureText: !_showPassword,
                                  suffixIcon: GestureDetector(
                                    onTap: () => setState(() => _showPassword = !_showPassword),
                                    child: Icon(
                                      _showPassword ? LucideIcons.eyeOff : LucideIcons.eye,
                                      color: isDark ? Colors.white54 : Colors.black54,
                                    ),
                                  ),
                                ),
                                
                                if (_isLogin)
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: Padding(
                                      padding: const EdgeInsets.only(top: 16.0),
                                      child: Text(
                                        'Forgot password?',
                                        style: TextStyle(
                                          color: Colors.yellow[400],
                                          fontWeight: FontWeight.w500,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                
                                const SizedBox(height: 24),
                                
                                // Submit Button
                                GestureDetector(
                                  onTap: _handleSubmit,
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
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          _isLogin ? 'Sign In' : 'Create Account',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        const Icon(LucideIcons.zap, color: Colors.white, size: 20),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 48),
                        ],
                      ).animate().fadeIn(delay: 200.ms, duration: 600.ms).moveY(begin: 20, end: 0, duration: 600.ms),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required Color iconColor,
    required String text,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(icon, color: iconColor, size: 16),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              text,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String placeholder,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return GlassContainer(
      padding: EdgeInsets.zero,
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        style: TextStyle(color: isDark ? Colors.white : Colors.black),
        decoration: InputDecoration(
          hintText: placeholder,
          hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
          prefixIcon: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
          ),
          suffixIcon: suffixIcon != null ? Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: suffixIcon,
          ) : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 20),
        ),
      ),
    );
  }
}
