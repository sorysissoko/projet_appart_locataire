import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:service/auth_service.dart';

class AppartementFilters extends StatefulWidget {
  final TabController tabController;
  final String selectedCity;
  final List<String> cities;
  final Color accentColor;
  final Function(String) onCityChanged;
  final Function(String) onSearchChanged;

  const AppartementFilters({
    super.key,
    required this.tabController,
    required this.selectedCity,
    required this.cities,
    required this.accentColor,
    required this.onCityChanged,
    required this.onSearchChanged,
  });

  @override
  State<AppartementFilters> createState() => _AppartementFiltersState();
}

class _AppartementFiltersState extends State<AppartementFilters> {
  late Future<Map<String, dynamic>?> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = AuthService().getProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildHeader(context),
        _buildTabs(),
        _buildCityFilters(),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEFE0),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("BONJOUR 👋", style: TextStyle(fontSize: 12.sp, color: const Color(0xA58A4E1E), letterSpacing: 1, fontWeight: FontWeight.w400)),
                  Text("Explorez le Mali 🇲🇱", style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: Colors.black87)),
                ],
              ),
              FutureBuilder<Map<String, dynamic>?>(
                future: _profileFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container(
                      width: 40.w, height: 40.h,
                      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: widget.accentColor, width: 2)),
                      child: const Center(child: CircularProgressIndicator(
                          color: Color(0xFFE85D26),
                          strokeWidth: 2
                      )),
                    );
                  }
                  final data = snapshot.data;
                  return Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: widget.accentColor, width: 2)),
                    child: data == null
                        ? const ProfileAvatar(prenom: "", nom: "")
                        : ProfileAvatar(prenom: data['prenom'] ?? '', nom: data['nom'] ?? ''),
                  );
                },
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xB3FFFFFF),
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: const Color(0xfffddbc7), width: 1),
            ),
            child: Row(
              children: [
                SizedBox(width: 16.w),
                Icon(Icons.search, size: 20.sp, color: widget.accentColor),
                Expanded(
                  child: TextField(
                    textAlign: TextAlign.center,
                    onChanged: widget.onSearchChanged,
                    decoration: InputDecoration(
                      hintText: "Rechercher une ville, un logement...",
                      hintStyle: TextStyle(fontSize: 14.sp, color: const Color(0xA58A4E1E)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                  ),
                ),
                SizedBox(width: 44.w),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Center(
      child: SizedBox(
        width: 320.w,
        child: TabBar(
          controller: widget.tabController,
          isScrollable: false,
          labelColor: widget.accentColor,
          unselectedLabelColor: const Color(0xA58A4E1E),
          indicatorColor: widget.accentColor,
          indicatorWeight: 3,
          labelStyle: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold),
          unselectedLabelStyle: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500),
          tabs: [
            Tab(icon: Image.asset('assets/images/appart_tous.png', width: 40, height: 40), text: 'Tous'),
            Tab(icon: Image.asset('assets/images/appartements.png', width: 40, height: 40), text: 'Appartement'),
            Tab(icon: Image.asset('assets/images/maison2.png', width: 40, height: 40), text: 'Villa'),
          ],
        ),
      ),
    );
  }

  Widget _buildCityFilters() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      height: 32.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: widget.cities.length,
        itemBuilder: (context, index) {
          final city = widget.cities[index];
          final isSelected = widget.selectedCity == city;
          return Padding(
            padding: EdgeInsets.only(right: 10.w),
            child: GestureDetector(
              onTap: () => widget.onCityChanged(city),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: isSelected ? widget.accentColor : widget.accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(30.r),
                ),
                child: Center(
                  child: Text(
                    city,
                    style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : widget.accentColor),
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

// Profil Avatar requis par le widget ci-dessus
class ProfileAvatar extends StatelessWidget {
  final String prenom;
  final String nom;
  final double size;

  const ProfileAvatar({super.key, required this.prenom, required this.nom, this.size = 42});

  String getInitials() {
    final p = prenom.trim();
    final n = nom.trim();
    return "${p.isNotEmpty ? p[0] : ''}${n.isNotEmpty ? n[0] : ''}".toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size.w,
      height: size.h,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFFE85D26), Color(0xFFFF8A50)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 6, offset: const Offset(0, 3))],
      ),
      child: Center(
        child: Text(
          (prenom.isEmpty && nom.isEmpty) ? "??" : getInitials(),
          style: TextStyle(fontSize: (size * 0.35).sp, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5),
        ),
      ),
    );
  }
}