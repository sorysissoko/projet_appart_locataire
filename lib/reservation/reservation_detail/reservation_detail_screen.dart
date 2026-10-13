import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:service/rating/rating_service.dart';
import 'package:service/database_service.dart';
import 'package:service/snackbar_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../locataire/details/models/date_status.dart';
import '../../locataire/favorite_appart/favorites_service.dart';
import '../../utils/date_utils.dart';
import '../../utils/formatters.dart' as formatters;
import '../../utils/reservation_utils.dart';
import '../../widgets/confirmation_modal.dart';
import '../../widgets/reservation_skeletons.dart';
import '../price_utils.dart' as price_utils;
import 'utils/reservation_helpers.dart';
import 'widgets/reservation_header.dart';
import 'widgets/reservation_status_row.dart';
import 'widgets/reservation_rooms_section.dart';
import 'widgets/reservation_amenities_section.dart';
import 'widgets/reservation_dates_section.dart';
import 'widgets/reservation_price_section.dart';
import 'widgets/reservation_rating_section.dart';
import 'widgets/reservation_bottom_bar.dart';

class ReservationDetailScreen extends StatefulWidget {
  final Map<String, dynamic> appartement;
  final DatabaseService appartementService;
  final Map<String, dynamic>? cachedData;
  final Map<String, dynamic>? reservation;

  const ReservationDetailScreen({
    super.key,
    required this.appartement,
    required this.appartementService,
    this.cachedData,
    this.reservation,
  });

  @override
  State<ReservationDetailScreen> createState() =>
      _ReservationDetailScreenState();
}

class _ReservationDetailScreenState extends State<ReservationDetailScreen> {
  // ==========================================================
  // CACHE
  // ==========================================================

  late Future<Map<String, dynamic>> _dataFuture;

  bool _isInitialLoad = true;

  final Map<String, dynamic> _cachedData = {};

  static const String _cacheKeyAppartement = 'appartement';
  static const String _cacheKeyUserRating = 'user_rating';
  static const String _cacheKeyRatingStats = 'rating_stats';
  static const String _cacheKeyInfos = 'infos';
  static const String _cacheKeyRoles = 'roles';
  static const String _cacheKeyPhotos = 'photos';
  static const String _cacheKeyDisponibilite = 'disponibilite';
  static const String _cacheKeyReservations = 'reservations';

  // ==========================================================
  // ETAT
  // ==========================================================

  int _selectedRating = 0;

  final TextEditingController _commentController =
  TextEditingController();

  int _currentImageIndex = 0;

  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;

  int _totalNights = 0;

  double _totalPrice = 0.0;

  bool _isFavorite = false;

  // ==========================================================
  // RESPONSIVE
  // ==========================================================

  double get _screenWidth => MediaQuery.sizeOf(context).width;

  double get _screenHeight => MediaQuery.sizeOf(context).height;

  bool get _isTablet => _screenWidth >= 600;

  bool get _isSmallScreen => _screenHeight < 700;

  bool get _isLandscape =>
      MediaQuery.orientationOf(context) == Orientation.landscape;

  double get _horizontalPadding {
    if (_isTablet) {
      return (_screenWidth * 0.08).clamp(24.0, 80.0);
    }

    return 16.w;
  }

  double get _contentMaxWidth {
    if (_isTablet) {
      return 900.0;
    }

    return double.infinity;
  }

  // ==========================================================
  // INIT
  // ==========================================================

  @override
  void initState() {
    super.initState();

    _initializeCache();

    _loadData();

    _initializeReservationDates();
  }

  void _initializeCache() {
    if (widget.cachedData != null) {
      _cachedData.addAll(widget.cachedData!);
    }
  }

