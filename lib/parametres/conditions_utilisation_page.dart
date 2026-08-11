import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ConditionsPage extends StatelessWidget {
  const ConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Conditions d'utilisation"),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            _buildSectionTitle("📋 Conditions générales"),
            _buildText("""
En utilisant cette application, vous acceptez de respecter les présentes conditions d'utilisation. 
Toute réservation effectuée engage le locataire.
"""),

            _buildSectionTitle("💰 Paiement"),
            _buildText("""
Le paiement peut être effectué à l’avance ou sur place selon les modalités définies par le propriétaire.

Des frais de service peuvent être appliqués par la plateforme.
"""),

            _buildSectionTitle("❌ Annulation et remboursement"),
            _buildText("""
1. Toute réservation est considérée comme ferme.

2. En cas d’annulation :

- Plus de 48h avant l’arrivée : remboursement partiel possible
- Moins de 48h : des frais peuvent être appliqués
- Les jours déjà consommés ne sont pas remboursables

3. L’avance versée peut ne pas être remboursée.

4. En cas de non-présentation (no-show), aucun remboursement ne sera effectué.
"""),

            _buildSectionTitle("🏠 Utilisation du logement"),
            _buildText("""
- Respect du logement et du voisinage
- Interdiction de sous-location
- Interdiction d’activités illégales
- Respect des règles définies par le propriétaire
"""),

            _buildSectionTitle("🔐 Responsabilité"),
            _buildText("""
Le locataire est responsable de tout dommage causé au logement durant son séjour.

Tout dégât pourra entraîner des frais supplémentaires.
"""),

            _buildSectionTitle("📞 Litiges"),
            _buildText("""
La plateforme agit en tant qu’intermédiaire entre le locataire et le propriétaire.

En cas de litige, les deux parties doivent trouver un accord.
"""),

            SizedBox(height: 20.h),

            Center(
              child: Text(
                "Merci d’utiliser notre application 🙏",
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            SizedBox(height: 30.h),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: EdgeInsets.only(top: 16.h, bottom: 8.h),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildText(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14.sp,
        height: 1.5,
        color: Colors.grey[800],
      ),
    );
  }
}