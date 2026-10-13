import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
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
  State<AppartementFilters> createState() =>
      _AppartementFiltersState();
}

class _AppartementFiltersState
    extends State<AppartementFilters> {

  late Future<Map<String, dynamic>?> _profileFuture;

  @override
  void initState() {
    super.initState();

    _profileFuture =
        AuthService().getProfile();
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

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(
      BuildContext context,
      ) {
    final width =
        MediaQuery.sizeOf(context).width;

    final horizontalPadding =
    width >= 900 ? 32.w : 16.w;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        horizontalPadding,
        16.h,
        horizontalPadding,
        8.h,
      ),
      decoration: BoxDecoration(
        color:
        const Color(0xFFFFEFE0),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withValues(alpha: 0.03),
            blurRadius: 4,
            offset:
            const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          // ======================================================
          // SALUTATION + PROFIL
          // ======================================================

          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BONJOUR 👋',
                      maxLines: 1,
                      overflow:
                      TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 12.sp,
                        color:
                        const Color(
                          0xA58A4E1E,
                        ),
                        letterSpacing: 1,
                        fontWeight:
                        FontWeight.w400,
                      ),
                    ),

                    SizedBox(height: 2.h),

                    Text(
                      'Explorez le Mali 🇲🇱',
                      maxLines: 1,
                      overflow:
                      TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 20.sp,
                        fontWeight:
                        FontWeight.bold,
                        color:
                        Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(width: 10.w),

              FutureBuilder<
                  Map<String, dynamic>?>(
                future: _profileFuture,
                builder:
                    (context, snapshot) {
                  if (snapshot
                      .connectionState ==
                      ConnectionState.waiting) {
                    return Container(
                      width: 42.w,
                      height: 42.w,
                      decoration:
                      BoxDecoration(
                        shape:
                        BoxShape.circle,
                        border: Border.all(
                          color:
                          widget.accentColor,
                          width: 2,
                        ),
                      ),
                      child:
                      const Center(
                        child:
                        CircularProgressIndicator(
                          color:
                          Color(
                            0xFFE85D26,
                          ),
                          strokeWidth: 2,
                        ),
                      ),
                    );
                  }

                  final data =
                      snapshot.data;

                  return Container(
                    padding:
                    EdgeInsets.all(2.w),
                    decoration:
                    BoxDecoration(
                      shape:
                      BoxShape.circle,
                      border: Border.all(
                        color:
                        widget.accentColor,
                        width: 2,
                      ),
                    ),
                    child: data == null
                        ? const ProfileAvatar(
                      prenom: '',
                      nom: '',
                    )
                        : ProfileAvatar(
                      prenom:
                      data['prenom']
                          ?.toString() ??
                          '',
                      nom:
                      data['nom']
                          ?.toString() ??
                          '',
                    ),
                  );
                },
              ),
            ],
          ),

          SizedBox(height: 14.h),

          // ======================================================
          // RECHERCHE
          // ======================================================

          Container(
            width: double.infinity,
            constraints:
            const BoxConstraints(
              minHeight: 48,
            ),
            decoration:
            BoxDecoration(
              color:
              const Color(
                0xB3FFFFFF,
              ),
              borderRadius:
              BorderRadius.circular(
                20.r,
              ),
              border: Border.all(
                color:
                const Color(
                  0xfffddbc7,
                ),
              ),
            ),
            child: Row(
              children: [
                SizedBox(width: 14.w),

                Icon(
                  Icons.search,
                  size: 20.sp,
                  color:
                  widget.accentColor,
                ),

                SizedBox(width: 6.w),

                Expanded(
                  child: TextField(
                    onChanged:
                    widget.onSearchChanged,
                    textAlign:
                    TextAlign.left,
                    maxLines: 1,
                    decoration:
                    InputDecoration(
                      hintText:
                      'Rechercher une ville, un logement...',
                      hintStyle:
                      GoogleFonts.poppins(
                        fontSize: 13.sp,
                        color:
                        const Color(
                          0xA58A4E1E,
                        ),
                      ),
                      border:
                      InputBorder.none,
                      contentPadding:
                      EdgeInsets.symmetric(
                        vertical: 12.h,
                      ),
                    ),
                  ),
                ),

                SizedBox(width: 14.w),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ONGLETS
  // ============================================================

  Widget _buildTabs() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      child: SizedBox(
        height: 88.h,
        child: TabBar(
          controller: widget.tabController,
          isScrollable: false,
          labelColor: widget.accentColor,
          unselectedLabelColor: const Color(0xA58A4E1E),
          indicatorColor: widget.accentColor,
          indicatorWeight: 3,
          labelStyle: GoogleFonts.poppins(
            fontSize: 13.sp,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: GoogleFonts.poppins(
            fontSize: 12.sp,
            fontWeight: FontWeight.w500,
          ),
          labelPadding: EdgeInsets.symmetric(
            horizontal: 2.w,
          ),
          tabs: [
            Tab(
              iconMargin: EdgeInsets.only(bottom: 3.h),
              icon: Image.asset(
                'assets/images/appart_tous.png',
                width: 32.w,
                height: 32.h,
                fit: BoxFit.contain,
              ),
              text: 'Tous',
            ),
            Tab(
              iconMargin: EdgeInsets.only(bottom: 3.h),
              icon: Image.asset(
                'assets/images/appartements.png',
                width: 32.w,
                height: 32.h,
                fit: BoxFit.contain,
              ),
              text: 'Appartement',
            ),
            Tab(
              iconMargin: EdgeInsets.only(bottom: 3.h),
              icon: Image.asset(
                'assets/images/maison2.png',
                width: 32.w,
                height: 32.h,
                fit: BoxFit.contain,
              ),
              text: 'Villa',
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // VILLES
  // ============================================================

  Widget _buildCityFilters() {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(
        horizontal: 16.w,
        vertical: 12.h,
      ),
      height: 34.h,
      child: ListView.builder(
        scrollDirection:
        Axis.horizontal,
        itemCount:
        widget.cities.length,
        itemBuilder:
            (context, index) {
          final city =
          widget.cities[index];

          final isSelected =
              widget.selectedCity ==
                  city;

          return Padding(
            padding:
            EdgeInsets.only(
              right: 10.w,
            ),
            child: GestureDetector(
              onTap: () =>
                  widget.onCityChanged(
                    city,
                  ),
              child: Container(
                padding:
                EdgeInsets.symmetric(
                  horizontal: 16.w,
                  vertical: 4.h,
                ),
                decoration:
                BoxDecoration(
                  color: isSelected
                      ? widget.accentColor
                      : widget.accentColor
                      .withValues(
                    alpha: 0.1,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    30.r,
                  ),
                ),
                child: Center(
                  child: Text(
                    city,
                    maxLines: 1,
                    style: GoogleFonts.poppins(
                      fontSize: 13.sp,
                      fontWeight:
                      FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : widget
                          .accentColor,
                    ),
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

// ============================================================
// PROFILE AVATAR
// ============================================================

class ProfileAvatar
    extends StatelessWidget {
  final String prenom;
  final String nom;
  final double size;

  const ProfileAvatar({
    super.key,
    required this.prenom,
    required this.nom,
    this.size = 42,
  });

  String getInitials() {
    final p = prenom.trim();
    final n = nom.trim();

    return '${p.isNotEmpty ? p[0] : ''}'
        '${n.isNotEmpty ? n[0] : ''}'
        .toUpperCase();
  }

  @override
  Widget build(
      BuildContext context,
      ) {
    return Container(
      width: size.w,
      height: size.w,
      decoration:
      const BoxDecoration(
        shape: BoxShape.circle,
        gradient:
        LinearGradient(
          colors: [
            Color(0xFFE85D26),
            Color(0xFFFF8A50),
          ],
          begin:
          Alignment.topLeft,
          end:
          Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          prenom.isEmpty &&
              nom.isEmpty
              ? '??'
              : getInitials(),
          style: GoogleFonts.poppins(
            fontSize:
            (size * 0.35).sp,
            fontWeight:
            FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}