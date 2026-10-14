import 'dart:async';

import 'package:app_movil_comunidad/models/post_cnc.dart';
import 'package:app_movil_comunidad/screens/noticias/post_detail.dart';
import 'package:app_movil_comunidad/services/wp_cnc_post.dart';
import 'package:app_movil_comunidad/widgets/ui.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Noticias de neocatechumenaleiter.org con paginación infinita y búsqueda.
class PostListPage extends StatefulWidget {
  const PostListPage({super.key});

  @override
  State<PostListPage> createState() => _PostListPageState();
}

class _PostListPageState extends State<PostListPage> {
  static const _perPage = 10;

  final _service = WordPressService();
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  Timer? _debounce;

  final List<PostModel> _posts = [];
  int _page = 0;
  int _totalPages = 1;
  int _total = 0;
  bool _loading = false;
  String? _error;
  String _search = '';

  /// Evita que una respuesta vieja pise una búsqueda más reciente.
  int _peticion = 0;

  bool get _hasMore => _page < _totalPages;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      final pos = _scrollController.position;
      if (pos.pixels >= pos.maxScrollExtent - 400) _cargarSiguiente();
    });
    _cargarSiguiente();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _cargarSiguiente() async {
    if (_loading || !_hasMore || _error != null) return;
    final id = ++_peticion;
    setState(() => _loading = true);
    try {
      final res = await _service.fetchPosts(
        _page + 1,
        _perPage,
        search: _search,
      );
      if (!mounted || id != _peticion) return;
      setState(() {
        _posts.addAll(res.posts);
        _page++;
        _totalPages = res.posts.isEmpty ? _page : res.totalPages;
        if (res.total > 0) _total = res.total;
      });
    } catch (_) {
      if (mounted && id == _peticion) {
        setState(
          () => _error =
              'No se pudieron cargar las noticias.\n'
              'Revisa tu conexión a internet.',
        );
      }
    } finally {
      if (mounted && id == _peticion) setState(() => _loading = false);
    }
  }

  Future<void> _reiniciar() async {
    _peticion++;
    setState(() {
      _posts.clear();
      _page = 0;
      _totalPages = 1;
      _total = 0;
      _error = null;
      _loading = false;
    });
    await _cargarSiguiente();
  }

  void _reintentar() {
    setState(() => _error = null);
    _cargarSiguiente();
  }

  void _onSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (value.trim() == _search) return;
      _search = value.trim();
      _reiniciar();
    });
  }

  void _abrir(PostModel post) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PostDetailPage(post: post)),
    );
  }

  Widget _buscador() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: TextField(
        controller: _searchController,
        textInputAction: TextInputAction.search,
        onChanged: _onSearch,
        onSubmitted: (v) {
          _debounce?.cancel();
          _search = v.trim();
          _reiniciar();
        },
        decoration: appInput(
          'Buscar noticias',
          icon: Icons.search,
          suffix: _searchController.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _search = '';
                    _reiniciar();
                  },
                ),
        ),
      ),
    );
  }

  Widget _pie() {
    if (_error != null) {
      return _posts.isEmpty
          ? const SizedBox.shrink()
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const Text('No se pudo cargar más noticias'),
                  TextButton.icon(
                    onPressed: _reintentar,
                    icon: const Icon(Icons.refresh, color: kRojo),
                    label: const Text(
                      'Reintentar',
                      style: TextStyle(color: kRojo),
                    ),
                  ),
                ],
              ),
            );
    }
    if (_hasMore || _loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator(color: kRojo)),
      );
    }
    if (_posts.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Text(
        'Has visto todas las noticias',
        textAlign: TextAlign.center,
        style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vacio = _posts.isEmpty && !_loading;

    return AppPage(
      title: 'Noticias',
      body: Column(
        children: [
          _buscador(),
          if (_total > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${_posts.length} de $_total noticias',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              color: kRojo,
              onRefresh: _reiniciar,
              child: vacio && _error != null
                  ? _scrollable(
                      EmptyState(icon: Icons.wifi_off_rounded, text: _error!),
                      boton: true,
                    )
                  : vacio && _page > 0
                  ? _scrollable(
                      EmptyState(
                        icon: Icons.search_off,
                        text: 'Sin resultados para "$_search"',
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                      itemCount: _posts.length + 1,
                      itemBuilder: (_, i) => i == _posts.length
                          ? _pie()
                          : _NoticiaCard(
                              post: _posts[i],
                              destacada: i == 0 && _search.isEmpty,
                              onTap: () => _abrir(_posts[i]),
                            ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  /// Permite "tirar para refrescar" también en los estados vacíos.
  Widget _scrollable(Widget child, {bool boton = false}) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 60),
        child,
        if (boton)
          Center(
            child: TextButton.icon(
              onPressed: _reintentar,
              icon: const Icon(Icons.refresh, color: kRojo),
              label: const Text('Reintentar', style: TextStyle(color: kRojo)),
            ),
          ),
      ],
    );
  }
}

class _NoticiaCard extends StatelessWidget {
  final PostModel post;
  final bool destacada;
  final VoidCallback onTap;

  const _NoticiaCard({
    required this.post,
    required this.destacada,
    required this.onTap,
  });

  static const _meses = [
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];

  String? get _fecha {
    final d = post.date;
    return d == null ? null : '${d.day} ${_meses[d.month - 1]} ${d.year}';
  }

  Widget _imagen(double height) {
    if (post.featuredImage == null) {
      return Container(
        height: height,
        color: kRojo.withValues(alpha: 0.08),
        child: const Center(
          child: Icon(Icons.article_outlined, color: kRojo, size: 36),
        ),
      );
    }
    return CachedNetworkImage(
      imageUrl: post.featuredImage!,
      height: height,
      width: double.infinity,
      fit: BoxFit.cover,
      placeholder: (_, _) =>
          Container(height: height, color: Colors.grey.shade200),
      errorWidget: (_, _, _) => Container(
        height: height,
        color: Colors.grey.shade200,
        child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fecha = _fecha;
    final texto = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (fecha != null)
          Text(
            fecha.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w600,
              color: kRojo,
            ),
          ),
        const SizedBox(height: 4),
        Text(
          post.title,
          maxLines: destacada ? 3 : 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: destacada ? 18 : 15,
            fontWeight: FontWeight.w700,
            height: 1.25,
            color: const Color(0xFF1F2937),
          ),
        ),
        if (destacada && post.excerpt.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            post.excerpt,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ],
    );

    return Card(
      elevation: 0,
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: onTap,
        child: destacada
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _imagen(190),
                  Padding(padding: const EdgeInsets.all(14), child: texto),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(width: 110, height: 100, child: _imagen(100)),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                      child: texto,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
