import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:service/rating/rating_service.dart';
import 'package:service/database_service.dart';
import 'package:service/snackbar_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../reservation/price_utils.dart' as price_utils;
import '../appartement/acceuil/services/historique_consultation_service.dart';
import '../favorite_appart/favorites_service.dart';

import 'models/date_status.dart';
import 'widgets/header_image.dart';
import 'widgets/status_row.dart';
import 'widgets/rooms_section.dart';
import 'widgets/features_section.dart';
import 'widgets/equipements_section.dart';
import 'widgets/rules_section.dart';
import 'widgets/rating_section.dart';
import 'widgets/location_section.dart';
import 'widgets/bottom_bar.dart';
import 'widgets/skeleton_widgets.dart';
import 'widgets/date_selector_section.dart';

class AppartementDetailPage extends StatefulWidget {
  final Map<String, dynamic> appartement;
  final DatabaseService appartementService;
  final Map<String, dynamic>? cachedData;

  const AppartementDetailPage({
    super.key,
    required this.appartement,
    required this.appartementService,
    this.cachedData,
  });

  @override
  State<AppartementDetailPage> createState() =>
      _AppartementDetailPageState();
}

class _AppartementDetailPageState extends State<AppartementDetailPage> {
  late Future<Map<String, dynamic>> _dataFuture;

  bool _isInitialLoad = true;

  final Map<String, dynamic> _cachedData = {};

  static const String _cacheKeyUserRating = 'user_rating';
  static const String _cacheKeyRatingStats = 'rating_stats';
  static const String _cacheKeyInfos = 'infos';
  static const String _cacheKeyRoles = 'roles';
  static const String _cacheKeyPhotos = 'photos';
  static const String _cacheKeyDisponibilite = 'disponibilite';
  static const String _cacheKeyReservations = 'reservations';

  int _selectedRating = 0;

  final TextEditingController _commentController =
  TextEditingController();

  int _currentImageIndex = 0;
  bool _isExpanded = false;

  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;

  int _totalNights = 0;

  double _totalReduction = 0.0;
  double _totalPrice = 0.0;

  Set<DateTime> _reservedDatesCache = {};

  // INIT

  @override
  void initState() {
    super.initState();

    _initializeCache();

    _dataFuture = _loadDataSequentially();

    _loadAppartementComplet();

    _enregistrerConsultation();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    context.read<FavoritesService>();

    _reservedDatesCache = _getReservedDates();
  }

  // INITIALISATION CACHE

  void _initializeCache() {
    if (widget.cachedData != null) {
      _cachedData.addAll(widget.cachedData!);
    }
  }

  // HELPERS : VILLE ADRESSE DEPUIS LA RÉSIDENCE
  String _getResidenceVille() {
    final residenceData = widget.appartement['residence'];

    if (residenceData is Map) {
      final ville = residenceData['ville']?.toString().trim();
      if (ville != null && ville.isNotEmpty) {
        return ville;
      }
    }

    final fallback = widget.appartement['ville']?.toString().trim();
    if (fallback != null && fallback.isNotEmpty) {
      return fallback;
    }

    return 'Ville inconnue';
  }

  String _getResidenceAdresse() {
    final residenceData = widget.appartement['residence'];

    if (residenceData is Map) {
      final adresse = residenceData['adresse']?.toString().trim();
      if (adresse != null && adresse.isNotEmpty) {
        return adresse;
      }
    }

    final fallback = widget.appartement['adresse']?.toString().trim();
    if (fallback != null && fallback.isNotEmpty) {
      return fallback;
    }

    return 'Adresse inconnue';
  }

  String? _getResidenceLocalisation() {
    final residenceData = widget.appartement['residence'];

    if (residenceData is Map) {
      final loc = residenceData['localisation']?.toString().trim();
      if (loc != null && loc.isNotEmpty) {
        return loc;
      }
    }

    final fallback =
    widget.appartement['residence_localisation']?.toString().trim();

    if (fallback != null && fallback.isNotEmpty) {
      return fallback;
    }

    return null;
  }



  // CHARGEMENT APPARTEMENT COMPLET

  Future<void> _loadAppartementComplet() async {
    try {

      //Récupérer l'appartement
      final appartement = await widget.appartementService.supabase
          .from('appartements')
          .select('*')
          .eq('id', widget.appartement['id'].toString())
          .single();

      if (!mounted) return;

      widget.appartement.addAll(appartement);

      //Récupérer la résidence via residence_id
      final residenceId = appartement['residence_id']?.toString();

      if (residenceId != null && residenceId.isNotEmpty) {
        final residence = await widget.appartementService.supabase
            .from('residences')
            .select('id, nom, ville, adresse, description, localisation')
            .eq('id', residenceId)
            .maybeSingle();

        if (residence != null) {
          setState(() {
            widget.appartement['residence'] = residence;
            widget.appartement['residence_nom'] = residence['nom'];
            widget.appartement['residence_desc'] = residence['description'];
            widget.appartement['residence_localisation'] = residence['localisation'];
          });

        debugPrint('residence response = $residence');

        } else {
          debugPrint('Résidence introuvable → problème RLS probable');
        }
      } else {
        debugPrint('residence_id est null');
      }

      _calculateTotal();

      debugPrint("Appartement complet chargé");
      debugPrint("Résidence : ${widget.appartement['residence_nom']}");
    } catch (e) {
      debugPrint("Erreur chargement appartement : $e");
    }
  }

  // HISTORIQUE CONSULTATION
  Future<void> _enregistrerConsultation() async {
    final id = widget.appartement['id'];

    if (id == null) {
      return;
    }

    try {
      await HistoriqueConsultationService()
          .ajouterConsultation(id.toString());
    } catch (e) {
      debugPrint(
        'Erreur historique consultation : $e',
      );
    }
  }

  // CHARGEMENT DES DONNÉES
  void _loadData() {
    setState(() {
      _dataFuture = _loadDataSequentially();
    });
  }

  void _refreshData() {
    _cachedData.clear();

    _reservedDatesCache = {};

    _loadData();
  }

