import 'package:supabase_flutter/supabase_flutter.dart';

enum AuthResult { signedIn, needsEmailConfirmation }

/// Returns an error message, or null when the form can be submitted.
String? validateAuthInput({
  required bool isSignUp,
  required String name,
  required String email,
  required String password,
}) {
  if (isSignUp && name.trim().isEmpty) return 'Enter your name';
  if (email.trim().isEmpty) return 'Enter your email';
  if (!email.contains('@')) return 'Enter a valid email';
  if (password.length < 6) return 'Password must be at least 6 characters';
  return null;
}

/// Deep link the reset email sends people back to. Must also be listed under
/// Supabase → Authentication → URL Configuration → Redirect URLs, and match the
/// intent filter in android/app/src/main/AndroidManifest.xml.
const resetRedirectUrl = 'io.supabase.joinme://reset-callback';

/// Where Google sign-in returns to the app. Also listed in Supabase Redirect URLs
/// and the Android/iOS URL scheme settings.
const loginRedirectUrl = 'io.supabase.joinme://login-callback';

/// Checks the "choose a new password" form.
String? validateNewPassword({required String password, required String confirm}) {
  if (password.length < 6) return 'Password must be at least 6 characters';
  if (password != confirm) return "Passwords don't match";
  return null;
}

class AuthService {
  SupabaseClient get _db => Supabase.instance.client;

  String? get userId => _db.auth.currentUser?.id;
  bool get isSignedIn => _db.auth.currentSession != null;
  Stream<AuthState> get changes => _db.auth.onAuthStateChange;

  Future<AuthResult> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final res = await _db.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'name': name.trim()},
    );
    return res.session == null ? AuthResult.needsEmailConfirmation : AuthResult.signedIn;
  }

  Future<void> signIn({required String email, required String password}) async {
    await _db.auth.signInWithPassword(email: email.trim(), password: password);
  }

  /// Opens Google sign-in in the browser; the app gets AuthChangeEvent.signedIn
  /// when the browser sends the user back via [loginRedirectUrl].
  Future<void> signInWithGoogle() async {
    await _db.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: loginRedirectUrl,
      authScreenLaunchMode: LaunchMode.externalApplication,
    );
  }

  /// Emails a reset link. Opening it on this phone brings the user back into the
  /// app signed in, and Supabase fires AuthChangeEvent.passwordRecovery.
  Future<void> sendResetLink(String email) =>
      _db.auth.resetPasswordForEmail(email.trim(), redirectTo: resetRedirectUrl);

  Future<void> updatePassword(String newPassword) =>
      _db.auth.updateUser(UserAttributes(password: newPassword));

  Future<void> signOut() => _db.auth.signOut();
}
