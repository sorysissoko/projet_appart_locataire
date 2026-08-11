import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AccessibilitePage extends StatefulWidget {
  const AccessibilitePage({super.key});

  @override
  State<AccessibilitePage> createState() => _AccessibilitePageState();
}

class _AccessibilitePageState extends State<AccessibilitePage> {
  // Variables pour les switchs
  bool showCity = true;
  bool showNeighborhood = false;
  bool showCheckIn = true;

  /// Widget réutilisable pour un switch avec couleur personnalisée
  Widget _buildSwitchSetting({
    required String title,
    String? subtitle,
    required bool value,
    required Function(bool) onChanged,
    Color activeColor = Colors.blue,
    Color inactiveColor = Colors.grey,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                if (subtitle != null)
                  Text(subtitle,
                      style:
                      const TextStyle(color: Colors.black54, fontSize: 14)),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            //activeColor: Colors.green,      // couleur du "thumb" quand activé
            activeTrackColor: Color(0xFF0000FF), // couleur du track quand activé
            inactiveThumbColor: Color(0xFF000032),     // couleur du "thumb" quand désactivé
            inactiveTrackColor: Color(0x4F0015FF), // couleur du track quand désactivé

          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // --- Contenu défilable ---
          ListView(
            padding: EdgeInsets.only(top: 80.h),
            children: [

              // Titre de la page
              Padding(
                padding: const EdgeInsets.only(top: 30, left: 40),
                child: Text(
                  "Accessibilté",
                  style: TextStyle(
                      fontSize: 25.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87),
                ),
              ),

              //const SizedBox(height: 8),

              // --- Switchs ---
              _buildSwitchSetting(
                title: "Pour les longues listes, un bouton Charger plus s’affiche à la place du défilement automatique.",
                value: showCity,
                onChanged: (val) => setState(() => showCity = val),
                activeColor: Colors.green,
                inactiveColor: Colors.grey,
              ),
              _buildSwitchSetting(
                title: "Afficher les boutons de zoom sur la carte",
                value: showNeighborhood,
                onChanged: (val) => setState(() => showNeighborhood = val),
                activeColor: Colors.green,
                inactiveColor: Colors.grey,
              ),
              _buildSwitchSetting(
                title: "Contrôles directionnels de la carte",
                value: showCheckIn,
                onChanged: (val) => setState(() => showCheckIn = val),
              ),

              const SizedBox(height: 20),
            ],
          ),

          // --- Bouton de retour fixe ---
          Positioned(
            top: 60.h,
            left: 20.w,
            child: InkWell(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 50.w,
                height: 50.w,
                decoration: BoxDecoration(
                  color: const Color(0xFFD9D9D9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back,
                    color: Colors.black, size: 28),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