  Future<Map<String, dynamic>> _loadDataSequentially() async {
    final String appartementId =
    widget.appartement['id'].toString();

    final Map<String, dynamic> result = {};

    try {

      // PHOTOS
      if (!_cachedData.containsKey(_cacheKeyPhotos)) {
        result[_cacheKeyPhotos] =
        await widget.appartementService
            .loadPhotoUrls(appartementId);

        _cachedData[_cacheKeyPhotos] =
        result[_cacheKeyPhotos];
      } else {
        result[_cacheKeyPhotos] =
        _cachedData[_cacheKeyPhotos];
      }


      // RÉSERVATIONS
      if (!_cachedData.containsKey(_cacheKeyReservations)) {
        try {
          final reservations =
          await widget.appartementService
              .getReservationsByAppartement(
            appartementId,
          );

          result[_cacheKeyReservations] = reservations;

          _cachedData[_cacheKeyReservations] =
              reservations;

          _reservedDatesCache = _getReservedDates();
        } catch (e) {
          debugPrint(
            'Erreur chargement réservations : $e',
          );

          result[_cacheKeyReservations] = [];

          _cachedData[_cacheKeyReservations] = [];
        }
      } else {
        result[_cacheKeyReservations] =
        _cachedData[_cacheKeyReservations];
      }


      // DONNÉES PARALLÈLES
      final futures = <String, Future<dynamic>>{};

      if (!_cachedData.containsKey(_cacheKeyInfos)) {
        futures[_cacheKeyInfos] =
            widget.appartementService
                .getInfoByAppartement(appartementId);
      }

      if (!_cachedData.containsKey(_cacheKeyRoles)) {
        futures[_cacheKeyRoles] =
            widget.appartementService
                .getRolesByAppartement(appartementId);
      }

      if (!_cachedData.containsKey(
        _cacheKeyDisponibilite,
      )) {
        futures[_cacheKeyDisponibilite] =
            widget.appartementService
                .fetchNextDisponibilite(appartementId);
      }

      if (futures.isNotEmpty) {
        final completedFutures =
        await Future.wait(futures.values);

        int index = 0;

        for (final key in futures.keys) {
          result[key] =
          completedFutures[index];

          _cachedData[key] =
          completedFutures[index];

          index++;
        }
      }


      //NOTE UTILISATEUR
      if (!_cachedData.containsKey(
        _cacheKeyUserRating,
      )) {
        final userRating =
        await RatingService()
            .getUserRating(appartementId);

        result[_cacheKeyUserRating] =
            userRating;

        _cachedData[_cacheKeyUserRating] =
            userRating;

        if (userRating != null) {
          _selectedRating = userRating;
        }
      } else {
        result[_cacheKeyUserRating] =
        _cachedData[_cacheKeyUserRating];
      }


      //STATISTIQUES NOTES
      if (!_cachedData.containsKey(
        _cacheKeyRatingStats,
      )) {
        final stats =
        await RatingService()
            .getAppartmentStats(appartementId);

        result[_cacheKeyRatingStats] =
            stats;

        _cachedData[_cacheKeyRatingStats] =
            stats;
      } else {
        result[_cacheKeyRatingStats] =
        _cachedData[_cacheKeyRatingStats];
      }


      // RÉCUPÉRATION CACHE
      for (final key in [
        _cacheKeyInfos,
        _cacheKeyRoles,
        _cacheKeyDisponibilite,
        _cacheKeyReservations,
        _cacheKeyUserRating,
        _cacheKeyRatingStats,
      ]) {
        if (!result.containsKey(key) &&
            _cachedData.containsKey(key)) {
          result[key] = _cachedData[key];
        }
      }


      //VALEURS PAR DÉFAUT
      result.putIfAbsent(
        _cacheKeyInfos,
            () => [],
      );

      result.putIfAbsent(
        _cacheKeyRoles,
            () => [],
      );

      result.putIfAbsent(
        _cacheKeyPhotos,
            () => [],
      );

      result.putIfAbsent(
        _cacheKeyDisponibilite,
            () => {},
      );

      result.putIfAbsent(
        _cacheKeyReservations,
            () => [],
      );

      result.putIfAbsent(
        _cacheKeyUserRating,
            () => null,
      );

      result.putIfAbsent(
        _cacheKeyRatingStats,
            () => {
          'average': 0.0,
          'count': 0,
        },
      );

      return result;
    } catch (e) {
      debugPrint(
        'Erreur chargement données : $e',
      );

      return {
        _cacheKeyInfos:
        _cachedData[_cacheKeyInfos] ?? [],

        _cacheKeyRoles:
        _cachedData[_cacheKeyRoles] ?? [],

        _cacheKeyPhotos:
        _cachedData[_cacheKeyPhotos] ?? [],

        _cacheKeyDisponibilite:
        _cachedData[_cacheKeyDisponibilite] ?? {},

        _cacheKeyReservations:
        _cachedData[_cacheKeyReservations] ?? [],
      };
    } finally {
      _isInitialLoad = false;
    }
  }


  // GESTION DES DATES
  DateStatus _getDateStatus() {
    if (_selectedStartDate == null ||
        _selectedEndDate == null) {
      return DateStatus.none;
    }

    final conflict = _checkReservationConflict(
      _selectedStartDate!,
      _selectedEndDate!,
    );

    if (conflict['hasConflict'] == true) {
      return DateStatus.conflict;
    }

    final disponibilite =
    _cachedData[_cacheKeyDisponibilite];

    if (disponibilite != null &&
        disponibilite['date_debut'] != null) {
      final dateDebutDispo =
      disponibilite['date_debut'] as DateTime;

      final dateDebutDispoNormalized =
      DateTime(
        dateDebutDispo.year,
        dateDebutDispo.month,
        dateDebutDispo.day,
      );

      final startNormalized =
      DateTime(
        _selectedStartDate!.year,
        _selectedStartDate!.month,
        _selectedStartDate!.day,
      );

      if (startNormalized
          .isBefore(dateDebutDispoNormalized)) {
        return DateStatus.invalid;
      }
    }

    return DateStatus.valid;
  }

  Color _getStatusColor(DateStatus status) {
    switch (status) {
      case DateStatus.valid:
        return const Color(0xD572CF62);

      case DateStatus.invalid:
        return const Color(0xD5FF3535);

      case DateStatus.conflict:
        return const Color(0xD5FF6800);

      case DateStatus.none:
        return Colors.grey;
    }
  }

  String _getStatusMessage(DateStatus status) {
    switch (status) {
      case DateStatus.valid:
        return 'Dates disponibles';

      case DateStatus.invalid:
        final disponibilite =
        _cachedData[_cacheKeyDisponibilite];

        if (disponibilite != null &&
            disponibilite['date_debut'] != null) {
          final dateDebut =
          disponibilite['date_debut'] as DateTime;

          return 'Disponible à partir du '
              '${_formatDateFrench(dateDebut)}';
        }

        return 'Dates non disponibles';

      case DateStatus.conflict:
        final conflict =
        _checkReservationConflict(
          _selectedStartDate!,
          _selectedEndDate!,
        );

        if (conflict['type'] == 'own') {
          return 'Vous avez déjà réservé pour ces dates';
        }

        final start =
        conflict['start'] as DateTime?;

        final end =
        conflict['end'] as DateTime?;

        if (start != null && end != null) {
          return 'Déjà réservé du '
              '${_formatDateShortFR(start)} '
              'au ${_formatDateShortFR(end)}';
        }

        return 'Ces dates sont déjà réservées';

      case DateStatus.none:
        return 'Sélectionnez vos dates';
    }
  }

