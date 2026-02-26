class Profile {
  final String id;
  final String? displayName;
  final String? avatarUrl;

  Profile({required this.id, this.displayName, this.avatarUrl});

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['user_id'],
      displayName: map['display_name'],
      avatarUrl: map['avatar_url'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': id,
      'display_name': displayName,
      'avatar_url': avatarUrl,
    };
  }
}
