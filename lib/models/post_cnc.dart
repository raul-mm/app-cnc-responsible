class PostModel {
  final int id;
  final String title;
  final String content;
  final String excerpt;
  final DateTime? date;
  final String? link;
  final String? featuredImage;

  PostModel({
    required this.id,
    required this.title,
    required this.content,
    this.excerpt = '',
    this.date,
    this.link,
    this.featuredImage,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    final media = json['_embedded']?['wp:featuredmedia']?[0];
    final sizes = media?['media_details']?['sizes'] as Map<String, dynamic>?;
    final image =
        sizes?['medium_large']?['source_url'] ??
        sizes?['large']?['source_url'] ??
        media?['source_url'];

    return PostModel(
      id: json['id'],
      title: limpiarHtml(json['title']?['rendered'] ?? ''),
      content: json['content']?['rendered'] ?? '',
      excerpt: limpiarHtml(json['excerpt']?['rendered'] ?? ''),
      date: DateTime.tryParse(json['date'] ?? ''),
      link: json['link'],
      featuredImage: image,
    );
  }
}

/// Quita etiquetas y decodifica las entidades HTML más comunes de WordPress.
String limpiarHtml(String html) {
  const entidades = {
    '&nbsp;': ' ',
    '&amp;': '&',
    '&quot;': '"',
    '&#039;': "'",
    '&lt;': '<',
    '&gt;': '>',
    '&hellip;': '…',
    '[&hellip;]': '…',
  };
  var s = html.replaceAll(RegExp(r'<[^>]*>'), '');
  entidades.forEach((k, v) => s = s.replaceAll(k, v));
  s = s.replaceAllMapped(
    RegExp(r'&#(\d+);'),
    (m) => String.fromCharCode(int.parse(m[1]!)),
  );
  return s.replaceAll(RegExp(r'\s+'), ' ').trim();
}
