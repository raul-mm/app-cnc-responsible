import 'package:app_movil_comunidad/db/db_helper.dart';
import 'package:app_movil_comunidad/models/comunidad.dart';
import 'package:app_movil_comunidad/widgets/ui.dart';
import 'package:flutter/material.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Comunidad? comunidad;
  Map<String, int> resumen = {};

  // Orden del flujo: primero personas, luego todo lo que se arma con ellas.
  static const items = [
    _DashboardItem('Personas', Icons.people_alt_outlined, 'comunidad', 'personas'),
    _DashboardItem('Equipo', Icons.workspace_premium_outlined, 'equipo', 'equipo'),
    _DashboardItem('Catequistas', Icons.school_outlined, 'catequista', 'catequistas'),
    _DashboardItem('Grupos', Icons.diversity_3_outlined, 'grupos', 'grupos'),
    _DashboardItem('Signos', Icons.volunteer_activism_outlined, 'signos', 'signos'),
    _DashboardItem('Carismas', Icons.auto_awesome_outlined, 'carismas', 'carismas'),
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _cargar();
  }

  Future<void> _cargar() async {
    final c = await DBHelper.obtenerComunidad();
    final r = await DBHelper.getResumen();
    if (!mounted) return;
    setState(() {
      comunidad = c;
      resumen = r;
    });
  }

  Future<void> _abrir(String ruta) async {
    await Navigator.pushNamed(context, ruta);
    _cargar();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _cabecera() {
    final c = comunidad;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [kRojo, Color(0xFFE53935)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            c == null ? 'Sin comunidad configurada' : 'Comunidad ${c.numero}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (c != null) ...[
            const SizedBox(height: 2),
            Text(
              '${c.tipoParroquia} ${c.parroquia}',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                if (c.pasoActual.isNotEmpty) _pill(Icons.flag_outlined, c.pasoActual),
                _pill(Icons.people_outline, '${resumen['personas'] ?? 0} hermanos'),
                _pill(Icons.favorite_border, '${resumen['matrimonios'] ?? 0} matrimonios'),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _pill(IconData icon, String text) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.white),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    ),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kFondo,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _cargar,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                  child: Row(
                    children: [
                      Hero(
                        tag: 'logo-virgen',
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(50),
                          child: Image.asset('assets/logos/logo-cnc.png', height: 44),
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Camino Neocatecumenal',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(child: _cabecera()),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                sliver: SliverGrid.builder(
                  itemCount: items.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.25,
                  ),
                  itemBuilder: (context, index) {
                    final animation = CurvedAnimation(
                      parent: _controller,
                      curve: Interval(0.08 * index, 1.0, curve: Curves.easeOutBack),
                    );
                    final item = items[index];
                    return FadeTransition(
                      opacity: _controller,
                      child: ScaleTransition(
                        scale: animation,
                        child: _DashboardCard(
                          item: item,
                          total: resumen[item.clave],
                          onTap: () => _abrir(item.route),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardItem {
  final String title;
  final IconData icon;
  final String route;
  final String clave; // clave en DBHelper.getResumen()

  const _DashboardItem(this.title, this.icon, this.route, this.clave);
}

class _DashboardCard extends StatelessWidget {
  final _DashboardItem item;
  final int? total;
  final VoidCallback onTap;

  const _DashboardCard({required this.item, required this.total, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: kRojo.withValues(alpha: 0.1),
                    child: Icon(item.icon, color: kRojo),
                  ),
                  const Spacer(),
                  Text(
                    '${total ?? '–'}',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                item.title,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
