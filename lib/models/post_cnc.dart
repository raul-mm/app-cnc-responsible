class PostModel {
  final int id;
  final String title;
  final String content;
  final String? featuredImage;

  PostModel({
    required this.id,
    required this.title,
    required this.content,
    this.featuredImage,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'],
      title: json['title']['rendered'],
      content: json['content']['rendered'],
      featuredImage: json['_embedded']?['wp:featuredmedia']?[0]?['source_url'],
    );
  }
}
