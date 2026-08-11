import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:service/rating/rating_service.dart';
import 'package:service/rating/rating_widget.dart';
import 'package:service/database_service.dart';
import 'package:service/snackbar_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:table_calendar/table_calendar.dart';

import '../inscription/connexion.dart';
import '../utils/date_utils.dart';
import '../utils/reservation_utils.dart';
import '../favorite_appart/favorites_service.dart';
import '../reservation/reservation.dart';
import '../reservation/price_utils.dart' as price_utils;
import '../widgets/confirmation_modal.dart';
import '../widgets/room_info_item.dart';
import '../widgets/full_screen_gallery.dart';
import '../widgets/reservation_skeletons.dart';

enum DateStatus { none, valid, invalid, conflict }

num safeParsePrice(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value;
  if (value is String) return num.tryParse(value) ?? 0;
  return 0;
}

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

  int _selectedRating = 0;
  final TextEditingController _commentController = TextEditingController();
  int _currentImageIndex = 0;
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  int _totalNights = 0;
  double _totalPrice = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeCache();
    _loadData();
    _calculateTotal();
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
        _selectedStartDate = DateTime.tryParse(debut.toString());
        _selectedEndDate = DateTime.tryParse(fin.toString());
        _calculateTotal();
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    context.read<FavoritesService>();
  }

  // ============ CHARGEMENT DES DONNÉES ============
  Future<Map<String, dynamic>> _loadDataSequentially() async {
    final String appartementId = widget.appartement['id'].toString();
    final Map<String, dynamic> result = {};

    try {
      // ⭐ 1. Charger l'appartement complet pour avoir prix_proprietaire et frais_service
      if (!_cachedData.containsKey(_cacheKeyAppartement)) {
        final appartementComplet = await widget.appartementService.supabase
            .from('appartements')
            .select('*')
            .eq('id', appartementId)
            .single();
        _cachedData[_cacheKeyAppartement] = appartementComplet;
      }
      // déjà en cache, on ne fait rien

      // 2. Photos
      if (!_cachedData.containsKey(_cacheKeyPhotos)) {
        result[_cacheKeyPhotos] = await widget.appartementService.loadPhotoUrls(appartementId);
        _cachedData[_cacheKeyPhotos] = result[_cacheKeyPhotos];
      } else {
        result[_cacheKeyPhotos] = _cachedData[_cacheKeyPhotos];
      }

      // 3. Réservations
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

      // 4. Infos, rôles, disponibilité
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

      // 5. Note utilisateur
      if (!_cachedData.containsKey(_cacheKeyUserRating)) {
        final userRating = await RatingService().getUserRating(appartementId);
        result[_cacheKeyUserRating] = userRating;
        _cachedData[_cacheKeyUserRating] = userRating;
        if (userRating != null) _selectedRating = userRating;
      } else {
        result[_cacheKeyUserRating] = _cachedData[_cacheKeyUserRating];
      }

      // 6. Statistiques de notation
      if (!_cachedData.containsKey(_cacheKeyRatingStats)) {
        final stats = await RatingService().getAppartmentStats(appartementId);
        result[_cacheKeyRatingStats] = stats;
        _cachedData[_cacheKeyRatingStats] = stats;
      } else {
        result[_cacheKeyRatingStats] = _cachedData[_cacheKeyRatingStats];
      }

      // 7. Remplir les clés manquantes avec les données du cache
      for (final key in [
        _cacheKeyInfos,
        _cacheKeyRoles,
        _cacheKeyDisponibilite,
        _cacheKeyReservations,
        _cacheKeyUserRating,
        _cacheKeyRatingStats,
      ]) {
        if (!result.containsKey(key) && _cachedData.containsKey(key)) {
          result[key] = _cachedData[key];
        }
      }

      // 8. Valeurs par défaut
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
        _cacheKeyUserRating: _cachedData[_cacheKeyUserRating],
        _cacheKeyRatingStats: _cachedData[_cacheKeyRatingStats] ?? {'average': 0.0, 'count': 0},
        _cacheKeyAppartement: _cachedData[_cacheKeyAppartement] ?? {},
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

  // ============ GESTION DES DATES ============
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

  Map<String, dynamic> _checkReservationConflict(DateTime startDate, DateTime endDate) {
    final reservations = _cachedData[_cacheKeyReservations] as List<dynamic>? ?? [];
    if (reservations.isEmpty) return {'hasConflict': false, 'type': 'none'};

    final normalizedStart = DateTime(startDate.year, startDate.month, startDate.day);
    final normalizedEnd = DateTime(endDate.year, endDate.month, endDate.day);

    for (final reservation in reservations) {
      try {
        final reservationStart = reservation['date_debut'];
        final reservationEnd = reservation['date_fin'];
        if (reservationStart == null || reservationEnd == null) continue;

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

  // ============ CALCUL DU PRIX (utilise price_utils) ============
  void _calculateTotal() {
    if (_selectedStartDate == null || _selectedEndDate == null) return;

    final appartement = _cachedData[_cacheKeyAppartement] as Map<String, dynamic>?;
    if (appartement == null) return;

    final nuits = _selectedEndDate!.difference(_selectedStartDate!).inDays;
    if (nuits <= 0) return;

    final prixProprietaire = double.tryParse(
      appartement['prix_proprietaire']?.toString() ?? '0',
    ) ?? 0.0;
    final fraisService = double.tryParse(
      appartement['frais_service']?.toString() ?? '0',
    ) ?? 0.0;

    final reductions = price_utils.calculerPrixAvecReduction(
      prixProprietaire: prixProprietaire,
      fraisService: fraisService,
      nuits: nuits,
    );

    setState(() {
      _totalPrice = reductions['total']!;
    });
  }

  // ============ GESTION DES NOTES ============
  Future<List<Map<String, dynamic>>> _getRatingStats() async {
    try {
      final appartementId = widget.appartement['id'].toString();
      final response = await Supabase.instance.client
          .from('ratings')
          .select('rating')
          .eq('appartement_id', appartementId);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Erreur chargement ratings: $e');
      return [];
    }
  }

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
      builder: (context) {
        int localRating = cachedUserRating;
        return AlertDialog(
          backgroundColor: const Color(0xFFFFF0E5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
          title: Text(
            'Votre évaluation',
            style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: const Color(0xFF673A15)),
            textAlign: TextAlign.center,
          ),
          content: StatefulBuilder(
            builder: (context, setDialogState) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        icon: Icon(
                          index < localRating ? Icons.star_rounded : Icons.star_border_rounded,
                          color: Colors.amber,
                          size: 36.sp,
                        ),
                        onPressed: () {
                          setDialogState(() {
                            localRating = index + 1;
                          });
                        },
                      );
                    }),
                  ),
                  SizedBox(height: 15.h),
                  TextField(
                    controller: _commentController,
                    maxLines: 3,
                    style: TextStyle(fontSize: 15.sp, color: const Color(0xFF673A15)),
                    decoration: InputDecoration(
                      hintText: 'Ajouter un commentaire (optionnel)...',
                      hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14.sp),
                      filled: true,
                      fillColor: const Color(0xFFFFEFE0),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.r),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Color(0xFFE36830), width: 1.5),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          actionsAlignment: MainAxisAlignment.spaceEvenly,
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Annuler', style: TextStyle(color: Colors.grey.shade600, fontSize: 16.sp)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE36830),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
              ),
              onPressed: () {
                setState(() {
                  _selectedRating = localRating;
                });
                Navigator.pop(context);
                _submitRating().then((_) {
                  if (onRatingSubmitted != null) {
                    onRatingSubmitted();
                  }
                });
              },
              child: Text(
                'Confirmer',
                style: TextStyle(color: Colors.white, fontSize: 16.sp, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitRating() async {
    final String appartementId = widget.appartement['id'].toString();
    try {
      await RatingService().submitRating(
        appartementId: appartementId,
        rating: _selectedRating,
        comment: _commentController.text.trim().isNotEmpty ? _commentController.text.trim() : null,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF51C32F),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10.w),
              const Text('Évaluation enregistrée avec succès ! 🎉'),
            ],
          ),
        ),
      );
      _commentController.clear();
      setState(() {
        _cachedData[_cacheKeyUserRating] = _selectedRating;
        final stats = _cachedData[_cacheKeyRatingStats] as Map<String, dynamic>? ?? {'average': 0.0, 'count': 0};
        final count = (stats['count'] as int? ?? 0) + 1;
        final newAverage = ((stats['average'] as double? ?? 0.0) * (count - 1) + _selectedRating) / count;
        _cachedData[_cacheKeyRatingStats] = {'average': newAverage, 'count': count};
      });
      _loadData();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
          content: Text('Une erreur est survenue : $e'),
        ),
      );
    }
  }

  // ============ ACTIONS ============
  Future<void> _modifyReservationDates() async {
    final status = determineReservationStatus(widget.reservation!);
    if (status != ReservationStatus.enAttente) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Vous ne pouvez modifier que les réservations en attente'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final currentStart = _selectedStartDate;
    final currentEnd = _selectedEndDate;
    if (currentStart == null || currentEnd == null) return;

    final freshReservations = await widget.appartementService
        .getReservationsByAppartement(widget.appartement['id'].toString());
    if (!mounted) return;

    setState(() {
      _cachedData[_cacheKeyReservations] = freshReservations;
    });

    DateTime? tempStart = currentStart;
    DateTime? tempEnd = currentEnd;
    final disponibilite = _cachedData[_cacheKeyDisponibilite];

    final Set<DateTime> reservedDates = _getReservedDates();
    for (DateTime d = currentStart; d.isBefore(currentEnd); d = d.add(const Duration(days: 1))) {
      reservedDates.remove(DateTime(d.year, d.month, d.day));
    }

    const CalendarStyle calendarStyle = CalendarStyle(
      todayDecoration: BoxDecoration(color: Color(0xFFFF1D1D), shape: BoxShape.circle),
      rangeStartDecoration: BoxDecoration(color: Color(0xFFC5521B), shape: BoxShape.circle),
      rangeEndDecoration: BoxDecoration(color: Color(0xFFC5521B), shape: BoxShape.circle),
      withinRangeDecoration: BoxDecoration(color: Color(0xFFC5521B), shape: BoxShape.circle),
    );

    final CalendarBuilders calendarBuilders = CalendarBuilders(
      defaultBuilder: (context, day, focusedDay) {
        final normalized = DateTime(day.year, day.month, day.day);
        if (reservedDates.contains(normalized)) {
          return Container(
            margin: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.22), shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text('${day.day}', style: const TextStyle(color: Colors.white)),
          );
        }
        return null;
      },
    );

    bool isRangeAvailable(DateTime start, DateTime end) {
      for (final reserved in reservedDates) {
        if (!reserved.isBefore(start) && !reserved.isAfter(end)) {
          return false;
        }
      }
      return true;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
                        decoration: BoxDecoration(color: const Color(0xE5E3B28A), borderRadius: BorderRadius.circular(10)),
                      ),
                      Text('Modifier les dates', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
                      if (disponibilite != null && disponibilite['date_debut'] != null)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 5),
                          child: Text(
                            'Disponible à partir du ${formatDateFrench(disponibilite['date_debut']!)}',
                            style: TextStyle(fontSize: 12.sp, color: const Color(0xE58A4E1E), fontWeight: FontWeight.w500),
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
                                  const SnackBar(content: Text("Certaines dates sont déjà réservées ❌")),
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              if (mounted) {
                                Navigator.pop(context);
                              }
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                            child: Text('Annuler', style: TextStyle(fontSize: 16.sp, color: Colors.white)),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              if (tempStart != null && tempEnd != null && isRangeAvailable(tempStart!, tempEnd!)) {
                                try {
                                  final reservationId = widget.reservation!['id'].toString();
                                  final newNights = tempEnd!.difference(tempStart!).inDays;

                                  await widget.appartementService.updateReservationDates(
                                    reservationId: reservationId,
                                    dateDebut: tempStart!.toIso8601String(),
                                    dateFin: tempEnd!.toIso8601String(),
                                    nuits: newNights,
                                  );

                                  if (!mounted) return;

                                  setState(() {
                                    _selectedStartDate = tempStart;
                                    _selectedEndDate = tempEnd;
                                    _totalNights = newNights;
                                    _calculateTotal();
                                    widget.reservation!['date_debut'] = tempStart!.toIso8601String();
                                    widget.reservation!['date_fin'] = tempEnd!.toIso8601String();
                                    widget.reservation!['nuits'] = newNights;
                                  });

                                  if (modalContext.mounted) {
                                    Navigator.pop(modalContext);
                                  }
                                  _loadData();

                                  if (mounted) {
                                    _showAppSnackBar(
                                      message: '✅ Dates modifiées avec succès !',
                                      type: SnackBarType.success,
                                    );
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    _showAppSnackBar(
                                      message: '❌ Erreur: $e',
                                      type: SnackBarType.error,
                                    );
                                  }
                                }
                              } else {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      behavior: SnackBarBehavior.floating,
                                      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 300),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      backgroundColor: const Color(0xFFFF9966),
                                      duration: const Duration(seconds: 3),
                                      content: const Text(
                                        "La plage sélectionnée n'est pas disponible.",
                                        textAlign: TextAlign.center,
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                      ),
                                    ),
                                  );
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE36830)),
                            child: Text(
                              'Confirmer',
                              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w300, color: Colors.white),
                            ),
                          ),
                        ],
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

  Future<void> _downloadReservationReceipt() async {
    try {
      final reservation = widget.reservation!;
      final checkIn = reservation['check_in']?.toString() ?? '14:00';
      final checkOut = reservation['check_out']?.toString() ?? '12:00';

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
Arrivée: ${formatDateLong(reservation['date_debut']?.toString())} (à partir de $checkIn)
Départ: ${formatDateLong(reservation['date_fin']?.toString())} (avant $checkOut)
Nombre de nuits: ${reservation['nuits']?.toString() ?? _totalNights.toString()}

--- DÉTAILS FINANCIERS ---
Prix par nuit: ${price_utils.formatPrice(double.tryParse(widget.appartement['prix']?.toString() ?? '0') ?? 0)} FCFA
Total à payer: ${price_utils.formatPrice(_totalPrice)} FCFA

--- STATUT ---
${reservation['status'] ?? 'Confirmé'}

========================================
     MERCI DE VOTRE CONFIANCE !
========================================
      ''';

      final tempDir = await getTemporaryDirectory();
      final file = File(
          '${tempDir.path}/reservation_${reservation['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch}.txt');
      await file.writeAsString(receiptContent);

      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text:
          'Voici votre récapitulatif de réservation pour ${widget.appartement['titre']}',
          subject: 'Réservation - ${widget.appartement['titre']}',
        ),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10.w),
              const Text('Récapitulatif téléchargé avec succès !'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      debugPrint('Erreur téléchargement: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showAppSnackBar({
    required String message,
    required SnackBarType type,
    Duration duration = const Duration(seconds: 4),
  }) {
    switch (type) {
      case SnackBarType.success:
        SnackBarService().showSuccess(message, duration: duration);
        break;
      case SnackBarType.error:
        SnackBarService().showError(message, duration: duration);
        break;
      case SnackBarType.warning:
        SnackBarService().showWarning(message, duration: duration);
        break;
      case SnackBarType.info:
        SnackBarService().showInfo(message, duration: duration);
        break;
    }
  }

  Future<void> _cancelReservation() async {
    showConfirmationModal(
      context: context,
      title: 'Annuler la réservation',
      message: 'Êtes-vous sûr de vouloir annuler cette réservation ? Cette action est irréversible.',
      confirmText: 'Oui, annuler',
      type: ConfirmationType.delete,
      onConfirm: _handleCancelReservation,
    );
  }

  Future<void> _handleCancelReservation() async {
    try {
      await widget.appartementService.cancelReservation(
        widget.reservation!['id'].toString(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10.w),
              const Text('Réservation annulée avec succès'),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.pop(context);
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _contactSupport() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contacter le support'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.phone, color: Color(0xFFE36830)),
              title: const Text('Appeler'),
              subtitle: const Text('+223 XX XX XX XX'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.email, color: Color(0xFFE36830)),
              title: const Text('Email'),
              subtitle: const Text('support@example.com'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat, color: Color(0xFFE36830)),
              title: const Text('Chat en direct'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _resetAndBookAgain() {
    setState(() {
      _selectedStartDate = null;
      _selectedEndDate = null;
      _totalNights = 0;
      _totalPrice = 0.0;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Sélectionnez de nouvelles dates pour réserver'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  DateTime _calculateFreeCancellationDate(DateTime startDate) {
    return startDate.subtract(const Duration(days: 2));
  }

  // ============ BUILD ============
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF0E5),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (_isInitialLoad && snapshot.connectionState == ConnectionState.waiting) {
            return buildSkeletonLoading();
          }
          if (snapshot.hasError) {
            return _buildErrorView(snapshot.error.toString());
          }
          if (snapshot.hasData) {
            final data = snapshot.data!;
            final List<Map<String, dynamic>> infos = List<Map<String, dynamic>>.from(data[_cacheKeyInfos] ?? []);
            final List<Map<String, dynamic>> roles = List<Map<String, dynamic>>.from(data[_cacheKeyRoles] ?? []);
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
          return buildSkeletonLoading();
        },
      ),
    );
  }

  // ============ WIDGETS ============
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
                onTap: () => _openFullScreenGallery(photos, index),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12.r),
                  child: img.startsWith('http')
                      ? Image.network(
                    img,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          color: const Color(0xFFE85D26),
                          strokeWidth: 2,
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
                      ),
                    ),
                  )
                      : Image.asset(
                    img,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: Icon(Icons.broken_image, size: 50, color: Colors.grey),
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
                color: Colors.black.withValues(alpha: 0x41A),
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
          Positioned(
            left: 15.w,
            bottom: 60.h,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on, color: Colors.white, size: 18),
                  SizedBox(width: 5.w),
                  Text(
                    widget.appartement['adresse'] ?? '',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                  ),
                ],
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

  void _openFullScreenGallery(List<String> photos, int initialIndex) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullScreenGallery(photos: photos, initialIndex: initialIndex),
      ),
    );
  }

  Widget _content(
      BuildContext context,
      Map<String, dynamic>? appartementInfo,
      Map<String, dynamic>? appartementRole,
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
              _apartmentRoomsSection(appartementInfo),
              SizedBox(height: 5.h),
              if (widget.reservation != null) _buildDatesDuSejourContainer(),
              SizedBox(height: 5.h),
              _buildPriceDetailsSection(),
              _buildAmenitiesSection(appartementInfo, appartementRole),
              _ratingSection(),
              SizedBox(height: 100.h),
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
    final String id = widget.appartement['id'].toString();
    final isFavorite = context.watch<FavoritesService>().isFavorite(id);

    ReservationStatus? reservationStatus;
    Map<String, dynamic>? cfg;

    if (widget.reservation != null) {
      reservationStatus = determineReservationStatus(widget.reservation!);
      cfg = getStatusConfig(reservationStatus);
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 2.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (widget.reservation != null && cfg != null)
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: cfg['bg'],
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(color: cfg['border'], width: 1),
              ),
              child: Row(
                children: [
                  Container(width: 6.w, height: 6.h, decoration: BoxDecoration(color: cfg['dot'], shape: BoxShape.circle)),
                  SizedBox(width: 6.w),
                  Text(
                    cfg['label'],
                    style: TextStyle(
                      color: cfg['text'],
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          const Spacer(),
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

                  final textToShare = "$titre\n${description.length > 100 ? '${description.substring(0, 100)}...' : description}";
                  await SharePlus.instance.share(
                    ShareParams(
                      files: [XFile(file.path)],
                      text: textToShare,
                      subject: titre,
                    ),
                  );
                } else {
                  await SharePlus.instance.share(
                    ShareParams(
                      text:
                      "$titre\n${description.length > 100 ? '${description.substring(0, 100)}...' : description}",
                    ),
                  );
                }
              } catch (e) {
                debugPrint('Erreur partage: $e');
              }
            },
          ),
          GestureDetector(
            onTap: () => context.read<FavoritesService>().toggleFavorite(id),
            child: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              size: 35.sp,
              color: isFavorite ? Colors.red : Colors.grey.shade500,
            ),
          ),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _getRatingStats(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const SizedBox(width: 40, height: 20);
              }
              final ratings = snapshot.data!;
              final sum = ratings.fold<int>(0, (sum, r) => sum + (r['rating'] as int));
              final average = sum / ratings.length;
              final count = ratings.length;
              if (count == 0) {
                return const SizedBox(width: 40);
              }
              return Padding(
                padding: EdgeInsets.only(left: 8.w),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star, size: 35.sp, color: Colors.amber),
                    SizedBox(width: 4.w),
                    Text(
                      average.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _apartmentRoomsSection(Map<String, dynamic>? appartementInfo) {
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
            RoomInfoItem(icon: Icons.stairs_outlined, label: 'Étage', value: appartementInfo?['etage']?.toString() ?? '', width: 110.w),
            RoomInfoItem(icon: Icons.weekend_outlined, label: 'Salon', value: appartementInfo?['salon']?.toString() ?? '', width: 90.w),
            RoomInfoItem(icon: Icons.king_bed_outlined, label: 'Chbres', value: appartementInfo?['chambre']?.toString() ?? '', width: 120.w),
            RoomInfoItem(icon: Icons.bathtub_outlined, label: 'Pièces', value: appartementInfo?['douche']?.toString() ?? '', width: 100.w),
            RoomInfoItem(icon: Icons.kitchen_outlined, label: 'Cuisine', value: appartementInfo?['cuisine']?.toString() ?? '', width: 110.w),
          ],
        ),
      ),
    );
  }

  Widget _buildAmenitiesSection(Map<String, dynamic>? appartementInfo, Map<String, dynamic>? appartementRole) {
    final Map<String, Map<String, dynamic>> amenities = {
      'wifi': {'icon': Icons.wifi, 'label': 'Wi-Fi', 'value': appartementInfo?['internet']},
      'parking': {'icon': Icons.local_parking, 'label': 'Parking', 'value': appartementInfo?['stationnement']},
      'climatisation': {'icon': Icons.ac_unit, 'label': 'Climatisation', 'value': appartementInfo?['climatisation']},
      'meuble': {'icon': Icons.chair, 'label': 'Meublé', 'value': appartementInfo?['meuble']},
      'service': {'icon': Icons.flash_on, 'label': 'Service inclus', 'value': appartementInfo?['service_inclus']},
      'animaux': {'icon': Icons.pets, 'label': 'Animaux acceptés', 'value': appartementRole?['animaux']},
      'fumeur': {'icon': Icons.smoking_rooms, 'label': 'Fumeurs acceptés', 'value': appartementRole?['fumeur']},
    };

    final availableAmenities = amenities.entries.where((entry) {
      final value = entry.value['value'];
      if (value == null) return false;
      final v = value.toString().toLowerCase().trim();
      return v == 'oui' || v == 'true' || v == '1' || v.contains('accept') || v.contains('yes') || v.contains('accepter');
    }).toList();

    if (availableAmenities.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.w),
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0x03A),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Équipements inclus", style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600, color: Colors.grey[800])),
          SizedBox(height: 16.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            children: availableAmenities.map((entry) {
              return Container(
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4ED),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(entry.value['icon'], size: 14.sp, color: const Color(0xFFFF6B00)),
                    SizedBox(width: 6.w),
                    Text(entry.value['label'], style: TextStyle(fontSize: 11.sp, color: Colors.grey[700])),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDatesDuSejourContainer() {
    final checkIn = widget.reservation?['check_in']?.toString() ?? '14:00';
    final checkOut = widget.reservation?['check_out']?.toString() ?? '12:00';
    final nights = widget.reservation?['nuits']?.toString() ?? _totalNights.toString();

    final dateDebut = widget.reservation?['date_debut'] != null
        ? DateTime.tryParse(widget.reservation!['date_debut'].toString())
        : null;

    final status = determineReservationStatus(widget.reservation!);

    return Column(
      children: [
        Container(
          margin: EdgeInsets.all(16.w),
          padding: EdgeInsets.all(20.r),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF5EC),
            borderRadius: BorderRadius.circular(24.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0x03A),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text("Dates du séjour", style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600, color: Colors.grey[800])),
                  if (status == ReservationStatus.enAttente)
                    GestureDetector(
                      onTap: _modifyReservationDates,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE36830),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.edit, size: 14.sp, color: Colors.white),
                            SizedBox(width: 4.w),
                            Text("Modifier", style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600, color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              SizedBox(height: 16.h),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.all(12.r),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF4ED),
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(color: const Color(0xFFFF6B00), width: 2),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Arrivée", style: TextStyle(fontSize: 10.sp, color: Colors.grey[500])),
                            SizedBox(height: 4.h),
                            Text(
                              formatDateLong(widget.reservation?['date_debut']?.toString()),
                              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500, color: Colors.grey[900]),
                            ),
                            SizedBox(height: 4.h),
                            Text("à partir de $checkIn", style: TextStyle(fontSize: 10.sp, color: Colors.grey[400])),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 60.w,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.arrow_forward, size: 20, color: Colors.grey),
                          SizedBox(height: 4.h),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF6B00),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Text("$nights nuits", style: const TextStyle(color: Colors.white, fontSize: 10)),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Container(
                        padding: EdgeInsets.all(12.r),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Départ", style: TextStyle(fontSize: 10.sp, color: Colors.grey[500])),
                            SizedBox(height: 4.h),
                            Text(
                              formatDateLong(widget.reservation?['date_fin']?.toString()),
                              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500, color: Colors.grey[900]),
                            ),
                            SizedBox(height: 4.h),
                            Text("avant $checkOut", style: TextStyle(fontSize: 10.sp, color: Colors.grey[400])),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (status != ReservationStatus.terminee && dateDebut != null)
          _buildCancellationInfo(dateDebut),
        if (status == ReservationStatus.terminee)
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 20.sp),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text('✅ Séjour terminé', style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold, color: Colors.green.shade800)),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildCancellationInfo(DateTime startDate) {
    final freeCancelDate = _calculateFreeCancellationDate(startDate);
    final now = DateTime.now();
    final isFree = now.isBefore(freeCancelDate);

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      padding: EdgeInsets.all(12.r),
      decoration: BoxDecoration(
        color: isFree ? const Color(0xFFE8F5E9) : const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: isFree ? Colors.green.shade300 : Colors.orange.shade300,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isFree ? Icons.check_circle_outline : Icons.info_outline,
            color: isFree ? Colors.green : Colors.orange,
            size: 20.sp,
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isFree ? '✅ Annulation gratuite' : '⚠️ Annulation avec frais',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                    color: isFree ? Colors.green.shade800 : Colors.orange.shade800,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  isFree
                      ? 'Annulation gratuite jusqu\'au ${formatDateFrench(freeCancelDate)}'
                      : 'L\'annulation est gratuite jusqu\'au ${formatDateFrench(freeCancelDate)}. Passé cette date, des frais peuvent s\'appliquer.',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: isFree ? Colors.green.shade600 : Colors.orange.shade700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Section détail du prix (utilise price_utils) ---
  Widget _buildPriceDetailsSection() {
    if (widget.reservation == null) return const SizedBox.shrink();

    // Récupérer l'appartement depuis le cache
    final appartement = _cachedData[_cacheKeyAppartement] as Map<String, dynamic>?;
    if (appartement == null) return const SizedBox.shrink();

    final dateDebut = _selectedStartDate ?? DateTime.now().add(const Duration(days: 1));
    final dateFin = _selectedEndDate ?? dateDebut.add(const Duration(days: 2));
    final totalNuits = dateFin.difference(dateDebut).inDays;
    final nuits = totalNuits <= 0 ? 1 : totalNuits;

    final prixProprietaire = double.tryParse(
      appartement['prix_proprietaire']?.toString() ?? '0',
    ) ?? 0.0;
    final fraisService = double.tryParse(
      appartement['frais_service']?.toString() ?? '0',
    ) ?? 0.0;
    final prixParNuit = double.tryParse(
      appartement['prix']?.toString() ?? '0',
    ) ?? 0.0;

    // Calcul avec réduction
    final reductions = price_utils.calculerPrixAvecReduction(
      prixProprietaire: prixProprietaire,
      fraisService: fraisService,
      nuits: nuits,
    );

    final reductionProprio = reductions['reductionProprietaire']!;
    final reductionService = reductions['reductionService']!;
    final totalProprioAvant = prixProprietaire * totalNuits;
    final totalServiceAvant = fraisService * totalNuits;
    final fraisDuProApres = totalProprioAvant - reductionProprio;
    final fraisServiceApres = totalServiceAvant - reductionService;

    _totalPrice = reductions['total']!;   // mise à jour de la variable d’état
    final prixSansReduction = prixParNuit * nuits;
    final economie = prixSansReduction - _totalPrice;

    // Widget local pour une ligne de prix
    Widget buildPriceRow(String label, String value, {bool isTotal = false}) {
      return Padding(
        padding: EdgeInsets.only(bottom: 12.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: isTotal ? 16.sp : 14.sp,
                fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
                color: isTotal ? Colors.black : Colors.grey[600],
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: isTotal ? 18.sp : 14.sp,
                fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                color: isTotal ? const Color(0xFFFF6B00) : Colors.grey[700],
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.w),
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Détail du prix", style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600, color: Colors.grey[800])),
          SizedBox(height: 16.h),

          buildPriceRow('Nuitées', '$nuits nuit${nuits > 1 ? 's' : ''}'),
          buildPriceRow('Prix par nuit', price_utils.formatPrice(prixParNuit)),
          buildPriceRow('Sous-total', price_utils.formatPrice(prixSansReduction)),

          if (economie > 0)
            Padding(
              padding: EdgeInsets.only(bottom: 12.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Réduction', style: TextStyle(fontSize: 14.sp, color: Colors.green)),
                  Text('- ${price_utils.formatPrice(economie)}',
                      style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold, color: Colors.green)),
                ],
              ),
            ),

          buildPriceRow('Frais du propriétaire', price_utils.formatPrice(fraisDuProApres)),
          buildPriceRow('Frais de service', price_utils.formatPrice(fraisServiceApres)),

          Divider(color: Colors.grey[200], height: 24.h),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold)),
              IntrinsicWidth(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      price_utils.formatPrice(_totalPrice),
                      style: TextStyle(fontSize: 22.sp, fontWeight: FontWeight.bold, color: const Color(0xFFFF7B32)),
                    ),
                    Container(height: 3, color: const Color(0xFFFF7B32)),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 16.h),

          // Mention paiement à l'arrivée
          Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4ED),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Row(
              children: [
                const Icon(Icons.credit_card, size: 16, color: Color(0xFFFF6B00)),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text("Paiement à l'arrivée", style: TextStyle(fontSize: 12.sp, color: Colors.grey[600])),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B00),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: const Text("En espèces", style: TextStyle(color: Colors.white, fontSize: 10)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _ratingSection() {
    return StatefulBuilder(
      builder: (context, setRatingState) {
        final stats = _cachedData[_cacheKeyRatingStats] as Map<String, dynamic>? ?? {'average': 0.0, 'count': 0};
        final double average = stats['average'] ?? 0.0;
        final int count = stats['count'] ?? 0;
        final int? currentRating = _cachedData[_cacheKeyUserRating] as int?;

        return RatingSection(
          average: average,
          count: count,
          currentUserRating: currentRating,
          onRatePressed: () {
            _openRatingDialog(
              onRatingSubmitted: () {
                setRatingState(() {});
              },
            );
          },
        );
      },
    );
  }

  // ==================== BARRE DU BAS ====================
  Widget _bottomBar(BuildContext context) {
    if (widget.reservation != null) {
      final status = determineReservationStatus(widget.reservation!);

      if (status == ReservationStatus.confirmee) {
        return _buildBottomBarLayout(
          leftWidget: Container(
            height: 48.h,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF51C32F), Color(0xFF3D8B40)],
              ),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 8.w),
                Text("Réservation confirmée", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.sp, color: Colors.white)),
              ],
            ),
          ),
          rightWidget: Container(
            height: 48.h,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF16522), Color(0xFFC5521B)],
              ),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
              ),
              onPressed: _downloadReservationReceipt,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.file_download_rounded, size: 18.sp, color: Colors.white),
                  SizedBox(width: 6.w),
                  Text("Reçu", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.sp, color: Colors.white)),
                ],
              ),
            ),
          ),
          contentOffset: -15.h,
        );
      }

      if (status == ReservationStatus.enAttente) {
        return _buildBottomBarLayout(
          leftWidget: SizedBox(
            height: 48.h,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.grey, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
              ),
              onPressed: _cancelReservation,
              child: Text("Annuler la réservation", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600, fontSize: 14.sp)),
            ),
          ),
          rightWidget: Container(
            height: 48.h,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF16522), Color(0xFFC5521B)],
              ),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
              ),
              onPressed: _contactSupport,
              child: Text("Contacter", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.sp, color: Colors.white)),
            ),
          ),
          contentOffset: -15.h,
        );
      }

      if (status == ReservationStatus.terminee) {
        return _buildBottomBarLayout(
          leftWidget: SizedBox(
            height: 48.h,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFE85D26), width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
              ),
              onPressed: () => _openRatingDialog(),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.star_rate_rounded, size: 18.sp, color: const Color(0xFFE85D26)),
                  SizedBox(width: 6.w),
                  Text("Laisser un avis", style: TextStyle(color: const Color(0xFFE85D26), fontWeight: FontWeight.w600, fontSize: 14.sp)),
                ],
              ),
            ),
          ),
          rightWidget: Container(
            height: 48.h,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFF16522), Color(0xFFC5521B)],
              ),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
              ),
              onPressed: _resetAndBookAgain,
              child: Text("Réserver à nouveau", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.sp, color: Colors.white)),
            ),
          ),
          contentOffset: -15.h,
        );
      }
    }

    // Barre par défaut
    final price = safeParsePrice(widget.appartement['prix']);
    final nbreSejour = widget.appartement['nbre_sejour']?.toString() ?? "Séjour";
    final dateStatus = _getDateStatus();
    final statusColor = _getStatusColor(dateStatus);
    bool canReserve = dateStatus == DateStatus.valid;

    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          margin: EdgeInsets.symmetric(horizontal: 15.w, vertical: 10.h),
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          height: 80.h,
          decoration: BoxDecoration(
            color: const Color(0xFFFFE5CB),
            borderRadius: BorderRadius.circular(30.r),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE85D26).withValues(alpha: 0x25A),
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
                    Text("Prix / $nbreSejour", style: TextStyle(fontSize: 13.sp, color: const Color(0xFF9C7A63))),
                    SizedBox(height: 2.h),
                    RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(text: price_utils.formatPrice(price), style: TextStyle(color: const Color(0xFFE85D26), fontWeight: FontWeight.bold, fontSize: 22.sp)),
                          TextSpan(text: " Fcfa", style: TextStyle(color: const Color(0xFF9C7A63), fontSize: 14.sp)),
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
                    colors: dateStatus == DateStatus.valid
                        ? [const Color(0xFFF16522), const Color(0xFFC5521B)]
                        : [statusColor, statusColor.withValues(alpha: 0x35A)],
                  ),
                  borderRadius: BorderRadius.circular(25.r),
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25.r)),
                  ),
                  onPressed: canReserve
                      ? () {
                    final currentUser = Supabase.instance.client.auth.currentUser;
                    if (currentUser == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          behavior: SnackBarBehavior.floating,
                          margin: const EdgeInsets.only(bottom: 100, left: 20, right: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
                          backgroundColor: const Color(0xFFFF0505),
                          duration: const Duration(seconds: 3),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.error_outline, color: Colors.white, size: 40),
                              SizedBox(height: 8.h),
                              Text('Vous devez être connecté pour réserver', textAlign: TextAlign.center, style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: Colors.white)),
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
                      dateStatus == DateStatus.conflict
                          ? "Déjà réservé"
                          : dateStatus == DateStatus.invalid
                          ? "Dates non autorisées"
                          : dateStatus == DateStatus.valid
                          ? "🏠 Réserver"
                          : "Sélectionnez les dates",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: dateStatus == DateStatus.valid ? 20.sp : 14.sp,
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

  Widget _buildBottomBarLayout({
    required Widget leftWidget,
    required Widget rightWidget,
    double contentOffset = 0,
  }) {
    return SafeArea(
      child: Transform.translate(
        offset: Offset(0, 25.h),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            width: double.infinity,
            height: 120.h,
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: const Color(0xFFFFE5CB),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE85D26).withValues(alpha: 0.15),
                  blurRadius: 8,
                  spreadRadius: 2,
                  offset: const Offset(0, -3),
                ),
              ],
              borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
            ),
            child: Transform.translate(
              offset: Offset(0, contentOffset),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(width: 200.w, height: 48.h, child: leftWidget),
                  SizedBox(width: 12.w),
                  SizedBox(width: 140.w, height: 48.h, child: rightWidget),
                ],
              ),
            ),
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
          icon: const Icon(Icons.arrow_back, color: Color(0xFF8A4E1E)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }

  Widget _buildPartialLoadingOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0x22A),
        child: const Center(
          child: CircularProgressIndicator(color: Color(0xFFE85D26), strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _buildErrorView(String error) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(20.r),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 50, color: Colors.red),
            SizedBox(height: 16.h),
            Text('Erreur de chargement', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w500)),
            SizedBox(height: 8.h),
            Text('Détails: $error', textAlign: TextAlign.center, style: TextStyle(fontSize: 14.sp, color: Colors.grey[600])),
            SizedBox(height: 20.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(onPressed: _refreshData, child: const Text('Réessayer')),
                SizedBox(width: 10.w),
                OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Retour')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}