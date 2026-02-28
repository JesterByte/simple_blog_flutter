class Profile {
  final String id;
  final String? displayName;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Profile({
    required this.id,
    this.displayName,
    this.avatarUrl,
    required this.createdAt,
    this.updatedAt,
  });

  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['user_id'],
      displayName: map['display_name'],
      avatarUrl: map['avatar_url'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'user_id': id,
      'display_name': displayName,
      'avatar_url': avatarUrl,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
