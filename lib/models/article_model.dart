class Article {
  final String id;
  final String title;
  final String preview;
  final String content;
  final String thumbnail; // путь к миниатюре в assets

  Article({
    required this.id,
    required this.title,
    required this.preview,
    required this.content,
    required this.thumbnail,
  });
}
