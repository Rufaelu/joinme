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

  Future<void> signOut() => _db.auth.signOut();
}
