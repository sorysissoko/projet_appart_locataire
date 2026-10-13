import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
//import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../widgets/parametre_header.dart';
import '../dialog/update_pwd_dialog.dart';

class ConnexionSecuritePage extends StatefulWidget {
  const ConnexionSecuritePage({super.key});

  @override
  State<ConnexionSecuritePage> createState() =>_ConnexionSecuritePageState();
}

class _ConnexionSecuritePageState
    extends State<ConnexionSecuritePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF2E5),
      body: Stack(
        children: [
          // --- Header personnalisé ---
          const ParametreHeader(title: "Connexion & sécurité"),
          const SizedBox(height: 20),

          // ---- Contenu principal ----
          Padding(
            padding: const EdgeInsets.only(top: 170, left: 16, right: 15),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Section : Nom complet
                  _buildInfoSection(
                    title: "Mot de passe",
                    value: "Dernière mise à jour il y'a...",
                    buttonLabel: "Mettre à jour",
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => const UpdatePwdPageDialog(),
                      );
                    },
                  ),
                  _divider(),

                  // Section : Adresse
                  _buildInfoSection(
                    title: "Désactiver votre compte",
                    value: "Cette action ne peut pas être annulée",
                    buttonLabel: "Désactiver",
                    onTap: () {
                      _showSnack("Compte désactivé");
                    },
                  ),
                ],
              ),
            ),
          ),

        ],
      ),
    );
  }

  // ---- Widget Section avec bouton ----
  Widget _buildInfoSection({
    required String title,
    required String value,
    required String buttonLabel,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Texte à gauche (occupe tout l’espace restant)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                      color: Color (0xFF8A4E1E)
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                      color: Color (0xBE8A4E1E)
                  ),
                ),
              ],
            ),
          ),

          // Bouton à droite
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 130,
              height: 40,
              decoration: BoxDecoration(
                color: Color (0xFFE85D26),
                borderRadius: BorderRadius.circular(20),
              ),
              alignment: Alignment.center,
              child: Text(
                buttonLabel,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  // ---- Divider standard ----
  Widget _divider() {
    return const Divider(
      thickness: 2,
      indent: 20,
      endIndent: 20,
      color: Color(0xFFE0E0E0),
    );
  }

  // ---- SnackBar helper ----
  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.inter()),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
