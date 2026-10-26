import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show AuthException;
import '../providers/app_state.dart';
import '../services/auth_service.dart';
import '../widgets/glass_container.dart';
import '../theme/app_theme.dart';

/// Step 1: email a reset link. Step 2 (opened from that link, see
/// AppState.inPasswordRecovery): choose a new password.
class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _linkSent = false;
  bool _busy = false;
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    _emailController.text = context.read<AppState>().resetEmail ?? '';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _sendLink() async {
    final email = _emailController.text.trim();
    if (!email.contains('@')) {
      _showMessage('Enter a valid email');
      return;
    }
    setState(() => _busy = true);
    try {
      await context.read<AppState>().auth.sendResetLink(email);
      if (!mounted) return;
      setState(() => _linkSent = true);
    } on AuthException catch (e) {
      _showMessage(e.statusCode == '429' ? 'Too many requests. Wait a minute and try again.' : e.message);
    } catch (_) {
      _showMessage('Something went wrong. Check your connection and try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _setNewPassword() async {
    final error = validateNewPassword(password: _passwordController.text, confirm: _confirmController.text);
    if (error != null) {
      _showMessage(error);
      return;
    }
    final appState = context.read<AppState>();
    setState(() => _busy = true);
    try {
      await appState.auth.updatePassword(_passwordController.text);
      _showMessage('Password updated. You are signed in.');
      appState.finishPasswordRecovery();
    } on AuthException catch (e) {
      _showMessage(e.message);
    } catch (_) {
      _showMessage('Something went wrong. Check your connection and try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final recovering = context.watch<AppState>().inPasswordRecovery;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [AppTheme.darkBg, AppTheme.darkBg2]
                : [AppTheme.lightBg, AppTheme.lightBg2],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              if (!recovering) Padding(
                padding: const EdgeInsets.all(16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () => context.read<AppState>().navigateTo('login'),
                    child: GlassContainer(
                      borderRadius: 30,
                      padding: const EdgeInsets.all(12),
                      child: Icon(LucideIcons.arrowLeft, color: isDark ? Colors.white : Colors.black),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (recovering) const SizedBox(height: 48),
                      Text(recovering ? 'New password' : 'Reset password',
                          style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
                      const SizedBox(height: 8),
                      Text(
                        recovering
                            ? 'Choose a new password for your account.'
                            : _linkSent
                                ? 'Check your email on this phone and tap "Reset password". It will open JoinMe so you can choose a new password.'
                                : "We'll email you a link to reset your password.",
                        style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 16),
                      ),
                      const SizedBox(height: 32),
                      if (!recovering)
                        _field(
                          isDark: isDark,
                          controller: _emailController,
                          icon: LucideIcons.mail,
                          hint: 'Email Address',
                          keyboardType: TextInputType.emailAddress,
                          enabled: !_linkSent,
                        ),
                      if (recovering) ...[
                        _field(
                          isDark: isDark,
                          controller: _passwordController,
                          icon: LucideIcons.lock,
                          hint: 'New password',
                          obscure: !_showPassword,
                          suffix: GestureDetector(
                            onTap: () => setState(() => _showPassword = !_showPassword),
                            child: Icon(_showPassword ? LucideIcons.eyeOff : LucideIcons.eye,
                                color: isDark ? Colors.white54 : Colors.black54),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _field(
                          isDark: isDark,
                          controller: _confirmController,
                          icon: LucideIcons.lock,
                          hint: 'Confirm new password',
                          obscure: !_showPassword,
                        ),
                      ],
                      const SizedBox(height: 32),
                      GestureDetector(
                        onTap: _busy ? null : (recovering ? _setNewPassword : _sendLink),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: AppTheme.primary,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: _busy
                                ? const SizedBox(
                                    width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                                : Text(
                                    recovering ? 'Save New Password' : (_linkSent ? 'Send Again' : 'Send Reset Link'),
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                                  ),
                          ),
                        ),
                      ),
                      if (_linkSent && !recovering) ...[
                        const SizedBox(height: 16),
                        Center(
                          child: TextButton(
                            onPressed: _busy ? null : () => setState(() => _linkSent = false),
                            child: Text('Use a different email',
                                style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)),
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),
                    ],
                  ).animate().fadeIn(duration: 400.ms).moveY(begin: 20, end: 0, duration: 400.ms),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field({
    required bool isDark,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    TextInputType? keyboardType,
    bool obscure = false,
    bool enabled = true,
    Widget? suffix,
  }) {
    return GlassContainer(
      padding: EdgeInsets.zero,
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscure,
        enabled: enabled,
        style: TextStyle(color: isDark ? Colors.white : Colors.black),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: AppTheme.accentLight),
          suffixIcon: suffix == null ? null : Padding(padding: const EdgeInsets.only(right: 12), child: suffix),
          suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
          hintText: hint,
          hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.black54),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
    );
  }
}
