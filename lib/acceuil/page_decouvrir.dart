import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

// Définition de la classe Slide si elle n'est pas déjà dans un fichier externe
class OnboardingSlide {
  final String title;
  final String description;
  final String subtitle;
  final String imageAsset;
  final IconData icon;

  OnboardingSlide({
    required this.title,
    required this.description,
    required this.subtitle,
    required this.imageAsset,
    required this.icon,
  });
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int current = 0;
  final PageController _pageController = PageController();

  final List<OnboardingSlide> slides = [
    OnboardingSlide(
      imageAsset: 'assets/images/decouvert.png',
      icon: LucideIcons.home,
      title: 'Découvrir',
      subtitle: 'Explorez le Mali',
      description: 'Découvrez des logements de vacances et de loisirs dans toutes les régions du Mali. Des moments uniques en couple, entre amis ou en famille.',
    ),
    OnboardingSlide(
      imageAsset: 'assets/images/rechercher.png',
      icon: LucideIcons.mapPin,
      title: 'Rechercher',
      subtitle: 'Trouvez facilement',
      description: 'Trouvez le logement parfait en un clic, partout au Mali. Filtrez par ville, prix, équipements et bien plus encore.',
    ),
    OnboardingSlide(
      imageAsset: 'assets/images/paiement.png',
      icon: LucideIcons.shield,
      title: 'Paiement sécurisé',
      subtitle: 'En toute confiance',
      description: 'Réservez le logement qui vous convient en toute sécurité grâce à notre système de paiement mobile et carte bancaire.',
    ),
  ];


  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void next() {
    if (current < slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  void goBack() {
    if (current > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final slide = slides[current];

    return Scaffold(
      backgroundColor: const Color(0xFFFFEFE0),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header avec Ignorer à gauche et indicateurs au centre
            Padding(
              padding: const EdgeInsets.only(left: 24, right: 24, top: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/home2');
                    },
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Ignorer',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF8A4E1E),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(
                      slides.length,
                          (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: i == current ? 24 : 8,
                        height: 6,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(3),
                          color: i == current
                              ? const Color(0xFFE85D26)
                              : const Color(0xFFFDDBC7),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),

            // Zone image
            Expanded(
              flex: 2,
              child: Center(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      current = index;
                    });
                  },
                  children: slides.map((s) {
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final imageSize =
                        (constraints.maxHeight * 0.65).clamp(160.0, 280.0);

                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: imageSize,
                              height: imageSize,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFEFE6).withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: Image.asset(
                                  s.imageAsset,
                                  fit: BoxFit.contain,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Icon(
                                      s.icon,
                                      size: 80,
                                      color: const Color(0xFFE85D26)
                                          .withValues(alpha: 0.5),
                                    );
                                  },
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFDDBC7),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    s.icon,
                                    size: 16,
                                    color: const Color(0xFFE85D26),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    s.subtitle,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFE85D26),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  }).toList(),
                ),
              ),
            ),

            // Zone texte et boutons
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 1200),

                    layoutBuilder: (currentChild, previousChildren) {
                      return ClipRect(
                        child: currentChild ??
                            const SizedBox.shrink(), // n'affiche que le nouveau
                      );
                    },

                    transitionBuilder: (child, animation) {
                      final slide = Tween<Offset>(
                        begin: const Offset(0, 0.35),
                        end: Offset.zero,
                      ).animate(
                        CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        ),
                      );

                      return ClipRect(
                        child: FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: slide,
                            child: child,
                          ),
                        ),
                      );
                    },

                    child: Column(
                      key: ValueKey(current),
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          slide.title,
                          style: const TextStyle(
                            fontSize: 35,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            color: Color(0xFF18181B),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          slide.description,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.7,
                            color: Color(0xE58A4E1E),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Zone des boutons animée
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: current == slides.length - 1
                    // ================= DERNIÈRE PAGE : BOUTON COMMENCER =================
                        ? Center(
                      key: const ValueKey("start_button"),
                      child: _PrimaryActionButton(
                        label: "Commencer",
                        icon: LucideIcons.play,
                        onTap: () {
                          Navigator.pushReplacementNamed(context, "/home2");
                        },
                      ),
                    )
                    // ================= AUTRES PAGES : BOUTON SUIVANT & RETOUR =================
                        : Row(
                      key: const ValueKey("navigation"),
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (current > 0)
                          TextButton(
                            onPressed: goBack,
                            child: const Text(
                              "Retour",
                              style: TextStyle(
                                color: Color(0xFF8A4E1E),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        else
                          const SizedBox(width: 60),

                        _AnimatedGradientButton(
                          label: "Suivant",
                          icon: LucideIcons.arrowRight,
                          onTap: next,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// =========================================================================
/// 1. BOUTON "SUIVANT" AVEC ANIMATION TACTILE & SCALE
/// =========================================================================
class _AnimatedGradientButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _AnimatedGradientButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_AnimatedGradientButton> createState() => _AnimatedGradientButtonState();
}

class _AnimatedGradientButtonState extends State<_AnimatedGradientButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;


  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.93).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) => _controller.forward();
  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap();
  }
  void _onTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnimation.value,
          child: child,
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
          decoration: BoxDecoration(
            color: Color(0xFFE85D26),
            borderRadius: BorderRadius.circular(40),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE85D26).withValues(alpha: 0.35),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(width: 8),
              Icon(widget.icon, color: Colors.white, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}

/// =========================================================================
/// BOUTON "COMMENCER" AVEC EFFET DE BALAYAGE LUMINEUX (SHIMMER) SUR LE TEXTE
/// =========================================================================
class _PrimaryActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _PrimaryActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_PrimaryActionButton> createState() => _PrimaryActionButtonState();
}

class _PrimaryActionButtonState extends State<_PrimaryActionButton>
    with TickerProviderStateMixin {
  late AnimationController _pressController;
  late AnimationController _pulseController;
  late AnimationController _shimmerController;

  late Animation<double> _scalePressAnimation;
  late Animation<double> _glowPulseAnimation;
  late Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();

    // 1. Animation au Clic (Pression)
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scalePressAnimation = Tween<double>(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );

    // 2. Animation de Pulsation de l'ombre (Glow)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    )..repeat(reverse: true);

    _glowPulseAnimation = Tween<double>(begin: 0.3, end: 0.65).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // 3. Animation du passage du reflet lumineux sur le texte
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  // --- Gestionnaires de clics corrigés ---
  void _onTapDown(TapDownDetails details) => _pressController.forward();

  void _onTapUp(TapUpDetails details) {
    _pressController.reverse();
    widget.onTap();
  }

  void _onTapCancel() => _pressController.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _scalePressAnimation,
          _glowPulseAnimation,
          _shimmerAnimation,
        ]),
        builder: (context, child) {
          return Transform.scale(
            scale: _scalePressAnimation.value,
            child: Container(
              decoration: BoxDecoration(
                color: Color(0xFFE85D26),
                borderRadius: BorderRadius.circular(40),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE85D26)
                        .withValues(alpha: _glowPulseAnimation.value),
                    blurRadius: 22,
                    spreadRadius: 2,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 55,
                  vertical: 17,
                ),
                child: ShaderMask(
                  shaderCallback: (bounds) {
                    final double val = _shimmerAnimation.value;
                    return LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: const [
                        Colors.white,
                        Colors.white,
                        Color(0xFFFFEEAA), // Éclat doré sur le texte
                        Colors.white,
                        Colors.white,
                      ],
                      stops: [
                        (val - 0.4).clamp(0.0, 1.0),
                        (val - 0.1).clamp(0.0, 1.0),
                        val.clamp(0.0, 1.0),
                        (val + 0.1).clamp(0.0, 1.0),
                        (val + 0.4).clamp(0.0, 1.0),
                      ],
                    ).createShader(bounds);
                  },
                  blendMode: BlendMode.srcIn,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Icon(widget.icon, color: Colors.white, size: 22),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}