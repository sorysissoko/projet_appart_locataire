import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:service/database_service.dart';

import '../../../details/appartement_detail_page.dart';
import '../../../favorite_appart/favorites_service.dart';
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

class _AppartementPageState extends State<AppartementPage>
    with TickerProviderStateMixin {

  // SERVICES
  final DatabaseService _databaseService = DatabaseService();

  // FUTURES
  late Future<Map<String, dynamic>> _futureAllData;
  late Future<List<Map<String, dynamic>>> _futureRecentApps;
  late TabController _tabController;


  // FILTRES
  String _selectedCity = 'Toutes';
  String _selectedType = 'Tous';
  String _searchQuery = '';

  final List<String> _cities = [
    'Toutes',
    'Bamako',
    'Kayes',
    'Ségou',
    'Mopti',
  ];

  // DONNÉES
  List<Map<String, dynamic>> _allApartments = [];

  //Map appartementId -> disponible ?
  Map<String, bool> _disponibilites = {};

  // COULEURS
  final Color accentColor = const Color(0xFFE85D26);
  static const Color backgroundColor = Color(0xFFFFEFE0);

  // RESPONSIVE
  bool _isSmallPhone(double width) => width < 360;
  bool _isPhone(double width) => width < 600;
  bool _isTablet(double width) => width >= 600 && width < 1000;

  double _horizontalPadding(double width) {
    if (_isSmallPhone(width)) {
      return 12.w;
    }

    if (_isPhone(width)) {
      return 16.w;
    }

    if (_isTablet(width)) {
      return 28.w;
    }

    return 40.w;
  }

  double _maxContentWidth(double width) {
    if (_isPhone(width)) {
      return width;
    }

    if (_isTablet(width)) {
      return 900;
    }

    return 1400;
  }

  double _bottomSpace(double width) {
    if (_isPhone(width)) {
      return 60.h;
    }

    if (_isTablet(width)) {
      return 80.h;
    }

    return 100.h;
  }

  // INITIALISATION

  @override
  void initState() {
    super.initState();

    _tabController = TabController(
      length: 3,
      vsync: this,
    );

    _futureAllData = _loadAllData();

    _futureRecentApps =
        HistoriqueConsultationService().getHistorique();

    _tabController.addListener(_onTabChanged);
  }

  // CHANGEMENT ONGLET

  void _onTabChanged() {
    if (!_tabController.indexIsChanging && mounted) {
      setState(() {
        switch (_tabController.index) {
          case 0:
            _selectedType = 'Tous';
            break;

          case 1:
            _selectedType = 'Appart';
            break;

          case 2:
            _selectedType = 'Villa';
            break;
        }
      });
    }
  }

  //CHARGEMENT COMPLET

  Future<Map<String, dynamic>> _loadAllData() async {
    try {
      debugPrint('Chargement des appartements locataire...');

      //APPARTEMENTS
      final appartements =
      await _databaseService.fetchAppartements();

      debugPrint(
        'TOTAL appartements récupérés par fetchAppartements(): '
            '${appartements.length}',
      );

      for (final app in appartements) {
        debugPrint(
          '${app['titre']} | '
              'ID=${app['id']} | '
              'STATUS="${app['status']}" | '
              'VILLE=${app['ville']}',
        );
      }

      //UNIQUEMENT LES APPARTEMENTS PUBLIÉS

      final appartementsPublies = appartements.where((app) {
        final status =
        (app['status'] ?? '').toString().toLowerCase();
        return status == 'publie';
      }).toList();

      debugPrint(
        '🏠 Appartements publiés trouvés: '
            '${appartementsPublies.length}',
      );

      if (appartementsPublies.isEmpty) {
        return {
          'appartements': <Map<String, dynamic>>[],
        };
      }

      //IDS
      final appartementIds = appartementsPublies
          .map((app) => app['id']?.toString())
          .whereType<String>()
          .toList();

      //PHOTOS
      final photos = await _databaseService
          .fetchPhotosByAppartementIds(appartementIds);

      //ORGANISER LES PHOTOS
      final Map<String, List<Map<String, dynamic>>>
      photosByAppartement = {};

      for (final photo in photos) {
        final appartementId =
        photo['appartement_id']?.toString();

        if (appartementId == null) continue;

        photosByAppartement
            .putIfAbsent(appartementId, () => [])
            .add(photo);
      }

      //CONSTRUCTION DES DONNÉES
      final List<Map<String, dynamic>> result = [];

      for (final appartement in appartementsPublies) {
        final app = Map<String, dynamic>.from(appartement);

        final appartementId = app['id']?.toString();

        if (appartementId != null) {
          //PHOTOS
          final appPhotos =
              photosByAppartement[appartementId] ?? [];

          app['photos'] = appPhotos;

          //URL PHOTOS
          final List<String> photoUrls = [];

          for (final photo in appPhotos) {
            final fileName = photo['fichiername']?.toString();

            if (fileName != null && fileName.isNotEmpty) {
              final url = _databaseService.photoUrl(
                appartementId,
                fileName,
              );
              photoUrls.add(url);
            }
          }

          app['photo_urls'] = photoUrls;

          //NOTES
          try {
            final ratingStats =
            await _databaseService.getRatingStats(appartementId);

            app['avg_rating'] =
                ratingStats['average'] ?? 0.0;
            app['ratings_count'] =
                ratingStats['count'] ?? 0;
          } catch (e) {
            debugPrint(
              'Erreur note appartement $appartementId: $e',
            );
            app['avg_rating'] = 0.0;
            app['ratings_count'] = 0;
          }
        } else {
          app['photos'] = <Map<String, dynamic>>[];
          app['photo_urls'] = <String>[];
          app['avg_rating'] = 0.0;
          app['ratings_count'] = 0;
        }

        result.add(app);
      }

      debugPrint(
        'Appartements locataire chargés: ${result.length}',
      );

    //CHARGER LES RÉSIDENCES POUR AVOIR VILLE/ADRESSE
      final residenceIds = result
          .map((app) => app['residence_id']?.toString())
          .whereType<String>()
          .where((id) => id.isNotEmpty)
          .toSet()
          .toList();

      debugPrint('Résidences à charger : ${residenceIds.length}');

      if (residenceIds.isNotEmpty) {
        try {
          final residencesResponse = await _databaseService.supabase
              .from('residences')
              .select('id, nom, ville, adresse, localisation, description')
              .inFilter('id', residenceIds);

          // Map residenceId residence
          final Map<String, Map<String, dynamic>> residencesById = {};

          for (final r in residencesResponse) {
            final id = r['id']?.toString();
            if (id == null) continue;
            residencesById[id] = Map<String, dynamic>.from(r);
          }

          debugPrint(
            'Résidences chargées : ${residencesById.length}',
          );

          // Attacher chaque résidence à son appartement
          for (final app in result) {
            final residenceId = app['residence_id']?.toString();

            if (residenceId != null &&
                residencesById.containsKey(residenceId)) {
              app['residence'] = residencesById[residenceId];
            }
          }
        } catch (e) {
          debugPrint('Erreur chargement résidences : $e');
        }
      }

      //CHARGER LES DISPONIBILITÉS EN BATCH
      final ids = result
          .map((a) => a['id']?.toString())
          .whereType<String>()
          .toList();

      debugPrint('Chargement dispos pour ${ids.length} apps');

      final dispos = await _databaseService
          .fetchDisponibiliteActuelleBatch(ids);

      debugPrint('Disponibilités : $dispos');

      _disponibilites = dispos;

      if (mounted) {
        setState(() {});
      }

      return {
        'appartements': result,
      };
    } catch (e) {
      debugPrint('❌ Erreur _loadAllData: $e');
      rethrow;
    }
  }

  // RAFRAÎCHISSEMENT

  Future<void> _refreshData() async {
    debugPrint('Actualisation de la page locataire...');

    try {
      final allData = await _loadAllData();

      final newApartments =
          (allData['appartements'] as List?)
              ?.cast<Map<String, dynamic>>() ??
              [];

      final recentApps =
      await HistoriqueConsultationService().getHistorique();

      if (!mounted) return;

      setState(() {
        _allApartments = newApartments;

        _futureAllData = Future.value({
          'appartements': newApartments,
        });

        _futureRecentApps = Future.value(recentApps);
      });

      debugPrint(
        '✅ Actualisation terminée : '
            '${newApartments.length} appartements',
      );
    } catch (e, stackTrace) {
      debugPrint('❌ Erreur pendant actualisation: $e');
      debugPrint('$stackTrace');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Impossible d’actualiser les logements.',
          ),
        ),
      );
    }
  }

  // FILTRAGE

  List<Map<String, dynamic>> _filteredApartments() {
    return _allApartments.where((app) {
      // VILLE
      if (_selectedCity != 'Toutes') {
        final appCity = (app['ville'] ?? '').toString();

        String normalizedCity = appCity;

        if (appCity.toLowerCase() == 'segou') {
          normalizedCity = 'Ségou';
        }

        if (!normalizedCity
            .toLowerCase()
            .contains(_selectedCity.toLowerCase())) {
          return false;
        }
      }

      // TYPE
      if (_selectedType != 'Tous') {
        final appType = (app['type'] ?? '').toString();

        if (!appType
            .toLowerCase()
            .contains(_selectedType.toLowerCase())) {
          return false;
        }
      }

      // RECHERCHE
      if (_searchQuery.isNotEmpty) {
        final title =
        (app['titre'] ?? '').toString().toLowerCase();
        final city =
        (app['ville'] ?? '').toString().toLowerCase();
        final address =
        (app['adresse'] ?? '').toString().toLowerCase();
        final description =
        (app['description'] ?? '').toString().toLowerCase();

        final query = _searchQuery.toLowerCase();

        if (!title.contains(query) &&
            !city.contains(query) &&
            !address.contains(query) &&
            !description.contains(query)) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  // POPULAIRES

  List<Map<String, dynamic>> _getPopularApartments() {
    final filtered = List<Map<String, dynamic>>.from(
      _filteredApartments(),
    );

    filtered.sort((a, b) {
      final ratingA = double.tryParse(
        a['avg_rating']?.toString() ?? '0',
      ) ??
          0.0;

      final ratingB = double.tryParse(
        b['avg_rating']?.toString() ?? '0',
      ) ??
          0.0;

      return ratingB.compareTo(ratingA);
    });

    return filtered.take(5).toList();
  }

  // RECOMMANDATIONS

  List<Map<String, dynamic>> _getRecommendedApartments(
      List<Map<String, dynamic>> popularApps,
      ) {
    final popularIds = popularApps
        .map((app) => app['id']?.toString())
        .whereType<String>()
        .toSet();

    final recommended = _filteredApartments().where((app) {
      final id = app['id']?.toString();

      final rating = double.tryParse(
        app['avg_rating']?.toString() ?? '0',
      ) ??
          0.0;

      return rating >= 4.0 && !popularIds.contains(id);
    }).toList();

    recommended.sort((a, b) {
      final ratingA = double.tryParse(
        a['avg_rating']?.toString() ?? '0',
      ) ??
          0.0;

      final ratingB = double.tryParse(
        b['avg_rating']?.toString() ?? '0',
      ) ??
          0.0;

      return ratingB.compareTo(ratingA);
    });

    return recommended;
  }

  // NOUVEAUTÉS

  List<Map<String, dynamic>> _getNewApartments() {
    final filtered = List<Map<String, dynamic>>.from(
      _filteredApartments(),
    );

    filtered.sort((a, b) {
      final dateA = a['created_at'] != null
          ? DateTime.tryParse(a['created_at'].toString())
          : null;

      final dateB = b['created_at'] != null
          ? DateTime.tryParse(b['created_at'].toString())
          : null;

      if (dateA == null) return 1;
      if (dateB == null) return -1;

      return dateB.compareTo(dateA);
    });

    return filtered.take(5).toList();
  }

  // NAVIGATION DÉTAIL

  Future<void> _navigateToDetail(
      Map<String, dynamic> app,
      ) async {
    final appartementId = app['id']?.toString();

    if (appartementId == null) return;

    await HistoriqueConsultationService()
        .ajouterConsultation(appartementId);

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
          appartementService: _databaseService,
        ),
      ),
    );
  }

  // LISTE

  Widget _buildListContent(
      List<Map<String, dynamic>> apartments,
      double width,
      ) {
    if (apartments.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 30.h),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.home_work_outlined,
                size: 50.sp,
                color: Colors.grey.shade300,
              ),
              SizedBox(height: 12.h),
              Text(
                'Aucun logement trouvé',
                style: GoogleFonts.poppins(
                  fontSize: _isSmallPhone(width) ? 13.sp : 14.sp,
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
      padding: EdgeInsets.symmetric(
        horizontal: _horizontalPadding(width),
      ),
      child: Column(
        children: apartments.map((app) {
          final appId = app['id']?.toString() ?? '';

          return Padding(
            padding: EdgeInsets.only(bottom: 12.h),
            child: AppartementCard(
              app: app,
              isCompact: false,

              // ✅ Statut de dispo
              isDisponible: _disponibilites[appId] ?? false,

              onTap: () => _navigateToDetail(app),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ERREUR

  Widget _buildErrorWidget(double width) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(_horizontalPadding(width)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 50.sp,
                color: Colors.red.shade400,
              ),
              SizedBox(height: 12.h),
              Text(
                'Erreur de chargement',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Impossible de charger les logements.',
                textAlign: TextAlign.center,
                style: GoogleFonts.poppins(
                  fontSize: 13.sp,
                  color: Colors.grey.shade600,
                ),
              ),
              SizedBox(height: 16.h),
              ElevatedButton(
                onPressed: _refreshData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  padding: EdgeInsets.symmetric(
                    horizontal: 24.w,
                    vertical: 12.h,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: Text(
                  'Réessayer',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 14.sp,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }


  // DISPOSE

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }


  // BUILD

  @override
  Widget build(BuildContext context) {
    context.watch<FavoritesService>();

    final mediaQuery = MediaQuery.of(context);
    final width = mediaQuery.size.width;
    final contentWidth = _maxContentWidth(width);

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: RefreshIndicator(
          color: accentColor,
          onRefresh: _refreshData,
          child: FutureBuilder<Map<String, dynamic>>(
            future: _futureAllData,
            builder: (context, snapshot) {

              // CHARGEMENT

              if (snapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFE85D26),
                  ),
                );
              }

              // ERREUR
              if (snapshot.hasError) {
                return _buildErrorWidget(width);
              }

              // DONNÉES
              final loadedApartments =
              (snapshot.data?['appartements'] as List?)
                  ?.cast<Map<String, dynamic>>();

              if (loadedApartments != null &&
                  !identical(_allApartments, loadedApartments)) {
                _allApartments = loadedApartments;
              }

              // SECTIONS
              final newApps = _getNewApartments();
              final popularApps = _getPopularApartments();
              final recommendedApps =
              _getRecommendedApartments(popularApps);

              // CONTENU RESPONSIVE
              return Column(
                children: [
                  AppartementFilters(
                    tabController: _tabController,
                    selectedCity: _selectedCity,
                    cities: _cities,
                    accentColor: accentColor,
                    onCityChanged: (city) {
                      setState(() {
                        _selectedCity = city;
                      });
                    },
                    onSearchChanged: (query) {
                      setState(() {
                        _searchQuery = query;
                      });
                    },
                  ),

                  Expanded(
                    child: SingleChildScrollView(
                      physics:
                      const AlwaysScrollableScrollPhysics(),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: contentWidth,
                          ),
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [

                              // NOUVEAUTÉS

                              if (newApps.isNotEmpty)
                                AppartementSection(
                                  title: '🆕 Nouveautés',
                                  apps: newApps,
                                  accentColor: accentColor,
                                  isNewSection: true,

                                  // ✅ AJOUT
                                  disponibilites: _disponibilites,

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

                              // POPULAIRES

                              if (popularApps.isNotEmpty)
                                AppartementSection(
                                  title: '⭐ Les Plus Populaires',
                                  apps: popularApps,
                                  accentColor: accentColor,
                                  isNewSection: false,

                                  // ✅ AJOUT
                                  disponibilites: _disponibilites,

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

                              // RECOMMANDATIONS
                              if (recommendedApps.isNotEmpty) ...[
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal:
                                    _horizontalPadding(width),
                                    vertical: 8.h,
                                  ),
                                  child: Text(
                                    '✨ Recommandations',
                                    style: GoogleFonts.poppins(
                                      fontSize:
                                      _isSmallPhone(width)
                                          ? 16.sp
                                          : 18.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                                _buildListContent(
                                  recommendedApps,
                                  width,
                                ),
                              ],

                              // HISTORIQUE
                              FutureBuilder<
                                  List<Map<String, dynamic>>>(
                                future: _futureRecentApps,
                                builder: (context, snapshot) {
                                  if (!snapshot.hasData ||
                                      snapshot.data!.isEmpty) {
                                    return const SizedBox.shrink();
                                  }

                                  final recentApps = snapshot.data!;

                                  return RecentAppartementSection(
                                    apps: recentApps,
                                    accentColor: accentColor,

                                    // ✅ AJOUT
                                    disponibilites: _disponibilites,

                                    onTapAll: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                          const HistoriqueConsultationsPage(),
                                        ),
                                      );
                                    },
                                    onTapCard: _navigateToDetail,
                                  );
                                },
                              ),

                              // ESPACE BAS
                              SizedBox(
                                height: _bottomSpace(width),
                              ),
                            ],
                          ),
                        ),
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