  //DISPONIBILITÉ APPARTEMENT
  bool _checkDisponibilite(
      Map<String, DateTime?>? disponibilite,
      ) {
    if (disponibilite == null) {
      return false;
    }

    final dateDebut =
    disponibilite['date_debut'];

    final dateFin =
    disponibilite['date_fin'];

    if (dateDebut == null ||
        dateFin == null) {
      return false;
    }

    final now = DateTime.now();

    final today = DateTime(
      now.year,
      now.month,
      now.day,
    );

    final debut = DateTime(
      dateDebut.year,
      dateDebut.month,
      dateDebut.day,
    );

    final fin = DateTime(
      dateFin.year,
      dateFin.month,
      dateFin.day,
    );

    return !fin.isBefore(today) &&
        !debut.isAfter(fin);
  }


  //DATES RÉSERVÉES
  Set<DateTime> _getReservedDates() {
    final reservations =
        _cachedData[_cacheKeyReservations]
        as List<dynamic>? ??
            [];

    final Set<DateTime> reservedDates = {};

    for (final reservation in reservations) {
      try {
        final rawStart =
        reservation['date_debut'];

        final rawEnd =
        reservation['date_fin'];

        if (rawStart == null ||
            rawEnd == null) {
          continue;
        }

        final start = rawStart is DateTime
            ? rawStart
            : DateTime.parse(
          rawStart.toString(),
        );

        final end = rawEnd is DateTime
            ? rawEnd
            : DateTime.parse(
          rawEnd.toString(),
        );

        final normalizedStart =
        DateTime(
          start.year,
          start.month,
          start.day,
        );

        final normalizedEnd =
        DateTime(
          end.year,
          end.month,
          end.day,
        );

        for (
        DateTime d = normalizedStart;
        d.isBefore(normalizedEnd);
        d = d.add(
          const Duration(days: 1),
        )
        ) {
          reservedDates.add(d);
        }
      } catch (_) {
        continue;
      }
    }

    return reservedDates;
  }

  //CONFLIT RÉSERVATION
  Map<String, dynamic> _checkReservationConflict(
      DateTime startDate,
      DateTime endDate,
      ) {
    final reservations =
        _cachedData[_cacheKeyReservations]
        as List<dynamic>? ??
            [];

    if (reservations.isEmpty) {
      return {
        'hasConflict': false,
        'type': 'none',
      };
    }

    final normalizedStart =
    DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    );

    final normalizedEnd =
    DateTime(
      endDate.year,
      endDate.month,
      endDate.day,
    );

    final currentUserId =
    widget.appartementService.currentUserId();

    for (final reservation in reservations) {
      try {
        final reservationStart =
        reservation['date_debut'];

        final reservationEnd =
        reservation['date_fin'];

        if (reservationStart == null ||
            reservationEnd == null) {
          continue;
        }

        DateTime resStart;

        if (reservationStart is DateTime) {
          resStart = DateTime(
            reservationStart.year,
            reservationStart.month,
            reservationStart.day,
          );
        } else {
          final parsed =
          DateTime.parse(
            reservationStart.toString(),
          );

          resStart = DateTime(
            parsed.year,
            parsed.month,
            parsed.day,
          );
        }

        DateTime resEnd;

        if (reservationEnd is DateTime) {
          resEnd = DateTime(
            reservationEnd.year,
            reservationEnd.month,
            reservationEnd.day,
          );
        } else {
          final parsed =
          DateTime.parse(
            reservationEnd.toString(),
          );

          resEnd = DateTime(
            parsed.year,
            parsed.month,
            parsed.day,
          );
        }

        final hasOverlap =
            normalizedStart.isBefore(resEnd) &&
                normalizedEnd.isAfter(resStart);

        if (!hasOverlap) {
          continue;
        }

        // IMPORTANT :
        // Le schéma utilise locataire_id.
        final reservationUserId =
            reservation['locataire_id']?.toString() ??
                '';

        final isOwnReservation =
            currentUserId != null &&
                reservationUserId ==
                    currentUserId;

        return {
          'hasConflict': true,
          'type': isOwnReservation
              ? 'own'
              : 'other',
          'start': resStart,
          'end': resEnd,
        };
      } catch (_) {
        continue;
      }
    }

