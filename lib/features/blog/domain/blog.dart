class Blog {
  final String id;
  final String authorId;
  final String title;
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<String> images;

  Blog({
    required this.id,
    required this.authorId,
    required this.title,
    required this.content,
    required this.createdAt,
    this.updatedAt,
    this.images = const [],
  });

  factory Blog.fromMap(Map<String, dynamic> map) {
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
    );
  }

  Map<String, dynamic> toInsertMap() {
    return {'author_id': authorId, 'title': title, 'content': content};
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'title': title,
      'content': content,
      'updated_at': DateTime.now().toIso8601String(),
    };
  }
}
