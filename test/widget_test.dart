import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:joinme/models/user_model.dart';

void main() {
  group('UserModel Tests', () {
    test('Should correctly parse from JSON', () {
      final now = Timestamp.now();
      final json = {
        'uid': 'test-uid',
        'fullName': 'Rufael Melese',
        'email': 'rufael@example.com',
        'photoUrl': 'https://example.com/avatar.jpg',
        'reliability': 98,
        'createdAt': now,
        'updatedAt': now,
      };
      
      final user = UserModel.fromJson(json);
      
      expect(user.uid, 'test-uid');
      expect(user.fullName, 'Rufael Melese');
      expect(user.email, 'rufael@example.com');
      expect(user.photoUrl, 'https://example.com/avatar.jpg');
      expect(user.reliability, 98);
      expect(user.createdAt, now.toDate());
      expect(user.updatedAt, now.toDate());
    });

    test('Should convert to JSON correctly', () {
      final now = DateTime.now();
      final user = UserModel(
        uid: 'test-uid',
        fullName: 'Imran Getu',
        email: 'imran@example.com',
        photoUrl: null,
        reliability: 95,
        createdAt: now,
        updatedAt: now,
      );

      final json = user.toJson();

      expect(json['uid'], 'test-uid');
      expect(json['fullName'], 'Imran Getu');
      expect(json['email'], 'imran@example.com');
      expect(json['photoUrl'], null);
      expect(json['reliability'], 95);
      expect(json['createdAt'], isA<Timestamp>());
      expect(json['updatedAt'], isA<Timestamp>());
    });
  });
}
