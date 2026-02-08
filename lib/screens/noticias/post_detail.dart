import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:app_movil_comunidad/models/post_cnc.dart';

class PostDetailPage extends StatefulWidget {
  final PostModel post;

  const PostDetailPage({super.key, required this.post});

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    // Simula carga corta (opcional)
    Future.delayed(const Duration(milliseconds: 200), () {
      if (mounted) {
        setState(() => _loading = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: const Text(
          'Noticia',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFFC62828),
        foregroundColor: Colors.white,
        elevation: 2,
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const SizedBox(height: 16),

                /// 🔹 TÍTULO ADAPTABLE
                Text(
                  widget.post.title,
                  maxLines: 4, // se adapta sin romper
                  overflow: TextOverflow.visible,
                  softWrap: true,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    height: 1.3,
                    color: Color(0xFF002060),
                  ),
                ),

                const SizedBox(height: 12),
                Html(
                  data: sanitizeHtml(widget.post.content),
                  style: {
                    "body": Style(
                      fontSize: FontSize(14),
                      color: Colors.black87,
                      lineHeight: LineHeight.number(1.6),
                    ),
                    "img": Style(
                      display: Display.block,
                      margin: Margins.symmetric(vertical: 12),
                    ),
                  },
                  extensions: [
                    ImageExtension(
                      builder: (context) {
                        final src = context.attributes['src'];
                        if (src == null || src.isEmpty) {
                          return const SizedBox.shrink();
                        }

                        return ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            src,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return const Padding(
                                padding: EdgeInsets.all(16),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              debugPrint('Image error: $error');
                              return const SizedBox.shrink();
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

String sanitizeHtml(String html) {
  return html
      .replaceAll('data-src=', 'src=')
      .replaceAll('data-lazy-src=', 'src=')
      .replaceAll('src="/', 'src="https://neocatechumenaleiter.org/')
      .replaceAll('http://', 'https://');
}
