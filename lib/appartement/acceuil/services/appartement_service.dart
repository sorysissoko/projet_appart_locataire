import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:service/database_service.dart';
import 'package:service/rating/rating_service.dart';

class AppartementService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final DatabaseService _db = DatabaseService();
  final RatingService _ratingService = RatingService();

  final Map<String, List<String>> imagesCache = {};

  Future<Map<String, dynamic>> loadAllData() async {
    final villes = ['Bamako', 'Kayes', 'Koulikoro', 'Sikasso', 'Segou', 'Bougouni', 'Koutiala', 'Mopti'];
    final types = ['Appart', 'Villa'];

    final allApps = await _db.fetchAppartementsForDashboard(villes: villes, types: types);
    if (allApps.isEmpty) return {'appartements': []};

    final ids = allApps.map((e) => e['id'].toString()).toList();
    imagesCache.clear();

    // Charger les disponibilités
    final disponibilites = await _supabase.from('disponibilites')
        .select('appartement_id, date_debut, date_fin')
        .inFilter('appartement_id', ids);

    final Map<String, Map<String, dynamic>> dispoMap = {};
    for (final d in disponibilites) {
      dispoMap[d['appartement_id'].toString()] = d;
    }

    // Charger les photos
    final photos = await _supabase.from('photo_appartements')
        .select('appartement_id, fichiername')
        .inFilter('appartement_id', ids)
        .order('est_principale', ascending: false)
        .order('ordre_affichage');

    final Map<String, List<String>> imagesMap = {};
    for (final p in photos) {
      final id = p['appartement_id'].toString();
      final file = p['fichiername'];
      imagesMap.putIfAbsent(id, () => []);
      imagesMap[id]!.add('https://rcaujtlhfyumkuwdfpcm.supabase.co/storage/v1/object/public/appartements/$id/$file');
    }

    // Charger Ratings
    final ratingsData = await _ratingService.loadRatingsForAppartements(ids);

    // Injection finale dans les appartements
    for (final app in allApps) {
      final id = app['id'].toString();
      final dispo = dispoMap[id];
      if (dispo != null) { app['date_debut'] = dispo['date_debut']; app['date_fin'] = dispo['date_fin']; }
      app['images'] = imagesMap[id] ?? [];
      final ratingInfo = ratingsData[id] ?? {};
      app['avg_rating'] = ratingInfo['avg_rating'] ?? 0.0;
      app['ratings_count'] = ratingInfo['ratings_count'] ?? 0;
    }

    return {'appartements': allApps};
  }
}