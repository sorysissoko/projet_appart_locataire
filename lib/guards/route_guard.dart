import 'package:flutter/material.dart';

import 'package:service/auth_service_wrapper.dart';
import 'package:service/navigation_service.dart';
import 'package:service/security_service.dart';
import 'package:service/service_locator.dart';

class RouteGuard {
  RouteGuard._();

  // ============================================================
  // SERVICES
  // ============================================================

  static AuthServiceWrapper get _auth =>
      ServiceLocator.authWrapper;

  static NavigationService get _navigation =>
      ServiceLocator.navigation;

  // ============================================================
  // ROUTES
  // ============================================================

  static const String loginRoute = '/connexion';

  static const String tenantDashboardRoute =
      '/dashboard';

  // ============================================================
  // AUTHENTIFICATION
  // ============================================================

  static Future<bool> isAuthenticated() async {
    return _auth.isAuthenticated;
  }

  // ============================================================
  // RÔLE COURANT
  // ============================================================

  static Future<String?> getCurrentRole() async {
    if (!_auth.isAuthenticated) {
      return null;
    }

    try {
      final role = await _auth.getUserRole();

      if (role == null) {
        debugPrint(
          '⚠️ RouteGuard LOCATAIRE : aucun rôle.',
        );

        return null;
      }

      final normalizedRole =
      SecurityService.normalizeRole(role);

      if (!SecurityService.isValidRole(
        normalizedRole,
      )) {
        debugPrint(
          '⚠️ RouteGuard LOCATAIRE : rôle invalide : '
              '$normalizedRole',
        );

        return null;
      }

      return normalizedRole;
    } catch (e) {
      debugPrint(
        '❌ RouteGuard LOCATAIRE : erreur rôle : $e',
      );

      return null;
    }
  }

  // ============================================================
  // COMPATIBILITÉ
  // ============================================================

  static Future<String?> getCurrentUserRole() async {
    return getCurrentRole();
  }

  // ============================================================
  // AUTORISATION LOCATAIRE
  // ============================================================

  /// Tous les rôles valides peuvent accéder
  /// à l'application LOCATAIRE.
  ///
  /// - admin
  /// - super_admin
  /// - proprietaire
  /// - locataire
  static Future<bool> isLocataire() async {
    final role = await getCurrentRole();

    return _isAllowedRole(role);
  }

  // ============================================================
  // SESSION
  // ============================================================

  static Future<bool> isSessionValid() async {
    try {
      return await _auth.checkSession();
    } catch (e) {
      debugPrint(
        '❌ RouteGuard LOCATAIRE : erreur session : $e',
      );

      return false;
    }
  }

  // ============================================================
  // VÉRIFICATION RÔLE AUTORISÉ
  // ============================================================

  static bool _isAllowedRole(String? role) {
    if (role == null) {
      return false;
    }

    return role == SecurityService.roleAdmin ||
        role == SecurityService.roleSuperAdmin ||
        role == SecurityService.roleProprietaire ||
        role == SecurityService.roleLocataire;
  }

  // ============================================================
  // CHECK ACCESS
  // ============================================================

  /// Vérifie l'accès à l'application LOCATAIRE.
  ///
  /// Autorisés :
  ///
  /// admin
  /// super_admin
  /// proprietaire
  /// locataire
  ///
  /// IMPORTANT :
  /// Cette méthode ne reçoit plus de BuildContext.
  /// Cela évite les warnings :
  ///
  /// use_build_context_synchronously
  static Future<bool> checkAccess({
    bool requireAuth = true,
    bool showSnackBar = true,
  }) async {
    // ==========================================================
    // 1. AUTHENTIFICATION
    // ==========================================================

    if (requireAuth) {
      final authenticated =
      await isAuthenticated();

      if (!authenticated) {
        _redirectToLogin(
          showSnackBar: showSnackBar,
        );

        return false;
      }

      // --------------------------------------------------------
      // Vérification session
      // --------------------------------------------------------

      final sessionValid =
      await isSessionValid();

      if (!sessionValid) {
        _redirectToLogin(
          showSnackBar: showSnackBar,
        );

        return false;
      }
    }

    // ==========================================================
    // 2. RÔLE
    // ==========================================================

    final role = await getCurrentRole();

    debugPrint(
      '🔐 RouteGuard LOCATAIRE - rôle : $role',
    );

    // ==========================================================
    // 3. RÔLE INVALIDE
    // ==========================================================

    if (role == null) {
      _redirectToLogin(
        showSnackBar: showSnackBar,
      );

      return false;
    }

    // ==========================================================
    // 4. AUTORISATION
    // ==========================================================

    final allowed =
    _isAllowedRole(role);

    debugPrint(
      '🔑 Accès APP LOCATAIRE : $allowed',
    );

    if (!allowed) {
      _accessDenied(
        message: 'Accès refusé.',
        fallbackRoute: loginRoute,
        showSnackBar: showSnackBar,
      );

      return false;
    }

    // ==========================================================
    // 5. ACCÈS AUTORISÉ
    // ==========================================================

    return true;
  }

  // ============================================================
  // HAS ROLE
  // ============================================================

  static Future<bool> hasRole(
      String targetRole,
      ) async {
    final role = await getCurrentRole();

    if (role == null) {
      return false;
    }

    final normalizedTarget =
    SecurityService.normalizeRole(
      targetRole,
    );

    if (!SecurityService.isValidRole(
      normalizedTarget,
    )) {
      return false;
    }

    return role == normalizedTarget;
  }

  // ============================================================
  // CAN ACCESS
  // ============================================================

  static Future<bool> canAccess() async {
    final role = await getCurrentRole();

    return _isAllowedRole(role);
  }

  // ============================================================
  // LOGIN
  // ============================================================

  static void _redirectToLogin({
    bool showSnackBar = true,
  }) {
    debugPrint(
      '🔀 RouteGuard LOCATAIRE : '
          'redirection vers $loginRoute',
    );

    // ----------------------------------------------------------
    // IMPORTANT
    // ----------------------------------------------------------
    //
    // On ne manipule plus BuildContext ici.
    //
    // NavigationService s'occupe directement
    // de la navigation.
    //
    // ----------------------------------------------------------

    if (showSnackBar) {
      debugPrint(
        '⚠️ Session expirée : '
            'redirection vers connexion.',
      );
    }

    _navigation.pushReplacementAndClearStack(
      loginRoute,
    );
  }

  // ============================================================
  // ACCÈS REFUSÉ
  // ============================================================

  static void _accessDenied({
    required String message,
    required String fallbackRoute,
    bool showSnackBar = true,
  }) {
    if (showSnackBar) {
      debugPrint(
        '🚫 RouteGuard LOCATAIRE : $message',
      );
    }

    debugPrint(
      '🔀 Redirection vers : $fallbackRoute',
    );

    _navigation.pushReplacementAndClearStack(
      fallbackRoute,
    );
  }

  // ============================================================
  // REDIRECTION DASHBOARD
  // ============================================================

  static Future<void> redirectToDashboard() async {
    final role = await getCurrentRole();

    final allowed =
    _isAllowedRole(role);

    debugPrint(
      '🔀 RouteGuard LOCATAIRE : '
          'rôle [$role], accès dashboard [$allowed]',
    );

    if (!allowed) {
      _redirectToLogin(
        showSnackBar: true,
      );

      return;
    }

    await _navigation.pushReplacementAndClearStack(
      tenantDashboardRoute,
    );
  }
}