import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:service/snackbar_service.dart';
import 'models/favorite_model.dart';

class FavoritesService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  // ÉTAT
  List<FavoriteModel> _favorites = [];
  bool _isLoading = false;

  final Set<String> _favoriteIds = {};
  bool _isToggling = false;

  //Cache des vérifications : id → vrai/faux
  final Map<String, bool> _favoriteStatusCache = {};

  // GETTERS

  List<FavoriteModel> get favorites => _favorites;
  bool get isLoading => _isLoading;
  bool isFavorite(String id) => _favoriteIds.contains(id);

  // TOGGLE FAVORI — INSTANTANÉ

  Future<void> toggleFavorite(
      String id, {
        Map<String, dynamic>? appartementData,
      }) async {
    if (_isToggling) return;
    _isToggling = true;

    final user = _supabase.auth.currentUser;

    if (user == null) {
      _isToggling = false;
      SnackBarService()
          .showWarning('Connectez-vous pour ajouter aux favoris');
      return;
    }

    //L'ÉTAT ACTUEL
    final wasFavorite = _favoriteIds.contains(id);

    //UPDATE IMMÉDIAT
    if (wasFavorite) {
      _favoriteIds.remove(id);
      _favorites.removeWhere((fav) => fav.appartementId == id);
    } else {
      _favoriteIds.add(id);

      if (appartementData != null) {
        final tempFav = FavoriteModel(
          id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
          appartementId: id,
          appartement: Map.from(appartementData),
        );
        _favorites.insert(0, tempFav);
      }
    }

    _favoriteStatusCache[id] = !wasFavorite;

    notifyListeners();

    //SNACKBAR
    SnackBarService().showSuccess(
      wasFavorite ? 'Retiré des favoris ❤️' : 'Ajouté aux favoris ❤️',
    );

    _isToggling = false;

    //APPEL RÉSEAU EN ARRIÈRE-PLAN
    _syncFavoriteToServer(
      appartementId: id,
      userId: user.id,
      isFavorite: !wasFavorite,
    );
  }

  // SYNCHRONISATION RÉSEAU (arrière-plan)
  Future<void> _syncFavoriteToServer({
    required String appartementId,
    required String userId,
    required bool isFavorite,
  }) async {
    try {
      if (isFavorite) {
        await _supabase.from('favorites').upsert(
          {
            'user_id': userId,
            'appartement_id': appartementId,
            'created_at': DateTime.now().toIso8601String(),
          },
          onConflict: 'user_id,appartement_id',
        );

        debugPrint('Favori ajouté en base : $appartementId');
      } else {
        //DELETE
        await _supabase
            .from('favorites')
            .delete()
            .eq('user_id', userId)
            .eq('appartement_id', appartementId);

        debugPrint('Favori retiré de la base : $appartementId');
      }
    } catch (e) {
      debugPrint('Erreur sync favori : $e');

      if (e is PostgrestException) {
        debugPrint('code : ${e.code}');
        debugPrint('message : ${e.message}');
      }

      // ROLLBACK EN CAS D'ÉCHEC (rare)
      if (isFavorite) {
        _favoriteIds.remove(appartementId);
        _favorites.removeWhere((fav) => fav.appartementId == appartementId);
      } else {
        _favoriteIds.add(appartementId);
      }

      notifyListeners();
    }
  }

  // CHARGER LES FAVORIS (au démarrage)
  Future<void> loadFavorites({bool background = false}) async {
    final user = _supabase.auth.currentUser;

    if (user == null) {
      _favorites = [];
      _favoriteIds.clear();
      _favoriteStatusCache.clear();
      notifyListeners();
      return;
    }

    if (!background) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      //RÉCUPÉRER LES FAVORIS
      final favoritesRaw = await _supabase
          .from('favorites')
          .select('id, appartement_id, created_at')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      if (favoritesRaw.isEmpty) {
        _favorites = [];
        _favoriteIds.clear();
        _favoriteStatusCache.clear();
        if (!background) _isLoading = false;
        notifyListeners();
        return;
      }

      //RÉCUPÉRER LES APPARTEMENTS
      final appartementIds = favoritesRaw
          .map((f) => f['appartement_id']?.toString())
          .whereType<String>()
          .toList();

      final appartementsRaw = await _supabase
          .from('appartements')
          .select('*')
          .inFilter('id', appartementIds);

      final Map<String, Map<String, dynamic>> appMap = {};

      for (final a in appartementsRaw) {
        final id = a['id']?.toString();
        if (id != null) {
          appMap[id] = Map<String, dynamic>.from(a);
        }
      }

      //CONSTRUIRE LA LISTE
      _favorites = favoritesRaw.map((f) {
        final appId = f['appartement_id']?.toString() ?? '';
        final app = appMap[appId] ?? {};

        return FavoriteModel(
          id: f['id']?.toString() ?? '',
          appartementId: appId,
          appartement: app,
        );
      }).toList();

      _favoriteIds.clear();
      _favoriteStatusCache.clear();

      for (final fav in _favorites) {
        _favoriteIds.add(fav.appartementId);
        _favoriteStatusCache[fav.appartementId] = true;
      }

      if (!background) _isLoading = false;
      notifyListeners();

      //DONNÉES ADDITIONNELLES (non bloquantes)
      _fetchAdditionalData();

    } catch (e) {
      debugPrint('Erreur loadFavorites : $e');

      if (e is PostgrestException) {
        debugPrint('code : ${e.code}');
        debugPrint('message : ${e.message}');
      }

      _isLoading = false;
      notifyListeners();
    }
  }

  // DONNÉES ADDITIONNELLES
  Future<void> _fetchAdditionalData() async {
    if (_favorites.isEmpty) return;

    final ids = _favorites.map((fav) => fav.appartementId).toList();

    await Future.wait([
      _loadPhotos(ids),
      _loadDisponibilites(ids),
      _loadRatings(ids),
    ]);

    notifyListeners();
  }

  Future<void> _loadPhotos(List<String> ids) async {
    try {
      final photos = await _supabase
          .from('photo_appartements')
          .select('appartement_id, fichiername')
          .inFilter('appartement_id', ids)
          .order('est_principale', ascending: false)
          .order('ordre_affichage');

      final Map<String, List<String>> imagesMap = {};

      for (final p in photos) {
        final id = p['appartement_id'].toString();
        final file = p['fichiername'];

        imagesMap.putIfAbsent(id, () => []);
        imagesMap[id]!.add(
          'https://rcaujtlhfyumkuwdfpcm.supabase.co/storage/v1/object/public/appartements/$id/$file',
        );
      }

      for (final fav in _favorites) {
        fav.appartement['images'] =
            imagesMap[fav.appartementId] ?? ['assets/images/default.jpg'];
      }
    } catch (e) {
      debugPrint('Erreur photos : $e');
    }
  }

  Future<void> _loadDisponibilites(List<String> ids) async {
    try {
      final disponibilites = await _supabase
          .from('disponibilites')
          .select('appartement_id, date_debut, date_fin')
          .inFilter('appartement_id', ids);

      final Map<String, Map<String, dynamic>> dispoMap = {};

      for (final d in disponibilites) {
        dispoMap[d['appartement_id'].toString()] = d;
      }

      for (final fav in _favorites) {
        final dispo = dispoMap[fav.appartementId];

        if (dispo != null) {
          fav.appartement['date_debut'] = dispo['date_debut'];
          fav.appartement['date_fin'] = dispo['date_fin'];
        }
      }
    } catch (e) {
      debugPrint('Erreur dispos : $e');
    }
  }

  Future<void> _loadRatings(List<String> ids) async {
    try {
      final ratings = await _supabase
          .from('ratings')
          .select('appartement_id, rating')
          .inFilter('appartement_id', ids);

      final Map<String, double> avgRatings = {};
      final Map<String, List<int>> ratingsList = {};

      for (final r in ratings) {
        final id = r['appartement_id'].toString();
        final ratingValue = r['rating'] as int;

        ratingsList.putIfAbsent(id, () => []);
        ratingsList[id]!.add(ratingValue);
      }

      for (final id in ids) {
        final list = ratingsList[id] ?? [];
        final avg = list.isNotEmpty
            ? list.reduce((a, b) => a + b) / list.length
            : 0.0;

        avgRatings[id] = avg;
      }

      for (final fav in _favorites) {
        fav.appartement['avg_rating'] =
            avgRatings[fav.appartementId] ?? 0.0;
      }
    } catch (e) {
      debugPrint('Erreur ratings : $e');
    }
  }

  // SUPPRIMER UN FAVORI
  Future<void> removeFavorite(String favoriteId) async {
    try {
      final favIndex = _favorites.indexWhere(
            (fav) => fav.id == favoriteId,
      );

      if (favIndex == -1) return;

      final appartementId = _favorites[favIndex].appartementId;

      //Optimistic update immédiat
      _favorites.removeAt(favIndex);
      _favoriteIds.remove(appartementId);
      _favoriteStatusCache.remove(appartementId);
      notifyListeners();

      //Appel réseau en arrière-plan
      await _supabase
          .from('favorites')
          .delete()
          .eq('id', favoriteId);

    } catch (e) {
      debugPrint('Erreur suppression : $e');
    }
  }
}