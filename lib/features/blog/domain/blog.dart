class Blog {
  final String id;
  final String authorId;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<String> images;
  final String? authorAvatar;
  final String? authorName;
  final int commentCount;

  Blog({
    required this.id,
    required this.authorId,
    required this.title,
    required this.content,
    required this.createdAt,
    this.updatedAt,
    this.images = const [],
    this.authorAvatar,
    this.authorName,
    this.commentCount = 0,
  });

  factory Blog.fromMap(Map<String, dynamic> map) {
    int parsedCommentCount = 0;
    if (map['comments'] is Map) {
      parsedCommentCount = map['comments']['count'] ?? 0;
    } else if (map['comments'] is List) {
      parsedCommentCount = (map['comments'] as List).length;
    }

    return Blog(
      id: map['id'],
      authorId: map['author_id'],
      title: map['title'],
      content: map['content'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'])
          : null,
      images:
          (map['blog_images'] as List?)
              ?.map((e) => e['image_url'] as String)
              .toList() ??
          [],
      authorAvatar: map['profiles']?['avatar_url'],
      authorName: map['profiles']?['display_name'],
      commentCount: parsedCommentCount,
    );
  }
}
