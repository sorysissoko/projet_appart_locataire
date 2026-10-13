import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:service/auth_service.dart';

class VoirProfilePage extends StatelessWidget {
  const VoirProfilePage({super.key});

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F2),
      body: SafeArea(
        child: Stack(
          children: [
            // --- Contenu principal scrollable ---
            ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const SizedBox(height: 70),

                // --- Carte Profil ---
                Center(
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 400),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE85D26),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 25),
                          blurRadius: 6,
                          offset: const Offset(2, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(50),
                          child: Image.asset(
                            "assets/images/utilisateur.png",
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 10),
                        FutureBuilder<Map<String, dynamic>?>(
                          future: AuthService().getProfile(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const CircularProgressIndicator(
                                color: Color(0xFFE85D26),
                              );
                            }

                            if (!snapshot.hasData || snapshot.data == null) {
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Nom Prénom",
                                    style: GoogleFonts.inter(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      color: const Color(0xFFFFFFFF),
                                      letterSpacing: 1.3,
                                    ),
                                  ),

                                  const SizedBox(height: 4),

                                  Text(
                                    "Client",
                                    style: GoogleFonts.inter(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFFACACAC),
                                    ),
                                  ),
                                ],
                              );
                            }

                            final data = snapshot.data!;
                            final fullName = "${data['prenom']} ${data['nom']}";
                            final role = data['role'] ?? "Client";

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Text(
                                  fullName,
                                  style: GoogleFonts.inter(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFFFFFFFF),
                                    letterSpacing: 1.3,
                                  ),
                                ),

                                const SizedBox(height: 4),

                                Text(
                                  role,
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFACACAC),
                                  ),
                                ),

                                const SizedBox(height: 20),
                              ],
                            );
                          },
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: const [
                            _StatItem(label: "Voyages", value: "0"),
                            _StatItem(label: "Revue", value: "0"),
                            _StatItem(label: "Années", value: "1"),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Row(
                  children: [
                    const Icon(Icons.verified_outlined, color: Colors.black),
                    const SizedBox(width: 8),
                    Text(
                      "Identité vérifiée",
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                          color: const Color(0xFF8A4E1E),
                      ),
                    ),
                  ],
                ),

                const Divider(height: 30, thickness: 1),

                Text(
                  "Mes revues",
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF8A4E1E),
                  ),
                ),

                const SizedBox(height: 15),

                Center(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE85D26),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      minimumSize: const Size(200, 45),
                    ),
                    child: Text(
                      "Voir revue",
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFFFFFFF),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // --- Bouton retour fixé en haut ---
            Positioned(
              top: 16,
              left: 16,
              child: InkWell(
                onTap: () => Navigator.pop(context),
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFE5CE),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    size: 20,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );

  }
}

// --- Widget réutilisable pour stats ---
class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    //final theme = Theme.of(context);

    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF858585),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.poppins(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: const Color(0xFFBABABA),
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}
