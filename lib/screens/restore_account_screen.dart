import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;
import '../providers/app_state.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';
import '../widgets/joinme_logo.dart';

/// Shown when someone whose account was deleted signs in again.
class RestoreAccountScreen extends StatefulWidget {
  const RestoreAccountScreen({super.key});

  @override
  State<RestoreAccountScreen> createState() => _RestoreAccountScreenState();
}

class _RestoreAccountScreenState extends State<RestoreAccountScreen> {
  bool _busy = false;

  Future<void> _restore() async {
    final appState = context.read<AppState>();
    setState(() => _busy = true);
    try {
      await appState.auth.restoreAccount();
      await appState.loadMe();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Welcome back! Your account is restored.')));
      appState.navigateTo('map');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e is PostgrestException ? e.message : 'Could not restore. Try again.')),
      );
      setState(() => _busy = false);
    }
  }

  String _date(DateTime d) => '${d.day}/${d.month}/${d.year}';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final me = context.watch<AppState>().me;
    final deletedAt = me?.deletedAt;
    final restorable = deletedAt != null && canRestore(deletedAt, DateTime.now());

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark ? [AppTheme.darkBg, AppTheme.darkBg2] : [AppTheme.lightBg, AppTheme.lightBg2],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Spacer(),
                const JoinMeLogo(size: 48),
                const SizedBox(height: 40),
                Icon(LucideIcons.userX, size: 56, color: isDark ? Colors.white54 : Colors.black45),
                const SizedBox(height: 16),
                Text(
                  restorable ? 'Restore your account?' : 'This account was deleted',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
                ),
                const SizedBox(height: 12),
                Text(
                  deletedAt == null
                      ? ''
                      : restorable
                          ? 'You deleted your account on ${_date(deletedAt)}. Restore it to get your profile, friends and chats back. '
                              'People you know will be told you\'re back.'
                          : 'It was deleted on ${_date(deletedAt)}, more than 30 days ago, so it can no longer be restored.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 15, height: 1.4, color: isDark ? Colors.white70 : Colors.black54),
                ),
                const Spacer(),
                if (restorable)
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _busy ? null : _restore,
                      child: _busy
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                          : const Text('Restore my account', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                    ),
                  ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _busy ? null : () => context.read<AppState>().auth.signOut(),
                  child: Text(restorable ? 'No, sign out' : 'Sign out',
                      style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
