import 'package:cloud_firestore/cloud_firestore.dart';

class ParticipantModel {
  final String userId;
  final String fullName;
  final String avatar;
  final DateTime joinedAt;

  ParticipantModel({
    required this.userId,
    required this.fullName,
    required this.avatar,
    required this.joinedAt,
  });

  factory ParticipantModel.fromJson(Map<String, dynamic> json) {
    return ParticipantModel(
      userId: json['userId'] as String? ?? '',
      fullName: json['fullName'] as String? ?? 'Anonymous',
      avatar: json['avatar'] as String? ?? 'AN',
      joinedAt: json['joinedAt'] != null
          ? (json['joinedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'fullName': fullName,
      'avatar': avatar,
      'joinedAt': Timestamp.fromDate(joinedAt),
    };
  }

  ParticipantModel copyWith({
    String? userId,
    String? fullName,
    String? avatar,
    DateTime? joinedAt,
  }) {
    return ParticipantModel(
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      avatar: avatar ?? this.avatar,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }
}
