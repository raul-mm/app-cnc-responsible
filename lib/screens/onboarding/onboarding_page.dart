import 'package:flutter/material.dart';
import 'package:app_movil_comunidad/screens/preferencias_usuario.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingContent> _items = [
    _OnboardingContent(
      image: 'assets/images/panto.jpg',
      title: '¡Bienvenido!',
      description:
          'Esta app te ayudará a gestionar la lista de hermanos de comunidad, crear grupos, carismas, llevar la relación de signos, entre otros.',
    ),
    _OnboardingContent(
      image: 'assets/images/sagrada-familia.jpg',
      title: 'Formar comunidad',
      description:
          'Forma tu comunidad y camina junto a otros\nsiguiendo la voluntad del Señor.',
    ),
    _OnboardingContent(
      image: 'assets/images/cristo-comu.jpg',
      title: 'Comenzar el camino',
      description:
          'Comienza tu peregrinación hacia una vida cristiana madura,\nen humildad, sencillez y alabanza.',
    ),
  ];

  void _finalizarOnboarding() async {
    final prefs = PreferenciasUsuario();
    await prefs.initPrefs();
    prefs.onboardingVisto = true;

    if (mounted) {
      Navigator.pushReplacementNamed(context, 'crearComunidad');
    }
  }

  Widget _buildPage(_OnboardingContent item) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            item.image,
            width: 300,
            fit: BoxFit.cover,
            errorBuilder:
                (_, __, ___) => const Icon(
                  Icons.broken_image,
                  size: 100,
                  color: Colors.red,
                ),
          ),
          const SizedBox(height: 32),
          Text(
            item.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFFC62828),
              fontFamily: 'Merriweather',
            ),
          ),
          const SizedBox(height: 16),
          Text(
            item.description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              fontFamily: 'Merriweather',
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isLastPage = _currentPage == _items.length - 1;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _items.length,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemBuilder: (_, i) => _buildPage(_items[i]),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: Visibility(
              visible: !isLastPage,
              child: TextButton(
                onPressed: _finalizarOnboarding,
                child: const Text(
                  'Omitir',
                  style: TextStyle(
                    color: Color(0xFFC62828),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Row(
            children: [
              // Indicadores
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: List.generate(
                    _items.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 8,
                      width: _currentPage == index ? 24 : 8,
                      decoration: BoxDecoration(
                        color:
                            _currentPage == index
                                ? const Color(0xFFC62828)
                                : Colors.grey[400],
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
              ),

              // Botón con ancho fijo
              SizedBox(
                width: 120,
                height: 40,
                child: ElevatedButton(
                  onPressed:
                      isLastPage
                          ? _finalizarOnboarding
                          : () => _pageController.nextPage(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeInOut,
                          ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC62828),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                  ),
                  child: Text(isLastPage ? 'Comenzar' : 'Siguiente', style: TextStyle(fontSize: 12),),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingContent {
  final String image;
  final String title;
  final String description;

  const _OnboardingContent({
    required this.image,
    required this.title,
    required this.description,
  });
}
