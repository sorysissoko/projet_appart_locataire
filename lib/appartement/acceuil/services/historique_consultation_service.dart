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
          .from('vue_historique_consultations')
          .select()
          .eq(
        'user_id',
        user.id,
      )
          .order(
        'date_vue',
        ascending: false,
      )
          .limit(10);


      return List<Map<String, dynamic>>.from(response);


    } catch (e) {

      debugPrint(
        "Erreur récupération historique : $e",
      );

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