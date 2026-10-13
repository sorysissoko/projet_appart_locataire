import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:service/auth_service.dart';

import '../../widgets/parametre_header.dart';

class ConfidentialitePage extends StatefulWidget {
  const ConfidentialitePage({super.key});

  @override
  State<ConfidentialitePage> createState() => _ConfidentialitePageState();
}

class _ConfidentialitePageState extends State<ConfidentialitePage> {
  final AuthService _authService = AuthService();

  // Variables pour les switchs
  bool showCity = true;
  bool showNeighborhood = false;
  bool showCheckIn = true;
  bool showCheckout = true;
  bool shareProfileData = false;
  bool receiveEmails = true;

  /// Widget réutilisable pour un switch avec couleur personnalisée
  Widget _buildSwitchSetting({
    required String title,
    String? subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF8A4E1E),
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: GoogleFonts.poppins(
                      color: Color(0x988A4E1E),
                      fontSize: 14,
                    ),
                  ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: const Color(0xFFE85D26),
            inactiveThumbColor: const Color(0x4AE85D26),
            inactiveTrackColor: const Color(0x80E85D26),
          ),
        ],
      ),
    );
  }

  /// Widget réutilisable pour un item cliquable
  Widget _buildClickableItem({
    required String title,
    required VoidCallback onTap,
  }) {
    final Color accentColor = const Color(0x80E85D26);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: double.infinity,
        height: 50,
        margin: const EdgeInsets.symmetric(vertical: 5, horizontal: 25),
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF2E5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: accentColor),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Color(0xFF8A4E1E),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: const Color(0xFF8A4E1E),
              size: 24.sp,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF2E5),
      body: Stack(
        children: [
          const ParametreHeader(title: "Confidentialité"),
          Padding(
            padding: EdgeInsets.only(
              top: 170.h,
              left: 12.w,
              right: 12.w,
            ),
            child: Column(
              children: [
                // --- Switchs ---
                _buildSwitchSetting(
                  title: "Montrer ma ville et mon pays",
                  subtitle: "Ex: Bamako, Mali",
                  value: showCity,
                  onChanged: (val) => setState(() => showCity = val),
                ),
                _buildSwitchSetting(
                  title: "Montrer mon quartier",
                  subtitle: "Ex: Quartier résidentiel",
                  value: showNeighborhood,
                  onChanged: (val) => setState(() => showNeighborhood = val),
                ),
                _buildSwitchSetting(
                  title: "Montrer mes dates de séjour (check-in)",
                  subtitle: "Ex: 10 janvier 2025",
                  value: showCheckIn,
                  onChanged: (val) => setState(() => showCheckIn = val),
                ),
                _buildSwitchSetting(
                  title: "Montrer mes dates de séjour (checkout)",
                  subtitle: "Ex: 20 janvier 2025",
                  value: showCheckout,
                  onChanged: (val) => setState(() => showCheckout = val),
                ),
                _buildSwitchSetting(
                  title: "Partager mes données de profil avec les partenaires",
                  value: shareProfileData,
                  onChanged: (val) => setState(() => shareProfileData = val),
                ),
                _buildSwitchSetting(
                  title: "Recevoir des e-mails promotionnels",
                  value: receiveEmails,
                  onChanged: (val) => setState(() => receiveEmails = val),
                ),
                const SizedBox(height: 25),
                const Divider(
                  indent: 25,
                  height: 30,
                  thickness: 1,
                  endIndent: 25,
                  color: Color(0x80E85D26),
                ),
                const SizedBox(height: 15),

                // --- Items cliquables ---
                _buildClickableItem(
                  title: "Mes données personnelles",
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Demande de données envoyée ✅"),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 5),
                _buildClickableItem(
                  title: "Supprimer mon compte",
                  onTap: _showDeleteConfirmationDialog,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmationDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFFFFF2E5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        elevation: 8,
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.red.shade600,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                "Supprimer le compte",
                style: GoogleFonts.poppins(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade900,
                  letterSpacing: -0.5,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Cette action est irréversible.",
              style: GoogleFonts.poppins(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              "La suppression de votre compte entraînera :",
              style: GoogleFonts.poppins(
                fontSize: 14.sp,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: 8.h),
            ..._getDeletionConsequences().map(
                  (item) => Padding(
                padding: EdgeInsets.only(bottom: 6.h),
                child: Text(
                  item,
                  style: GoogleFonts.poppins(
                    fontSize: 13.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
            ),
          ],
        ),
        actionsPadding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 20.h),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey.shade700,
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade300),
              ),
            ),
            child: Text(
              "Annuler",
              style: GoogleFonts.poppins(
                fontSize: 15.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          SizedBox(width: 12.w),
          ElevatedButton(
            onPressed: () {
              // Fermer le dialog
              Navigator.of(dialogContext).pop();
              // Lancer la suppression
              _handleAccountDeletion();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              "Confirmer la suppression",
              style: GoogleFonts.poppins(
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _getDeletionConsequences() {
    return [
      "✓ La perte définitive de toutes vos données",
      "✓ La suppression de votre historique",
      "✓ L'impossibilité de récupérer votre compte",
      "✓ La suppression de vos annonces (si propriétaire)",
      "✓ L'annulation de vos réservations en cours",
    ];
  }

  Future<void> _handleAccountDeletion() async {
    // Sauvegarder les références avant l'appel async
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    // Afficher le loader
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                  color: Color(0xFFE85D26),
                  strokeWidth: 2
              ),
              const SizedBox(height: 16),
              Text(
                "Suppression en cours...",
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      // Appeler la méthode de suppression
      await _authService.deleteCurrentUserAccount();

      // Vérifier si le contexte est toujours valide
      if (context.mounted) {
        // Fermer le loader
        navigator.pop();

        // Afficher le message de succès
        messenger.showSnackBar(
          const SnackBar(
            content: Text("Votre compte a été supprimé avec succès"),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );

        // Rediriger vers l'écran de connexion
        navigator.pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (e) {
      // Gérer l'erreur
      if (context.mounted) {
        // Fermer le loader
        navigator.pop();

        // Afficher l'erreur
        messenger.showSnackBar(
          SnackBar(
            content: Text("Erreur lors de la suppression : ${e.toString()}"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }
}