import 'package:flutter/material.dart';

class InfoPage extends StatelessWidget {
  const InfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Información',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFFC62828),
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 4,
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
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
          Padding(
            padding: EdgeInsets.all(24.0),
            child: Text(
              'Esta aplicación es parte del Camino Neocatecumenal. '
              'Desde aquí puedes gestionar tu comunidad, equipos, catequistas, grupos y más.',
              style: TextStyle(fontSize: 14, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
