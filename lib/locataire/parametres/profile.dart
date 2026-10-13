import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:service/auth_service.dart';
import 'package:service/snackbar_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../widgets/appbar.dart';
import '../../widgets/confirmation_modal.dart';
import '../notifications/notification_service.dart';
import '../notifications/notifications_page.dart';
import 'voir_profile.dart';

enum SnackBarType {
  success,
  error,
  warning,
  info,
}

class UserProfileData {
  final Map<String, dynamic>? profile;
  final int reservationsCount;
  final int favoritesCount;
  final double averageRating;

  const UserProfileData({
    required this.profile,
    required this.reservationsCount,
    required this.favoritesCount,
    required this.averageRating,
  });
}

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {

  // PROFIL

  late Future<UserProfileData> _profileDataFuture;


  // NOTIFICATIONS

  final NotificationService _notificationService =
  NotificationService();

  StreamSubscription<NotificationRealtimeEvent>?
  _notificationSubscription;

  int _unreadNotificationCount = 0;


  // INIT

  @override
  void initState() {
    super.initState();
    _checkSessionAndLoad();
  }


  // SESSION

  void _checkSessionAndLoad() {
    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        Navigator.pushReplacementNamed(
          context,
          '/connexion',
        );
      });

      return;
    }

    _refreshData();
    _initializeNotifications();
  }


  // NOTIFICATIONS

  Future<void> _initializeNotifications() async {
    await _loadUnreadNotificationCount();

    if (!mounted) return;

    _notificationSubscription =
        _notificationService.events.listen(
          _handleNotificationEvent,
        );

    await _notificationService.startRealtime();
  }

  Future<void> _loadUnreadNotificationCount() async {
    final count =
    await _notificationService.getUnreadCount();

    if (!mounted) return;

    setState(() {
      _unreadNotificationCount = count;
    });
  }

  void _handleNotificationEvent(
      NotificationRealtimeEvent event,
      ) {
    if (!mounted) return;

    switch (event.type) {

    // INSERT

      case NotificationRealtimeType.inserted:
        if (event.newIsRead != true) {
          setState(() {
            _unreadNotificationCount++;
          });
        }
        break;


    // UPDATE

      case NotificationRealtimeType.updated:
        final oldRead = event.oldIsRead == true;
        final newRead = event.newIsRead == true;

        // Non lue, lue
        if (!oldRead && newRead) {
          setState(() {
            if (_unreadNotificationCount > 0) {
              _unreadNotificationCount--;
            }
          });
        }

        // Lue, non lue
        else if (oldRead && !newRead) {
          setState(() {
            _unreadNotificationCount++;
          });
        }

        break;


    // DELETE

      case NotificationRealtimeType.deleted:
        if (event.oldIsRead != true) {
          setState(() {
            if (_unreadNotificationCount > 0) {
              _unreadNotificationCount--;
            }
          });
        }
        break;
    }
  }


  // PROFIL

  void _refreshData() {
    if (!mounted) return;

    setState(() {
      _profileDataFuture = _loadAllProfileData();
    });
  }

  Future<UserProfileData> _loadAllProfileData() async {
    try {
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) {
        return const UserProfileData(
          profile: null,
          reservationsCount: 0,
          favoritesCount: 0,
          averageRating: 0.0,
        );
      }

      final profileFuture =
      AuthService().getProfile();

      final reservationsFuture = supabase
          .from('reservations')
          .select('id')
          .eq('locataire_id', user.id);

      final favoritesFuture = supabase
          .from('favorites')
          .select('id')
          .eq('user_id', user.id);

      final ratingsFuture = supabase
          .from('ratings')
          .select('rating')
          .eq('user_id', user.id);

      final profile = await profileFuture;
      final reservations = await reservationsFuture;
      final favorites = await favoritesFuture;
      final ratings = await ratingsFuture;

      double avgRating = 0.0;

      if (ratings.isNotEmpty) {
        final totalSum = ratings.fold<num>(
          0,
              (sum, item) =>
          sum + (item['rating'] ?? 0),
        );

        avgRating =
            totalSum / ratings.length;
      }

      return UserProfileData(
        profile: profile,
        reservationsCount:
        reservations.length,
        favoritesCount:
        favorites.length,
        averageRating: avgRating,
      );
    } catch (e) {
      if (mounted) {
        _showAppSnackBar(
          message:
          'Erreur de chargement : ${e.toString()}',
          type: SnackBarType.error,
        );
      }

      rethrow;
    }
  }


  // SNACKBAR

  void _showAppSnackBar({
    required String message,
    required SnackBarType type,
    Duration duration =
    const Duration(seconds: 4),
  }) {
    switch (type) {
      case SnackBarType.success:
        SnackBarService().showSuccess(
          message,
          duration: duration,
        );
        break;

      case SnackBarType.error:
        SnackBarService().showError(
          message,
          duration: duration,
        );
        break;

      case SnackBarType.warning:
        SnackBarService().showWarning(
          message,
          duration: duration,
        );
        break;

      case SnackBarType.info:
        SnackBarService().showInfo(
          message,
          duration: duration,
        );
        break;
    }
  }


  // LOGOUT

  void _showLoadingDialog(
      BuildContext context,
      ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Container(
        color: Colors.black.withValues(
          alpha: 0.3,
        ),
        child: Center(
          child: Container(
            padding:
            const EdgeInsets.all(20),
            decoration:
            const BoxDecoration(
              color: Colors.white,
              borderRadius:
              BorderRadius.all(
                Radius.circular(16),
              ),
            ),
            child: Column(
              mainAxisSize:
              MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  color: Color(0xFFE85D26),
                ),
                const SizedBox(height: 12),
                Text(
                  'Déconnexion en cours...',
                  style:
                  GoogleFonts.poppins(
                    fontSize: 14,
                    color:
                    const Color(
                      0xFF2D1F16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutModal() {
    showConfirmationModal(
      context: context,
      title: 'Déconnexion',
      message:
      'Êtes-vous sûr de vouloir vous déconnecter de votre compte ?',
      confirmText: 'Déconnecter',
      type: ConfirmationType.logout,
      onConfirm: _handleLogout,
    );
  }

  Future<void> _handleLogout() async {
    final currentContext = context;

    if (!currentContext.mounted) {
      return;
    }

    final navigator =
    Navigator.of(currentContext);

    _showLoadingDialog(
      currentContext,
    );

    try {
      await AuthService().signOut();

      if (!currentContext.mounted) {
        return;
      }

      // Fermer le dialogue de chargement
      if (Navigator.of(currentContext)
          .canPop()) {
        Navigator.of(currentContext).pop();
      }

      _showAppSnackBar(
        message:
        'Déconnexion réussie !',
        type:
        SnackBarType.success,
      );

      await Future.delayed(
        const Duration(
          milliseconds: 300,
        ),
      );

      if (!currentContext.mounted) {
        return;
      }

      navigator.pushNamedAndRemoveUntil(
        '/home2',
            (Route<dynamic> route) =>
        false,
      );
    } catch (e) {
      if (!currentContext.mounted) {
        return;
      }

      // Fermer le dialogue
      if (Navigator.of(currentContext)
          .canPop()) {
        Navigator.of(currentContext).pop();
      }

      _showAppSnackBar(
        message:
        'Erreur : ${e.toString()}',
        type:
        SnackBarType.error,
      );
    }
  }

  // ALERTE CERTIFICATION

  Widget _buildCertificationAlert() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color:
        const Color(0xFFFFF3E0),
        borderRadius:
        BorderRadius.circular(18.r),
        border: Border.all(
          color:
          const Color(0xFFFFB74D),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(
              0xFFFF9800,
            ).withValues(
              alpha: 0.08,
            ),
            blurRadius: 12,
            offset:
            const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment:
        CrossAxisAlignment.start,
        children: [
          Container(
            width: 44.w,
            height: 44.w,
            decoration:
            BoxDecoration(
              color:
              const Color(0xFFFFE0B2),
              borderRadius:
              BorderRadius.circular(
                14.r,
              ),
            ),
            child: Icon(
              PhosphorIconsFill.warning,
              color:
              const Color(0xFFF57C00),
              size: 23.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  'Compte non certifié',
                  style:
                  GoogleFonts.inter(
                    fontSize: 15.sp,
                    fontWeight:
                    FontWeight.w800,
                    color:
                    const Color(
                      0xFF6D3B00,
                    ),
                  ),
                ),
                SizedBox(height: 5.h),
                Text(
                  'Votre compte n\'est pas encore certifié. '
                      'Certifiez votre compte pour profiter pleinement '
                      'des fonctionnalités de DS APPARTS.',
                  style:
                  GoogleFonts.inter(
                    fontSize: 12.5.sp,
                    height: 1.45,
                    color:
                    const Color(
                      0xFF8A5A2B,
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
                SizedBox(
                  height: 38.h,
                  child:
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(
                        context,
                        '/parametre_profile',
                      );
                    },
                    icon: Icon(
                      PhosphorIconsFill
                          .shieldCheck,
                      size: 17.sp,
                    ),
                    label: Text(
                      'Certifier mon compte',
                      style:
                      GoogleFonts.inter(
                        fontSize: 12.5.sp,
                        fontWeight:
                        FontWeight.w700,
                      ),
                    ),
                    style:
                    ElevatedButton.styleFrom(
                      backgroundColor:
                      const Color(
                        0xFFE85D26,
                      ),
                      foregroundColor:
                      Colors.white,
                      elevation: 0,
                      padding:
                      EdgeInsets.symmetric(
                        horizontal: 14.w,
                      ),
                      shape:
                      RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(
                          12.r,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  //BOUTON NOTIFICATION

  Widget _buildNotificationButton() {
    final count =
        _unreadNotificationCount;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const NotificationsPage(),
            ),
          );

          if (mounted) {
            await _loadUnreadNotificationCount();
          }
        },
        borderRadius:
        BorderRadius.circular(16.r),
        child: Container(
          width: 46.w,
          height: 46.w,
          decoration: BoxDecoration(
            color:
            Colors.white.withValues(
              alpha: 0.18,
            ),
            borderRadius:
            BorderRadius.circular(
              16.r,
            ),
            border: Border.all(
              color:
              Colors.white.withValues(
                alpha: 0.28,
              ),
              width: 1,
            ),
          ),
          child: Stack(
            clipBehavior:
            Clip.none,
            alignment:
            Alignment.center,
            children: [
              Icon(
                PhosphorIcons.bell(),
                color: Colors.white,
                size: 23.sp,
              ),
              if (count > 0)
                Positioned(
                  top: -6.h,
                  right: -6.w,
                  child: Container(
                    constraints:
                    BoxConstraints(
                      minWidth: 21.w,
                      minHeight: 21.w,
                    ),
                    padding:
                    EdgeInsets.symmetric(
                      horizontal: 5.w,
                      vertical: 2.h,
                    ),
                    decoration:
                    BoxDecoration(
                      color:
                      const Color(
                        0xFFE53935,
                      ),
                      shape:
                      BoxShape.circle,
                      border: Border.all(
                        color:
                        const Color(
                          0xFFE85D26,
                        ),
                        width: 2,
                      ),
                    ),
                    alignment:
                    Alignment.center,
                    child: Text(
                      count > 99
                          ? '99+'
                          : '$count',
                      style:
                      GoogleFonts.inter(
                        color:
                        Colors.white,
                        fontSize: 9.sp,
                        fontWeight:
                        FontWeight.w800,
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

  // DISPOSE

  @override
  void dispose() {
    _notificationSubscription?.cancel();
    super.dispose();
  }

  // BUILD

  @override
  Widget build(
      BuildContext context,
      ) {
    return Scaffold(
      backgroundColor:
      const Color(0xFFFFEFE0),

      appBar: CustomAppBar(
        title: 'Profile',
        actions: [
          _buildNotificationButton(),
        ],
      ),

      body:
      FutureBuilder<UserProfileData>(
        future: _profileDataFuture,

        builder:
            (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child:
              CircularProgressIndicator(
                color:
                Color(0xFFE85D26),
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment:
                MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 60.sp,
                    color:
                    Colors.red[300],
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    'Une erreur est survenue',
                    style:
                    GoogleFonts.inter(
                      fontSize: 18.sp,
                      fontWeight:
                      FontWeight.w600,
                      color:
                      const Color(
                        0xFF2D1F16,
                      ),
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Padding(
                    padding:
                    EdgeInsets.symmetric(
                      horizontal: 24.w,
                    ),
                    child: Text(
                      snapshot.error
                          .toString(),
                      style:
                      GoogleFonts.inter(
                        fontSize: 14.sp,
                        color:
                        const Color(
                          0xFF7A6E65,
                        ),
                      ),
                      textAlign:
                      TextAlign.center,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  ElevatedButton(
                    onPressed:
                    _refreshData,
                    style:
                    ElevatedButton.styleFrom(
                      backgroundColor:
                      const Color(
                        0xFFE85D26,
                      ),
                      shape:
                      RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(
                          12.r,
                        ),
                      ),
                    ),
                    child: Text(
                      'Réessayer',
                      style:
                      GoogleFonts.inter(
                        color:
                        Colors.white,
                        fontWeight:
                        FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          final data =
              snapshot.data ??
                  const UserProfileData(
                    profile: null,
                    reservationsCount: 0,
                    favoritesCount: 0,
                    averageRating: 0,
                  );

          return RefreshIndicator(
            color:
            const Color(0xFFE85D26),
            onRefresh: () async {
              _refreshData();
              await _loadUnreadNotificationCount();
            },
            child:
            _buildProfileContent(
              data,
            ),
          );
        },
      ),
    );
  }

  // CONTENU PROFIL

  Widget _buildProfileContent(
      UserProfileData data,
      ) {
    final profile = data.profile;

    final String firstName =
        profile?['prenom']
            ?.toString() ??
            '';

    final String lastName =
        profile?['nom']
            ?.toString() ??
            '';

    final String fullName =
    (firstName.isEmpty &&
        lastName.isEmpty)
        ? 'Utilisateur'
        : '$firstName $lastName';

    final String role =
        profile?['role']
            ?.toString() ??
            'Client';

    final bool estCertifie =
        profile?['est_certifie'] ==
            true;

    final String initials =
    (firstName.isNotEmpty &&
        lastName.isNotEmpty)
        ? '${firstName[0]}${lastName[0]}'
        .toUpperCase()
        : firstName.isNotEmpty
        ? firstName[0]
        .toUpperCase()
        : lastName.isNotEmpty
        ? lastName[0]
        .toUpperCase()
        : 'U';

    return Column(
      children: [

        // HEADER PROFIL

        Container(
          width: double.infinity,
          height: 170.sp,
          padding:
          EdgeInsets.fromLTRB(
            24.w,
            16.h,
            24.w,
            55.h,
          ),
          color:
          const Color(0xFFE85D26),

          child: Stack(
            clipBehavior:
            Clip.none,
            children: [

              // CARTE PROFIL

              Container(
                decoration:
                BoxDecoration(
                  color:
                  const Color(
                    0xFFF6AA89,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    20.r,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black
                          .withValues(
                        alpha: 0.1,
                      ),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                padding:
                EdgeInsets.all(3.w),

                child: Container(
                  decoration:
                  BoxDecoration(
                    color: Colors.white
                        .withValues(
                      alpha: 0.05,
                    ),
                    borderRadius:
                    BorderRadius.circular(
                      17.r,
                    ),
                    border:
                    Border.all(
                      color:
                      const Color(
                        0xFFE85D26,
                      ).withValues(
                        alpha: 0.5,
                      ),
                      width: 2.w,
                    ),
                  ),
                  padding:
                  EdgeInsets.all(14.w),

                  child: Row(
                    children: [

                      // AVATAR

                      Container(
                        width: 64.w,
                        height: 64.w,
                        decoration:
                        BoxDecoration(
                          shape:
                          BoxShape.circle,
                          color: Colors.white
                              .withValues(
                            alpha: 0.25,
                          ),
                          border:
                          Border.all(
                            color: Colors
                                .white
                                .withValues(
                              alpha: 0.4,
                            ),
                            width: 2.w,
                          ),
                        ),
                        alignment:
                        Alignment.center,
                        child: Text(
                          initials,
                          style:
                          GoogleFonts.inter(
                            fontSize:
                            18.sp,
                            fontWeight:
                            FontWeight
                                .w700,
                            color: Colors
                                .white,
                          ),
                        ),
                      ),

                      SizedBox(
                        width: 16.w,
                      ),

                      // INFOS
                      Expanded(
                        child:
                        InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) =>
                                const VoirProfilePage(),
                              ),
                            );
                          },
                          borderRadius:
                          BorderRadius.circular(
                            12.r,
                          ),
                          child: Padding(
                            padding: EdgeInsets.zero,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fullName,
                                  style: GoogleFonts.inter(
                                    fontSize: 17.sp,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),

                                SizedBox(height: 3.h),

                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Flexible(
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 14.w,
                                          vertical: 1.h,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white.withValues(
                                            alpha: 0.2,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            30.r,
                                          ),
                                        ),
                                        child: Text(
                                          role,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.inter(
                                            fontSize: 11.sp,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),

                                    SizedBox(width: 6.w),

                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 8.w,
                                        vertical: 0.5.h,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.2,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          30.r,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            PhosphorIconsFill.star,
                                            color: const Color(0xFFFFC107),
                                            size: 17.sp,
                                          ),
                                          SizedBox(width: 3.w),
                                          Text(
                                            data.averageRating > 0
                                                ? data.averageRating.toStringAsFixed(1)
                                                : 'N/A',
                                            style: GoogleFonts.inter(
                                              fontSize: 11.5.sp,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),


              // STATISTIQUES
              Positioned(
                bottom:
                -80.h,
                left: 0,
                right: 0,
                child: Padding(
                  padding:
                  EdgeInsets.symmetric(
                    horizontal: 16.w,
                  ),
                  child: Row(
                    children: [
                      _buildStatCard(
                        data.reservationsCount
                            .toString(),
                        'Séjours',
                      ),
                      SizedBox(
                        width: 8.w,
                      ),
                      _buildStatCard(
                        data.favoritesCount
                            .toString(),
                        'Favoris',
                      ),
                      SizedBox(
                        width: 8.w,
                      ),
                      _buildStatCard(
                        data.averageRating >
                            0
                            ? data.averageRating
                            .toStringAsFixed(
                          1,
                        )
                            : '0.0',
                        'Avis',
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),


        // ESPACE HEADER
        SizedBox(
          height: 35.h,
        ),

        // ALERTE CERTIFICATION
        if (!estCertifie) ...[
          Padding(
            padding:
            EdgeInsets.symmetric(
              horizontal: 16.w,
            ),
            child:
            _buildCertificationAlert(),
          ),
          SizedBox(
            height: 20.h,
          ),
        ],

        // CONTENU
        Expanded(
          child:
          SingleChildScrollView(
            physics:
            const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment
                  .stretch,
              children: [

                //ACTIONS RAPIDES
                Padding(
                  padding:
                  EdgeInsets.symmetric(
                    horizontal: 16.w,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child:
                        _buildQuickAction(
                          label:
                          'Vos réservations',
                          sub:
                          'Voir toutes vos réservations',
                          imagePath:
                          'assets/images/chambre.jpg',
                          onTap: () =>
                              Navigator
                                  .pushNamed(
                                context,
                                '/liste_reservation',
                              ),
                        ),
                      ),
                      SizedBox(
                        width: 12.w,
                      ),
                      Expanded(
                        child:
                        _buildQuickAction(
                          label:
                          'Devenir hôte',
                          sub:
                          'Publiez votre bien',
                          imagePath:
                          'assets/images/maison2.png',
                          onTap: () =>
                              Navigator
                                  .pushNamed(
                                context,
                                '/devenir_hote',
                              ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(
                  height: 20.h,
                ),


                // MENU
                Container(
                  margin:
                  EdgeInsets.symmetric(
                    horizontal: 16.w,
                  ),
                  decoration:
                  BoxDecoration(
                    color:
                    const Color(
                      0xFFFFF5EC,
                    ),
                    borderRadius:
                    BorderRadius.circular(
                      20.r,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(
                          0xFFE85D3A,
                        ).withValues(
                          alpha: 0.04,
                        ),
                        blurRadius: 16,
                        offset:
                        const Offset(
                          0,
                          6,
                        ),
                      ),
                    ],
                    border:
                    Border.all(
                      color:
                      const Color(
                        0xFFFFF5EC,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildMenuItem(
                        icon:
                        PhosphorIcons
                            .gear(),
                        label:
                        'Paramètres de profile',
                        sub:
                        'Compte, sécurité',
                        onTap: () =>
                            Navigator
                                .pushNamed(
                              context,
                              '/parametre_profile',
                            ),
                      ),
                      _buildMenuItem(
                        icon:
                        PhosphorIcons
                            .shield(),
                        label:
                        'Légal & confidentialité',
                        sub:
                        'CGU, politique',
                        onTap: () =>
                            Navigator
                                .pushNamed(
                              context,
                              '/legal',
                            ),
                      ),
                      _buildMenuItem(
                        icon:
                        PhosphorIcons
                            .question(),
                        label:
                        "Centre d'aide",
                        sub:
                        'Support & FAQ',
                        onTap: () =>
                            Navigator
                                .pushNamed(
                              context,
                              '/centre_aide',
                            ),
                      ),
                      _buildMenuItem(
                        icon:
                        PhosphorIcons
                            .signOut(),
                        label:
                        'Déconnexion',
                        danger: true,
                        onTap:
                        _showLogoutModal,
                      ),
                    ],
                  ),
                ),

                SizedBox(
                  height: 32.h,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }


  // STAT CARD
  Widget _buildStatCard(
      String value,
      String label,
      ) {
    return Expanded(
      child: Container(
        padding:
        EdgeInsets.symmetric(
          vertical: 10.h,
          horizontal: 8.w,
        ),
        decoration:
        BoxDecoration(
          color:
          const Color(0xFFFFF5EC),
          borderRadius:
          BorderRadius.circular(
            16.r,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(
                0x0DE85D3A,
              ),
              blurRadius: 14,
              offset:
              const Offset(0, 6),
            ),
          ],
          border: Border.all(
            color:
            const Color(0xFFF5F0EC),
          ),
        ),
        child: Column(
          children: [
            Text(
              value,
              style:
              GoogleFonts.inter(
                fontSize: 22.sp,
                fontWeight:
                FontWeight.w800,
                color:
                const Color(
                  0xFFD63F23,
                ),
              ),
            ),
            SizedBox(
              height: 3.h,
            ),
            Text(
              label.toUpperCase(),
              style:
              GoogleFonts.inter(
                fontSize: 10.sp,
                color:
                const Color(
                  0xFF9A8E85,
                ),
                fontWeight:
                FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // QUICK ACTION
  Widget _buildQuickAction({
    required String label,
    required String sub,
    required String imagePath,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius:
      BorderRadius.circular(
        18.r,
      ),
      child: Container(
        height: 110.h,
        decoration:
        BoxDecoration(
          borderRadius:
          BorderRadius.circular(
            18.r,
          ),
          border: Border.all(
            color:
            const Color(0xB2E85D26),
            width: 1.sp,
          ),
          boxShadow: [
            BoxShadow(
              color:
              const Color(
                0xB2E85D26,
              ).withValues(
                alpha: 0.08,
              ),
              blurRadius: 10,
              offset:
              const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius:
          BorderRadius.circular(
            18.r,
          ),
          child: Stack(
            children: [
              Image.asset(
                imagePath,
                height:
                double.infinity,
                width:
                double.infinity,
                fit:
                BoxFit.cover,
              ),
              Container(
                decoration:
                BoxDecoration(
                  gradient:
                  LinearGradient(
                    begin:
                    Alignment.topCenter,
                    end:
                    Alignment.bottomCenter,
                    colors: [
                      Colors.black
                          .withValues(
                        alpha: 0.05,
                      ),
                      Colors.black
                          .withValues(
                        alpha: 0.7,
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom:
                12.h,
                left:
                14.w,
                right:
                14.w,
                child:
                Column(
                  crossAxisAlignment:
                  CrossAxisAlignment
                      .start,
                  children: [
                    Text(
                      label,
                      style:
                      GoogleFonts.inter(
                        fontSize:
                        13.sp,
                        fontWeight:
                        FontWeight.w800,
                        color:
                        Colors.white,
                      ),
                    ),
                    SizedBox(
                      height: 2.h,
                    ),
                    Text(
                      sub,
                      style:
                      GoogleFonts.inter(
                        fontSize:
                        11.sp,
                        color: Colors
                            .white
                            .withValues(
                          alpha:
                          0.75,
                        ),
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

  // MENU ITEM

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    String? sub,
    String? badge,
    bool danger = false,
    VoidCallback? onTap,
  }) {
    final isLast =
        label ==
            'Déconnexion';

    return InkWell(
      onTap: onTap,
      borderRadius:
      BorderRadius.circular(
        20.r,
      ),
      child: Container(
        padding:
        EdgeInsets.symmetric(
          horizontal: 16.w,
          vertical: 15.h,
        ),
        decoration:
        BoxDecoration(
          border:
          Border(
            bottom: isLast
                ? BorderSide.none
                : const BorderSide(
              color:
              Color(
                0xFFFFF5EC,
              ),
              width: 1.5,
            ),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38.w,
              height: 38.w,
              decoration:
              BoxDecoration(
                color: danger
                    ? const Color(
                  0x0FEE4444,
                )
                    : const Color(
                  0x0FE85D3A,
                ),
                borderRadius:
                BorderRadius.circular(
                  12.r,
                ),
              ),
              child: Icon(
                icon,
                color: danger
                    ? const Color(
                  0xFFEE4444,
                )
                    : const Color(
                  0xFFEC6645,
                ),
                size: 19.sp,
              ),
            ),

            SizedBox(
              width: 14.w,
            ),

            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment
                    .start,
                children: [
                  Text(
                    label,
                    style:
                    GoogleFonts.inter(
                      fontSize:
                      14.2.sp,
                      fontWeight:
                      FontWeight.w600,
                      color: danger
                          ? const Color(
                        0xFFEE4444,
                      )
                          : const Color(
                        0xFF3A2C23,
                      ),
                    ),
                  ),
                  if (sub != null) ...[
                    SizedBox(
                      height: 2.h,
                    ),
                    Text(
                      sub,
                      style:
                      GoogleFonts.inter(
                        fontSize:
                        11.5.sp,
                        color:
                        const Color(
                          0xFF91847B,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            if (badge != null)
              Container(
                margin:
                EdgeInsets.only(
                  right: 4.w,
                ),
                padding:
                EdgeInsets.symmetric(
                  horizontal: 8.w,
                  vertical: 3.h,
                ),
                decoration:
                BoxDecoration(
                  color:
                  const Color(
                    0xFFEC6645,
                  ),
                  borderRadius:
                  BorderRadius.circular(
                    30.r,
                  ),
                ),
                child: Text(
                  badge,
                  style:
                  GoogleFonts.inter(
                    fontSize: 10.sp,
                    fontWeight:
                    FontWeight.w800,
                    color:
                    Colors.white,
                  ),
                ),
              ),

            if (!danger)
              Icon(
                PhosphorIcons
                    .caretRight(),
                color:
                const Color(
                  0xFFC7BDB6,
                ),
                size: 16.sp,
              ),
          ],
        ),
      ),
    );
  }
}

