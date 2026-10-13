import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'notification_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({
    super.key,
  });

  @override
  State<NotificationsPage> createState() =>
      _NotificationsPageState();
}

class _NotificationsPageState
    extends State<NotificationsPage> {
  // COULEURS
  static const Color accentColor =
  Color(0xFFE85D26);

  static const Color backgroundColor =
  Color(0xFFFFEFE0);

  static const Color cardColor =
  Color(0xFFFFF8F3);

  static const Color textColor =
  Color(0xFF4A2C1A);

  // SERVICE
  final NotificationService
  _notificationService =
  NotificationService();

  StreamSubscription<
      NotificationRealtimeEvent>?
  _subscription;

  // ============================================================
  // DONNÉES
  // ============================================================

  List<Map<String, dynamic>>
  _notifications = [];

  bool _isLoading = true;

  bool _isRefreshing = false;

  // ============================================================
  // FILTRE
  // ============================================================

  String _selectedFilter = 'Toutes';

  final List<String> _filters = [
    'Toutes',
    'Non lues',
    'Réservations',
    'Système',
  ];

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _subscription =
        _notificationService.events.listen(
          _handleRealtimeEvent,
        );

    _initialize();
  }

  // INITIALISATION
  Future<void> _initialize() async {
    await _loadNotifications();

    await _notificationService
        .startRealtime();
  }

  // ============================================================
  // CHARGEMENT
  // ============================================================

  Future<void> _loadNotifications() async {
    try {
      final notifications =
      await _notificationService
          .getNotifications();

      if (!mounted) return;

      setState(() {
        _notifications =
            notifications;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint(
        '❌ Erreur notifications : $e',
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      _showSnackBar(
        'Impossible de charger les notifications.',
      );
    }
  }

  // ============================================================
  // REFRESH
  // ============================================================

  Future<void> _refresh() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    await _loadNotifications();

    if (!mounted) return;

    setState(() {
      _isRefreshing = false;
    });
  }

  // ============================================================
  // REALTIME
  // ============================================================

  void _handleRealtimeEvent(
      NotificationRealtimeEvent event,
      ) {
    if (!mounted) return;

    setState(() {
      switch (event.type) {
      // ------------------------------------------------------
      // INSERT
      // ------------------------------------------------------

        case NotificationRealtimeType.inserted:
          final notification =
              event.notification;

          if (notification == null) {
            return;
          }

          final id =
          notification['id']
              ?.toString();

          final exists =
          _notifications.any(
                (item) =>
            item['id']?.toString() ==
                id,
          );

          if (!exists) {
            _notifications.insert(
              0,
              notification,
            );
          }

          break;

      // ------------------------------------------------------
      // UPDATE
      // ------------------------------------------------------

        case NotificationRealtimeType.updated:
          final notification =
              event.notification;

          if (notification == null) {
            return;
          }

          final id =
          notification['id']
              ?.toString();

          final index =
          _notifications.indexWhere(
                (item) =>
            item['id']?.toString() ==
                id,
          );

          if (index != -1) {
            _notifications[index] =
                notification;
          }

          break;

      // ------------------------------------------------------
      // DELETE
      // ------------------------------------------------------

        case NotificationRealtimeType.deleted:
          final id =
              event.notificationId;

          if (id != null) {
            _notifications.removeWhere(
                  (item) =>
              item['id']?.toString() ==
                  id,
            );
          }

          break;
      }
    });
  }

  // ============================================================
  // FILTRAGE
  // ============================================================

  List<Map<String, dynamic>>
  get _filteredNotifications {
    switch (_selectedFilter) {
      case 'Non lues':
        return _notifications
            .where(
              (notification) =>
          notification['is_read'] !=
              true,
        )
            .toList();

      case 'Réservations':
        return _notifications
            .where(
              (notification) =>
          notification['type']
              ?.toString() ==
              'reservation',
        )
            .toList();

      case 'Système':
        return _notifications
            .where(
              (notification) {
            final type =
            notification['type']
                ?.toString()
                .toLowerCase();

            return type == 'system' ||
                type == 'info' ||
                type == 'certification';
          },
        )
            .toList();

      default:
        return List<
            Map<String, dynamic>>.from(
          _notifications,
        );
    }
  }

  // ============================================================
  // COMPTEUR
  // ============================================================

  int get _unreadCount {
    return _notifications
        .where(
          (notification) =>
      notification['is_read'] !=
          true,
    )
        .length;
  }

  // ============================================================
  // MARQUER LU
  // ============================================================

  Future<void> _markAsRead(
      Map<String, dynamic>
      notification,
      ) async {
    final id =
    notification['id']?.toString();

    if (id == null) return;

    if (notification['is_read'] == true) {
      return;
    }

    // Mise à jour immédiate de l'interface
    setState(() {
      notification['is_read'] = true;
      notification['read_at'] =
          DateTime.now()
              .toUtc()
              .toIso8601String();
    });

    try {
      await _notificationService
          .markAsRead(id);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        notification['is_read'] = false;
        notification['read_at'] = null;
      });

      _showSnackBar(
        'Impossible de marquer la notification.',
      );
    }
  }

  // ============================================================
  // TOUT LIRE
  // ============================================================

  Future<void> _markAllAsRead() async {
    if (_unreadCount == 0) {
      return;
    }

    try {
      await _notificationService
          .markAllAsRead();

      if (!mounted) return;

      setState(() {
        for (final notification
        in _notifications) {
          notification['is_read'] = true;
          notification['read_at'] =
              DateTime.now()
                  .toUtc()
                  .toIso8601String();
        }
      });

      _showSnackBar(
        'Toutes les notifications sont lues.',
      );
    } catch (e) {
      _showSnackBar(
        'Impossible de tout marquer comme lu.',
      );
    }
  }

  // ============================================================
  // SUPPRIMER
  // ============================================================

  Future<void> _deleteNotification(
      Map<String, dynamic>
      notification,
      ) async {
    final id =
    notification['id']?.toString();

    if (id == null) return;

    try {
      await _notificationService
          .deleteNotification(id);

      if (!mounted) return;

      setState(() {
        _notifications.removeWhere(
              (item) =>
          item['id']?.toString() ==
              id,
        );
      });
    } catch (e) {
      _showSnackBar(
        'Impossible de supprimer la notification.',
      );
    }
  }

  // ============================================================
  // SUPPRIMER TOUT
  // ============================================================

  Future<void> _deleteAll() async {
    if (_notifications.isEmpty) {
      return;
    }

    final confirmed =
    await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(
              18.r,
            ),
          ),
          title: Text(
            'Supprimer toutes les notifications ?',
            style: GoogleFonts.poppins(
              fontWeight:
              FontWeight.w700,
              color: textColor,
              fontSize: 17.sp,
            ),
          ),
          content: Text(
            'Cette action est irréversible.',
            style: GoogleFonts.poppins(
              color:
              Colors.black54,
              fontSize: 13.sp,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(
                    context,
                    false,
                  ),
              child: Text(
                'Annuler',
                style: GoogleFonts.poppins(
                  color:
                  Colors.black54,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pop(
                    context,
                    true,
                  ),
              style:
              ElevatedButton.styleFrom(
                backgroundColor:
                Colors.red,
              ),
              child: const Text(
                'Supprimer',
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      await _notificationService
          .deleteAllNotifications();

      if (!mounted) return;

      setState(() {
        _notifications.clear();
      });

      _showSnackBar(
        'Notifications supprimées.',
      );
    } catch (e) {
      _showSnackBar(
        'Impossible de supprimer les notifications.',
      );
    }
  }

  // ============================================================
  // ICÔNE
  // ============================================================

  IconData _getIcon(
      String? type,
      ) {
    switch (type) {
      case 'reservation':
        return Icons.calendar_month_rounded;

      case 'payment':
        return Icons.payments_rounded;

      case 'certification':
        return Icons.verified_rounded;

      case 'appartement_publie':
        return Icons.home_work_rounded;

      case 'appartement_soumis':
        return Icons.home_work_outlined;

      case 'appartement_refuse':
        return Icons.home_work_outlined;

      case 'message':
        return Icons.message_rounded;

      case 'promotion':
        return Icons.local_offer_rounded;

      case 'system':
        return Icons.settings_rounded;

      default:
        return Icons.notifications_rounded;
    }
  }

  // ============================================================
  // COULEUR ICÔNE
  // ============================================================

  Color _getIconColor(
      String? type,
      ) {
    switch (type) {
      case 'reservation':
        return accentColor;

      case 'payment':
        return Colors.green;

      case 'certification':
        return Colors.blue;

      case 'appartement_refuse':
        return Colors.red;

      case 'appartement_publie':
        return Colors.green;

      case 'message':
        return Colors.indigo;

      default:
        return accentColor;
    }
  }

  // ============================================================
  // DATE
  // ============================================================

  String _formatDate(
      String? value,
      ) {
    if (value == null ||
        value.isEmpty) {
      return '';
    }

    final date =
    DateTime.tryParse(value);

    if (date == null) {
      return '';
    }

    final local =
    date.toLocal();

    final difference =
    DateTime.now()
        .difference(local);

    if (difference.inSeconds < 60) {
      return 'À l’instant';
    }

    if (difference.inMinutes < 60) {
      return 'Il y a ${difference.inMinutes} min';
    }

    if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours} h';
    }

    if (difference.inDays == 1) {
      return 'Hier à ${DateFormat('HH:mm').format(local)}';
    }

    if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jours';
    }

    return DateFormat(
      'dd/MM/yyyy à HH:mm',
      'fr_FR',
    ).format(local);
  }

  // ============================================================
  // SNACKBAR
  // ============================================================

  void _showSnackBar(
      String message,
      ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
        accentColor,
      ),
    );
  }

  // ============================================================
  // CARD NOTIFICATION
  // ============================================================

  Widget _buildNotificationCard(
      Map<String, dynamic>
      notification,
      ) {
    final bool isRead =
        notification['is_read'] == true;

    final String message =
        notification['message']
            ?.toString() ??
            'Notification';

    final String? type =
    notification['type']
        ?.toString();

    final String date =
    _formatDate(
      notification['created_at']
          ?.toString(),
    );

    final icon =
    _getIcon(type);

    final iconColor =
    _getIconColor(type);

    return Dismissible(
      key: ValueKey(
        notification['id']
            ?.toString(),
      ),
      direction:
      DismissDirection.endToStart,
      confirmDismiss:
          (_) async {
        await _deleteNotification(
          notification,
        );

        return false;
      },
      background: Container(
        margin: EdgeInsets.only(
          bottom: 10.h,
        ),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius:
          BorderRadius.circular(
            18.r,
          ),
        ),
        alignment:
        Alignment.centerRight,
        padding:
        EdgeInsets.only(
          right: 22.w,
        ),
        child: Icon(
          Icons.delete_outline,
          color: Colors.white,
          size: 25.sp,
        ),
      ),
      child: GestureDetector(
        onTap: () =>
            _markAsRead(
              notification,
            ),
        child: Container(
          margin: EdgeInsets.only(
            bottom: 10.h,
          ),
          padding:
          EdgeInsets.all(15.w),
          decoration: BoxDecoration(
            color: isRead
                ? cardColor
                : Colors.white,
            borderRadius:
            BorderRadius.circular(
              18.r,
            ),
            border: Border.all(
              color: isRead
                  ? const Color(
                0xFFF1DDD0,
              )
                  : accentColor
                  .withValues(
                alpha: 0.35,
              ),
              width:
              isRead ? 1 : 1.3,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black
                    .withValues(
                  alpha:
                  isRead
                      ? 0.03
                      : 0.06,
                ),
                blurRadius: 10,
                offset:
                const Offset(
                  0,
                  4,
                ),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              // ------------------------------------------------
              // ICÔNE
              // ------------------------------------------------

              Container(
                width: 48.w,
                height: 48.w,
                decoration:
                BoxDecoration(
                  color:
                  iconColor.withValues(
                    alpha: 0.10,
                  ),
                  shape:
                  BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color:
                  iconColor,
                  size: 23.sp,
                ),
              ),

              SizedBox(
                width: 12.w,
              ),

              // ------------------------------------------------
              // CONTENU
              // ------------------------------------------------

              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
                  children: [
                    Row(
                      crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                      children: [
                        Expanded(
                          child: Text(
                            message,
                            style: GoogleFonts
                                .poppins(
                              color:
                              textColor,
                              fontSize:
                              13.5.sp,
                              fontWeight:
                              isRead
                                  ? FontWeight.w500
                                  : FontWeight.w700,
                              height: 1.35,
                            ),
                          ),
                        ),

                        if (!isRead)
                          Container(
                            width:
                            8.w,
                            height:
                            8.w,
                            margin:
                            EdgeInsets.only(
                              left: 8.w,
                              top: 5.h,
                            ),
                            decoration:
                            const BoxDecoration(
                              color:
                              accentColor,
                              shape:
                              BoxShape.circle,
                            ),
                          ),
                      ],
                    ),

                    SizedBox(
                      height: 7.h,
                    ),

                    Text(
                      date,
                      style:
                      GoogleFonts.poppins(
                        color:
                        Colors.black45,
                        fontSize:
                        11.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // FILTRES
  // ============================================================

  Widget _buildFilters() {
    return SizedBox(
      height: 42.h,
      child: ListView.separated(
        scrollDirection:
        Axis.horizontal,
        itemCount:
        _filters.length,
        separatorBuilder:
            (_, _) =>
            SizedBox(
              width: 8.w,
            ),
        itemBuilder:
            (context, index) {
          final filter =
          _filters[index];

          final selected =
              filter ==
                  _selectedFilter;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedFilter =
                    filter;
              });
            },
            child: AnimatedContainer(
              duration:
              const Duration(
                milliseconds: 200,
              ),
              padding:
              EdgeInsets.symmetric(
                horizontal: 15.w,
              ),
              alignment:
              Alignment.center,
              decoration:
              BoxDecoration(
                color: selected
                    ? accentColor
                    : Colors.white,
                borderRadius:
                BorderRadius.circular(
                  22.r,
                ),
                border: Border.all(
                  color: selected
                      ? accentColor
                      : const Color(
                    0xFFE8D5C8,
                  ),
                ),
              ),
              child: Text(
                filter,
                style:
                GoogleFonts.poppins(
                  color: selected
                      ? Colors.white
                      : textColor,
                  fontSize:
                  12.sp,
                  fontWeight:
                  FontWeight.w600,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
      BuildContext context,
      ) {
    final notifications =
        _filteredNotifications;

    return Scaffold(
      backgroundColor:
      backgroundColor,

      appBar: AppBar(
        backgroundColor:
        backgroundColor,
        elevation: 0,
        surfaceTintColor:
        Colors.transparent,

        leading: IconButton(
          onPressed: () =>
              Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: textColor,
            size: 20.sp,
          ),
        ),

        title: Text(
          'Notifications',
          style: GoogleFonts.poppins(
            color: textColor,
            fontSize: 19.sp,
            fontWeight:
            FontWeight.w700,
          ),
        ),

        actions: [
          if (_notifications.isNotEmpty)
            PopupMenuButton<String>(
              color: Colors.white,
              icon: Icon(
                Icons.more_vert,
                color: textColor,
              ),
              onSelected:
                  (value) {
                if (value ==
                    'read') {
                  _markAllAsRead();
                }

                if (value ==
                    'delete') {
                  _deleteAll();
                }
              },
              itemBuilder:
                  (context) {
                return [
                  const PopupMenuItem(
                    value: 'read',
                    child: Text(
                      'Tout marquer comme lu',
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text(
                      'Supprimer tout',
                    ),
                  ),
                ];
              },
            ),
        ],
      ),

      body: RefreshIndicator(
        color: accentColor,
        onRefresh: _refresh,

        child: _isLoading
            ? const Center(
          child:
          CircularProgressIndicator(
            color:
            accentColor,
          ),
        )
            : ListView(
          physics:
          const AlwaysScrollableScrollPhysics(),
          padding:
          EdgeInsets.fromLTRB(
            16.w,
            10.h,
            16.w,
            30.h,
          ),
          children: [
            // ==========================================
            // RÉSUMÉ
            // ==========================================

            Container(
              padding:
              EdgeInsets.all(
                18.w,
              ),
              decoration:
              BoxDecoration(
                gradient:
                LinearGradient(
                  colors: [
                    accentColor,
                    accentColor
                        .withValues(
                      alpha: 0.75,
                    ),
                  ],
                ),
                borderRadius:
                BorderRadius.circular(
                  22.r,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width:
                    48.w,
                    height:
                    48.w,
                    decoration:
                    BoxDecoration(
                      color: Colors
                          .white
                          .withValues(
                        alpha:
                        0.18,
                      ),
                      shape:
                      BoxShape.circle,
                    ),
                    child:
                    const Icon(
                      Icons
                          .notifications_rounded,
                      color:
                      Colors.white,
                    ),
                  ),

                  SizedBox(
                    width: 13.w,
                  ),

                  Expanded(
                    child:
                    Column(
                      crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                      children: [
                        Text(
                          _unreadCount ==
                              0
                              ? 'Tout est à jour'
                              : '$_unreadCount notification${_unreadCount > 1 ? 's' : ''} non lue${_unreadCount > 1 ? 's' : ''}',
                          style:
                          GoogleFonts.poppins(
                            color:
                            Colors.white,
                            fontSize:
                            15.sp,
                            fontWeight:
                            FontWeight.w700,
                          ),
                        ),
                        SizedBox(
                          height:
                          3.h,
                        ),
                        Text(
                          '${_notifications.length} notification${_notifications.length > 1 ? 's' : ''}',
                          style:
                          GoogleFonts.poppins(
                            color:
                            Colors.white70,
                            fontSize:
                            11.5.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(
              height: 18.h,
            ),

            // ==========================================
            // FILTRES
            // ==========================================

            _buildFilters(),

            SizedBox(
              height: 18.h,
            ),

            // ==========================================
            // LISTE
            // ==========================================

            if (notifications.isEmpty)
              Padding(
                padding:
                EdgeInsets.only(
                  top: 70.h,
                ),
                child:
                Column(
                  children: [
                    Icon(
                      Icons
                          .notifications_none_rounded,
                      size: 60.sp,
                      color: Colors
                          .grey
                          .shade300,
                    ),
                    SizedBox(
                      height:
                      15.h,
                    ),
                    Text(
                      'Aucune notification',
                      style:
                      GoogleFonts.poppins(
                        color:
                        textColor,
                        fontSize:
                        16.sp,
                        fontWeight:
                        FontWeight.w600,
                      ),
                    ),
                    SizedBox(
                      height:
                      5.h,
                    ),
                    Text(
                      _selectedFilter ==
                          'Toutes'
                          ? 'Vous êtes à jour.'
                          : 'Aucune notification dans cette catégorie.',
                      textAlign:
                      TextAlign.center,
                      style:
                      GoogleFonts.poppins(
                        color:
                        Colors.black45,
                        fontSize:
                        12.sp,
                      ),
                    ),
                  ],
                ),
              )
            else
              ...notifications.map(
                _buildNotificationCard,
              ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _subscription?.cancel();

    super.dispose();
  }
}