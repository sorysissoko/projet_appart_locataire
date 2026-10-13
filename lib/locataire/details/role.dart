import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class RulesModal extends StatelessWidget {
  final Map<String, dynamic>? appartementRole;
  final Map<String, dynamic> appartement;

  const RulesModal({
    super.key,
    required this.appartementRole,
    required this.appartement,
  });

  // Helper function to check if value contains "accept"
  bool _containsAccept(dynamic value) {
    if (value == null) return false;
    if (value is String) {
      return value.toLowerCase().contains('accept');
    }
    return false;
  }

  String _getTimeDisplay(String? time) {
    if (time == null || time.isEmpty) return '12:00';
    if (time.contains(':')) return time;
    return '$time:00';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
          color: Color(0xFFFFEFE0),
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Poignée pour drag
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: Text(
              'Règles de l\'appartement',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: const Color(0xF11F2937),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                const SizedBox(height: 5),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  child: Text(
                    '${appartement['description'] ?? 'Pas de description disponible'}',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                        color: Color(0xE58A4E1E),
                    ),
                  ),
                ),
                const SizedBox(height:10),
                // Séparateur
                Divider(height: 20.h,
                  color: const Color(0xFF8A4E1E),
                  indent: 10,
                  endIndent: 10,
                  thickness: 1,
                ),
                // Section Arrivée et départ
                _buildSectionHeader('Arrivée et départ'),
                Container(
                  margin: const EdgeInsets.only(bottom:5),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Ligne Arrivée
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Image.asset(
                              'assets/images/lhorloge_1.png',
                              width: 30,
                              height: 30,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Text(
                                'Arrivée : ${_getTimeDisplay(appartementRole?['heure_arrive'])}',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xE58A4E1E),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Image.asset(
                            'assets/images/lhorloge_1.png',
                            width: 30,
                            height: 30,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Text(
                              'Départ: Avant ${_getTimeDisplay(appartementRole?['heure_depart'])}',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Color(0xE58A4E1E),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 5),
                // Séparateur
                Divider(height: 20.h,
                  color: const Color(0xFF8A4E1E),
                  indent: 10,
                  endIndent: 10,
                  thickness: 1,
                ),
                // Section Durant votre séjour
                _buildSectionHeader('Durant votre séjour'),
                Container(
                  margin: const EdgeInsets.only(bottom:5),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      //Nombre de clients
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Image.asset(
                              'assets/images/equipe.png',
                              width: 30,
                              height: 30,
                              fit: BoxFit.contain,
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Text(
                                '${appartementRole?['nombre_client'] ?? 0} clients maximum',
                                style: GoogleFonts.poppins(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xE58A4E1E),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 5),

                      //Fêtes
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Image.asset(
                            _containsAccept(appartementRole?['fete'])
                                ? 'assets/images/celebration.png'
                                : 'assets/images/pas_de_fete.png',
                            width: 30,
                            height: 30,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Text(
                              _containsAccept(appartementRole?['fete'])
                                  ? 'Fêtes acceptées'
                                  : 'Pas de fêtes',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Color(0xE58A4E1E),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),

                      //Animaux
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Image.asset(
                            _containsAccept(appartementRole?['animaux'])
                                ? 'assets/images/pattes.png'
                                : 'assets/images/pas_danimaux.png',
                            width: 30,
                            height: 30,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Text(
                              _containsAccept(appartementRole?['animaux'])
                                  ? 'Animaux acceptés'
                                  : 'Pas d\'animaux',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Color(0xE58A4E1E),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Séparateur
                Divider(height: 20.h,
                  color: const Color(0xFF8A4E1E),
                  indent: 10,
                  endIndent: 10,
                  thickness: 1,
                ),
                // Règles supplémentaires
                _buildSectionHeader('Règles supplémentaires'),
                Container(
                  margin: const EdgeInsets.only(bottom:5),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildRuleRow('assets/images/lune.png', 'Respect du voisinage après 22h'),
                      const SizedBox(height: 10),
                      _buildRuleRow('assets/images/proprete.png', 'Merci de laisser l\'appartement propre comme vous l\'avez trouvé'),
                      const SizedBox(height: 10),
                      _buildRuleRow('assets/images/cle.png', 'Les clés doivent être remises à notre agent au départ'),
                      const SizedBox(height: 10),
                      _buildRuleRow('assets/images/cles.png', 'Verrouillez toujours la porte en partant'),
                      const SizedBox(height: 10),
                      _buildRuleRow('assets/images/pas_son.png', 'Évitez les bruits excessifs, surtout la nuit'),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 15, left: 15, bottom: 10),
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Color(0xF11F2937),
        ),
      ),
    );
  }

  Widget _buildRuleRow(String iconPath, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Image.asset(
          iconPath,
          width: 30,
          height: 30,
          fit: BoxFit.contain,
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Color(0xE58A4E1E),
            ),
          ),
        ),
      ],
    );
  }
}

// Fonction pour afficher la modale
void showRulesModal({
  required BuildContext context,
  required Map<String, dynamic>? appartementRole,
  required Map<String, dynamic> appartement,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
    ),
    builder: (context) {
      return DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            ),
            child: RulesModal(
              appartementRole: appartementRole,
              appartement: appartement,
            ),
          );
        },
      );
    },
  );
}