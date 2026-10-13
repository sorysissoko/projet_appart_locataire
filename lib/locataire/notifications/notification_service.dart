import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// ============================================================
/// TYPES D'ÉVÉNEMENTS REALTIME
/// ============================================================

enum NotificationRealtimeType {
  inserted,
  updated,
  deleted,
}

/// ============================================================
/// ÉVÉNEMENT REALTIME
/// ============================================================

class NotificationRealtimeEvent {
  final NotificationRealtimeType type;

  final Map<String, dynamic>? notification;

  final String? notificationId;

  final bool? oldIsRead;

  final bool? newIsRead;

  const NotificationRealtimeEvent({
    required this.type,
    this.notification,
    this.notificationId,
    this.oldIsRead,
    this.newIsRead,
  });
}

/// ============================================================
/// SERVICE NOTIFICATIONS
/// ============================================================
///
/// Singleton afin que MainPage, Header et NotificationsPage
/// utilisent tous le même canal Realtime.
///
/// Les notifications sont créées par PostgreSQL.
/// Flutter ne crée donc pas lui-même les notifications.
///

class NotificationService {
  // ============================================================
  // SINGLETON
  // ============================================================

  static final NotificationService _instance =
  NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  // ============================================================
  // SUPABASE
  // ============================================================

  final SupabaseClient _supabase =
      Supabase.instance.client;

  // ============================================================
  // REALTIME
  // ============================================================

  RealtimeChannel? _channel;

  String? _subscribedUserId;

  // ============================================================
  // STREAM
  // ============================================================

  final StreamController<NotificationRealtimeEvent>
  _eventController =
  StreamController<NotificationRealtimeEvent>.broadcast();

  Stream<NotificationRealtimeEvent> get events =>
      _eventController.stream;

  // ============================================================
  // NOTIFICATIONS
  // ============================================================

  Future<List<Map<String, dynamic>>> getNotifications({
    int limit = 100,
  }) async {
    final user =
        _supabase.auth.currentUser;

    if (user == null) {
      debugPrint(
        '⚠️ Aucun utilisateur connecté.',
      );

      return [];
    }

    try {
      final data = await _supabase
          .from('notifications')
          .select()
          .eq('user_id', user.id)
          .order(
        'created_at',
        ascending: false,
      )
          .limit(limit);

      return List<Map<String, dynamic>>.from(
        data,
      );
    } catch (e, stackTrace) {
      debugPrint(
        '❌ Erreur récupération notifications : $e',
      );

      debugPrint(
        '$stackTrace',
      );

      rethrow;
    }
  }

  // ============================================================
  // COMPTEUR NON LUES
  // ============================================================

  Future<int> getUnreadCount() async {
    final user =
        _supabase.auth.currentUser;

    if (user == null) {
      return 0;
    }

    try {
      final data = await _supabase
          .from('notifications')
          .select('id')
          .eq(
        'user_id',
        user.id,
      )
          .eq(
        'is_read',
        false,
      );

      return data.length;
    } catch (e) {
      debugPrint(
        '❌ Erreur compteur notifications : $e',
      );

      return 0;
    }
  }

  // ============================================================
  // MARQUER UNE NOTIFICATION COMME LUE
  // ============================================================

  Future<void> markAsRead(
      String notificationId,
      ) async {
    final user =
        _supabase.auth.currentUser;

    if (user == null) {
      return;
    }

    try {
      await _supabase
          .from('notifications')
          .update({
        'is_read': true,
        'read_at': DateTime.now()
            .toUtc()
            .toIso8601String(),
      })
          .eq(
        'id',
        notificationId,
      )
          .eq(
        'user_id',
        user.id,
      );
    } catch (e) {
      debugPrint(
        '❌ Erreur marquage notification : $e',
      );

      rethrow;
    }
  }

  // ============================================================
  // TOUT MARQUER COMME LU
  // ============================================================

  Future<void> markAllAsRead() async {
    final user =
        _supabase.auth.currentUser;

    if (user == null) {
      return;
    }

    try {
      await _supabase
          .from('notifications')
          .update({
        'is_read': true,
        'read_at': DateTime.now()
            .toUtc()
            .toIso8601String(),
      })
          .eq(
        'user_id',
        user.id,
      )
          .eq(
        'is_read',
        false,
      );
    } catch (e) {
      debugPrint(
        '❌ Erreur marquage global : $e',
      );

      rethrow;
    }
  }

  // ============================================================
  // SUPPRIMER UNE NOTIFICATION
  // ============================================================

