import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    Timer(const Duration(seconds: 15), () {
      Navigator.pushReplacementNamed(context, '/onboarding');
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushReplacementNamed(context, '/onboarding'),
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFE85D26),
                Color(0xFFF5A623),
                Color(0xFFE85D26),
              ],
              stops: [0.0, 0.7, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // cercle décor haut droite
              Positioned(
                top: -20,
                right: -90,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                top: -50,
                right: -30,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              // cercle décor bas gauche
              Positioned(
                bottom: -80,
                left: -80,
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              Positioned(
                bottom: -80,
                left: 50,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                ),
              ),

              // contenu
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    // logo box
                    Container(
                      padding: const EdgeInsets.all(30),
                      decoration: BoxDecoration(
                        //color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Image.asset(
                        'assets/images/animations/logo_appart.gif',
                        width: 350,
                        height: 350,
                        fit: BoxFit.contain,
                      ),
                    ),

                    // titre
                    Transform.translate(
                      offset: const Offset(0, -110),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // TITRE
                          RichText(
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: "DS",
                                  style: GoogleFonts.carterOne(
                                    fontSize: 40,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: 2,
                                  ),
                                ),
                                TextSpan(
                                  text: "APPARTS",
                                  style: GoogleFonts.righteous(
                                    fontSize: 36,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFFFFE0A3),
                                    letterSpacing: 2,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 5),

                          // SOUS-TITRE
                          Text(
                            "LOCATION DE LOGEMENTS",
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 12,
                              letterSpacing: 2,
                            ),
                          ),

                          const SizedBox(height: 15),

                          // SLOGAN
                          Text(
                            "Vivez Mali autrement 🌍",
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),

                          const SizedBox(height: 30),

                          // dots animés
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(3, (i) {
                              return AnimatedBuilder(
                                animation: _controller,
                                builder: (context, child) {
                                  double opacity =
                                      (i + 1) * 0.3 - (_controller.value);
                                  opacity = opacity.clamp(0.2, 1);

                                  return Container(
                                    margin:
                                    const EdgeInsets.symmetric(horizontal: 4),
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: opacity),
                                      shape: BoxShape.circle,
                                    ),
                                  );
                                },
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // texte bas
              Positioned(
                bottom: 30,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    "Touchez pour continuer",
                    style: GoogleFonts.poppins(
                      color: Colors.white38,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}