import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'package:mobile_app/details/role.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:service/rating/rating_service.dart';
import 'package:service/database_service.dart';
import 'package:service/snackbar_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:table_calendar/table_calendar.dart';
import '../appartement/acceuil/services/historique_consultation_service.dart';
import '../data/equipements_categories.dart';
import '../favorite_appart/favorites_service.dart';
import '../reservation/price_utils.dart' as price_utils;
import '../reservation/reservation.dart';
import '../widgets/feature_card.dart';
import '../widgets/full_screen_gallery.dart';
import '../widgets/room_info_item.dart';

enum DateStatus {
  none,
  valid,
  invalid,
  conflict,
}

num safeParsePrice(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value;
  if (value is String) return num.tryParse(value) ?? 0;
  return 0;
}

Set<DateTime> _reservedDatesCache = {};

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
  State<AppartementDetailPage> createState() => _AppartementDetailPageState();
}

class _AppartementDetailPageState extends State<AppartementDetailPage> {
  late Future<Map<String, dynamic>> _dataFuture;
  bool _isInitialLoad = true;
  final Map<String, dynamic> _cachedData = {};

  static const String _cacheKeyUserRating = 'user_rating';
  static const String _cacheKeyRatingStats = 'rating_stats';

  int _selectedRating = 0;
  final TextEditingController _commentController = TextEditingController();

  int _currentImageIndex = 0;
  bool _isExpanded = false;

  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  int _totalNights = 0;
  double _totalPrice = 0.0;

  static const String _cacheKeyInfos = 'infos';
  static const String _cacheKeyRoles = 'roles';
  static const String _cacheKeyPhotos = 'photos';
  static const String _cacheKeyDisponibilite = 'disponibilite';
  static const String _cacheKeyReservations = 'reservations';

  @override
  void initState() {
    super.initState();
    _initializeCache();
    _loadAppartementComplet();
    _loadData();
    _calculateTotal();
    _enregistrerConsultation();
  }

  Future<void> _loadAppartementComplet() async {
    try {
      final response = await widget.appartementService.supabase
          .from('appartements')
          .select('*')
          .eq('id', widget.appartement['id'].toString())
          .single();
      setState(() {
        widget.appartement.clear();
        widget.appartement.addAll(response);
      });
      debugPrint("✅ autres_equipements chargé: ${widget.appartement['autres_equipements']}");
    } catch (e) {
      debugPrint("❌ Erreur: $e");
    }
  }

  void _initializeCache() {
    if (widget.cachedData != null) {
      _cachedData.addAll(widget.cachedData!);
    }
  }

  Future<void> _enregistrerConsultation() async {
    final id = widget.appartement['id'];
    if (id == null) {
      return;
    }
    await HistoriqueConsultationService().ajouterConsultation(id.toString());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    context.read<FavoritesService>();
    _reservedDatesCache = _getReservedDates();
  }

