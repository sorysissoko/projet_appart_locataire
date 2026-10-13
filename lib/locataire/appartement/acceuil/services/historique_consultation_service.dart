import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HistoriqueConsultationService {

  final SupabaseClient supabase = Supabase.instance.client;


  /// Ajouter une consultation
  Future<void> ajouterConsultation(String appartementId) async {

    final user = supabase.auth.currentUser;

    if (user == null) return;

    try {

      await supabase.rpc(
        'ajouter_historique_consultation',
        params: {
          'p_appartement_id': appartementId,
        },
      );

    } catch (e) {

      debugPrint(
        "Erreur ajout historique consultation : $e",
      );

    }
  }



  /// Récupérer les appartements récemment consultés
  Future<List<Map<String, dynamic>>> getHistorique() async {
    final user = supabase.auth.currentUser;

    if (user == null) return [];

    try {
      final response = await supabase
          .from('historique_consultations')
          .select('''
          id,
          appartement_id,
          user_id,
          date_vue,
          appartement:appartements!historique_consultations_appartement_id_fkey (
            id,
            titre,
            description,
            type,
            prix,
            prix_proprietaire,
            frais_service,
            nbre_sejour,
            status,
            residence_id,
            avg_rating,
            ratings_count,
            autres_equipements
          )
        ''')
          .eq('user_id', user.id)
          .order('date_vue', ascending: false)
          .limit(10);

      // Aplatir : on veut une liste d'appartements enrichis
      final List<Map<String, dynamic>> result = [];

      for (final row in response) {
        final appartement = row['appartement'];

        if (appartement is Map) {
          final app = Map<String, dynamic>.from(appartement);

          // Ajouter les infos de consultation
          app['historique_id'] = row['id'];
          app['date_vue'] = row['date_vue'];

          result.add(app);
        }
      }

      return result;
    } catch (e) {
      debugPrint("Erreur récupération historique : $e");
      return [];
    }
  }



  /// Supprimer tout l'historique utilisateur
  Future<void> supprimerHistorique() async {

    final user = supabase.auth.currentUser;

    if (user == null) return;


    try {

      await supabase
          .from('historique_consultations')
          .delete()
          .eq(
        'user_id',
        user.id,
      );


    } catch (e) {

      debugPrint(
        "Erreur suppression historique : $e",
      );

    }

  }



  /// Supprimer une consultation
  Future<void> supprimerUneConsultation(
      String historiqueId,
      ) async {


    final user = supabase.auth.currentUser;

    if (user == null) return;


    try {

      await supabase
          .from('historique_consultations')
          .delete()
          .eq(
        'id',
        historiqueId,
      )
          .eq(
        'user_id',
        user.id,
      );


    } catch (e) {

      debugPrint(
        "Erreur suppression consultation : $e",
      );

    }

  }

}