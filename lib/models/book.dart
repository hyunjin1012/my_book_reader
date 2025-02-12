class Book {
  final String id;
  final String title;
  final String author;
  final String content;

  Book({
    required this.id,
    required this.title,
    required this.author,
    required this.content,
  });

  factory Book.fromJson(Map<String, dynamic> json) {
    return Book(
      id: json['id'].toString(),
      title: json['title'],
      author: json['authors'] != null && json['authors'].isNotEmpty
          ? json['authors'][0]
              ['name'] // Assuming the first author is the main one
          : 'Unknown',
      content: json['content'] ?? '',
    );
  }
}