  // ---------- Gestion des dates ----------
  DateStatus _getDateStatus() {
    if (_selectedStartDate == null || _selectedEndDate == null) {
      return DateStatus.none;
    }
    final conflict = _checkReservationConflict(_selectedStartDate!, _selectedEndDate!);
    if (conflict['hasConflict'] == true) {
      return DateStatus.conflict;
    }
    final disponibilite = _cachedData[_cacheKeyDisponibilite];
    if (disponibilite != null && disponibilite['date_debut'] != null) {
      final dateDebutDispo = disponibilite['date_debut']! as DateTime;
      final dateDebutDispoNormalized = DateTime(dateDebutDispo.year, dateDebutDispo.month, dateDebutDispo.day);
      final startNormalized = DateTime(_selectedStartDate!.year, _selectedStartDate!.month, _selectedStartDate!.day);
      if (startNormalized.isBefore(dateDebutDispoNormalized)) {
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

  Set<DateTime> _getReservedDates() {
    final reservations = _cachedData[_cacheKeyReservations] as List<dynamic>? ?? [];
    final Set<DateTime> reservedDates = {};
    for (final reservation in reservations) {
      final start = DateTime.parse(reservation['date_debut']);
      final end = DateTime.parse(reservation['date_fin']);
      for (DateTime d = start; d.isBefore(end); d = d.add(const Duration(days: 1))) {
        reservedDates.add(DateTime(d.year, d.month, d.day));
      }
    }
    return reservedDates;
  }

  String _getStatusMessage(DateStatus status) {
    switch (status) {
      case DateStatus.valid:
        return 'Dates disponibles';
      case DateStatus.invalid:
        final disponibilite = _cachedData[_cacheKeyDisponibilite];
        if (disponibilite != null && disponibilite['date_debut'] != null) {
          final dateDebut = disponibilite['date_debut']! as DateTime;
          return 'Disponible à partir du ${_formatDateFrench(dateDebut)}';
        }
        return 'Dates non disponibles';
      case DateStatus.conflict:
        final conflict = _checkReservationConflict(_selectedStartDate!, _selectedEndDate!);
        if (conflict['type'] == 'own') {
          return 'Vous avez déjà réservé pour ces dates';
        } else {
          final start = conflict['start'] as DateTime?;
          final end = conflict['end'] as DateTime?;
          if (start != null && end != null) {
            return 'Déjà réservé du ${_formatDateShortFR(start)} au ${_formatDateShortFR(end)}';
          }
          return 'Ces dates sont déjà réservées';
        }
      case DateStatus.none:
        return 'Sélectionnez vos dates';
    }
  }

  Map<String, dynamic> _checkReservationConflict(DateTime startDate, DateTime endDate) {
    final reservations = _cachedData[_cacheKeyReservations] as List<dynamic>? ?? [];
    if (reservations.isEmpty) {
      return {'hasConflict': false, 'type': 'none'};
    }

    final normalizedStart = DateTime(startDate.year, startDate.month, startDate.day);
    final normalizedEnd = DateTime(endDate.year, endDate.month, endDate.day);

    for (final reservation in reservations) {
      try {
        final reservationStart = reservation['date_debut'];
        final reservationEnd = reservation['date_fin'];
        if (reservationStart == null || reservationEnd == null) {
          continue;
        }

        DateTime resStart;
        if (reservationStart is DateTime) {
          resStart = DateTime(reservationStart.year, reservationStart.month, reservationStart.day);
        } else if (reservationStart is String) {
          resStart = DateTime.parse(reservationStart);
          resStart = DateTime(resStart.year, resStart.month, resStart.day);
        } else {
          continue;
        }

        DateTime resEnd;
        if (reservationEnd is DateTime) {
          resEnd = DateTime(reservationEnd.year, reservationEnd.month, reservationEnd.day);
        } else if (reservationEnd is String) {
          resEnd = DateTime.parse(reservationEnd);
          resEnd = DateTime(resEnd.year, resEnd.month, resEnd.day);
        } else {
          continue;
        }

        final hasOverlap = normalizedStart.isBefore(resEnd) && normalizedEnd.isAfter(resStart);
        if (hasOverlap) {
          final String? currentUserId = widget.appartementService.currentUserId();
          final String reservationUserId = reservation['user_id']?.toString() ?? '';
          return {
            'hasConflict': true,
            'type': (currentUserId != null && reservationUserId == currentUserId) ? 'own' : 'other',
            'start': resStart,
            'end': resEnd,
          };
        }
      } catch (e) {
        continue;
      }
    }
    return {'hasConflict': false, 'type': 'none'};
  }

  // ---------- Chargement des données ----------
  Future<Map<String, dynamic>> _loadDataSequentially() async {
    final String appartementId = widget.appartement['id'].toString();
    final Map<String, dynamic> result = {};

    try {
      if (!_cachedData.containsKey(_cacheKeyPhotos)) {
        result[_cacheKeyPhotos] = await widget.appartementService.loadPhotoUrls(appartementId);
        _cachedData[_cacheKeyPhotos] = result[_cacheKeyPhotos];
      } else {
        result[_cacheKeyPhotos] = _cachedData[_cacheKeyPhotos];
      }

      if (!_cachedData.containsKey(_cacheKeyReservations)) {
        try {
          final reservations = await widget.appartementService.getReservationsByAppartement(appartementId);
          result[_cacheKeyReservations] = reservations;
          _cachedData[_cacheKeyReservations] = reservations;
        } catch (e) {
          result[_cacheKeyReservations] = [];
          _cachedData[_cacheKeyReservations] = [];
        }
      } else {
        result[_cacheKeyReservations] = _cachedData[_cacheKeyReservations];
      }

      final futures = <String, Future<dynamic>>{};
      if (!_cachedData.containsKey(_cacheKeyInfos)) {
        futures[_cacheKeyInfos] = widget.appartementService.getInfoByAppartement(appartementId);
      }
      if (!_cachedData.containsKey(_cacheKeyRoles)) {
        futures[_cacheKeyRoles] = widget.appartementService.getRolesByAppartement(appartementId);
      }
      if (!_cachedData.containsKey(_cacheKeyDisponibilite)) {
        futures[_cacheKeyDisponibilite] = widget.appartementService.fetchNextDisponibilite(appartementId);
      }
      if (futures.isNotEmpty) {
        final completedFutures = await Future.wait(futures.values);
        int index = 0;
        for (final key in futures.keys) {
          result[key] = completedFutures[index];
          _cachedData[key] = completedFutures[index];
          index++;
        }
      }

      if (!_cachedData.containsKey(_cacheKeyUserRating)) {
        final userRating = await RatingService().getUserRating(appartementId);
        result[_cacheKeyUserRating] = userRating;
        _cachedData[_cacheKeyUserRating] = userRating;
        if (userRating != null) {
          _selectedRating = userRating;
        }
      } else {
        result[_cacheKeyUserRating] = _cachedData[_cacheKeyUserRating];
      }

      if (!_cachedData.containsKey(_cacheKeyRatingStats)) {
        final stats = await RatingService().getAppartmentStats(appartementId);
        result[_cacheKeyRatingStats] = stats;
        _cachedData[_cacheKeyRatingStats] = stats;
      } else {
        result[_cacheKeyRatingStats] = _cachedData[_cacheKeyRatingStats];
      }

      for (final key in [_cacheKeyInfos, _cacheKeyRoles, _cacheKeyDisponibilite,
        _cacheKeyReservations, _cacheKeyUserRating, _cacheKeyRatingStats]) {
        if (!result.containsKey(key) && _cachedData.containsKey(key)) {
          result[key] = _cachedData[key];
        }
      }

      result.putIfAbsent(_cacheKeyInfos, () => []);
      result.putIfAbsent(_cacheKeyRoles, () => []);
      result.putIfAbsent(_cacheKeyPhotos, () => []);
      result.putIfAbsent(_cacheKeyDisponibilite, () => {});
      result.putIfAbsent(_cacheKeyReservations, () => []);
      result.putIfAbsent(_cacheKeyUserRating, () => null);
      result.putIfAbsent(_cacheKeyRatingStats, () => {'average': 0.0, 'count': 0});

      return result;
    } catch (e) {
      return {
        _cacheKeyInfos: _cachedData[_cacheKeyInfos] ?? [],
        _cacheKeyRoles: _cachedData[_cacheKeyRoles] ?? [],
        _cacheKeyPhotos: _cachedData[_cacheKeyPhotos] ?? [],
        _cacheKeyDisponibilite: _cachedData[_cacheKeyDisponibilite] ?? {},
        _cacheKeyReservations: _cachedData[_cacheKeyReservations] ?? [],
      };
    } finally {
      _isInitialLoad = false;
    }
  }

  void _loadData() {
    setState(() {
      _dataFuture = _loadDataSequentially();
    });
  }

  void _refreshData() {
    _cachedData.clear();
    _loadData();
  }

  // ---------- Rating ----------
  void _openRatingDialog({VoidCallback? onRatingSubmitted}) {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(bottom: 100.h, left: 20.w, right: 20.w),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          backgroundColor: const Color(0xFFFF0505),
          duration: const Duration(seconds: 3),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: Colors.white, size: 40.sp),
              SizedBox(height: 8.h),
              Text(
                'Vous devez être connecté pour laisser une note',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
        ),
      );
      return;
    }

    final int cachedUserRating = _cachedData[_cacheKeyUserRating] as int? ?? 5;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        int localRating = cachedUserRating > 0 ? cachedUserRating : 5;
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
          child: Container(
            width: 360.w,
            constraints: BoxConstraints(maxWidth: 400.w, minWidth: 280.w),
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF0E5),
              borderRadius: BorderRadius.circular(24.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  'Votre évaluation',
                  style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: const Color(0xFF673A15)),
                ),
                SizedBox(height: 16.h),
                StatefulBuilder(
                  builder: (context, setDialogState) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(5, (index) {
                            return GestureDetector(
                              onTap: () {
                                setDialogState(() {
                                  localRating = index + 1;
                                });
                              },
                              child: Container(
                                margin: EdgeInsets.symmetric(horizontal: 4.w),
                                padding: EdgeInsets.all(4.w),
                                decoration: BoxDecoration(
                                  color: index < localRating
                                      ? Colors.amber.withValues(alpha: 0.1)
                                      : Colors.transparent,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  index < localRating
                                      ? Icons.star_rounded
                                      : Icons.star_border_rounded,
                                  color: Colors.amber,
                                  size: 36.sp,
                                ),
                              ),
                            );
                          }),
                        ),
                        SizedBox(height: 12.h),
                        TextField(
                          controller: _commentController,
                          maxLines: 3,
                          style: TextStyle(fontSize: 15.sp, color: const Color(0xFF673A15)),
                          decoration: InputDecoration(
                            hintText: 'Ajouter un commentaire (optionnel)...',
                            hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14.sp),
                            filled: true,
                            fillColor: const Color(0xFFFFF5EC),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.r),
                              borderSide: BorderSide.none,
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: Color(0xFFE36830), width: 1.5),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                SizedBox(height: 16.h),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey[300]!),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                        ),
                        child: Text('Annuler', style: TextStyle(color: Colors.grey[600], fontSize: 15.sp)),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE36830),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
                          padding: EdgeInsets.symmetric(vertical: 14.h),
                        ),
                        onPressed: () {
                          setState(() {
                            _selectedRating = localRating;
                          });
                          Navigator.pop(context);
                          _submitRating(onRatingSubmitted: onRatingSubmitted);
                        },
                        child: Text(
                          cachedUserRating > 0 ? 'Modifier' : 'Confirmer',
                          style: TextStyle(color: Colors.white, fontSize: 15.sp, fontWeight: FontWeight.w700),
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

  Future<void> _submitRating({VoidCallback? onRatingSubmitted}) async {
    final String appartementId = widget.appartement['id'].toString();
    try {
      await RatingService().submitRating(
        appartementId: appartementId,
        rating: _selectedRating,
        comment: _commentController.text.trim().isNotEmpty
            ? _commentController.text.trim()
            : null,
      );
      if (mounted) {
        SnackBarService().showSuccess('Évaluation enregistrée !');
      }
      _commentController.clear();
      setState(() {
        _cachedData[_cacheKeyUserRating] = _selectedRating;
        final stats = _cachedData[_cacheKeyRatingStats] as Map<String, dynamic>? ?? {'average': 0.0, 'count': 0};
        final count = (stats['count'] as int? ?? 0) + 1;
        final newAverage = ((stats['average'] as double? ?? 0.0) * (count - 1) + _selectedRating) / count;
        _cachedData[_cacheKeyRatingStats] = {'average': newAverage, 'count': count};
      });
      if (onRatingSubmitted != null) {
        onRatingSubmitted();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
            content: Text('Erreur : $e'),
          ),
        );
      }
    }
  }

  // ---------- Helpers de date ----------
  String _formatDateFrench(DateTime date) {
    final day = date.day;
    final monthNames = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
    ];
    final month = monthNames[date.month - 1];
    final year = date.year;
    final weekdayNames = [
      'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'
    ];
    final weekday = weekdayNames[date.weekday - 1];
    return '$weekday $day $month $year';
  }

  String _formatDateShortFR(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  // ---------- Sélection des dates (modal) ----------
  Future<void> _openDateRangeModal() async {
    final freshReservations = await widget.appartementService.getReservationsByAppartement(
      widget.appartement['id'].toString(),
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _cachedData[_cacheKeyReservations] = freshReservations;
      _reservedDatesCache = _getReservedDates();
    });

    DateTime? tempStart = _selectedStartDate;
    DateTime? tempEnd = _selectedEndDate;
    final disponibilite = _cachedData[_cacheKeyDisponibilite];

    final CalendarStyle calendarStyle = CalendarStyle(
      todayDecoration: BoxDecoration(color: const Color(0xFFFF1D1D), shape: BoxShape.circle),
      rangeStartDecoration: BoxDecoration(color: const Color(0xFFC5521B), shape: BoxShape.circle),
      rangeEndDecoration: BoxDecoration(color: const Color(0xFFC5521B), shape: BoxShape.circle),
      withinRangeDecoration: BoxDecoration(color: const Color(0xFFC5521B), shape: BoxShape.circle),
    );

    final CalendarBuilders calendarBuilders = CalendarBuilders(
      defaultBuilder: (context, day, focusedDay) {
        final normalized = DateTime(day.year, day.month, day.day);
        if (_reservedDatesCache.contains(normalized)) {
          return Container(
            margin: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0x3A), shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text('${day.day}', style: const TextStyle(color: Colors.white)),
          );
        }
        return null;
      },
    );

    bool isRangeAvailable(DateTime start, DateTime end) {
      for (final reserved in _reservedDatesCache) {
        if (!reserved.isBefore(start) && !reserved.isAfter(end)) {
          return false;
        }
      }
      return true;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE6EB),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30.r)),
                ),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.64,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 50,
                        height: 5,
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xE5E3B28A),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      Text(
                        'Sélectionnez vos dates',
                        style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                      ),
                      if (disponibilite != null && disponibilite['date_debut'] != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 5),
                          child: Text(
                            'Disponible à partir du ${_formatDateFrench(disponibilite['date_debut']!)}',
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: const Color(0xE58A4E1E),
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      TableCalendar(
                        firstDay: DateTime.now(),
                        lastDay: DateTime(DateTime.now().year + 2),
                        focusedDay: tempStart ?? DateTime.now(),
                        availableCalendarFormats: const {CalendarFormat.month: 'Mois'},
                        rangeSelectionMode: RangeSelectionMode.toggledOn,
                        rangeStartDay: tempStart,
                        rangeEndDay: tempEnd,
                        calendarStyle: calendarStyle,
                        calendarBuilders: calendarBuilders,
                        onRangeSelected: (start, end, focusedDay) {
                          setModalState(() {
                            if (start != null && end != null) {
                              tempStart = start;
                              tempEnd = end;
                              if (!isRangeAvailable(start, end)) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Certaines dates sont déjà réservées ❌"),
                                  ),
                                );
                              }
                            } else if (start != null && end == null) {
                              tempStart = start;
                              tempEnd = null;
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 15),
                      ElevatedButton(
                        onPressed: () {
                          if (tempStart != null && tempEnd != null && isRangeAvailable(tempStart!, tempEnd!)) {
                            setState(() {
                              _selectedStartDate = tempStart;
                              _selectedEndDate = tempEnd;
                              _calculateTotal();
                            });
                            Navigator.pop(context);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                behavior: SnackBarBehavior.floating,
                                margin: EdgeInsets.symmetric(horizontal: 20, vertical: 300),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                backgroundColor: const Color(0xFFFF9966),
                                duration: const Duration(seconds: 3),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.warning, color: Colors.red, size: 40),
                                    const SizedBox(height: 8),
                                    Text(
                                      "La plage sélectionnée n'est pas disponible.",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE36830)),
                        child: Text(
                          'Confirmer',
                          style: TextStyle(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.w300,
                            color: Colors.white,
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

  // ---------- Calcul du prix ----------
  void _calculateTotal() {
    if (_selectedStartDate != null && _selectedEndDate != null) {
      _totalNights = _selectedEndDate!.difference(_selectedStartDate!).inDays;
      if (_totalNights <= 0) {
        _totalNights = 1;
      }

      final double prixProprietaire = double.tryParse(
        widget.appartement['prix_proprietaire']?.toString() ?? '0',
      ) ?? 0.0;

      final double fraisService = double.tryParse(
        widget.appartement['frais_service']?.toString() ?? '0',
      ) ?? 0.0;

      final result = price_utils.calculerPrixAvecReduction(
        prixProprietaire: prixProprietaire,
        fraisService: fraisService,
        nuits: _totalNights,
      );
      _totalPrice = result['total'] ?? 0.0;
    } else {
      _totalNights = 0;
      _totalPrice = 0.0;
    }
  }

  // ---------- Build ----------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFFFF0E5),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (_isInitialLoad && snapshot.connectionState == ConnectionState.waiting) {
            return _buildSkeletonLoading();
          }
          if (snapshot.hasError) {
            return _buildErrorView(snapshot.error.toString());
          }
          if (snapshot.hasData) {
            final data = snapshot.data!;
            final List<Map<String, dynamic>> infos =
            List<Map<String, dynamic>>.from(data[_cacheKeyInfos] ?? []);
            final List<Map<String, dynamic>> roles =
            List<Map<String, dynamic>>.from(data[_cacheKeyRoles] ?? []);
            final List<String> photos = List<String>.from(data[_cacheKeyPhotos] ?? []);
            final Map<String, DateTime?>? disponibilite = data[_cacheKeyDisponibilite] != null
                ? Map<String, DateTime?>.from(data[_cacheKeyDisponibilite] as Map)
                : null;

            return Stack(
              children: [
                _headerImage(photos),
                _content(
                  context,
                  infos.isNotEmpty ? infos.first : null,
                  roles.isNotEmpty ? roles.first : null,
                  disponibilite,
                ),
                _bottomBar(context),
                _backButton(context),
                if (snapshot.connectionState == ConnectionState.waiting && !_isInitialLoad)
                  _buildPartialLoadingOverlay(),
              ],
            );
          }
          return _buildSkeletonLoading();
        },
      ),
    );
  }

  // ---------- Widgets ----------
  Widget _headerImage(List<String> photos) {
    return SizedBox(
      height: 300.h,
      width: double.infinity,
      child: photos.isNotEmpty
          ? Stack(
        children: [
          PageView.builder(
            itemCount: photos.length,
            onPageChanged: (index) {
              setState(() {
                _currentImageIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final img = photos[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FullScreenGallery(
                        photos: photos,
                        initialIndex: index,
                      ),
                    ),
                  );
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.r),
                  child: img.startsWith('http')
                      ? Image.network(
                    img,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    loadingBuilder: (context, child, progress) {
                      return progress == null
                          ? child
                          : Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFE85D26),
                          strokeWidth: 2,
                        ),
                      );
                    },
                    errorBuilder: (_, _, _) => Container(
                      color: Colors.grey[200],
                      child: const Icon(
                        Icons.broken_image,
                        size: 50,
                        color: Colors.grey,
                      ),
                    ),
                  )
                      : Image.asset(
                    img,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (_, _, _) => Container(
                      color: Colors.grey[200],
                      child: const Icon(
                        Icons.broken_image,
                        size: 50,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          Positioned(
            bottom: 60.h,
            right: 20.w,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0x6A),
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(
                "${_currentImageIndex + 1} / ${photos.length}",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      )
          : Container(
        color: Colors.grey[200],
        child: const Center(child: Icon(Icons.image, size: 50, color: Colors.grey)),
      ),
    );
  }

  Widget _content(
      BuildContext context,
      Map<String, dynamic>? info,
      Map<String, dynamic>? role,
      Map<String, DateTime?>? disponibilite,
      ) {
    return DraggableScrollableSheet(
      initialChildSize: 0.71,
      minChildSize: 0.71,
      maxChildSize: 0.95,
      snap: true,
      snapSizes: const [0.71, 0.75, 0.95],
      builder: (_, controller) {
        return Container(
          padding: EdgeInsets.only(top: 5.h),
          decoration: const BoxDecoration(
            color: Color(0xFFFFEFE0),
            borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
          ),
          child: ListView(
            controller: controller,
            physics: const ClampingScrollPhysics(),
            children: [
              _title(),
              _statusRow(disponibilite),
              _apartmentRoomsSection(info),
              SizedBox(height: 5.h),
              _features(info, role),
              Divider(
                height: 20.h,
                color: const Color(0xFF8A4E1E),
                indent: 20,
                endIndent: 20,
                thickness: 1,
              ),
              _description(),
              Divider(
                height: 20.h,
                color: const Color(0xFF8A4E1E),
                indent: 20,
                endIndent: 20,
                thickness: 1,
              ),
              _autresEquipements(),
              Divider(
                height: 20.h,
                color: const Color(0xFF8A4E1E),
                indent: 20,
                endIndent: 20,
                thickness: 1,
              ),
              _rules(context, role),
              Divider(
                height: 20.h,
                color: const Color(0xFF8A4E1E),
                indent: 20,
                endIndent: 20,
                thickness: 1,
              ),
              _ratingSection(),
              Divider(
                height: 20.h,
                color: const Color(0xFF8A4E1E),
                indent: 20,
                endIndent: 20,
                thickness: 1,
              ),
              _location(),
              SizedBox(height: 80.h),
            ],
          ),
        );
      },
    );
  }

  Widget _title() {
    final title = widget.appartement['titre']?.toString() ?? 'Titre inconnu';
    return Center(
      child: Transform.translate(
        offset: const Offset(0, -20),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Text(
            title,
            style: TextStyle(fontSize: 26.sp, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Widget _statusRow(Map<String, DateTime?>? disponibilite) {
    bool isDisponible = _checkDisponibilite(disponibilite);
    final status = widget.appartement['status']?.toString() ?? 'disponible';
    if (status == 'refuse' || status == 'en_attente') {
      isDisponible = false;
    }

    final String id = widget.appartement['id'].toString();
    final isFavorite = context.watch<FavoritesService>().isFavorite(id);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Chip(
            label: Text(
              isDisponible ? 'Disponible' : 'Indisponible',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
                color: Colors.white,
              ),
            ),
            backgroundColor: isDisponible ? const Color(0xFF51C32F) : const Color(0xFF8A0000),
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
          ),
          SizedBox(width: 100.w),
          IconButton(
            icon: Icon(Icons.share, size: 35.sp),
            onPressed: () async {
              final titre = widget.appartement['titre'] ?? 'Appartement';
              final description = widget.appartement['description'] ?? '';
              final photos = List<String>.from(_cachedData[_cacheKeyPhotos] ?? []);
              final imageUrl = photos.isNotEmpty ? photos.first : '';
              try {
                if (imageUrl.isNotEmpty) {
                  final response = await http.get(Uri.parse(imageUrl));
                  final bytes = response.bodyBytes;
                  final tempDir = await getTemporaryDirectory();
                  final file = File('${tempDir.path}/appartement.jpg');
                  await file.writeAsBytes(bytes);
                  final textToShare =
                      "$titre\n${description.length > 100 ? description.substring(0, 100) + '...' : description}";
                  await Share.shareXFiles(
                    [XFile(file.path)],
                    text: textToShare,
                    subject: titre,
                  );
                } else {
                  Share.share(
                      "$titre\n${description.length > 100 ? description.substring(0, 100) + '...' : description}");
                }
              } catch (e) {
                throw ('Erreur partage: $e');
              }
            },
          ),
          GestureDetector(
            onTap: () {
              context.read<FavoritesService>().toggleFavorite(id);
            },
            child: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              size: 40.sp,
              color: isFavorite ? Colors.red : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  bool _checkDisponibilite(Map<String, DateTime?>? disponibilite) {
    if (disponibilite == null) {
      return false;
    }
    final dateDebut = disponibilite['date_debut'];
    final dateFin = disponibilite['date_fin'];
    if (dateDebut == null || dateFin == null) {
      return false;
    }
    final now = DateTime.now();
    return dateDebut.isAfter(now.subtract(const Duration(days: 30))) ||
        dateFin.isAfter(now);
  }

  Widget _apartmentRoomsSection(Map<String, dynamic>? info) {
    final type = widget.appartement['type']?.toString() ?? 'Type...';
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 10.h),
        child: Wrap(
          spacing: 8.w,
          runSpacing: 15.h,
          alignment: WrapAlignment.center,
          children: [
            RoomInfoItem(icon: Icons.apartment_outlined, label: type, value: '', width: 80.w),
            RoomInfoItem(
              icon: Icons.stairs_outlined,
              label: 'Étage',
              value: info?['etage']?.toString() ?? '',
              width: 110.w,
            ),
            RoomInfoItem(
              icon: Icons.weekend_outlined,
              label: 'Salon',
              value: info?['salon']?.toString() ?? '',
              width: 90.w,
            ),
            RoomInfoItem(
              icon: Icons.king_bed_outlined,
              label: 'Chbres',
              value: info?['chambre']?.toString() ?? '',
              width: 120.w,
            ),
            RoomInfoItem(
              icon: Icons.bathtub_outlined,
              label: 'Pièces',
              value: info?['douche']?.toString() ?? '',
              width: 100.w,
            ),
            RoomInfoItem(
              icon: Icons.kitchen_outlined,
              label: 'Cuisine',
              value: info?['cuisine']?.toString() ?? '',
              width: 110.w,
            ),
          ],
        ),
      ),
    );
  }

  Widget _features(Map<String, dynamic>? info, Map<String, dynamic>? role) {
    String ouiNon(dynamic value) {
      if (value == null) {
        return 'Non';
      }
      final v = value.toString().toLowerCase().trim();
      if (v.contains('animaux')) {
        return (v.contains('chien') || v.contains('chat') || v.contains('accept')) ? 'Oui' : 'Non';
      }
      if (v.contains('fumeur')) {
        return v.contains('accept') ? 'Oui' : 'Non';
      }
      if (v.contains('fête') || v.contains('fete')) {
        return v.contains('accept') ? 'Oui' : 'Non';
      }
      return (v == 'oui' ||
          v == 'true' ||
          v == '1' ||
          v.contains('accept') ||
          v.contains('yes') ||
          v.contains('accepter'))
          ? 'Oui'
          : 'Non';
    }

    return Container(
      color: const Color(0xFFFFEFE0),
      height: 350.h,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: 25.w, vertical: 10.h),
        child: Row(
          children: [
            FeatureCard(
              width: 230.w,
              title: 'Aperçu',
              items: [
                FeatureItemData(
                  Icons.flash_on,
                  'Service inclus',
                  ouiNon(info?['service_inclus']),
                ),
                FeatureItemData(
                  Icons.wifi,
                  'Internet',
                  ouiNon(info?['internet']),
                ),
                FeatureItemData(
                  Icons.local_parking,
                  'Stationnement',
                  ouiNon(info?['stationnement']),
                ),
                FeatureItemData(
                  Icons.pets,
                  'Animaux',
                  ouiNon(role?['animaux']),
                ),
              ],
            ),
            SizedBox(width: 30.w),
            FeatureCard(
              width: 250.w,
              title: "L'unité d'habitation",
              items: [
                FeatureItemData(
                  Icons.straighten,
                  'Taille',
                  '${info?['taille']?.toString() ?? '0'} m²',
                ),
                FeatureItemData(
                  Icons.chair,
                  'Meublé',
                  ouiNon(info?['meuble']),
                ),
                FeatureItemData(
                  Icons.ac_unit,
                  'Climatisation',
                  ouiNon(info?['climatisation']),
                ),
                FeatureItemData(
                  Icons.smoking_rooms,
                  'Fumeurs acceptés',
                  ouiNon(role?['fumeur']),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _description() {
    final description =
        widget.appartement['description']?.toString() ?? 'Pas de description...';
    return Padding(
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('A propos', style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold)),
          SizedBox(height: 10.h),
          Text(
            description,
            maxLines: _isExpanded ? null : 4,
            overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
            style: TextStyle(fontSize: 16.sp, color: const Color(0xE58A4E1E)),
          ),
          if (description.length > 150)
            GestureDetector(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              child: Padding(
                padding: EdgeInsets.only(top: 8.h),
                child: Text(
                  _isExpanded ? 'Voir moins' : 'Voir plus',
                  style: TextStyle(
                    color: const Color(0xFFE85D26),
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _autresEquipements() {
    final data = widget.appartement['autres_equipements'];
    Map<String, dynamic> raw = {};
    if (data is Map) {
      raw = Map<String, dynamic>.from(data);
    } else if (data is String && data.isNotEmpty) {
      try {
        raw = Map<String, dynamic>.from(jsonDecode(data));
      } catch (e) {
        return const SizedBox.shrink();
      }
    }

    final Set<String> equipementsActifs =
    raw.entries.where((e) => e.value == true).map((e) => e.key.toString()).toSet();
    final List<Map<String, dynamic>> tousLesEquipements = [];
    for (final categoryKey in EquipementsCategories.data.keys) {
      final category = EquipementsCategories.data[categoryKey];
      final items = category['items'] as Map<String, dynamic>;
      for (final itemKey in items.keys) {
        tousLesEquipements.add({
          'key': itemKey,
          'label': EquipementsCategories.getLabelForKey(itemKey),
          'icon': EquipementsCategories.getIconForKey(itemKey),
          'actif': equipementsActifs.contains(itemKey),
        });
      }
    }

    final actifs = tousLesEquipements.where((item) => item['actif'] == true).toList();
    final preview = actifs.take(5).toList();
    final restants = actifs.length - 5;
    final hasMore = restants > 0;

    return Padding(
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Autres équipements",
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE85D26),
            ),
          ),
          const SizedBox(height: 12),
          ...preview.map((item) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(item['icon'], size: 24, color: const Color(0xFFE36830)),
                  const SizedBox(width: 12),
                  Text(item['label'], style: const TextStyle(fontSize: 16, color: Color(0xE58A4E1E))),
                ],
              ),
            );
          }),
          const SizedBox(height: 16),
          Center(
            child: Container(
              width: 320.w,
              height: 50.h,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF16522), Color(0xFFC5521B)],
                ),
                borderRadius: BorderRadius.circular(25.r),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFFE36830).withValues(alpha: 0x3A),
                    blurRadius: 2,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFE36830),
                  foregroundColor: Colors.white,
                  shadowColor: Color(0x80E36830),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25.r)),
                ),
                onPressed: () {
                  _showAllEquipementsModal(tousLesEquipements);
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      hasMore
                          ? 'Voir les $restants autres équipements'
                          : 'Voir tous les ${actifs.length} équipements',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Icon(Icons.arrow_forward, size: 20.sp),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAllEquipementsModal(List<Map<String, dynamic>> tousLesEquipements) {
    if (tousLesEquipements.isEmpty) {
      return;
    }
    final Map<String, List<Map<String, dynamic>>> equipementsParCategorie = {};
    for (final item in tousLesEquipements) {
      final key = item['key'];
      final categoryKey = EquipementsCategories.getCategoryForKey(key);
      if (categoryKey != null) {
        equipementsParCategorie.putIfAbsent(categoryKey, () => []);
        equipementsParCategorie[categoryKey]!.add(item);
      }
    }
    final categories = equipementsParCategorie.keys.toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.4,
          builder: (_, controller) {
            return Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              decoration: const BoxDecoration(
                color: Color(0xFFFFF5EC),
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  Row(
                    children: [
                      const Text(
                        "Autres équipements",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFE85D26),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        icon: Icon(Icons.close, size: 22, color: Colors.grey[500]),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: ListView.builder(
                      controller: controller,
                      itemCount: categories.length,
                      itemBuilder: (context, index) {
                        final categoryKey = categories[index];
                        final items = equipementsParCategorie[categoryKey]!;
                        final category = EquipementsCategories.data[categoryKey];
                        if (category == null) {
                          return const SizedBox.shrink();
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                category['label'],
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xE58A4E1E),
                                ),
                              ),
                              const SizedBox(height: 6),
                              ...items.map((item) {
                                final isActive = item['actif'] == true;
                                final description = EquipementsCategories.getDescriptionForKey(
                                  item['key'],
                                  isActive: isActive,
                                );
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(
                                            item['icon'],
                                            size: 30,
                                            color: isActive
                                                ? const Color(0xFFE36830)
                                                : Color(0xBE8A4E1E),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              item['label'],
                                              style: TextStyle(
                                                fontSize: 18,
                                                color: isActive
                                                    ? Color(0xE58A4E1E)
                                                    : Color(0xBE8A4E1E),
                                                decoration: isActive
                                                    ? null
                                                    : TextDecoration.lineThrough,
                                                decorationColor: const Color(0xBE8A4E1E),
                                                decorationThickness: 2.0,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (description.isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(left: 28, top: 2),
                                          child: Text(
                                            description,
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Color(0xB38A4E1E),
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _rules(BuildContext context, Map<String, dynamic>? role) {
    return Padding(
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Les règles de l'appartement",
            style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10.h),
          if (role != null) ...[
            if (role['heure_arrive'] != null)
              Text(
                'Arrivée à partir de : ${role['heure_arrive']}',
                style: TextStyle(fontSize: 16.sp, color: Color(0xE58A4E1E)),
              ),
            if (role['heure_depart'] != null)
              Text(
                'Départ avant : ${role['heure_depart']}',
                style: TextStyle(fontSize: 16.sp, color: Color(0xE58A4E1E)),
              ),
            if (role['nombre_client'] != null)
              Text(
                '${role['nombre_client']} clients maximum',
                style: TextStyle(fontSize: 16.sp, color: Color(0xE58A4E1E)),
              ),
          ] else ...[
            Text('Aucune règle définie', style: TextStyle(fontSize: 16.sp)),
          ],
          SizedBox(height: 25.h),
          _buildDateSelectorSection(),
          SizedBox(height: 15.h),
          Center(
            child: Container(
              width: 300.w,
              height: 50.h,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF16522), Color(0xFFC5521B)],
                ),
                borderRadius: BorderRadius.circular(25.r),
                boxShadow: [
                  BoxShadow(
                    color: Color(0xFFE36830).withValues(alpha: 0x3A),
                    blurRadius: 2,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFFE36830),
                  foregroundColor: Colors.white,
                  shadowColor: Color(0x80E36830),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25.r)),
                ),
                onPressed: () {
                  if (role != null) {
                    showRulesModal(
                      context: context,
                      appartementRole: role,
                      appartement: widget.appartement,
                    );
                  }
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Voir plus de détails',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Icon(Icons.arrow_forward, size: 20.sp),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ratingSection() {
    return StatefulBuilder(
      builder: (context, setRatingState) {
        final stats = _cachedData[_cacheKeyRatingStats] as Map<String, dynamic>? ??
            {'average': 0.0, 'count': 0};
        final double average = stats['average'] ?? 0.0;
        final int count = stats['count'] ?? 0;
        final int? currentRating = _cachedData[_cacheKeyUserRating] as int?;

        return Padding(
          padding: EdgeInsets.all(16.r),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Avis & Expérience",
                style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8.h),
              Row(
                children: [
                  Icon(Icons.star_rounded, color: Colors.amber, size: 24.sp),
                  SizedBox(width: 4.w),
                  Text(
                    average > 0 ? average.toStringAsFixed(1) : "Aucune note",
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF673A15),
                    ),
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    "($count avis)",
                    style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              Center(
                child: Container(
                  width: 300.w,
                  height: 50.h,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF16522), Color(0xFFC5521B)],
                    ),
                    borderRadius: BorderRadius.circular(25.r),
                  ),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE36830),
                      foregroundColor: Colors.white,
                      shadowColor: const Color(0x80E36830),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25.r),
                      ),
                    ),
                    onPressed: () {
                      _openRatingDialog(
                        onRatingSubmitted: () {
                          setRatingState(() {});
                        },
                      );
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          currentRating != null
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          size: 24.sp,
                          color: Colors.amber,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          currentRating != null
                              ? "Modifier ma note ($currentRating/5)"
                              : "Noter l'appartement",
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDateSelectorSection() {
    final pricePerNight =
        double.tryParse(widget.appartement['prix']?.toString() ?? '0') ?? 0.0;
    final status = _getDateStatus();
    final statusColor = _getStatusColor(status);
    final statusMessage = _getStatusMessage(status);

    Map<String, double> reductions = {};
    if (_selectedStartDate != null && _selectedEndDate != null) {
      final double prixProprietaire = double.tryParse(
        widget.appartement['prix_proprietaire']?.toString() ?? '0',
      ) ?? 0.0;
      final double fraisService = double.tryParse(
        widget.appartement['frais_service']?.toString() ?? '0',
      ) ?? 0.0;
      reductions = price_utils.calculerPrixAvecReduction(
        prixProprietaire: prixProprietaire,
        fraisService: fraisService,
        nuits: _totalNights,
      );
      _totalPrice = reductions['total']!;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dates de séjour',
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 12.h),
        GestureDetector(
          onTap: _openDateRangeModal,
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 20.w),
            decoration: BoxDecoration(
              color: Color(0xFFFFF5EC),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Color(0xFFFFC189), width: 1.5),
            ),
            child: Row(
              children: [
                Icon(Icons.date_range, color: Color(0xFFE36830), size: 26.sp),
                SizedBox(width: 15.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _selectedStartDate != null && _selectedEndDate != null
                            ? '${_formatDateShortFR(_selectedStartDate!)} → ${_formatDateShortFR(_selectedEndDate!)}'
                            : 'Sélectionnez vos dates',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF673A15),
                        ),
                      ),
                      if (_selectedStartDate != null && _selectedEndDate != null)
                        Padding(
                          padding: EdgeInsets.only(top: 4.h),
                          child: Text(
                            statusMessage,
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: statusColor,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_ios, size: 18.sp, color: Colors.grey),
              ],
            ),
          ),
        ),
        SizedBox(height: 20.h),
        if (_selectedStartDate != null && _selectedEndDate != null)
          Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0x1A),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: statusColor.withValues(alpha: 0x2A)),
            ),
            child: Column(
              children: [
                if (status == DateStatus.conflict)
                  Padding(
                    padding: EdgeInsets.only(bottom: 10.h),
                    child: Container(
                      padding: EdgeInsets.all(8.r),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0x1A),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange, size: 16.sp),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              statusMessage,
                              style: TextStyle(fontSize: 12.sp, color: Colors.orange[800]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Nuitées', style: TextStyle(fontSize: 14.sp)),
                    Text(
                      '$_totalNights nuit${_totalNights > 1 ? 's' : ''}',
                      style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Prix par nuit'),
                    Text(price_utils.formatPrice(pricePerNight)),
                  ],
                ),
                SizedBox(height: 8.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Réductions', style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500)),
                    Text(
                      '-${price_utils.formatPrice(reductions['totalReduction'] ?? 0)}',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                Divider(height: 20.h, color: const Color(0xFF8A4E1E), thickness: 0.5),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
                    Text(
                      price_utils.formatPrice(_totalPrice),
                      style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _location() {
    final ville = widget.appartement['ville']?.toString() ?? 'Ville inconnue';
    final adresse = widget.appartement['adresse']?.toString() ?? 'Adresse inconnue';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: 15.h, left: 15.w, right: 15.w),
          child: Text(
            'Où vous allez être',
            style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Row(
            children: [
              Icon(Icons.location_on, color: const Color(0xFFE36830), size: 18.sp),
              SizedBox(width: 4.w),
              Expanded(
                child: Text(
                  '$adresse, $ville, Mali',
                  style: TextStyle(color: const Color(0xE58A4E1E), fontSize: 16.sp),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 14.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Center(
            child: Image.asset(
              'assets/images/map.png',
              height: 450.h,
              width: 400.w,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 450.h,
                width: 400.w,
                color: Colors.grey[200],
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.map_outlined, size: 50.sp, color: Colors.grey[400]),
                      SizedBox(height: 10.h),
                      Text(
                        'Carte non disponible',
                        style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _bottomBar(BuildContext context) {
    final price = safeParsePrice(widget.appartement['prix']);
    final nbreSejour = widget.appartement['nbre_sejour']?.toString() ?? "Séjour";
    final status = _getDateStatus();
    final statusColor = _getStatusColor(status);
    bool canReserve = status == DateStatus.valid;

    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 15.w, vertical: 10.h),
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          height: 80.h,
          decoration: BoxDecoration(
            color: Color(0xFFFFE5CB),
            borderRadius: BorderRadius.circular(30.r),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE85D26).withValues(alpha: 0.25),
                blurRadius: 5,
                spreadRadius: 1.5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Prix / $nbreSejour",
                      style: TextStyle(fontSize: 13.sp, color: const Color(0xFF9C7A63)),
                    ),
                    SizedBox(height: 2.h),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: price_utils.formatPrice(price),
                            style: TextStyle(
                              color: const Color(0xFFE85D26),
                              fontWeight: FontWeight.bold,
                              fontSize: 22.sp,
                            ),
                          ),
                          TextSpan(
                            text: " Fcfa",
                            style: TextStyle(
                              color: const Color(0xFF9C7A63),
                              fontSize: 14.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 180.w,
                height: 52.h,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: status == DateStatus.valid
                        ? [Color(0xFFF16522), Color(0xFFC5521B)]
                        : [statusColor, statusColor.withValues(alpha: 0x5A)],
                  ),
                  borderRadius: BorderRadius.circular(25.r),
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25.r),
                    ),
                  ),
                  onPressed: canReserve
                      ? () {
                    final currentUser = Supabase.instance.client.auth.currentUser;
                    if (currentUser == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          behavior: SnackBarBehavior.floating,
                          margin: EdgeInsets.only(bottom: 100, left: 20, right: 20),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16.r),
                          ),
                          backgroundColor: const Color(0xFFFF0505),
                          duration: const Duration(seconds: 3),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.check_circle, color: Colors.white, size: 40.sp),
                              SizedBox(height: 8.h),
                              Text(
                                'Vous devez être connecté pour réserver',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 20.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                      return;
                    }
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReservationPage(
                          appartement: widget.appartement,
                          disponibilite: _cachedData[_cacheKeyDisponibilite],
                          startDate: _selectedStartDate,
                          endDate: _selectedEndDate,
                          totalPrice: _totalPrice,
                          totalNights: _totalNights,
                          databaseService: widget.appartementService,
                        ),
                      ),
                    );
                  }
                      : null,
                  child: Center(
                    child: Text(
                      status == DateStatus.conflict
                          ? "Déjà réservé"
                          : status == DateStatus.invalid
                          ? "Dates non autorisées"
                          : status == DateStatus.valid
                          ? "🏠 Réserver"
                          : "Sélectionnez les dates",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: status == DateStatus.valid ? 20.sp : 14.sp,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _backButton(BuildContext context) {
    return Positioned(
      top: 40.h,
      left: 15.w,
      child: CircleAvatar(
        backgroundColor: const Color(0xFFFFE5CE),
        radius: 25.r,
        child: IconButton(
          icon: Icon(Icons.arrow_back, color: const Color(0xFF8A4E1E)),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
    );
  }

  // ---------- Squelettes ----------
  Widget _buildSkeletonLoading() {
    return Scaffold(
      backgroundColor: Color(0xFFFFF0E5),
      body: Stack(
        children: [
          Container(height: 300.h, width: double.infinity, color: Color(0xFFFFF0E5)),
          DraggableScrollableSheet(
            initialChildSize: 0.75,
            minChildSize: 0.71,
            maxChildSize: 0.95,
            builder: (_, controller) {
              return Container(
                padding: EdgeInsets.only(top: 5.h),
                decoration: const BoxDecoration(
                  color: Color(0xFFFFF0E5),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
                ),
                child: ListView(
                  controller: controller,
                  physics: const ClampingScrollPhysics(),
                  children: [
                    _buildSkeletonTitle(),
                    _buildSkeletonStatusRow(),
                    _buildSkeletonRoomsSection(),
                    _buildSkeletonFeatures(),
                    const Divider(),
                    _buildSkeletonDescription(),
                    const Divider(),
                    _buildSkeletonRules(),
                    const Divider(),
                    _buildSkeletonLocation(),
                    SizedBox(height: 80.h),
                  ],
                ),
              );
            },
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Container(
                margin: EdgeInsets.only(top: 2.h, left: 15.w, right: 15.w, bottom: 10.h),
                padding: EdgeInsets.symmetric(horizontal: 20.w),
                height: 70.h,
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(25.r),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 100.w,
                          height: 20.h,
                          color: Colors.grey[300],
                          margin: EdgeInsets.only(bottom: 5.h),
                        ),
                        Container(width: 60.w, height: 15.h, color: Colors.grey[300]),
                      ],
                    ),
                    Container(
                      width: 180.w,
                      height: 50.h,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(25.r),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 40.h,
            left: 15.w,
            child: CircleAvatar(backgroundColor: Colors.grey[300], radius: 25.r),
          ),
        ],
      ),
    );
  }

  Widget _buildPartialLoadingOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0x3A),
        child: const Center(
          child: CircularProgressIndicator(
            color: Color(0xFFE85D26),
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }

  Widget _buildSkeletonTitle() => Center(
    child: Transform.translate(
      offset: const Offset(0, -20),
      child: Container(
        width: 200.w,
        height: 30.h,
        color: Colors.grey[300],
        margin: EdgeInsets.symmetric(horizontal: 20.w),
      ),
    ),
  );

  Widget _buildSkeletonStatusRow() => Padding(
    padding: EdgeInsets.symmetric(vertical: 2.h),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Container(
          width: 100.w,
          height: 30.h,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(20.r),
          ),
        ),
        SizedBox(width: 100.w),
        CircleAvatar(backgroundColor: Colors.grey[300], radius: 20.r),
        CircleAvatar(backgroundColor: Colors.grey[300], radius: 20.r),
      ],
    ),
  );

  Widget _buildSkeletonRoomsSection() => Padding(
    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 10.h),
    child: Wrap(
      spacing: 8.w,
      runSpacing: 15.h,
      children: List.generate(6, (index) => SizedBox(
        width: 80.w,
        child: Column(
          children: [
            Container(width: 30.w, height: 30.h, color: Colors.grey[300]),
            SizedBox(height: 5.h),
            Container(width: 40.w, height: 10.h, color: Colors.grey[300]),
            SizedBox(height: 3.h),
            Container(width: 60.w, height: 8.h, color: Colors.grey[300]),
          ],
        ),
      )),
    ),
  );

  Widget _buildSkeletonFeatures() => SizedBox(
    height: 320.h,
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.symmetric(horizontal: 25.w, vertical: 12.h),
      child: Row(
        children: [
          _buildSkeletonFeatureCard(),
          SizedBox(width: 30.w),
          _buildSkeletonFeatureCard(),
        ],
      ),
    ),
  );

  Widget _buildSkeletonFeatureCard() => Container(
    width: 220.w,
    decoration: BoxDecoration(
      color: const Color(0xFFFFEFE6),
      borderRadius: BorderRadius.circular(16.r),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.1),
          blurRadius: 3,
          offset: const Offset(0, 1),
        ),
      ],
    ),
    padding: EdgeInsets.only(top: 20.h, right: 10.w, left: 15.w, bottom: 20.h),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(width: 100.w, height: 20.h, color: Colors.grey[300]),
        SizedBox(height: 12.h),
        ...List.generate(
          4,
              (index) => Padding(
            padding: EdgeInsets.only(bottom: 14.h),
            child: Row(
              children: [
                Container(width: 22.w, height: 22.h, color: Colors.grey[300]),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(width: 120.w, height: 15.h, color: Colors.grey[300]),
                      SizedBox(height: 2.h),
                      Container(width: 60.w, height: 15.h, color: Colors.grey[300]),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );

  Widget _buildSkeletonDescription() => Padding(
    padding: EdgeInsets.all(16.r),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(width: 100.w, height: 25.h, color: Colors.grey[300]),
        SizedBox(height: 10.h),
        Container(width: double.infinity, height: 60.h, color: Colors.grey[200]),
      ],
    ),
  );

  Widget _buildSkeletonRules() => Padding(
    padding: EdgeInsets.all(16.r),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(width: 200.w, height: 25.h, color: Colors.grey[300]),
        SizedBox(height: 10.h),
        Container(width: 250.w, height: 15.h, color: Colors.grey[200]),
        SizedBox(height: 5.h),
        Container(width: 200.w, height: 15.h, color: Colors.grey[200]),
      ],
    ),
  );

  Widget _buildSkeletonLocation() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: EdgeInsets.only(top: 15.h, left: 15.w, right: 15.w),
        child: Container(width: 150.w, height: 25.h, color: Colors.grey[300]),
      ),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Container(width: 200.w, height: 15.h, color: Colors.grey[200]),
      ),
      SizedBox(height: 14.h),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Center(
          child: Container(height: 450.h, width: 400.w, color: Colors.grey[200]),
        ),
      ),
    ],
  );

  Widget _buildErrorView(String error) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 50, color: Colors.red),
            SizedBox(height: 16.h),
            Text(
              'Erreur de chargement',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 8.h),
            Text(
              'Détails: $error',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
            ),
            SizedBox(height: 20.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  onPressed: _refreshData,
                  child: const Text('Réessayer'),
                ),
                SizedBox(width: 10.w),
                OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Retour'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}