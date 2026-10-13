import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class Home2Page extends StatefulWidget {
  const Home2Page({super.key});

  @override
  State<Home2Page> createState() => _Home2PageState();
}

class _Home2PageState extends State<Home2Page>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  late Animation<double> _fadeAnimation1;
  late Animation<double> _fadeAnimation2;

  late Animation<Offset> _slideAnimation1;
  late Animation<Offset> _slideAnimation2;

  late PageController _pageController;

  int _currentPage = 0;
  late Timer _timer;

  // IMAGES DU CAROUSEL
  final List<String> _carouselImages = [
    'assets/images/bamako.jpg',
    'assets/images/kayes.jpg',
    'assets/images/koulikoro.jpg',
    'assets/images/segou.jpg',
  ];

  // INIT
  @override
  void initState() {
    super.initState();

    _pageController = PageController();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation1 = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    _fadeAnimation2 = CurvedAnimation(
      parent: _controller,
      curve: const Interval(
        0.2,
        1.0,
        curve: Curves.easeOut,
      ),
    );

    _slideAnimation1 = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    _slideAnimation2 = Tween<Offset>(
      begin: const Offset(0, 0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          0.2,
          1.0,
          curve: Curves.easeOut,
        ),
      ),
    );

    _controller.forward();

    _startAutoScroll();
  }

  // AUTO SCROLL
  void _startAutoScroll() {
    _timer = Timer.periodic(
      const Duration(seconds: 4),
          (Timer timer) {
        if (!_pageController.hasClients) return;

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
      },
    );
  }

  // DISPOSE
  @override
  void dispose() {
    _timer.cancel();
    _pageController.dispose();
    _controller.dispose();

    super.dispose();
  }

  // BUILD
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFFFEFE0),
      body: SafeArea(
        child: Column(
          children: [
            // HERO
            SizedBox(
              height: screenHeight * 0.52,
              child: Stack(
                children: [
                  _buildCarousel(),
                  _buildGradient(),
                  _buildLogo(),
                  _buildPageIndicator(),
                ],
              ),
            ),

            // CONTENU
            Expanded(
              child: Container(
                width: double.infinity,
                color: const Color(0xFFFFEFE0),
                padding: EdgeInsets.symmetric(
                  horizontal: 24.w,
                  vertical: 8.h,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildWelcomeSection(),
                    _buildButtonsSection(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // CAROUSEL
  Widget _buildCarousel() {
    return PageView.builder(
      controller: _pageController,
      itemCount: _carouselImages.length,
      onPageChanged: (int page) {
        if (!mounted) return;

        setState(() {
          _currentPage = page;
        });
      },
      itemBuilder: (context, index) {
        return Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              _carouselImages[index],
              fit: BoxFit.cover,
              errorBuilder: (
                  BuildContext context,
                  Object error,
                  StackTrace? stackTrace,
                  ) {
                return Container(
                  color: Colors.grey.shade300,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.error_outline,
                    size: 50.sp,
                    color: Colors.grey,
                  ),
                );
              },
            ),

            // Titre
            Positioned(
              left: 20.w,
              right: 20.w,
              bottom: 80.h,
              child: Text(
                _getImageTitle(index),
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                  shadows: const [
                    Shadow(
                      offset: Offset(2, 2),
                      blurRadius: 4,
                      color: Colors.black26,
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // GRADIENT
  Widget _buildGradient() {
    return IgnorePointer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0x1AE85D26),
              Color(0xF7FFF8F2),
            ],
            stops: [
              0.0,
              1.0,
            ],
          ),
        ),
      ),
    );
  }

  // LOGO
  Widget _buildLogo() {
    return Positioned(
      top: 20.h,
      left: 0,
      right: 0,
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 16.w,
            vertical: 8.h,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'DS',
                  style: GoogleFonts.carterOne(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFFE85D26),
                    letterSpacing: 2,
                  ),
                ),
                TextSpan(
                  text: 'APPARTS',
                  style: GoogleFonts.righteous(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.w,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // INDICATEUR
  Widget _buildPageIndicator() {
    return Positioned(
      bottom: 18.h,
      left: 0,
      right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(
          _carouselImages.length,
              (index) {
            final bool active = _currentPage == index;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: EdgeInsets.symmetric(
                horizontal: 4.w,
              ),
              width: active ? 24.w : 8.w,
              height: 8.h,
              decoration: BoxDecoration(
                color: active
                    ? const Color(0xFFE85D26)
                    : Colors.white.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(4.r),
              ),
            );
          },
        ),
      ),
    );
  }

  // BIENVENUE
  Widget _buildWelcomeSection() {
    return FadeTransition(
      opacity: _fadeAnimation1,
      child: SlideTransition(
        position: _slideAnimation1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🏠 Bienvenue au Mali !',
              style: GoogleFonts.poppins(
                fontSize: 25.sp,
                fontWeight: FontWeight.w800,
                height: 1.3,
                color: Colors.black87,
              ),
            ),

            SizedBox(height: 8.h),

            Text(
              'Nous vous proposons des lieux de vacances et de loisirs '
                  'dans toutes les localités du Mali pour des moments de '
                  'détente en couple, entre amis ou en famille.',
              style: GoogleFonts.poppins(
                fontSize: 13.5.sp,
                height: 1.7,
                color: const Color(0xE58A4E1E),
              ),
            ),

            SizedBox(height: 14.h),

            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
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
    );
  }

  // CHIP VILLE
  Widget _buildCityChip(String city) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 12.w,
        vertical: 6.h,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFDDBC7),
        borderRadius: BorderRadius.circular(40.r),
      ),
      child: Text(
        city,
        style: GoogleFonts.poppins(
          fontSize: 12.sp,
          fontWeight: FontWeight.w500,
          color: const Color(0xFFE85D26),
        ),
      ),
    );
  }

  // BOUTONS
  Widget _buildButtonsSection() {
    return FadeTransition(
      opacity: _fadeAnimation2,
      child: SlideTransition(
        position: _slideAnimation2,
        child: Column(
          children: [
            // INSCRIPTION
            SizedBox(
              width: double.infinity,
              height: 54.h,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40.r),
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFE85D26),
                      Color(0xFFF5A623),
                    ],
                  ),
                ),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      '/register',
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(40.r),
                    ),
                  ),
                  child: Text(
                    'Inscrivez-vous',
                    style: GoogleFonts.poppins(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),

            SizedBox(height: 10.h),

            // CONNEXION
            SizedBox(
              width: double.infinity,
              height: 54.h,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/connexion',
                  );
                },
                style: OutlinedButton.styleFrom(
                  backgroundColor: const Color(0xB3FFFFFF),
                  foregroundColor: const Color(0xFFE85D26),
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(40.r),
                  ),
                  side: const BorderSide(
                    color: Color(0xFFFDDBC7),
                    width: 1,
                  ),
                ),
                child: Text(
                  'Connectez-vous',
                  style: GoogleFonts.poppins(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFFE85D26),
                  ),
                ),
              ),
            ),

            SizedBox(height: 5.h),
          ],
        ),
      ),
    );
  }

  // TITRE IMAGE
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
}