  void _initializeReservationDates() {
    if (widget.reservation != null) {
      final debut = widget.reservation!['date_debut'];
      final fin = widget.reservation!['date_fin'];

      if (debut != null && fin != null) {
        _selectedStartDate =
            DateTime.tryParse(debut.toString());

        _selectedEndDate =
            DateTime.tryParse(fin.toString());
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final favoritesService =
    context.read<FavoritesService>();

    _isFavorite = favoritesService.isFavorite(
      widget.appartement['id'].toString(),
    );
  }

  // ==========================================================
  // CHARGEMENT DES DONNÉES
  // ==========================================================

  Future<Map<String, dynamic>> _loadDataSequentially() async {
    final String appartementId =
    widget.appartement['id'].toString();

    final Map<String, dynamic> result = {};

    try {
      // --------------------------------------------------------
      // APPARTEMENT
      // --------------------------------------------------------

      if (!_cachedData.containsKey(_cacheKeyAppartement)) {
        final appartementComplet =
        await widget.appartementService.supabase
            .from('appartements')
            .select('*')
            .eq('id', appartementId)
            .single();

        _cachedData[_cacheKeyAppartement] =
            appartementComplet;
      }

      // --------------------------------------------------------
      // PHOTOS
      // --------------------------------------------------------

      if (!_cachedData.containsKey(_cacheKeyPhotos)) {
        final photos =
        await widget.appartementService
            .loadPhotoUrls(appartementId);

        result[_cacheKeyPhotos] = photos;

        _cachedData[_cacheKeyPhotos] = photos;
      } else {
        result[_cacheKeyPhotos] =
        _cachedData[_cacheKeyPhotos];
      }

      // --------------------------------------------------------
      // RESERVATIONS
      // --------------------------------------------------------

      if (!_cachedData.containsKey(
        _cacheKeyReservations,
      )) {
        try {
          final reservations =
          await widget.appartementService
              .getReservationsByAppartement(
            appartementId,
          );

          result[_cacheKeyReservations] =
              reservations;

          _cachedData[_cacheKeyReservations] =
              reservations;
        } catch (_) {
          result[_cacheKeyReservations] = [];

          _cachedData[_cacheKeyReservations] = [];
        }
      } else {
        result[_cacheKeyReservations] =
        _cachedData[_cacheKeyReservations];
      }

      // --------------------------------------------------------
      // DONNÉES PARALLÈLES
      // --------------------------------------------------------

      final futures =
      <String, Future<dynamic>>{};

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
        final completed =
        await Future.wait(futures.values);

        int index = 0;

        for (final key in futures.keys) {
          result[key] = completed[index];

          _cachedData[key] = completed[index];

          index++;
        }
      }

      // --------------------------------------------------------
      // NOTE UTILISATEUR
      // --------------------------------------------------------

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

      // --------------------------------------------------------
      // STATISTIQUES NOTES
      // --------------------------------------------------------

      if (!_cachedData.containsKey(
        _cacheKeyRatingStats,
      )) {
        final stats =
        await RatingService()
            .getAppartmentStats(appartementId);

        result[_cacheKeyRatingStats] = stats;

        _cachedData[_cacheKeyRatingStats] =
            stats;
      } else {
        result[_cacheKeyRatingStats] =
        _cachedData[_cacheKeyRatingStats];
      }

      // --------------------------------------------------------
      // COMPLETION CACHE
      // --------------------------------------------------------

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

        _cacheKeyUserRating:
        _cachedData[_cacheKeyUserRating],

        _cacheKeyRatingStats:
        _cachedData[_cacheKeyRatingStats] ??
            {
              'average': 0.0,
              'count': 0,
            },

        _cacheKeyAppartement:
        _cachedData[_cacheKeyAppartement] ?? {},
      };
    } finally {
      _isInitialLoad = false;
    }
  }

  void _loadData() {
    if (!mounted) return;

    setState(() {
      _dataFuture = _loadDataSequentially();
    });
  }

  void _refreshData() {
    _cachedData.clear();

    _isInitialLoad = true;

    _loadData();
  }

  // ==========================================================
  // GESTION DES DATES
  // ==========================================================

  DateStatus _getDateStatus() {
    if (_selectedStartDate == null ||
        _selectedEndDate == null) {
      return DateStatus.none;
    }

    final conflict =
    _checkReservationConflict(
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
      disponibilite['date_debut'] is DateTime
          ? disponibilite['date_debut'] as DateTime
          : DateTime.tryParse(
        disponibilite['date_debut']
            .toString(),
      );

      if (dateDebutDispo != null) {
        final dateDebutNormalized =
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
            .isBefore(dateDebutNormalized)) {
          return DateStatus.invalid;
        }
      }
    }

