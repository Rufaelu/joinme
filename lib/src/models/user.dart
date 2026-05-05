class UserModel {
  UserModel({
    required this.id,
    required this.name,
    required this.avatarUrl,
    required this.bio,
    required this.rating,
    required this.reviewCount,
    required this.eventsHosted,
    required this.eventsJoined,
    required this.friendsCount,
    required this.online,
    required this.interests,
  });

  final String id;
  String name;
  String avatarUrl;
  String bio;
  double rating;
  int reviewCount;
  int eventsHosted;
  int eventsJoined;
  int friendsCount;
  bool online;
  List<String> interests;
}
