import 'package:flutter_test/flutter_test.dart';
import 'package:joinme/services/auth_service.dart';

void main() {
  group('validateNewPassword', () {
    test('matching passwords pass', () {
      expect(validateNewPassword(password: 'newpass1', confirm: 'newpass1'), isNull);
    });
    test('short password is rejected', () {
      expect(validateNewPassword(password: '12345', confirm: '12345'), 'Password must be at least 6 characters');
    });
    test('mismatched passwords are rejected', () {
      expect(validateNewPassword(password: 'newpass1', confirm: 'newpass2'), "Passwords don't match");
    });
  });

  test('reset link opens the app via its own URL scheme', () {
    expect(resetRedirectUrl, 'io.supabase.joinme://reset-callback');
  });

  test('Google sign-in returns to the app via the same scheme', () {
    expect(loginRedirectUrl, 'io.supabase.joinme://login-callback');
  });
}