    return DateStatus.valid;
  }

  Color _getStatusColor(
      DateStatus status,
      ) {
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
        DateTime resEnd;

        if (reservationStart is DateTime) {
          resStart = reservationStart;
        } else {
          resStart =
              DateTime.parse(
                reservationStart.toString(),
              );
        }

        if (reservationEnd is DateTime) {
          resEnd = reservationEnd;
        } else {
          resEnd =
              DateTime.parse(
                reservationEnd.toString(),
              );
        }

        resStart = DateTime(
          resStart.year,
          resStart.month,
          resStart.day,
        );

        resEnd = DateTime(
          resEnd.year,
          resEnd.month,
          resEnd.day,
        );

        final hasOverlap =
            normalizedStart.isBefore(resEnd) &&
                normalizedEnd.isAfter(resStart);

        if (hasOverlap) {
          final currentUserId =
          widget.appartementService
              .currentUserId();

          final reservationUserId =
              reservation['user_id']?.toString() ??
                  '';

          return {
            'hasConflict': true,
            'type': currentUserId != null &&
                reservationUserId ==
                    currentUserId
                ? 'own'
                : 'other',
            'start': resStart,
            'end': resEnd,
          };
        }
      } catch (_) {
        continue;
      }
    }

    return {
      'hasConflict': false,
      'type': 'none',
    };
  }

  Set<DateTime> _getReservedDates() {
    final reservations =
        _cachedData[_cacheKeyReservations]
        as List<dynamic>? ??
            [];

    final Set<DateTime> reservedDates = {};

    for (final reservation in reservations) {
      try {
        final start =
        DateTime.parse(
          reservation['date_debut'].toString(),
        );

        final end =
        DateTime.parse(
          reservation['date_fin'].toString(),
        );

        for (
        DateTime d = start;
        d.isBefore(end);
        d = d.add(
          const Duration(days: 1),
        )
        ) {
          reservedDates.add(
            DateTime(
              d.year,
              d.month,
              d.day,
            ),
          );
        }
      } catch (_) {
        continue;
      }
    }

    return reservedDates;
  }

  // ==========================================================
  // CALCUL PRIX
  // ==========================================================

  void _calculateTotal() {
    if (_selectedStartDate == null ||
        _selectedEndDate == null) {
      return;
    }

    final appartement =
    _cachedData[_cacheKeyAppartement]
    as Map<String, dynamic>?;

    if (appartement == null) return;

    final nuits =
        _selectedEndDate!
            .difference(_selectedStartDate!)
            .inDays;

    if (nuits <= 0) return;

    final prixProprietaire =
        double.tryParse(
          appartement['prix_proprietaire']
              ?.toString() ??
              '0',
        ) ??
            0.0;

    final fraisService =
        double.tryParse(
          appartement['frais_service']
              ?.toString() ??
              '0',
        ) ??
            0.0;

    final reductions =
    price_utils.calculerPrixAvecReduction(
      prixProprietaire: prixProprietaire,
      fraisService: fraisService,
      nuits: nuits,
    );

    if (!mounted) return;

    setState(() {
      _totalNights = nuits;

      _totalPrice =
          reductions['total'] ?? 0.0;
    });
  }

  // ==========================================================
  // NOTATION
  // ==========================================================

  void _openRatingDialog() {
    final currentUser =
        Supabase.instance.client.auth.currentUser;

    if (currentUser == null) {
      ReservationHelpers.showAppSnackBar(
        message:
        'Vous devez être connecté pour laisser une note',
        type: SnackBarType.warning,
      );

      return;
    }

    final cachedUserRating =
        _cachedData[_cacheKeyUserRating]
        as int? ??
            5;

    showDialog(
      context: context,
      builder: (dialogContext) {
        int localRating = cachedUserRating;

        return AlertDialog(
          backgroundColor:
          const Color(0xFFFFF0E5),
          shape: RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(
              20.r,
            ),
          ),
          title: Text(
            'Votre évaluation',
            style: GoogleFonts.poppins(
              fontSize: _isTablet ? 22 : 20.sp,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF673A15),
            ),
            textAlign: TextAlign.center,
          ),
          content: StatefulBuilder(
            builder: (
                context,
                setDialogState,
                ) {
              return ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth:
                  _isTablet ? 550 : 400,
                ),
                child: Column(
                  mainAxisSize:
                  MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment:
                      MainAxisAlignment.center,
                      children:
                      List.generate(
                        5,
                            (index) {
                          return IconButton(
                            icon: Icon(
                              index < localRating
                                  ? Icons.star_rounded
                                  : Icons
                                  .star_border_rounded,
                              color:
                              Colors.amber,
                              size:
                              _isTablet
                                  ? 40
                                  : 36.sp,
                            ),
                            onPressed: () {
                              setDialogState(
                                    () {
                                  localRating =
                                      index + 1;
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),

                    SizedBox(height: 15.h),

                    TextField(
                      controller:
                      _commentController,
                      maxLines: 3,
                      style: GoogleFonts.poppins(
                        fontSize:
                        _isTablet
                            ? 16
                            : 15.sp,
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
                        GoogleFonts.poppins(
                          color:
                          Colors.grey.shade500,
                          fontSize:
                          _isTablet
                              ? 15
                              : 14.sp,
                        ),
                        filled: true,
                        fillColor:
                        const Color(
                          0xFFFFEFE0,
                        ),
                        border:
                        OutlineInputBorder(
                          borderRadius:
                          BorderRadius
                              .circular(
                            12.r,
                          ),
                          borderSide:
                          BorderSide.none,
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
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          actionsAlignment:
          MainAxisAlignment.spaceEvenly,
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(
                    dialogContext,
                  ),
              child: Text(
                'Annuler',
                style: GoogleFonts.poppins(
                  color:
                  Colors.grey.shade600,
                  fontSize:
                  _isTablet
                      ? 16
                      : 16.sp,
                ),
              ),
            ),
            ElevatedButton(
              style:
              ElevatedButton.styleFrom(
                backgroundColor:
                const Color(
                  0xFFE36830,
                ),
                shape:
                RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(
                    20.r,
                  ),
                ),
              ),
              onPressed: () {
                setState(() {
                  _selectedRating =
                      localRating;
                });

                Navigator.pop(
                  dialogContext,
                );

                _submitRating();
              },
              child: Text(
                'Confirmer',
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize:
                  _isTablet
                      ? 16
                      : 16.sp,
                  fontWeight:
                  FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitRating() async {
    final appartementId =
    widget.appartement['id']
        .toString();

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

      if (!mounted) return;

      ReservationHelpers.showAppSnackBar(
        message:
        '✅ Évaluation enregistrée avec succès ! 🎉',
        type: SnackBarType.success,
      );

      _commentController.clear();

      setState(() {
        _cachedData[_cacheKeyUserRating] =
            _selectedRating;

        final stats =
            _cachedData[
            _cacheKeyRatingStats]
            as Map<String, dynamic>? ??
                {
                  'average': 0.0,
                  'count': 0,
                };

        final count =
            (stats['count'] as int? ??
                0) +
                1;

        final average =
            (stats['average'] as num?)
                ?.toDouble() ??
                0.0;

        final newAverage =
            ((average *
                (count - 1)) +
                _selectedRating) /
                count;

        _cachedData[
        _cacheKeyRatingStats] =
        {
          'average': newAverage,
          'count': count,
        };
      });

      _loadData();
    } catch (e) {
      if (!mounted) return;

      ReservationHelpers.showAppSnackBar(
        message:
        '❌ Une erreur est survenue : $e',
        type: SnackBarType.error,
      );
    }
  }

  // MODIFIER RESERVATION
  Future<void> _modifyReservationDates() async {
    if (widget.reservation == null) {
      return;
    }

    final status =
    determineReservationStatus(
      widget.reservation!,
    );

    if (status !=
        ReservationStatus.enAttente) {
      ReservationHelpers.showAppSnackBar(
        message:
        '❌ Vous ne pouvez modifier que les réservations en attente',
        type: SnackBarType.error,
      );

      return;
    }

    final currentStart =
        _selectedStartDate;

    final currentEnd =
        _selectedEndDate;

    if (currentStart == null ||
        currentEnd == null) {
      return;
    }

    final freshReservations =
    await widget.appartementService
        .getReservationsByAppartement(
      widget.appartement['id'].toString(),
    );

    if (!mounted) return;

    setState(() {
      _cachedData[_cacheKeyReservations] =
          freshReservations;
    });

    DateTime? tempStart =
        currentStart;

    DateTime? tempEnd =
        currentEnd;

    final disponibilite =
    _cachedData[
    _cacheKeyDisponibilite];

    final Set<DateTime> reservedDates =
    _getReservedDates();

    // Retirer les anciennes dates
    for (
    DateTime d = currentStart;
    d.isBefore(currentEnd);
    d = d.add(
      const Duration(days: 1),
    )
    ) {
      reservedDates.remove(
        DateTime(
          d.year,
          d.month,
          d.day,
        ),
      );
    }

    final calendarStyle =
    CalendarStyle(
      todayDecoration:
      const BoxDecoration(
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
      cellMargin: EdgeInsets.all(
        _isTablet ? 5 : 4,
      ),
    );

    final calendarBuilders =
    CalendarBuilders(
      defaultBuilder:
          (
          context,
          day,
          focusedDay,
          ) {
        final normalized =
        DateTime(
          day.year,
          day.month,
          day.day,
        );

        if (reservedDates
            .contains(normalized)) {
          return Container(
            margin:
            EdgeInsets.all(
              _isTablet ? 5 : 4,
            ),
            decoration:
            BoxDecoration(
              color: Colors.red
                  .withValues(
                alpha: 0.22,
              ),
              shape:
              BoxShape.circle,
            ),
            alignment:
            Alignment.center,
            child: Text(
              '${day.day}',
              style:
              GoogleFonts.poppins(
                color:
                Colors.white,
                fontSize:
                _isTablet
                    ? 15
                    : 14.sp,
              ),
            ),
          );
        }

        return null;
      },
    );

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor:
      Colors.transparent,
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (
              context,
              setModalState,
              ) {
            final height =
                MediaQuery.sizeOf(
                  context,
                ).height;

            final width =
                MediaQuery.sizeOf(
                  context,
                ).width;

            final calendarHeight =
            _isLandscape
                ? height * 0.50
                : _isTablet
                ? height * 0.42
                : height * 0.45;

            return SafeArea(
              child: Align(
                alignment:
                Alignment.bottomCenter,
                child: Container(
                  width: _isTablet
                      ? width * 0.80
                      : width,
                  constraints:
                  const BoxConstraints(
                    maxWidth: 850,
                  ),
                  decoration:
                  BoxDecoration(
                    color:
                    const Color(
                      0xFFFFE6EB,
                    ),
                    borderRadius:
                    BorderRadius.vertical(
                      top:
                      Radius.circular(
                        _isTablet
                            ? 32
                            : 30.r,
                      ),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding:
                    EdgeInsets.only(
                      bottom:
                      MediaQuery
                          .viewInsetsOf(
                        context,
                      ).bottom,
                    ),
                    child: Padding(
                      padding:
                      EdgeInsets.symmetric(
                        horizontal:
                        _isTablet
                            ? 24
                            : 12.w,
                        vertical: 8.h,
                      ),
                      child: Column(
                        mainAxisSize:
                        MainAxisSize.min,
                        children: [
                          Container(
                            width:
                            _isTablet
                                ? 60
                                : 50,
                            height: 5,
                            margin:
                            EdgeInsets.symmetric(
                              vertical:
                              10.h,
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
                                10,
                              ),
                            ),
                          ),

                          Text(
                            'Modifier les dates',
                            style:
                            GoogleFonts.poppins(
                              fontSize:
                              _isTablet
                                  ? 21
                                  : 18.sp,
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
                                horizontal:
                                20.w,
                                vertical:
                                5.h,
                              ),
                              child: Text(
                                'Disponible à partir du ${DateUtilsHelper.formatDateFrench(disponibilite['date_debut']!)}',
                                style:
                                GoogleFonts.poppins(
                                  fontSize:
                                  _isTablet
                                      ? 14
                                      : 12.sp,
                                  color:
                                  const Color(
                                    0xE58A4E1E,
                                  ),
                                  fontWeight:
                                  FontWeight.w500,
                                ),
                                textAlign:
                                TextAlign
                                    .center,
                              ),
                            ),

                          SizedBox(
                            height:
                            calendarHeight,
                            child:
                            TableCalendar(
                              firstDay:
                              DateTime.now(),
                              lastDay:
                              DateTime(
                                DateTime.now()
                                    .year +
                                    2,
                              ),
                              focusedDay:
                              tempStart ??
                                  DateTime.now(),
                              availableCalendarFormats:
                              const {
                                CalendarFormat
                                    .month:
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
                                setModalState(
                                      () {
                                    if (start !=
                                        null &&
                                        end !=
                                            null) {
                                      tempStart =
                                          start;

                                      tempEnd =
                                          end;

                                      if (!ReservationHelpers
                                          .isRangeAvailable(
                                        start,
                                        end,
                                        reservedDates,
                                      )) {
                                        ReservationHelpers
                                            .showAppSnackBar(
                                          message:
                                          '❌ Certaines dates sont déjà réservées',
                                          type:
                                          SnackBarType.error,
                                        );
                                      }
                                    } else if (start !=
                                        null &&
                                        end ==
                                            null) {
                                      tempStart =
                                          start;

                                      tempEnd =
                                      null;
                                    }
                                  },
                                );
                              },
                            ),
                          ),

                          SizedBox(
                            height:
                            _isTablet
                                ? 20
                                : 12.h,
                          ),

                          Row(
                            children: [
                              Expanded(
                                child:
                                OutlinedButton(
                                  onPressed:
                                      () {
                                    Navigator.pop(
                                      modalContext,
                                    );
                                  },
                                  style:
                                  OutlinedButton
                                      .styleFrom(
                                    padding:
                                    EdgeInsets.symmetric(
                                      vertical:
                                      13.h,
                                    ),
                                    side:
                                    const BorderSide(
                                      color:
                                      Colors.grey,
                                    ),
                                  ),
                                  child:
                                  Text(
                                    'Annuler',
                                    style:
                                    GoogleFonts.poppins(
                                      fontSize:
                                      _isTablet
                                          ? 16
                                          : 15.sp,
                                      color:
                                      Colors.grey,
                                    ),
                                  ),
                                ),
                              ),

                              SizedBox(
                                width:
                                _isTablet
                                    ? 20
                                    : 12.w,
                              ),

                              Expanded(
                                child:
                                ElevatedButton(
                                  onPressed:
                                      () async {
                                    if (tempStart !=
                                        null &&
                                        tempEnd !=
                                            null &&
                                        ReservationHelpers
                                            .isRangeAvailable(
                                          tempStart!,
                                          tempEnd!,
                                          reservedDates,
                                        )) {
                                      try {
                                        final reservationId =
                                        widget.reservation![
                                        'id']
                                            .toString();

                                        final newNights =
                                            tempEnd!
                                                .difference(
                                              tempStart!,
                                            )
                                                .inDays;

                                        await widget.appartementService
                                            .modifierDatesReservation(
                                          reservationId: reservationId,
                                          dateDebut: tempStart!,
                                          dateFin: tempEnd!,
                                        );

                                        if (!mounted) {
                                          return;
                                        }

                                        setState(
                                              () {
                                            _selectedStartDate =
                                                tempStart;

                                            _selectedEndDate =
                                                tempEnd;

                                            _totalNights =
                                                newNights;

                                            widget.reservation![
                                            'date_debut'] =
                                                tempStart!
                                                    .toIso8601String();

                                            widget.reservation![
                                            'date_fin'] =
                                                tempEnd!
                                                    .toIso8601String();

                                            widget.reservation![
                                            'nuits'] =
                                                newNights;
                                          },
                                        );

                                        _calculateTotal();

                                        if (modalContext
                                            .mounted) {
                                          Navigator.pop(
                                            modalContext,
                                          );
                                        }

                                        _loadData();

                                        if (mounted) {
                                          ReservationHelpers
                                              .showAppSnackBar(
                                            message:
                                            '✅ Dates modifiées avec succès !',
                                            type:
                                            SnackBarType.success,
                                          );
                                        }
                                      } catch (e) {
                                        if (mounted) {
                                          ReservationHelpers
                                              .showAppSnackBar(
                                            message:
                                            '❌ Erreur: $e',
                                            type:
                                            SnackBarType.error,
                                          );
                                        }
                                      }
                                    } else {
                                      ReservationHelpers
                                          .showAppSnackBar(
                                        message:
                                        '❌ La plage sélectionnée n\'est pas disponible.',
                                        type:
                                        SnackBarType.error,
                                      );
                                    }
                                  },
                                  style:
                                  ElevatedButton
                                      .styleFrom(
                                    backgroundColor:
                                    const Color(
                                      0xFFE36830,
                                    ),
                                    padding:
                                    EdgeInsets.symmetric(
                                      vertical:
                                      13.h,
                                    ),
                                  ),
                                  child:
                                  Text(
                                    'Confirmer',
                                    style:
                                    GoogleFonts.poppins(
                                      fontSize:
                                      _isTablet
                                          ? 16
                                          : 15.sp,
                                      fontWeight:
                                      FontWeight.w600,
                                      color:
                                      Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          SizedBox(
                            height:
                            10.h,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // REÇU
  Future<void> _downloadReservationReceipt() async {
    try {
      final reservation =
      widget.reservation!;

      final checkIn =
          reservation['check_in']
              ?.toString() ??
              '14:00';

      final checkOut =
          reservation['check_out']
              ?.toString() ??
              '12:00';

      final receiptContent = '''
      
========================================
         RÉCAPITULATIF DE RÉSERVATION
========================================

RÉFÉRENCE: ${reservation['id']?.toString() ?? 'N/A'}
DATE DE RÉSERVATION: ${DateFormat('dd/MM/yyyy à HH:mm').format(DateTime.now())}

--- INFORMATIONS LOGEMENT ---
Titre: ${widget.appartement['titre'] ?? 'N/A'}
Adresse: ${widget.appartement['adresse'] ?? 'N/A'}, ${widget.appartement['ville'] ?? 'N/A'}
Type: ${widget.appartement['type'] ?? 'N/A'}

--- DATES DU SÉJOUR ---
Arrivée: ${DateUtilsHelper.formatDateLong(reservation['date_debut']?.toString())} (à partir de $checkIn)
Départ: ${DateUtilsHelper.formatDateLong(reservation['date_fin']?.toString())} (avant $checkOut)
Nombre de nuits: ${reservation['nuits']?.toString() ?? _totalNights.toString()}

--- DÉTAILS FINANCIERS ---
Prix par nuit: ${formatters.formatPrice(double.tryParse(widget.appartement['prix']?.toString() ?? '0') ?? 0)} FCFA
Total à payer: ${formatters.formatPrice(_totalPrice)} FCFA

--- STATUT ---
${reservation['status'] ?? 'Confirmé'}

========================================
     MERCI DE VOTRE CONFIANCE !
========================================
''';

      final tempDir =
      await getTemporaryDirectory();

      final file = File(
        '${tempDir.path}/reservation_${reservation['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch}.txt',
      );

      await file.writeAsString(
        receiptContent,
      );

      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile(file.path),
          ],
          text:
          'Voici votre récapitulatif de réservation pour ${widget.appartement['titre']}',
          subject:
          'Réservation - ${widget.appartement['titre']}',
        ),
      );

      if (!mounted) return;

      ReservationHelpers.showAppSnackBar(
        message:
        '✅ Récapitulatif téléchargé avec succès !',
        type: SnackBarType.success,
      );
    } catch (e) {
      debugPrint(
        'Erreur téléchargement: $e',
      );

      if (!mounted) return;

      ReservationHelpers.showAppSnackBar(
        message:
        '❌ Erreur: $e',
        type: SnackBarType.error,
      );
    }
  }

  // ANNULATION
  Future<void> _cancelReservation() async {
    showConfirmationModal(
      context: context,
      title: 'Annuler la réservation',
      message:
      'Êtes-vous sûr de vouloir annuler cette réservation ? Cette action est irréversible.',
      confirmText:
      'Oui, annuler',
      type:
      ConfirmationType.delete,
      onConfirm:
      _handleCancelReservation,
    );
  }

  Future<void> _handleCancelReservation() async {
    try {
      await widget.appartementService
          .cancelReservation(
        widget.reservation!['id']
            .toString(),
      );

      if (!mounted) return;

      ReservationHelpers.showAppSnackBar(
        message:
        '✅ Réservation annulée avec succès',
        type: SnackBarType.success,
      );

      Future.delayed(
        const Duration(seconds: 2),
            () {
          if (mounted) {
            Navigator.pop(context);
          }
        },
      );
    } catch (e) {
      if (!mounted) return;

      ReservationHelpers.showAppSnackBar(
        message:
        '❌ Erreur: ${e.toString()}',
        type: SnackBarType.error,
      );
    }
  }

  // SUPPORT
  void _contactSupport() {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title:
          const Text(
            'Contacter le support',
          ),
          shape:
          RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(
              20.r,
            ),
          ),
          content:
          ConstrainedBox(
            constraints:
            const BoxConstraints(
              maxWidth: 500,
            ),
            child:
            Column(
              mainAxisSize:
              MainAxisSize.min,
              children: [
                ListTile(
                  leading:
                  const Icon(
                    Icons.phone,
                    color:
                    Color(
                      0xFFE36830,
                    ),
                  ),
                  title:
                  const Text(
                    'Appeler',
                  ),
                  subtitle:
                  const Text(
                    '+223 XX XX XX XX',
                  ),
                  onTap:
                      () {
                    Navigator.pop(
                      dialogContext,
                    );
                  },
                ),
                ListTile(
                  leading:
                  const Icon(
                    Icons.email,
                    color:
                    Color(
                      0xFFE36830,
                    ),
                  ),
                  title:
                  const Text(
                    'Email',
                  ),
                  subtitle:
                  const Text(
                    'support@example.com',
                  ),
                  onTap:
                      () {
                    Navigator.pop(
                      dialogContext,
                    );
                  },
                ),
                ListTile(
                  leading:
                  const Icon(
                    Icons.chat,
                    color:
                    Color(
                      0xFFE36830,
                    ),
                  ),
                  title:
                  const Text(
                    'Chat en direct',
                  ),
                  onTap:
                      () {
                    Navigator.pop(
                      dialogContext,
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed:
                  () => Navigator.pop(
                dialogContext,
              ),
              child:
              const Text(
                'Fermer',
              ),
            ),
          ],
        );
      },
    );
  }

  // REBOOK
  void _resetAndBookAgain() {
    setState(() {
      _selectedStartDate = null;
      _selectedEndDate = null;
      _totalNights = 0;
      _totalPrice = 0.0;
    });

    ReservationHelpers.showAppSnackBar(
      message:
      'Sélectionnez de nouvelles dates pour réserver',
      type:
      SnackBarType.info,
    );
  }

  // FAVORIS
  void _toggleFavorite() {
    final favoritesService =
    context.read<FavoritesService>();

    final id =
    widget.appartement['id']
        .toString();

    favoritesService.toggleFavorite(id);

    setState(() {
      _isFavorite =
      !_isFavorite;
    });
  }

  // BUILD
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
      const Color(0xFFFFF0E5),
      body: SafeArea(
        top: false,
        bottom: false,
        child:
        FutureBuilder<
            Map<String, dynamic>>(
          future: _dataFuture,
          builder:
              (context, snapshot) {
            if (_isInitialLoad &&
                snapshot.connectionState ==
                    ConnectionState.waiting) {
              return buildSkeletonLoading();
            }

            if (snapshot.hasError) {
              return _buildErrorView(
                snapshot.error
                    .toString(),
              );
            }

            if (snapshot.hasData) {
              final data =
              snapshot.data!;

              final infos =
              List<Map<String,
                  dynamic>>.from(
                data[_cacheKeyInfos] ??
                    [],
              );

              final roles =
              List<Map<String,
                  dynamic>>.from(
                data[_cacheKeyRoles] ??
                    [],
              );

              final photos =
              List<String>.from(
                data[_cacheKeyPhotos] ??
                    [],
              );

              final disponibilite =
              data[_cacheKeyDisponibilite] !=
                  null
                  ? Map<String,
                  DateTime?>.from(
                data[
                _cacheKeyDisponibilite],
              )
                  : null;

              return Stack(
                children: [
                  ReservationHeader(
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
                    adresse:
                    widget.appartement[
                    'adresse'] ??
                        '',
                    onGalleryTap:
                        () {},
                  ),

                  _buildResponsiveContent(
                    context,
                    infos,
                    roles,
                    disponibilite,
                  ),

                  ReservationBottomBar(
                    appartement:
                    widget.appartement,
                    disponibilite:
                    _cachedData[
                    _cacheKeyDisponibilite],
                    reservation:
                    widget.reservation,
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
                    dateStatus:
                    _getDateStatus(),
                    statusColor:
                    _getStatusColor(
                      _getDateStatus(),
                    ),
                    onCancelReservation:
                    _cancelReservation,
                    onContactSupport:
                    _contactSupport,
                    onDownloadReceipt:
                    _downloadReservationReceipt,
                    onResetAndBookAgain:
                    _resetAndBookAgain,
                    onOpenRatingDialog:
                    _openRatingDialog,
                  ),

                  _buildBackButton(),

                  if (snapshot.connectionState ==
                      ConnectionState.waiting &&
                      !_isInitialLoad)
                    _buildPartialLoadingOverlay(),
                ],
              );
            }

            return buildSkeletonLoading();
          },
        ),
      ),
    );
  }

  // CONTENU RESPONSIVE
  Widget _buildResponsiveContent(
      BuildContext context,
      List<Map<String, dynamic>> infos,
      List<Map<String, dynamic>> roles,
      Map<String, DateTime?>? disponibilite,
      ) {
    return Align(
      alignment:
      Alignment.bottomCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth:
          _contentMaxWidth,
        ),
        child: _buildContent(
          context,
          infos,
          roles,
          disponibilite,
        ),
      ),
    );
  }

  Widget _buildContent(
      BuildContext context,
      List<Map<String, dynamic>> infos,
      List<Map<String, dynamic>> roles,
      Map<String, DateTime?>? disponibilite,
      ) {
    final appartementInfo =
    infos.isNotEmpty
        ? infos.first
        : null;

    final appartementRole =
    roles.isNotEmpty
        ? roles.first
        : null;

    final initialSize =
    _isLandscape
        ? 0.78
        : _isSmallScreen
        ? 0.68
        : _isTablet
        ? 0.64
        : 0.71;

    final maxSize =
    _isLandscape
        ? 0.96
        : 0.95;

    return DraggableScrollableSheet(
      initialChildSize:
      initialSize,
      minChildSize:
      initialSize,
      maxChildSize:
      maxSize,
      snap: true,
      snapSizes: [
        initialSize,
        ((initialSize + maxSize) / 2)
            .clamp(0.70, 0.90),
        maxSize,
      ],
      builder:
          (_, controller) {
        return Container(
          decoration:
          BoxDecoration(
            color:
            const Color(
              0xFFFFEFE0,
            ),
            borderRadius:
            BorderRadius.vertical(
              top:
              Radius.circular(
                _isTablet
                    ? 38
                    : 35.r,
              ),
            ),
          ),
          child: ListView(
            controller:
            controller,
            physics:
            const ClampingScrollPhysics(),
            padding:
            EdgeInsets.only(
              top: 5.h,
              bottom:
              _isTablet
                  ? 120
                  : 100.h,
            ),
            children: [
              _buildTitle(),

              _buildSectionContainer(
                child:
                ReservationStatusRow(
                  appartement:
                  widget.appartement,
                  reservation:
                  widget.reservation,
                  photos:
                  _cachedData[
                  _cacheKeyPhotos] ??
                      [],
                  isFavorite:
                  _isFavorite,
                  onFavoriteToggle:
                  _toggleFavorite,
                ),
              ),

              _buildSectionContainer(
                child:
                ReservationRoomsSection(
                  appartementInfo:
                  appartementInfo,
                  type:
                  widget.appartement[
                  'type']
                      ?.toString() ??
                      'Type...',
                ),
              ),

              SizedBox(
                height:
                _isTablet
                    ? 8
                    : 5.h,
              ),

              if (widget.reservation !=
                  null)
                _buildSectionContainer(
                  child:
                  ReservationDatesSection(
                    reservation:
                    widget.reservation,
                    totalNights:
                    _totalNights,
                    canModify:
                    determineReservationStatus(
                      widget.reservation!,
                    ) ==
                        ReservationStatus
                            .enAttente,
                    onModifyDates:
                    _modifyReservationDates,
                  ),
                ),

              SizedBox(
                height:
                _isTablet
                    ? 8
                    : 5.h,
              ),

              _buildSectionContainer(
                child:
                ReservationPriceSection(
                  totalNights:
                  _totalNights,
                  totalPrice:
                  _totalPrice,
                  pricePerNight:
                  double.tryParse(
                    widget.appartement[
                    'prix']
                        ?.toString() ??
                        '0',
                  ) ??
                      0.0,
                  appartement:
                  _cachedData[
                  _cacheKeyAppartement],
                  reservation:
                  widget.reservation,
                ),
              ),

              _buildSectionContainer(
                child:
                ReservationAmenitiesSection(
                  appartementInfo:
                  appartementInfo,
                  appartementRole:
                  appartementRole,
                ),
              ),

              _buildSectionContainer(
                child:
                _buildRatingSection(),
              ),
            ],
          ),
        );
      },
    );
  }

  // SECTION RESPONSIVE
  Widget _buildSectionContainer({
    required Widget child,
  }) {
    return Padding(
      padding:
      EdgeInsets.symmetric(
        horizontal:
        _horizontalPadding,
        vertical:
        _isTablet
            ? 4
            : 2.h,
      ),
      child: child,
    );
  }

  // ==========================================================
  // TITRE
  // ==========================================================

  Widget _buildTitle() {
    final title =
        widget.appartement[
        'titre']
            ?.toString() ??
            'Titre inconnu';

    return Padding(
      padding:
      EdgeInsets.fromLTRB(
        _horizontalPadding,
        _isTablet
            ? 8
            : 4.h,
        _horizontalPadding,
        _isTablet
            ? 8
            : 4.h,
      ),
      child: Center(
        child: Text(
          title,
          style: GoogleFonts.poppins(
            fontSize:
            _isTablet
                ? 28
                : _isSmallScreen
                ? 23.sp
                : 26.sp,
            fontWeight:
            FontWeight.bold,
          ),
          textAlign:
          TextAlign.center,
          maxLines: 2,
          overflow:
          TextOverflow.ellipsis,
        ),
      ),
    );
  }

  // RATING
  Widget _buildRatingSection() {
    return StatefulBuilder(
      builder:
          (context, setRatingState) {
        final stats =
            _cachedData[
            _cacheKeyRatingStats]
            as Map<String, dynamic>? ??
                {
                  'average': 0.0,
                  'count': 0,
                };

        final average =
            (stats['average']
            as num?)
                ?.toDouble() ??
                0.0;

        final count =
            (stats['count']
            as num?)
                ?.toInt() ??
                0;

        final currentRating =
        _cachedData[
        _cacheKeyUserRating]
        as int?;

        return ReservationRatingSection(
          average: average,
          count: count,
          currentUserRating:
          currentRating,
          onRatePressed:
          _openRatingDialog,
        );
      },
    );
  }

  // BOUTON RETOUR
  Widget _buildBackButton() {
    return Positioned(
      top:
      MediaQuery.paddingOf(
        context,
      ).top +
          (_isTablet
              ? 12
              : 8.h),
      left:
      _isTablet
          ? 20
          : 15.w,
      child: SafeArea(
        child: Material(
          color:
          Colors.transparent,
          child: InkWell(
            borderRadius:
            BorderRadius.circular(
              50,
            ),
            onTap:
                () => Navigator.pop(
              context,
            ),
            child: Container(
              width:
              _isTablet
                  ? 52
                  : 50.w,
              height:
              _isTablet
                  ? 52
                  : 50.w,
              decoration:
              const BoxDecoration(
                color:
                Color(0xFFFFE5CE),
                shape:
                BoxShape.circle,
              ),
              child:
              Icon(
                Icons.arrow_back,
                color:
                const Color(
                  0xFF8A4E1E,
                ),
                size:
                _isTablet
                    ? 25
                    : 24.sp,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // LOADING PARTIEL
  Widget _buildPartialLoadingOverlay() {
    return Positioned.fill(
      child: Container(
        color:
        Colors.black.withValues(
          alpha: 0.22,
        ),
        child: const Center(
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
      child: SingleChildScrollView(
        padding:
        EdgeInsets.all(
          _horizontalPadding,
        ),
        child: ConstrainedBox(
          constraints:
          const BoxConstraints(
            maxWidth: 600,
          ),
          child: Column(
            mainAxisAlignment:
            MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size:
                _isTablet
                    ? 60
                    : 50.sp,
                color:
                Colors.red,
              ),

              SizedBox(
                height:
                _isTablet
                    ? 20
                    : 16.h,
              ),

              Text(
                'Erreur de chargement',
                style:
                GoogleFonts.poppins(
                  fontSize:
                  _isTablet
                      ? 22
                      : 18.sp,
                  fontWeight:
                  FontWeight.w500,
                ),
                textAlign:
                TextAlign.center,
              ),

              SizedBox(
                height:
                _isTablet
                    ? 10
                    : 8.h,
              ),

              Text(
                error,
                textAlign:
                TextAlign.center,
                style:
                GoogleFonts.poppins(
                  fontSize:
                  _isTablet
                      ? 15
                      : 14.sp,
                  color:
                  Colors.grey[600],
                ),
              ),

              SizedBox(
                height:
                _isTablet
                    ? 25
                    : 20.h,
              ),

              Wrap(
                spacing:
                _isTablet
                    ? 16
                    : 10.w,
                runSpacing:
                10.h,
                alignment:
                WrapAlignment.center,
                children: [
                  ElevatedButton(
                    onPressed:
                    _refreshData,
                    child:
                    const Text(
                      'Réessayer',
                    ),
                  ),
                  OutlinedButton(
                    onPressed:
                        () =>
                        Navigator.pop(
                          context,
                        ),
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
