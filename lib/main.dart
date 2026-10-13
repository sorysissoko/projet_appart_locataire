import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:service/service_locator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:mobile_app/providers/tab_provider.dart';
import 'package:mobile_app/reservation/liste_reservations.dart';
import 'package:mobile_app/widgets/main_page.dart';

import 'package:service/snackbar_service.dart';

import 'locataire/acceuil/home1.dart';
import 'locataire/acceuil/home2.dart';
import 'locataire/acceuil/page_decouvrir.dart';

import 'locataire/favorite_appart/favorites_service.dart';
import 'locataire/favorite_appart/page_favorite.dart';

import 'locataire/google_map/google_map.dart';

import 'locataire/inscription/connexion.dart';
import 'locataire/inscription/register.dart';
import 'locataire/inscription/reset_password.dart';

import 'locataire/message/message.dart';

import 'locataire/notifications/notifications_page.dart';
import 'locataire/parametres/accessibilite.dart';
import 'locataire/parametres/centre_aide.dart';
import 'locataire/parametres/conditions_utilisation_page.dart';
import 'locataire/parametres/confidentialite.dart';
import 'locataire/parametres/connexion_securite.dart';
import 'locataire/parametres/coupons.dart';
import 'locataire/parametres/documents/documents_verification.dart';
import 'locataire/parametres/information_personnelle.dart';
import 'locataire/parametres/legal.dart';
import 'locataire/parametres/methode_paiement.dart';
import 'locataire/parametres/paiement_et_versement.dart';
import 'locataire/parametres/parametre_profile.dart';
import 'locataire/parametres/profile.dart';
import 'locataire/parametres/vos_paiements.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();


  // LOCALISATION
  await initializeDateFormatting('fr_FR', null);


  // SUPABASE

  await Supabase.initialize(
    url: 'https://rcaujtlhfyumkuwdfpcm.supabase.co',
    publishableKey:
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJjYXVqdGxoZnl1bWt1d2RmcGNtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjAyMzM5MTEsImV4cCI6MjA3NTgwOTkxMX0.AAGqqVywuJ_0D4YT9_TcE6-CKs2b3A4TS60mSEGIgbE',
  );


  // SERVICES
  ServiceLocator.initialize();

  // APPLICATION
  runApp(const TenantApp());
}

class TenantApp extends StatelessWidget {
  const TenantApp({super.key});

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

            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],

            supportedLocales: const [
              Locale('fr', 'FR'),
              Locale('en', 'US'),
            ],

            locale: const Locale('fr', 'FR'),

            // NAVIGATION

            navigatorKey: ServiceLocator.navigation.navigatorKey,
            scaffoldMessengerKey: SnackBarService.messengerKey,
            theme: ThemeData(
              primarySwatch: Colors.blue,
              fontFamily: 'Inter',
              scaffoldBackgroundColor: const Color(0xFFFFEFE0),
            ),

            home: const WelcomeScreen(),

            routes: {
              // ACCUEIL

              '/main': (context) => const MainPage(),
              '/home1': (context) => const WelcomeScreen(),
              '/onboarding': (context) => const OnboardingScreen(),
              '/home2': (context) => const Home2Page(),

              // AUTHENTIFICATION LOCATAIRE
              '/connexion': (context) => const ConnexionWidget(),
              '/register': (context) => const RegisterPage(),
              '/reset_password': (context) => const ResetPasswordWidget(),

              // PROFIL
              '/parametres': (context) => const ProfilePage(),
              '/notinfications': (context) => const NotificationsPage(),
              '/parametre_profile': (context) => const SettingsPage(),
              '/information_personnelle': (context) => const InformationPersonnellePage(),
              '/documents_verification': (context) => const DocumentsVerificationPage(),
              '/connexion_securite': (context) => const ConnexionSecuritePage(),

              // PARAMÈTRES
              '/legal': (context) => const LegalPage(),
              '/centre_aide': (context) => const HelpPage(),
              '/confidentialite': (context) => const ConfidentialitePage(),
              '/accessibilite': (context) => const AccessibilitePage(),
              '/conditions': (context) => const ConditionsPage(),
              '/politiques': (context) => const ConfidentialitePage(),
              '/licence': (context) => const ConditionsPage(),

              // ==================================================
              // PAIEMENTS
              '/paiement_versement': (context) => const PaiementEtVersementPage(),
              '/mode_paiement': (context) => const ModePaiementPage(),
              '/vos_paiements': (context) => const VosPaiementsPage(),
              '/coupons': (context) => const CouponsPage(),

              // AUTRES
              '/google_map': (context) => const GoogleMapPage(),
              '/liste_reservation': (context) => const ListeReservationsPage(),
              '/favorite': (context) => const FavoritesPage(),
              '/message': (context) => const MessagePage(),
            },

            onGenerateRoute: (settings) {
              if (settings.name == '/') {
                return MaterialPageRoute(
                  builder: (_) => const WelcomeScreen(),
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