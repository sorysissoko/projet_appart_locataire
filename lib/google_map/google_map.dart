import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class GoogleMapPage extends StatefulWidget {
  const GoogleMapPage({super.key});

  @override
  State<GoogleMapPage> createState() => _GoogleMapPageState();
}

class _GoogleMapPageState extends State<GoogleMapPage> {
  GoogleMapController? _mapController;

  final CameraPosition _initialPosition = const CameraPosition(
    target: LatLng(12.6392, -8.0029), // 🔹 Bamako par exemple
    zoom: 12.0,
  );

  int _currentIndex = 4;

  @override
  void dispose() {
    _mapController?.dispose(); // 🔹 libère la carte quand on quitte
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 🧭 AppBar personnalisé
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(70.h),
        child: Container(
          decoration: BoxDecoration(
            color: Color(0xD31111E3),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(35),
              bottomRight: Radius.circular(35),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                offset: const Offset(0, 4),
                blurRadius: 6,
              ),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.only(top: 20.w, bottom: 20.h),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Titre centré
                  Text(
                    "Google Maps",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22.sp,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),

      // 🔹 Navbar style Figma
      bottomNavigationBar: BottomAppBar(
        height: 90.w,
        color: const Color(0x56BCBCBC),
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: SizedBox(
          height: 80.h,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // 🔹 Accueil
              GestureDetector(
                onTap: () {
                  setState(() => _currentIndex = 0);
                  Navigator.pushNamed(context, '/appartement');
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _currentIndex == 0 ? Icons.home_rounded : Icons.home_outlined,
                      color: const Color(0xFF0000FF),
                      size: 30.sp,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      "Accueil",
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: const Color(0xFF0000FF),
                        fontWeight: _currentIndex == 0 ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),

              // 🔹 Favoris
              GestureDetector(
                onTap: () => setState(() => _currentIndex = 1),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _currentIndex == 1 ? Icons.favorite : Icons.favorite_border,
                      color: const Color(0xFF0000FF),
                      size: 30.sp,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      "Favoris",
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: const Color(0xFF0000FF),
                        fontWeight: _currentIndex == 1 ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 60), // espace pour le FloatingActionButton central

              // 🔹 Messages
              GestureDetector(
                onTap: () => setState(() => _currentIndex = 2),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _currentIndex == 2 ? Icons.message_rounded : Icons.message_outlined,
                      color: const Color(0xFF0000FF),
                      size: 30.sp,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      "Messages",
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: const Color(0xFF0000FF),
                        fontWeight: _currentIndex == 2 ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),

              // 🔹 Profil
              GestureDetector(
                onTap: (){
                  setState(() => _currentIndex = 3);
                  Navigator.pushNamed(context, '/parametres');
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _currentIndex == 3 ? Icons.person : Icons.person_outline_outlined,
                      color: const Color(0xFF0000FF),
                      size: 30.sp,
                    ),
                    SizedBox(height: 4.h),

                    Text(
                      "Profil",
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: const Color(0xFF0000FF),
                        fontWeight: _currentIndex == 3 ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      // 🔹 Bouton central (Map)
      floatingActionButton: SizedBox(
        width: 70.w,
        height: 70.h,
        child: RawMaterialButton(
          onPressed: () {
            Navigator.pushNamed(context, '/google_map'); // si tu veux naviguer vers une page
          },
          fillColor: const Color(0xFF0000FF),
          shape: const CircleBorder(),
          elevation: 6,
          child: Icon(
            _currentIndex == 4 ? Icons.map_rounded : Icons.map_outlined,
            color: Colors.white,
            size: 38.sp,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,


    // 🗺️ Corps de la page : Google Map
      body: GoogleMap(
        initialCameraPosition: _initialPosition,
        mapType: MapType.normal,
        myLocationEnabled: true, // localisation de l’utilisateur
        myLocationButtonEnabled: true, // bouton de localisation
        zoomControlsEnabled: false,
        compassEnabled: true,
        onMapCreated: (controller) {
          _mapController = controller; // on garde la référence
        },
      ),
    );
  }
}
