import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:service/database_service.dart';

import 'package:mobile_app/details/appartement_detail_page.dart';
import 'package:mobile_app/favorite_appart/favorites_service.dart';

import '../services/appartement_service.dart';
import '../services/historique_consultation_service.dart';
import '../widgets/appartement_card.dart';
import '../widgets/appartement_filters.dart';
import '../widgets/appartement_sections.dart';
import '../widgets/recent_appartement_section.dart';
import 'all_historique_appartements_page.dart';
import 'all_new_appartements_page.dart';
import 'all_popular_appartements_page.dart';

class AppartementPage extends StatefulWidget {
  const AppartementPage({super.key});

  @override
  State<AppartementPage> createState() => _AppartementPageState();
}

class _AppartementPageState extends State<AppartementPage> with TickerProviderStateMixin {
  late Future<Map<String, dynamic>> _futureAllData;
  late TabController _tabController;
  late Future<List<Map<String, dynamic>>> _futureRecentApps;

  // Filtres
  String _selectedCity = 'Toutes';
  String _selectedType = 'Tous';
  String _searchQuery = '';
  final List<String> _cities = ['Toutes', 'Bamako', 'Kayes', 'Ségou', 'Mopti'];

  List<Map<String, dynamic>> _allApartments = [];
  final Color accentColor = const Color(0xFFE85D26);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _futureAllData = AppartementService().loadAllData();
    _futureRecentApps = HistoriqueConsultationService().getHistorique();
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging && mounted) {
        setState(() {
          switch (_tabController.index) {
            case 0: _selectedType = 'Tous'; break;
            case 1: _selectedType = 'Appart'; break;
            case 2: _selectedType = 'Villa'; break;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // --- Logique de filtrage (gardée ici car propre à la page) ---

  List<Map<String, dynamic>> _filteredApartments() {
    return _allApartments.where((app) {
      if (_selectedCity != 'Toutes') {
        final appCity = (app['ville'] ?? '').toString();
        String normalizedCity = appCity == 'Segou' ? 'Ségou' : appCity;
        if (!normalizedCity.contains(_selectedCity)) return false;
      }
      if (_selectedType != 'Tous') {
        final appType = (app['type'] ?? '').toString();
        if (!appType.toLowerCase().contains(_selectedType.toLowerCase())) return false;
      }
      if (_searchQuery.isNotEmpty) {
        final title = (app['titre'] ?? '').toString().toLowerCase();
        final city = (app['ville'] ?? '').toString().toLowerCase();
        final query = _searchQuery.toLowerCase();
        if (!title.contains(query) && !city.contains(query)) return false;
      }
      return true;
    }).toList();
  }

  List<Map<String, dynamic>> _getPopularApartments() {
    final filtered = _filteredApartments();

    filtered.sort((a, b) {
      final ratingA =
          double.tryParse(a['avg_rating']?.toString() ?? '0') ?? 0.0;

      final ratingB =
          double.tryParse(b['avg_rating']?.toString() ?? '0') ?? 0.0;

      return ratingB.compareTo(ratingA);
    });

    return filtered.take(5).toList();
  }

  List<Map<String, dynamic>> _getRecommendedApartments(
      List<Map<String, dynamic>> popularApps,
      ) {
    final popularIds = popularApps
        .map((app) => app['id']?.toString())
        .whereType<String>()
        .toSet();

    final recommended = _filteredApartments().where((app) {
      final id = app['id']?.toString();

      final rating =
          double.tryParse(app['avg_rating']?.toString() ?? '0') ?? 0.0;

      //Seulement les logements >= 4.0 Et qui ne sont pas déjà dans Les Plus Populaires
      return rating >= 4.0 && !popularIds.contains(id);
    }).toList();

    // 5.0 à 4.0
    recommended.sort((a, b) {
      final ratingA =
          double.tryParse(a['avg_rating']?.toString() ?? '0') ?? 0.0;

      final ratingB =
          double.tryParse(b['avg_rating']?.toString() ?? '0') ?? 0.0;

      return ratingB.compareTo(ratingA);
    });

    return recommended;
  }

  List<Map<String, dynamic>> _getNewApartments() {
    final filtered = _filteredApartments();
    filtered.sort((a, b) {
      final dateA = a['created_at'] != null ? DateTime.tryParse(a['created_at'].toString()) : null;
      final dateB = b['created_at'] != null ? DateTime.tryParse(b['created_at'].toString()) : null;
      if (dateA == null) return 1;
      if (dateB == null) return -1;
      return dateB.compareTo(dateA);
    });
    return filtered.take(5).toList();
  }

  // --- UI et Navigation ---
  void _navigateToDetail(Map<String,dynamic> app) async {

    await HistoriqueConsultationService()
        .ajouterConsultation(app['id'].toString());

    if (!mounted) return;

    setState(() {
      _futureRecentApps =
          HistoriqueConsultationService().getHistorique();
    });


    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AppartementDetailPage(
          appartement: app,
          appartementService: DatabaseService(),
        ),
      ),
    );
  }

  Widget _buildListContent(List<Map<String, dynamic>> apartments) {
    if (apartments.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 30.h),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.home_work_outlined, size: 50.sp, color: Colors.grey.shade300),
              SizedBox(height: 12.h),
              Text(
                "Aucun logement trouvé",
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Column(
        children: apartments.map((app) {
          return Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            // ⚡️ Utilisation du widget AppartementCard en mode "Compact" (horizontal)
            child: AppartementCard(
              app: app,
              isCompact: true,
              onTap: () => _navigateToDetail(app),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 50.sp, color: Colors.red.shade400),
            SizedBox(height: 12.h),
            Text('Erreur de chargement', style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
            SizedBox(height: 16.h),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _futureAllData = AppartementService().loadAllData();
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
              ),
              child: const Text('Réessayer', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Permet au service des favoris d'écouter les changements globaux
    context.watch<FavoritesService>();

    return Scaffold(
      backgroundColor: const Color(0xFFFFEFE0),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            setState(() {
              _futureAllData = AppartementService().loadAllData();
              _futureRecentApps = HistoriqueConsultationService().getHistorique();
            });
            await _futureAllData;
          },
          color: accentColor,
          child: FutureBuilder<Map<String, dynamic>>(
            future: _futureAllData,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(
                    color: Color(0xFFE85D26)
                ),);
              }
              if (snapshot.hasError) return _buildErrorWidget();

              // Récupération et mise en cache locale pour les filtres
              _allApartments = (snapshot.data?['appartements'] as List?)?.cast<Map<String, dynamic>>() ?? [];

              final newApps = _getNewApartments();

              final popularApps = _getPopularApartments();

              final recommendedApps = _getRecommendedApartments(popularApps,);

              return Column(
                children: [
                  // ✅ Widget Filtres (Gère le Header, Tabs, Barre de recherche, Villes)
                  AppartementFilters(
                    tabController: _tabController,
                    selectedCity: _selectedCity,
                    cities: _cities,
                    accentColor: accentColor,
                    onCityChanged: (city) => setState(() => _selectedCity = city),
                    onSearchChanged: (query) => setState(() => _searchQuery = query),
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ✅ Widget Sections (Nouveautés et Populaires)
                          if (newApps.isNotEmpty)
                            AppartementSection(
                              title: "🆕 Nouveautés",
                              apps: newApps,
                              accentColor: accentColor,
                              isNewSection: true,
                              onTapAll: () {

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                    const NouveauxAppartementsPage(),
                                  ),
                                );

                              },
                              onTapCard: _navigateToDetail,
                            ),

                          if (popularApps.isNotEmpty)
                            AppartementSection(
                              title: "⭐ Les Plus Populaires",
                              apps: popularApps,
                              accentColor: accentColor,
                              isNewSection: false,
                              onTapAll: () {

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                    const PopulairesAppartementsPage(),
                                  ),
                                );

                              },
                              onTapCard: _navigateToDetail,
                            ),

                          if (recommendedApps.isNotEmpty) ...[
                            Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 8.h,
                              ),
                              child: Text(
                                "✨ Recommandations",
                                style: TextStyle(
                                  fontSize: 18.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ),

                            _buildListContent(recommendedApps),
                          ],

                          FutureBuilder<List<Map<String, dynamic>>>(
                            future: _futureRecentApps,
                            builder: (context, snapshot) {

                              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                return const SizedBox.shrink();
                              }

                              final recentApps = snapshot.data!;

                              return RecentAppartementSection(
                                apps: recentApps,
                                accentColor: accentColor,

                                onTapAll: () {

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const HistoriqueConsultationsPage(),
                                    ),
                                  );

                                },

                                onTapCard: _navigateToDetail,
                              );
                            },
                          ),
                          SizedBox(height: 80.h), // Espace pour le Floating Action Button
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}