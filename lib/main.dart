import 'dart:async';
import 'package:mobile_app/favorite_appart/page_favorite.dart';
import 'package:mobile_app/message/message.dart';
import 'package:mobile_app/parametres/accessibilite.dart';
import 'package:mobile_app/parametres/centre_aide.dart';
import 'package:mobile_app/parametres/conditions_utilisation_page.dart';
import 'package:mobile_app/parametres/confidentialite.dart';
import 'package:mobile_app/parametres/connexion_securite.dart';
import 'package:mobile_app/parametres/coupons.dart';
import 'package:mobile_app/parametres/information_personnelle.dart';
import 'package:mobile_app/parametres/legal.dart';
import 'package:mobile_app/parametres/methode_paiement.dart';
import 'package:mobile_app/parametres/paiement_et_versement.dart';
import 'package:mobile_app/parametres/parametre_profile.dart';
import 'package:mobile_app/parametres/profile.dart';
import 'package:mobile_app/parametres/vos_paiements.dart';
import 'package:mobile_app/providers/tab_provider.dart';
import 'package:mobile_app/reservation/liste_reservations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mobile_app/widgets/main_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';

import 'acceuil/home1.dart';
import 'acceuil/home2.dart';
import 'acceuil/page_decouvrir.dart';
import 'favorite_appart/favorites_service.dart';
import 'google_map/google_map.dart';
import 'inscription/connexion.dart';
import 'inscription/register.dart';
import 'inscription/reset_password.dart';
import 'package:service/snackbar_service.dart';

class NavigationService {
  static final NavigationService _instance = NavigationService._internal();
  factory NavigationService() => _instance;
  NavigationService._internal();

  static final GlobalKey<NavigatorState> navigatorKey =
  GlobalKey<NavigatorState>();

  void pushReplacementAndClearStack(String routeName) {
    navigatorKey.currentState?.pushNamedAndRemoveUntil(
      routeName,
          (Route<dynamic> route) => false,
    );
  }

  Future<void> pushReplacementAndClearStackWithDelay(
      String routeName, {
        Duration delay = const Duration(milliseconds: 300),
      }) async {
    await Future.delayed(delay);
    if (navigatorKey.currentState != null) {
      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        routeName,
            (Route<dynamic> route) => false,
      );
    }
  }

  bool get isNavigatorReady => navigatorKey.currentState != null;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);

  await Supabase.initialize(
    url: 'https://rcaujtlhfyumkuwdfpcm.supabase.co',
    publishableKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJjYXVqdGxoZnl1bWt1d2RmcGNtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjAyMzM5MTEsImV4cCI6MjA3NTgwOTkxMX0.AAGqqVywuJ_0D4YT9_TcE6-CKs2b3A4TS60mSEGIgbE',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, child) {
        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => TabProvider()),
            ChangeNotifierProvider(create: (_) => FavoritesService()),
          ],
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'ADS',

            navigatorKey: NavigationService.navigatorKey,

            scaffoldMessengerKey: SnackBarService.messengerKey,

            theme: ThemeData(
              primarySwatch: Colors.blue,
              fontFamily: 'Inter',
              scaffoldBackgroundColor: const Color(0xFFFFEFE0),
            ),

            home: const WelcomeScreen(),

            routes: {
              '/main': (context) => const MainPage(),
              '/home1': (context) => const WelcomeScreen(),
              '/onboarding': (context) => const OnboardingScreen(),
              '/home2': (context) => const Home2Page(),
              '/connexion': (context) => const ConnexionWidget(),
              '/register': (context) => const RegisterPage(),
              '/parametres': (context) => const ProfilePage(),
              '/parametre_profile': (context) => const SettingsPage(),
              '/legal': (context) => const LegalPage(),
              '/centre_aide': (context) => const HelpPage(),
              '/confidentialite': (context) => const ConfidentialitePage(),
              '/accessibilite': (context) => const AccessibilitePage(),
              '/paiement_versement': (context) => const PaiementEtVersementPage(),
              '/mode_paiement': (context) => const ModePaiementPage(),
              '/vos_paiements': (context) => const VosPaiementsPage(),
              '/coupons': (context) => const CouponsPage(),
              '/information_personnelle': (context) => const InformationPersonnellePage(),
              '/connexion_securite': (context) => const ConnexionSecuritePage(),
              '/reset_password': (context) => const ResetPasswordWidget(),
              '/google_map': (context) => const GoogleMapPage(),
              '/liste_reservation': (context) => const ListeReservationsPage(),
              '/conditions': (context) => const ConditionsPage(),
              '/politiques': (context) => const ConfidentialitePage(),
              '/licence': (context) => const ConditionsPage(),
              '/favorite': (context) => const FavoritesPage(),
              '/message': (context) => const MessagePage(),
            },

            onGenerateRoute: (settings) {
              if (settings.name == '/') {
                return MaterialPageRoute(
                  builder: (context) => const WelcomeScreen(),
                );
              }
              return null;
            },
          ),
        );
      },
    );
  }
}