  Future<void> deleteNotification(
      String notificationId,
      ) async {
    final user =
        _supabase.auth.currentUser;

    if (user == null) {
      return;
    }

    try {
      await _supabase
          .from('notifications')
          .delete()
          .eq(
        'id',
        notificationId,
      )
          .eq(
        'user_id',
        user.id,
      );
    } catch (e) {
      debugPrint(
        '❌ Erreur suppression notification : $e',
      );

      rethrow;
    }
  }

  // ============================================================
  // SUPPRIMER TOUTES LES NOTIFICATIONS
  // ============================================================

  Future<void> deleteAllNotifications() async {
    final user =
        _supabase.auth.currentUser;

    if (user == null) {
      return;
    }

    try {
      await _supabase
          .from('notifications')
          .delete()
          .eq(
        'user_id',
        user.id,
      );
    } catch (e) {
      debugPrint(
        '❌ Erreur suppression notifications : $e',
      );

      rethrow;
    }
  }

  // ============================================================
  // REALTIME
  // ============================================================

  Future<void> startRealtime() async {
    final user =
        _supabase.auth.currentUser;

    if (user == null) {
      debugPrint(
        '⚠️ Realtime notifications : aucun utilisateur.',
      );

      return;
    }

    // ----------------------------------------------------------
    // ÉVITER LES DOUBLONS
    // ----------------------------------------------------------

    if (_channel != null &&
        _subscribedUserId == user.id) {
      return;
    }

    // ----------------------------------------------------------
    // ARRÊTER ANCIEN CANAL
    // ----------------------------------------------------------

    await stopRealtime();

    final userId = user.id;

    _subscribedUserId = userId;

    debugPrint(
      '🔔 Démarrage Realtime notifications pour $userId',
    );

    // ----------------------------------------------------------
    // CRÉER CANAL
    // ----------------------------------------------------------

    final channelName =
        'mobile_notifications_$userId';

    final channel =
    _supabase.channel(channelName);

    _channel = channel;

    // ==========================================================
    // INSERT
    // ==========================================================

    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'notifications',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'user_id',
        value: userId,
      ),
      callback: (payload) {
        final record =
        Map<String, dynamic>.from(
          payload.newRecord,
        );

        debugPrint(
          '🔔 Nouvelle notification reçue',
        );

        _eventController.add(
          NotificationRealtimeEvent(
            type:
            NotificationRealtimeType.inserted,
            notification:
            record,
            notificationId:
            record['id']?.toString(),
            newIsRead:
            record['is_read'] == true,
          ),
        );
      },
    );

    // ==========================================================
    // UPDATE
    // ==========================================================

    channel.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'notifications',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'user_id',
        value: userId,
      ),
      callback: (payload) {
        final newRecord =
        Map<String, dynamic>.from(
          payload.newRecord,
        );

        final oldRecord =
        Map<String, dynamic>.from(
          payload.oldRecord,
        );

        debugPrint(
          '🔄 Notification mise à jour',
        );

        _eventController.add(
          NotificationRealtimeEvent(
            type:
            NotificationRealtimeType.updated,
            notification:
            newRecord,
            notificationId:
            newRecord['id']?.toString() ??
                oldRecord['id']?.toString(),
            oldIsRead:
            oldRecord['is_read'] == true,
            newIsRead:
            newRecord['is_read'] == true,
          ),
        );
      },
    );

    // ==========================================================
    // DELETE
    // ==========================================================

    channel.onPostgresChanges(
      event: PostgresChangeEvent.delete,
      schema: 'public',
      table: 'notifications',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'user_id',
        value: userId,
      ),
      callback: (payload) {
        final oldRecord =
        Map<String, dynamic>.from(
          payload.oldRecord,
        );

        debugPrint(
          '🗑️ Notification supprimée',
        );

        _eventController.add(
          NotificationRealtimeEvent(
            type:
            NotificationRealtimeType.deleted,
            notificationId:
            oldRecord['id']?.toString(),
            oldIsRead:
            oldRecord['is_read'] == true,
          ),
        );
      },
    );

    // ==========================================================
    // ABONNEMENT
    // ==========================================================

    channel.subscribe();
  }

  // ============================================================
  // STOP REALTIME
  // ============================================================

  Future<void> stopRealtime() async {
    final channel =
        _channel;

    _channel = null;
    _subscribedUserId = null;

    if (channel != null) {
      try {
        await _supabase.removeChannel(
          channel,
        );
      } catch (e) {
        debugPrint(
          '⚠️ Erreur arrêt Realtime : $e',
        );
      }
    }
  }

  // ============================================================
  // DISPOSE DU SERVICE
  // ============================================================

  Future<void> disposeService() async {
    await stopRealtime();

    await _eventController.close();
  }
}