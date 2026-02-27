class Comment {
  final String id;
  final String blogId;
  final String authorId;
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<String> images;

  Comment({
    required this.id,
    required this.blogId,
    required this.authorId,
    required this.content,
    required this.createdAt,
    this.updatedAt,
    this.images = const [],
  });

  factory Comment.fromMap(Map<String, dynamic> map) {
    return Comment(
      id: map['id'],
      blogId: map['blog_id'],
      authorId: map['author_id'],
      content: map['content'],
      createdAt: DateTime.parse(map['created_at']),
      images:
          (map['comment_images'] as List?)
              ?.map((e) => e['image_url'] as String)
              .toList() ??
          [],
    );
  }
}
