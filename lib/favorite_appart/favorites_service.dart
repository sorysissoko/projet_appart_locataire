import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:service/snackbar_service.dart';
import 'models/favorite_model.dart';

class FavoritesService extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Liste complète des favoris pour la page Favorites
  List<FavoriteModel> _favorites = [];
  bool _isLoading = false;

  // Set simple pour vérifier rapidement si un ID est favori (pour la page Appartement)
  final Set<String> _favoriteIds = {};
  bool _isToggling = false; // Pour éviter les clics multiples

  List<FavoriteModel> get favorites => _favorites;
  bool get isLoading => _isLoading;

  // --- Pour la page Appartement ---
  bool isFavorite(String id) => _favoriteIds.contains(id);

  // --- Gestion des favoris (pour la page Appartement) ---
// Dans favorites_service.dart (Méthode toggleFavorite mise à jour)
  Future<void> toggleFavorite(String id, {Map<String, dynamic>? appartementData}) async {
    if (_isToggling) return;
    _isToggling = true;

    final user = _supabase.auth.currentUser;
    if (user == null) {
      _isToggling = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        SnackBarService().showWarning('Connectez-vous pour ajouter aux favoris');
      });
      return;
    }

    final wasFavorite = _favoriteIds.contains(id);

    // 1. Optimistic update (mise à jour visuelle immédiate)
    if (wasFavorite) {
      _favoriteIds.remove(id);
      // Supprimer instantanément de la liste détaillée des favoris
      _favorites.removeWhere((fav) => fav.appartementId == id);
    } else {
      _favoriteIds.add(id);
      // Ajouter instantanément une carte de favori provisoire si on a les données
      if (appartementData != null) {
        final tempFav = FavoriteModel(
          id: 'temp_${DateTime.now().millisecondsSinceEpoch}', // ID temporaire
          appartementId: id,
          appartement: Map.from(appartementData), // Copie profonde
        );
        // On l'ajoute au début de la liste pour qu'il soit visible immédiatement
        _favorites.insert(0, tempFav);
      }
    }
    notifyListeners(); // 🔥 Déclenche le rebuild immédiat de la page Favoris

    try {
      // 2. Appel à Supabase
      if (wasFavorite) {
        await _supabase.from('favorites').delete().eq('user_id', user.id).eq('appartement_id', id);
      } else {
        await _supabase.from('favorites').insert({
          'user_id': user.id,
          'appartement_id': id,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      // 3. Resynchronisation en arrière-plan pour garantir que tout est parfait
      _refreshFavoritesInBackground();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        SnackBarService().showSuccess(wasFavorite ? 'Retiré des favoris ❤️' : 'Ajouté aux favoris ❤️');
      });

    } catch (e) {
      // 4. Rollback en cas d'échec
      if (wasFavorite) {
        _favoriteIds.add(id);
      } else {
        _favoriteIds.remove(id);
      }
      notifyListeners();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        SnackBarService().showError('Erreur, veuillez réessayer');
      });
    } finally {
      _isToggling = false;
    }
  }

// Méthode privée pour resynchroniser sans bloquer l'UI
  Future<void> _refreshFavoritesInBackground() async {
    try {
      await loadFavorites(background: true);
    } catch (e) {
      debugPrint("Erreur resync silencieuse: $e");
    }
  }


  // --- Pour la page Favorites (Load & Remove) ---
  Future<void> loadFavorites({bool background = false}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      _favorites = [];
      _favoriteIds.clear();
      notifyListeners();
      return;
    }

    if (!background) {
      _isLoading = true;
      notifyListeners();
    }

    try {
      final data = await _supabase
          .from('favorites')
          .select('id, appartement_id, appartements (*)')
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      _favorites = (data as List).map((e) => FavoriteModel.fromJson(e)).toList();
      _favoriteIds.clear();
      for (var fav in _favorites) {
        _favoriteIds.add(fav.appartementId);
      }

      await _fetchAdditionalData();

      if (!background) _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur favoris: $e');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }


  Future<void> _fetchAdditionalData() async {
    if (_favorites.isEmpty) return;
    final ids = _favorites.map((fav) => fav.appartementId).toList();

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
        imagesMap[id]!.add('https://rcaujtlhfyumkuwdfpcm.supabase.co/storage/v1/object/public/appartements/$id/$file');
      }

      final disponibilites = await _supabase
          .from('disponibilites')
          .select('appartement_id, date_debut, date_fin')
          .inFilter('appartement_id', ids);

      final Map<String, Map<String, dynamic>> dispoMap = {};
      for (final d in disponibilites) {
        dispoMap[d['appartement_id'].toString()] = d;
      }

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
        final avg = list.isNotEmpty ? list.reduce((a, b) => a + b) / list.length : 0.0;
        avgRatings[id] = avg;
      }

      for (var fav in _favorites) {
        final appId = fav.appartementId;
        final appartement = fav.appartement;
        appartement['images'] = imagesMap[appId] ?? ['assets/images/default.jpg'];
        appartement['avg_rating'] = avgRatings[appId] ?? 0.0;
        final dispo = dispoMap[appId];
        if (dispo != null) {
          appartement['date_debut'] = dispo['date_debut'];
          appartement['date_fin'] = dispo['date_fin'];
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Erreur chargement données additionnelles: $e');
    }
  }

  Future<void> removeFavorite(String favoriteId) async {
    try {
      // 1. Trouver l'ID de l'appartement associé à ce favoriteId AVANT de le supprimer de la liste
      final favIndex = _favorites.indexWhere((fav) => fav.id == favoriteId);
      if (favIndex == -1) return; // Déjà supprimé

      final appartementId = _favorites[favIndex].appartementId;

      // 2. Appel API
      await _supabase.from('favorites').delete().eq('id', favoriteId);

      // 3. Supprimer de la liste locale
      _favorites.removeAt(favIndex);

      // 4. Retirer du Set des IDs pour la page Appartement
      _favoriteIds.remove(appartementId);

      notifyListeners();
    } catch (e) {
      debugPrint('Erreur suppression: $e');
      rethrow;
    }
  }
}