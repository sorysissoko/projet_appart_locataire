import 'dart:async';
import 'package:flutter/material.dart';

class Home2Page extends StatefulWidget {
  const Home2Page({super.key});

  @override
  State<Home2Page> createState() => _Home2PageState();
}

class _Home2PageState extends State<Home2Page> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation1;
  late Animation<double> _fadeAnimation2;
  late Animation<Offset> _slideAnimation1;
  late Animation<Offset> _slideAnimation2;

  late PageController _pageController;
  int _currentPage = 0;
  late Timer _timer;

  final List<String> _carouselImages = [
    'assets/images/bamako.jpg',
    'assets/images/kayes.jpg',
    'assets/images/koulikoro.jpg',
    'assets/images/segou.jpg',
  ];

  @override
  void initState() {
    super.initState();

    _pageController = PageController();
    _startAutoScroll();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation1 = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _fadeAnimation2 = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    );

    _slideAnimation1 = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _slideAnimation2 = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
    ));

    _controller.forward();
  }

  void _startAutoScroll() {
    _timer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
      if (_pageController.hasClients) {
        if (_currentPage < _carouselImages.length - 1) {
          _currentPage++;
        } else {
          _currentPage = 0;
        }
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _timer.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Hero carousel section
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.52,
            child: Stack(
              children: [
                PageView.builder(
                  controller: _pageController,
                  onPageChanged: (int page) {
                    setState(() {
                      _currentPage = page;
                    });
                  },
                  itemCount: _carouselImages.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        // CORRECTION: Utiliser Image.asset pour les images locales
                        Image.asset(
                          _carouselImages[index],
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[300],
                              child: const Center(
                                child: Icon(Icons.error, size: 50, color: Colors.grey),
                              ),
                            );
                          },
                        ),
                        // Titre sur l'image
                        Positioned(
                          bottom: 80,
                          left: 20,
                          right: 20,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getImageTitle(index),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  shadows: [
                                    Shadow(
                                      offset: Offset(2, 2),
                                      blurRadius: 4,
                                      color: Colors.black26,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
                // Gradient overlay
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0x1AE85D26),
                        Color(0xF7FFF8F2),
                      ],
                      stops: [0.0, 1.0],
                    ),
                  ),
                ),
                // Logo
                Positioned(
                  top: 40,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: RichText(
                        text: TextSpan(
                          children: [
                            const TextSpan(
                              text: 'DS',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                                color: Color(0xFFE85D26),
                              ),
                            ),
                            TextSpan(
                              text: 'APPARTS',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                                color: Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // Dots indicator with animation
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _carouselImages.length,
                          (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? const Color(0xFFE85D26)
                              : Colors.white.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Bottom content
          Expanded(
            child: Container(
              color: Color(0xFFFFEFE0),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  FadeTransition(
                    opacity: _fadeAnimation1,
                    child: SlideTransition(
                      position: _slideAnimation1,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '🏠 Bienvenue au Mali !',
                            style: TextStyle(
                              fontSize: 25,
                              fontWeight: FontWeight.w900,
                              height: 1.3,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Nous vous proposons des lieux de vacances et de loisirs dans toutes les localités du Mali pour des moments de détente en couple, entre amis ou en famille.",
                            style: TextStyle(
                              fontSize: 13.5,
                              height: 1.7,
                              color: Color(0xE58A4E1E),
                            ),
                            textAlign: TextAlign.left,
                          ),
                          const SizedBox(height: 14),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildCityChip('Bamako'),
                              _buildCityChip('Kayes'),
                              _buildCityChip('Koulikoro'),
                              _buildCityChip('Ségou'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  FadeTransition(
                    opacity: _fadeAnimation2,
                    child: SlideTransition(
                      position: _slideAnimation2,
                      child: Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(40),
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFFE85D26),
                                    Color(0xFFF5A623),
                                  ],
                                ),
                              ),
                              child: ElevatedButton(
                                onPressed: () {
                                  Navigator.pushNamed(context, '/register');
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(40),
                                  ),
                                ),
                                child: const Text(
                                  'Inscrivez-vous',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/connexion');
                              },
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Color (0xB3FFFFFF),
                                foregroundColor: const Color(0xFFE85D26),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(40),
                                ),
                                side: const BorderSide(
                                  color: Color(0xFFFDDBC7),
                                  width: 1,
                                ),
                              ),
                              child: const Text(
                                'Connectez-vous',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xffe85d26)
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 80),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getImageTitle(int index) {
    switch (index) {
      case 0:
        return 'Bamako';
      case 1:
        return 'Kayes';
      case 2:
        return 'Koulikoro';
      case 3:
        return 'Ségou';
      default:
        return '';
    }
  }

  Widget _buildCityChip(String city) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFDDBC7),
        borderRadius: BorderRadius.circular(40),
      ),
      child: Text(
        city,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Color(0xFFE85D26),
        ),
      ),
    );
  }
}