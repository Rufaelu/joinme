import 'package:flutter_test/flutter_test.dart';
import 'package:joinme/services/auth_service.dart';

void main() {
  group('validateAuthInput', () {
    test('valid login passes', () {
      expect(validateAuthInput(isSignUp: false, name: '', email: 'a@b.co', password: 'secret1'), isNull);
    });
    test('missing email is rejected', () {
      expect(validateAuthInput(isSignUp: false, name: '', email: '  ', password: 'secret1'), 'Enter your email');
    });
    test('email without @ is rejected', () {
      expect(validateAuthInput(isSignUp: false, name: '', email: 'abc', password: 'secret1'), 'Enter a valid email');
    });
    test('short password is rejected', () {
      expect(validateAuthInput(isSignUp: false, name: '', email: 'a@b.co', password: '12345'),
          'Password must be at least 6 characters');
    });
    test('sign up needs a name', () {
      expect(validateAuthInput(isSignUp: true, name: ' ', email: 'a@b.co', password: 'secret1'), 'Enter your name');
    });
    test('login ignores name', () {
      expect(validateAuthInput(isSignUp: false, name: '', email: 'a@b.co', password: 'secret1'), isNull);
    });
  });
}
