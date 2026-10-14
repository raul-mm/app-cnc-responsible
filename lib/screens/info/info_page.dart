import 'package:app_movil_comunidad/widgets/ui.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class InfoPage extends StatelessWidget {
  const InfoPage({super.key});

  static final _sitioWeb = Uri.parse('https://neocatechumenaleiter.org/');

  Future<void> _abrirSitio(BuildContext context) async {
    final ok = await launchUrl(_sitioWeb, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      toast(context, 'No se pudo abrir el sitio web');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Información',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        backgroundColor: kRojo,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 4,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Hero(
              tag: 'logo-pant',
              child: Image.asset(
                'assets/images/panto.jpg',
                width: 300,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 24),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Esta aplicación es parte del Camino Neocatecumenal. '
                'Desde aquí puedes gestionar tu comunidad, equipos, catequistas, grupos y más.',
                style: TextStyle(fontSize: 14, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: kRojo,
                  side: const BorderSide(color: kRojo),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.language),
                label: const Text('neocatechumenaleiter.org'),
                onPressed: () => _abrirSitio(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