    return {
      'hasConflict': false,
      'type': 'none',
    };
  }

  //FORMAT DATES
  String _formatDateFrench(DateTime date) {
    final day = date.day;

    final monthNames = [
      'janvier',
      'février',
      'mars',
      'avril',
      'mai',
      'juin',
      'juillet',
      'août',
      'septembre',
      'octobre',
      'novembre',
      'décembre',
    ];

    final month =
    monthNames[date.month - 1];

    final year = date.year;

    final weekdayNames = [
      'Lundi',
      'Mardi',
      'Mercredi',
      'Jeudi',
      'Vendredi',
      'Samedi',
      'Dimanche',
    ];

    final weekday =
    weekdayNames[date.weekday - 1];

    return '$weekday $day $month $year';
  }

  String _formatDateShortFR(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }


  //SÉLECTION DES DATES
  Future<void> _openDateRangeModal() async {
    final freshReservations =
    await widget.appartementService
        .getReservationsByAppartement(
      widget.appartement['id'].toString(),
    );

    if (!mounted) {
      return;
    }

    setState(() {
      _cachedData[_cacheKeyReservations] =
          freshReservations;

      _reservedDatesCache =
          _getReservedDates();
    });

    DateTime? tempStart =
        _selectedStartDate;

    DateTime? tempEnd =
        _selectedEndDate;

    final disponibilite =
    _cachedData[_cacheKeyDisponibilite];

    final CalendarStyle calendarStyle =
    CalendarStyle(
      todayDecoration: const BoxDecoration(
        color: Color(0xFFFF1D1D),
        shape: BoxShape.circle,
      ),
      rangeStartDecoration:
      const BoxDecoration(
        color: Color(0xFFC5521B),
        shape: BoxShape.circle,
      ),
      rangeEndDecoration:
      const BoxDecoration(
        color: Color(0xFFC5521B),
        shape: BoxShape.circle,
      ),
      withinRangeDecoration:
      const BoxDecoration(
        color: Color(0xFFC5521B),
        shape: BoxShape.circle,
      ),
    );

    final CalendarBuilders calendarBuilders =
    CalendarBuilders(
      defaultBuilder:
          (context, day, focusedDay) {
        final normalized =
        DateTime(
          day.year,
          day.month,
          day.day,
        );

        if (_reservedDatesCache
            .contains(normalized)) {
          return Container(
            margin:
            const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.red.withValues(
                alpha: 0x3A,
              ),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '${day.day}',
              style: GoogleFonts.poppins(
                color: Colors.white,
              ),
            ),
          );
        }

        return null;
      },
    );


    //DISPONIBILITÉ D'UNE PLAGE
    bool isRangeAvailable(
        DateTime start,
        DateTime end,
        ) {
      final normalizedStart =
      DateTime(
        start.year,
        start.month,
        start.day,
      );

      final normalizedEnd =
      DateTime(
        end.year,
        end.month,
        end.day,
      );

      for (final reserved
      in _reservedDatesCache) {
        if (normalizedStart.isBefore(
          reserved.add(
            const Duration(days: 1),
          ),
        ) &&
            normalizedEnd.isAfter(reserved)) {
          return false;
        }
      }

      return true;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius:
        BorderRadius.vertical(
          top: Radius.circular(25.r),
        ),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder:
              (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context)
                    .viewInsets
                    .bottom,
              ),
              child: Container(
                decoration:
                const BoxDecoration(
                  color: Color(0xFFFFE6EB),
                  borderRadius:
                  BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                ),
                child: SizedBox(
                  height:
                  MediaQuery.of(context)
                      .size
                      .height *
                      0.64,
                  child: Column(
                    mainAxisSize:
                    MainAxisSize.min,
                    children: [
                      Container(
                        width: 50.w,
                        height: 5.h,
                        margin:
                        EdgeInsets.symmetric(
                          vertical: 12.h,
                        ),
                        decoration:
                        BoxDecoration(
                          color:
                          const Color(
                            0xE5E3B28A,
                          ),
                          borderRadius:
                          BorderRadius
                              .circular(
                            10.r,
                          ),
                        ),
                      ),

                      Text(
                        'Sélectionnez vos dates',
                        style:
                        GoogleFonts.poppins(
                          fontSize: 18.sp,
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),

                      if (disponibilite !=
                          null &&
                          disponibilite[
                          'date_debut'] !=
                              null)
                        Padding(
                          padding:
                          EdgeInsets.symmetric(
                            horizontal: 30.w,
                            vertical: 5.h,
                          ),
                          child: Text(
                            'Disponible à partir du '
                                '${_formatDateFrench(
                              disponibilite[
                              'date_debut'],
                            )}',
                            style:
                            GoogleFonts.poppins(
                              fontSize: 12.sp,
                              color:
                              const Color(
                                0xE58A4E1E,
                              ),
                              fontWeight:
                              FontWeight.w500,
                            ),
                            textAlign:
                            TextAlign.center,
                          ),
                        ),

                      TableCalendar(
                        firstDay:
                        DateTime.now(),
                        lastDay: DateTime(
                          DateTime.now().year + 2,
                        ),
                        focusedDay:
                        tempStart ??
                            DateTime.now(),
                        availableCalendarFormats:
                        const {
                          CalendarFormat.month:
                          'Mois',
                        },
                        rangeSelectionMode:
                        RangeSelectionMode
                            .toggledOn,
                        rangeStartDay:
                        tempStart,
                        rangeEndDay:
                        tempEnd,
                        calendarStyle:
                        calendarStyle,
                        calendarBuilders:
                        calendarBuilders,
                        onRangeSelected:
                            (
                            start,
                            end,
                            focusedDay,
                            ) {
                          setModalState(() {
                            if (start !=
                                null &&
                                end !=
                                    null) {
                              tempStart =
                                  start;

                              tempEnd =
                                  end;

                              if (!isRangeAvailable(
                                start,
                                end,
                              )) {
                                ScaffoldMessenger
                                    .of(
                                  context,
                                ).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Certaines dates sont déjà réservées',
                                    ),
                                  ),
                                );
                              }
                            } else if (start !=
                                null &&
                                end == null) {
                              tempStart =
                                  start;

                              tempEnd = null;
                            }
                          });
                        },
                      ),

                      SizedBox(
                        height: 15.h,
                      ),

                      ElevatedButton(
                        onPressed: () {
                          //DATES
                          if (tempStart ==
                              null ||
                              tempEnd ==
                                  null) {
                            ScaffoldMessenger
                                .of(
                              context,
                            ).showSnackBar(
                              SnackBar(
                                behavior:
                                SnackBarBehavior
                                    .floating,
                                margin:
                                EdgeInsets
                                    .symmetric(
                                  horizontal:
                                  20.w,
                                  vertical:
                                  300.h,
                                ),
                                shape:
                                RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius
                                      .circular(
                                    16.r,
                                  ),
                                ),
                                backgroundColor:
                                const Color(
                                  0xFFFF9966,
                                ),
                                duration:
                                const Duration(
                                  seconds: 3,
                                ),
                                content:
                                Column(
                                  mainAxisSize:
                                  MainAxisSize
                                      .min,
                                  children: [
                                    const Icon(
                                      Icons
                                          .warning,
                                      color:
                                      Colors
                                          .red,
                                      size: 40,
                                    ),
                                    SizedBox(
                                      height:
                                      8.h,
                                    ),
                                    Text(
                                      'Veuillez sélectionner une date de début et une date de fin.',
                                      textAlign:
                                      TextAlign
                                          .center,
                                      style:
                                      GoogleFonts
                                          .poppins(
                                        fontSize:
                                        20.sp,
                                        fontWeight:
                                        FontWeight
                                            .bold,
                                        color:
                                        Colors
                                            .white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );

                            return;
                          }

                          //VÉRIFICATION DISPONIBILITÉ
                          if (!isRangeAvailable(
                            tempStart!,
                            tempEnd!,
                          )) {
                            ScaffoldMessenger
                                .of(
                              context,
                            ).showSnackBar(
                              SnackBar(
                                behavior:
                                SnackBarBehavior
                                    .floating,
                                margin:
                                EdgeInsets
                                    .symmetric(
                                  horizontal:
                                  20.w,
                                  vertical:
                                  300.h,
                                ),
                                shape:
                                RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius
                                      .circular(
                                    16.r,
                                  ),
                                ),
                                backgroundColor:
                                const Color(
                                  0xFFFF9966,
                                ),
                                duration:
                                const Duration(
                                  seconds: 3,
                                ),
                                content:
                                Column(
                                  mainAxisSize:
                                  MainAxisSize
                                      .min,
                                  children: [
                                    const Icon(
                                      Icons
                                          .warning,
                                      color:
                                      Colors
                                          .red,
                                      size: 40,
                                    ),
                                    SizedBox(
                                      height:
                                      8.h,
                                    ),
                                    Text(
                                      "La plage sélectionnée n'est pas disponible.",
                                      textAlign:
                                      TextAlign
                                          .center,
                                      style:
                                      GoogleFonts
                                          .poppins(
                                        fontSize:
                                        20.sp,
                                        fontWeight:
                                        FontWeight
                                            .bold,
                                        color:
                                        Colors
                                            .white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );

                            return;
                          }

                          //ENREGISTREMENT LOCAL
                          setState(() {
                            _selectedStartDate =
                                tempStart;

                            _selectedEndDate =
                                tempEnd;
                          });

                          //CALCUL DU PRIX
                          _calculateTotal();

                          //FERMETURE
                          Navigator.pop(
                            context,
                          );
                        },
                        style:
                        ElevatedButton
                            .styleFrom(
                          backgroundColor:
                          const Color(
                            0xFFE36830,
                          ),
                        ),
                        child: Text(
                          'Confirmer',
                          style:
                          GoogleFonts
                              .poppins(
                            fontSize: 24.sp,
                            fontWeight:
                            FontWeight.w300,
                            color:
                            Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }


  // CALCUL DU PRIX AVEC RÉDUCTION

  void _calculateTotal() {
    if (_selectedStartDate == null ||
        _selectedEndDate == null) {
      if (!mounted) {
        _totalNights = 0;
        _totalPrice = 0.0;
        _totalReduction = 0.0;

        return;
      }

      setState(() {
        _totalNights = 0;
        _totalPrice = 0.0;
        _totalReduction = 0.0;
      });

      return;
    }


    // NOMBRE DE NUITS

    int nights =
        _selectedEndDate!
            .difference(
          _selectedStartDate!,
        )
            .inDays;

    if (nights <= 0) {
      nights = 1;
    }


    // PRIX DE BASE

    final double prixProprietaire =
        double.tryParse(
          widget.appartement[
          'prix_proprietaire']
              ?.toString() ??
              '0',
        ) ??
            0.0;

    final double fraisService =
        double.tryParse(
          widget.appartement[
          'frais_service']
              ?.toString() ??
              '0',
        ) ??
            0.0;


    // CALCUL CENTRALISÉ

    final result =
    price_utils.calculerPrixAvecReduction(
      prixProprietaire:
      prixProprietaire,
      fraisService:
      fraisService,
      nuits: nights,
    );


    // RÉCUPÉRATION DES VALEURS

    final double prixProTotal =
        result['prixProTotal'] ?? 0.0;

    final double serviceTotal =
        result['serviceTotal'] ?? 0.0;

    final double reductionProprietaire =
        result['reductionProprietaire'] ??
            0.0;

    final double reductionService =
        result['reductionService'] ??
            0.0;

    final double totalReduction =
        result['totalReduction'] ?? 0.0;

    final double sousTotal =
        result['sousTotal'] ?? 0.0;

    final double total =
        result['total'] ?? 0.0;


    // MISE À JOUR

    if (!mounted) {
      _totalNights = nights;

      _totalReduction = totalReduction;

      _totalPrice = total;

      return;
    }

    setState(() {
      _totalNights = nights;

      _totalReduction = totalReduction;

      _totalPrice = total;
    });


    // LOG

    debugPrint(
      'CALCUL PRIX',
    );

    debugPrint(
      'Nuits: $nights',
    );

    debugPrint(
      'Prix propriétaire/nuit: '
          '$prixProprietaire',
    );

    debugPrint(
      'Frais service/nuit: '
          '$fraisService',
    );

    debugPrint(
      'Prix propriétaire total: '
          '$prixProTotal',
    );

    debugPrint(
      'Frais service total: '
          '$serviceTotal',
    );

    debugPrint(
      'Sous-total: '
          '$sousTotal',
    );

    debugPrint(
      'Réduction propriétaire: '
          '$reductionProprietaire',
    );

    debugPrint(
      'Réduction service: '
          '$reductionService',
    );

    debugPrint(
      'Réduction totale: '
          '$totalReduction',
    );

    debugPrint(
      'TOTAL FINAL: '
          '$total',
    );
  }


  // RATING

  void _openRatingDialog({
    VoidCallback? onRatingSubmitted,
  }) {
    final currentUser =
        Supabase.instance.client.auth.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          behavior:
          SnackBarBehavior.floating,
          margin: EdgeInsets.only(
            bottom: 100.h,
            left: 20.w,
            right: 20.w,
          ),
          shape:
          RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(
              16.r,
            ),
          ),
          backgroundColor:
          const Color(0xFFFF0505),
          duration:
          const Duration(seconds: 3),
          content: Column(
            mainAxisSize:
            MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.white,
                size: 40.sp,
              ),
              SizedBox(
                height: 8.h,
              ),
              Text(
                'Vous devez être connecté pour laisser une note',
                textAlign:
                TextAlign.center,
                style:
                GoogleFonts.poppins(
                  fontSize: 18.sp,
                  fontWeight:
                  FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );

      return;
    }

    final int cachedUserRating =
        _cachedData[
        _cacheKeyUserRating]
        as int? ??
            0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        int localRating =
        cachedUserRating > 0
            ? cachedUserRating
            : 5;

        return Dialog(
          backgroundColor:
          Colors.transparent,
          insetPadding:
          EdgeInsets.symmetric(
            horizontal: 24.w,
            vertical: 24.h,
          ),
          child: Container(
            width: 360.w,
            constraints:
            BoxConstraints(
              maxWidth: 400.w,
              minWidth: 280.w,
            ),
            padding:
            EdgeInsets.all(20.w),
            decoration:
            BoxDecoration(
              color:
              const Color(0xFFFFF0E5),
              borderRadius:
              BorderRadius.circular(
                24.r,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black
                      .withValues(
                    alpha: 0.1,
                  ),
                  blurRadius: 20,
                  offset:
                  const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize:
              MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40.w,
                    height: 4.h,
                    decoration:
                    BoxDecoration(
                      color:
                      Colors.grey[300],
                      borderRadius:
                      BorderRadius.circular(
                        2.r,
                      ),
                    ),
                  ),
                ),

                SizedBox(
                  height: 16.h,
                ),

                Text(
                  'Votre évaluation',
                  style:
                  GoogleFonts.poppins(
                    fontSize: 20.sp,
                    fontWeight:
                    FontWeight.bold,
                    color:
                    const Color(
                      0xFF673A15,
                    ),
                  ),
                ),

                SizedBox(
                  height: 16.h,
                ),

                StatefulBuilder(
                  builder:
                      (
                      context,
                      setDialogState,
                      ) {
                    return Column(
                      mainAxisSize:
                      MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment
                              .center,
                          children:
                          List.generate(
                            5,
                                (index) {
                              return GestureDetector(
                                onTap: () {
                                  setDialogState(
                                        () {
                                      localRating =
                                          index +
                                              1;
                                    },
                                  );
                                },
                                child:
                                Container(
                                  margin:
                                  EdgeInsets
                                      .symmetric(
                                    horizontal:
                                    4.w,
                                  ),
                                  padding:
                                  EdgeInsets
                                      .all(
                                    4.w,
                                  ),
                                  decoration:
                                  BoxDecoration(
                                    color: index <
                                        localRating
                                        ? Colors
                                        .amber
                                        .withValues(
                                      alpha:
                                      0.1,
                                    )
                                        : Colors
                                        .transparent,
                                    shape:
                                    BoxShape
                                        .circle,
                                  ),
                                  child: Icon(
                                    index <
                                        localRating
                                        ? Icons
                                        .star_rounded
                                        : Icons
                                        .star_border_rounded,
                                    color:
                                    Colors
                                        .amber,
                                    size:
                                    36.sp,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),

                        SizedBox(
                          height: 12.h,
                        ),

                        TextField(
                          controller:
                          _commentController,
                          maxLines: 3,
                          style:
                          GoogleFonts.poppins(
                            fontSize: 15.sp,
                            color:
                            const Color(
                              0xFF673A15,
                            ),
                          ),
                          decoration:
                          InputDecoration(
                            hintText:
                            'Ajouter un commentaire (optionnel)...',
                            hintStyle:
                            GoogleFonts
                                .poppins(
                              color: Colors
                                  .grey
                                  .shade500,
                              fontSize:
                              14.sp,
                            ),
                            filled: true,
                            fillColor:
                            const Color(
                              0xFFFFF5EC,
                            ),
                            border:
                            OutlineInputBorder(
                              borderRadius:
                              BorderRadius
                                  .circular(
                                12.r,
                              ),
                              borderSide:
                              BorderSide
                                  .none,
                            ),
                            focusedBorder:
                            OutlineInputBorder(
                              borderSide:
                              const BorderSide(
                                color:
                                Color(
                                  0xFFE36830,
                                ),
                                width: 1.5,
                              ),
                              borderRadius:
                              BorderRadius
                                  .circular(
                                12.r,
                              ),
                            ),
                            contentPadding:
                            EdgeInsets
                                .symmetric(
                              horizontal:
                              16.w,
                              vertical:
                              12.h,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),

                SizedBox(
                  height: 16.h,
                ),

                Row(
                  children: [
                    Expanded(
                      child:
                      OutlinedButton(
                        onPressed: () {
                          Navigator.pop(
                            context,
                          );
                        },
                        style:
                        OutlinedButton
                            .styleFrom(
                          side:
                          BorderSide(
                            color:
                            Colors.grey[
                            300]!,
                          ),
                          shape:
                          RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius
                                .circular(
                              14.r,
                            ),
                          ),
                          padding:
                          EdgeInsets
                              .symmetric(
                            vertical:
                            14.h,
                          ),
                        ),
                        child: Text(
                          'Annuler',
                          style:
                          GoogleFonts
                              .poppins(
                            color:
                            Colors.grey[
                            600],
                            fontSize:
                            15.sp,
                          ),
                        ),
                      ),
                    ),

                    SizedBox(
                      width: 12.w,
                    ),

                    Expanded(
                      child:
                      ElevatedButton(
                        style:
                        ElevatedButton
                            .styleFrom(
                          backgroundColor:
                          const Color(
                            0xFFE36830,
                          ),
                          shape:
                          RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius
                                .circular(
                              14.r,
                            ),
                          ),
                          padding:
                          EdgeInsets
                              .symmetric(
                            vertical:
                            14.h,
                          ),
                        ),
                        onPressed: () {
                          setState(() {
                            _selectedRating =
                                localRating;
                          });

                          Navigator.pop(
                            context,
                          );

                          _submitRating(
                            onRatingSubmitted:
                            onRatingSubmitted,
                          );
                        },
                        child: Text(
                          cachedUserRating >
                              0
                              ? 'Modifier'
                              : 'Confirmer',
                          style:
                          GoogleFonts
                              .poppins(
                            color:
                            Colors.white,
                            fontSize:
                            15.sp,
                            fontWeight:
                            FontWeight
                                .w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  // ENREGISTREMENT NOTE

  Future<void> _submitRating({
    VoidCallback? onRatingSubmitted,
  }) async {
    final String appartementId =
    widget.appartement['id'].toString();

    try {
      await RatingService().submitRating(
        appartementId: appartementId,
        rating: _selectedRating,
        comment:
        _commentController.text
            .trim()
            .isNotEmpty
            ? _commentController.text
            .trim()
            : null,
      );

      if (mounted) {
        SnackBarService()
            .showSuccess(
          'Évaluation enregistrée !',
        );
      }

      _commentController.clear();

      if (!mounted) {
        return;
      }

      setState(() {
        _cachedData[
        _cacheKeyUserRating] =
            _selectedRating;

        final stats =
            _cachedData[
            _cacheKeyRatingStats]
            as Map<String, dynamic>? ??
                {
                  'average': 0.0,
                  'count': 0,
                };

        final int count =
            (stats['count'] as int? ??
                0) +
                1;

        final double average =
            (stats['average'] as num?)
                ?.toDouble() ??
                0.0;

        final double newAverage =
            ((average *
                (count - 1)) +
                _selectedRating) /
                count;

        _cachedData[
        _cacheKeyRatingStats] = {
          'average': newAverage,
          'count': count,
        };
      });

      if (onRatingSubmitted !=
          null) {
        onRatingSubmitted();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(
          SnackBar(
            behavior:
            SnackBarBehavior
                .floating,
            backgroundColor:
            Colors.red,
            content:
            Text('Erreur : $e'),
          ),
        );
      }
    }
  }


  // BUILD

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      const Color(0xFFFFF0E5),
      body:
      FutureBuilder<Map<String, dynamic>>(
        future: _dataFuture,
        builder:
            (context, snapshot) {
          if (_isInitialLoad &&
              snapshot.connectionState ==
                  ConnectionState.waiting) {
            return SkeletonWidgets
                .buildSkeletonLoading();
          }

          if (snapshot.hasError) {
            return _buildErrorView(
              snapshot.error.toString(),
            );
          }

          if (snapshot.hasData) {
            final data =
            snapshot.data!;

            final List<
                Map<String, dynamic>> infos =
            List<
                Map<String, dynamic>>.from(
              data[
              _cacheKeyInfos] ??
                  [],
            );

            final List<
                Map<String, dynamic>> roles =
            List<
                Map<String, dynamic>>.from(
              data[
              _cacheKeyRoles] ??
                  [],
            );

            final List<String> photos =
            List<String>.from(
              data[
              _cacheKeyPhotos] ??
                  [],
            );

            final Map<String, DateTime?>?
            disponibilite =
            data[
            _cacheKeyDisponibilite] !=
                null
                ? Map<String,
                DateTime?>.from(
              data[
              _cacheKeyDisponibilite]
              as Map,
            )
                : null;

            return Stack(
              children: [

                // HEADER

                HeaderImage(
                  photos: photos,
                  currentIndex:
                  _currentImageIndex,
                  onPageChanged:
                      (index) {
                    setState(() {
                      _currentImageIndex =
                          index;
                    });
                  },
                ),


                // CONTENU

                _buildContent(
                  context,
                  infos,
                  roles,
                  disponibilite,
                ),


                // BOTTOM BAR

                BottomBar(
                  appartement:
                  widget.appartement,
                  disponibilite:
                  _cachedData[
                  _cacheKeyDisponibilite] ??
                      {},
                  startDate:
                  _selectedStartDate,
                  endDate:
                  _selectedEndDate,
                  totalPrice:
                  _totalPrice,
                  totalNights:
                  _totalNights,
                  databaseService:
                  widget.appartementService,
                  status:
                  _getDateStatus(),
                  statusColor:
                  _getStatusColor(
                    _getDateStatus(),
                  ),
                ),


                // RETOUR

                _buildBackButton(),


                // LOADING PARTIEL

                if (snapshot
                    .connectionState ==
                    ConnectionState.waiting &&
                    !_isInitialLoad)
                  _buildPartialLoadingOverlay(),
              ],
            );
          }

          return SkeletonWidgets
              .buildSkeletonLoading();
        },
      ),
    );
  }


  // CONTENU

  Widget _buildContent(
      BuildContext context,
      List<Map<String, dynamic>> infos,
      List<Map<String, dynamic>> roles,
      Map<String, DateTime?>? disponibilite,
      ) {
    final info =
    infos.isNotEmpty
        ? infos.first
        : null;

    final role =
    roles.isNotEmpty
        ? roles.first
        : null;

    return DraggableScrollableSheet(
      initialChildSize: 0.71,
      minChildSize: 0.71,
      maxChildSize: 0.95,
      snap: true,
      snapSizes: const [
        0.71,
        0.75,
        0.95,
      ],
      builder:
          (_, controller) {
        return Container(
          padding:
          EdgeInsets.only(
            top: 5.h,
          ),
          decoration:
          const BoxDecoration(
            color:
            Color(0xFFFFEFE0),
            borderRadius:
            BorderRadius.vertical(
              top: Radius.circular(35),
            ),
          ),
          child: ListView(
            controller:
            controller,
            physics:
            const ClampingScrollPhysics(),
            children: [
              _buildTitle(),

              // STATUS

              StatusRow(
                isDisponible:
                _checkDisponibilite(
                  disponibilite,
                ),
                appartementId:
                widget.appartement[
                'id']
                    .toString(),
                isFavorite:
                context
                    .watch<
                    FavoritesService>()
                    .isFavorite(
                  widget.appartement[
                  'id']
                      .toString(),
                ),
                onFavoriteToggle:
                    () {
                  context
                      .read<
                      FavoritesService>()
                      .toggleFavorite(
                    widget.appartement[
                    'id']
                        .toString(),
                  );
                },
                photos:
                _cachedData[
                _cacheKeyPhotos] ??
                    [],
                titre:
                widget.appartement[
                'titre'] ??
                    'Appartement',
                description:
                widget.appartement[
                'description'] ??
                    '',
              ),


              // CHAMBRES

              RoomsSection(
                info: info,
                type:
                widget.appartement[
                'type']
                    ?.toString() ??
                    'Type...',
              ),

              SizedBox(
                height: 5.h,
              ),


              // CARACTÉRISTIQUES

              FeaturesSection(
                info: info,
                role: role,
              ),

              const Divider(
                height: 20,
                color:
                Color(0xFF8A4E1E),
                indent: 20,
                endIndent: 20,
                thickness: 0.5,
              ),


              // DESCRIPTION

              _buildDescription(),

              const Divider(
                height: 20,
                color:
                Color(0xFF8A4E1E),
                indent: 20,
                endIndent: 20,
                thickness: 0.5,
              ),


              // ÉQUIPEMENTS

              EquipementsSection(
                appartement:
                widget.appartement,
              ),

              const Divider(
                height: 20,
                color:
                Color(0xFF8A4E1E),
                indent: 20,
                endIndent: 20,
                thickness: 0.5,
              ),

              // RÈGLES + SÉLECTION DATES

              RulesSection(
                role: role,
                appartement: widget.appartement,
                dateSelectorSection: DateSelectorSection(
                  selectedStartDate: _selectedStartDate,
                  selectedEndDate: _selectedEndDate,
                  totalNights: _totalNights,
                  totalPrice: _totalPrice,


                  // PRIX PUBLIC PAR NUIT
                  // prix propriétaire + frais de service

                  pricePerNight:
                  (double.tryParse(
                    widget.appartement['prix_proprietaire']?.toString() ?? '0',
                  ) ??
                      0.0) +
                      (double.tryParse(
                        widget.appartement['frais_service']?.toString() ?? '0',
                      ) ??
                          0.0),


                  // RÉDUCTION TOTALE

                  totalReduction: _totalReduction,

                  status: _getDateStatus(),

                  statusColor: _getStatusColor(
                    _getDateStatus(),
                  ),

                  statusMessage: _getStatusMessage(
                    _getDateStatus(),
                  ),

                  onTap: _openDateRangeModal,
                ),
              ),

              const Divider(
                height: 20,
                color: Color(0xFF8A4E1E),
                indent: 20,
                endIndent: 20,
                thickness: 0.5,
              ),

              // NOTES

              RatingSection(
                average:
                (_cachedData[
                _cacheKeyRatingStats]
                as Map<String,
                    dynamic>?)?[
                'average'] ??
                    0.0,

                count:
                (_cachedData[
                _cacheKeyRatingStats]
                as Map<String,
                    dynamic>?)?[
                'count'] ??
                    0,

                currentRating:
                _cachedData[
                _cacheKeyUserRating]
                as int?,

                onTap: () {
                  _openRatingDialog(
                    onRatingSubmitted:
                        () {
                      setState(
                            () {},
                      );
                    },
                  );
                },
              ),

              const Divider(
                height: 20,
                color:
                Color(0xFF8A4E1E),
                indent: 20,
                endIndent: 20,
                thickness: 0.5,
              ),


              // LOCALISATION

              LocationSection(
                ville: _getResidenceVille(),
                adresse: _getResidenceAdresse(),
                localisation: _getResidenceLocalisation(),
              ),

              SizedBox(
                height: 80.h,
              ),
            ],
          ),
        );
      },
    );
  }

  // TITRE
  Widget _buildTitle() {
    final title = widget.appartement['titre']?.toString() ?? 'Titre inconnu';

    String? residenceNom;

    final residenceData = widget.appartement['residence'];
    if (residenceData is Map) {
      residenceNom = residenceData['nom']?.toString();
    }

    residenceNom ??= widget.appartement['residence_nom']?.toString();

    final hasResidence = residenceNom != null && residenceNom.trim().isNotEmpty;

    return Center(
      child: Transform.translate(
        offset: const Offset(0, -20),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [

              // NOM DE LA RÉSIDENCE avec badge

              if (hasResidence)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE85D26).withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: const Color(0xFFE85D26).withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.business_outlined,
                        size: 14.sp,
                        color: const Color(0xFFE85D26),
                      ),
                      SizedBox(width: 5.w),
                      Flexible(
                        child: Text(
                          residenceNom,
                          style: GoogleFonts.poppins(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFE85D26),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

              if (hasResidence) SizedBox(height: 8.h),

              // TITRE DE L'APPARTEMENT
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }


  // DESCRIPTION

  Widget _buildDescription() {

    // Description de la résidence
    String? residenceDesc;

    final residenceData = widget.appartement['residence'];
    if (residenceData is Map) {
      residenceDesc = residenceData['description']?.toString().trim();
    }
    residenceDesc ??= widget.appartement['residence_desc']?.toString().trim();

    final hasResidenceDesc =
        residenceDesc != null && residenceDesc.isNotEmpty;

    // Description de l'appartement

    final appartementDesc =
        widget.appartement['description']?.toString().trim() ?? '';

    final hasAppartementDesc = appartementDesc.isNotEmpty;


    // Texte combiné

    final String combinedText;
    if (hasResidenceDesc && hasAppartementDesc) {
      combinedText = '$residenceDesc\n\n$appartementDesc';
    } else if (hasResidenceDesc) {
      combinedText = residenceDesc;
    } else if (hasAppartementDesc) {
      combinedText = appartementDesc;
    } else {
      combinedText = 'Pas de description...';
    }

    final hasContent = hasResidenceDesc || hasAppartementDesc;

    return Padding(
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          // TITRE

          Text(
            'À propos',
            style: GoogleFonts.poppins(
              fontSize: 20.sp,
              fontWeight: FontWeight.w600,
            ),
          ),

          SizedBox(height: 10.h),


          // TEXTE COMBINÉ

          Text(
            combinedText,
            maxLines: _isExpanded ? null : 4,
            overflow: _isExpanded
                ? TextOverflow.visible
                : TextOverflow.ellipsis,
            style: GoogleFonts.poppins(
              fontSize: 15.sp,
              color: const Color(0xE58A4E1E),
              height: 1.5,
            ),
          ),


          // VOIR PLUS / VOIR MOINS

          if (hasContent && combinedText.length > 150)
            GestureDetector(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              child: Padding(
                padding: EdgeInsets.only(top: 10.h),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isExpanded ? 'Voir moins' : 'Voir plus',
                      style: GoogleFonts.poppins(
                        color: const Color(0xFFE85D26),
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Icon(
                      _isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: const Color(0xFFE85D26),
                      size: 18.sp,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }


  // BOUTON RETOUR
  Widget _buildBackButton() {
    return Positioned(
      top: 40.h,
      left: 15.w,
      child: CircleAvatar(
        backgroundColor:
        const Color(
          0xFFFFE5CE,
        ),
        radius: 25.r,
        child: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color:
            const Color(
              0xFF8A4E1E,
            ),
            size: 24.sp,
          ),
          onPressed: () {
            Navigator.pop(
              context,
            );
          },
        ),
      ),
    );
  }


  // LOADING
  Widget _buildPartialLoadingOverlay() {
    return Positioned.fill(
      child: Container(
        color:
        Colors.black.withValues(
          alpha: 0x3A,
        ),
        child:
        const Center(
          child:
          CircularProgressIndicator(
            color:
            Color(0xFFE85D26),
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }

  // ERREUR
  Widget _buildErrorView(
      String error,
      ) {
    return Center(
      child: Padding(
        padding:
        EdgeInsets.all(20.r),
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment
              .center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 50,
              color: Colors.red,
            ),

            SizedBox(
              height: 16.h,
            ),

            Text(
              'Erreur de chargement',
              style:
              GoogleFonts.poppins(
                fontSize: 18.sp,
                fontWeight:
                FontWeight.w500,
              ),
            ),

            SizedBox(
              height: 8.h,
            ),

            Text(
              'Détails: $error',
              textAlign:
              TextAlign.center,
              style:
              GoogleFonts.poppins(
                fontSize: 14.sp,
                color:
                Colors.grey[600],
              ),
            ),

            SizedBox(
              height: 20.h,
            ),

            Row(
              mainAxisAlignment:
              MainAxisAlignment
                  .center,
              children: [
                ElevatedButton(
                  onPressed:
                  _refreshData,
                  child:
                  const Text(
                    'Réessayer',
                  ),
                ),

                SizedBox(
                  width: 10.w,
                ),

                OutlinedButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                    );
                  },
                  child:
                  const Text(
                    'Retour',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }


  // DISPOSE

  @override
  void dispose() {
    _commentController.dispose();

    super.dispose();
  }
}
