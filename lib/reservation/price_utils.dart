import 'package:intl/intl.dart';

String formatPrice(num price) {
  final formatter = NumberFormat("#,###", "fr_FR");
  return "${formatter.format(price)} FCFA";
}

Map<String, double> calculerPrixAvecReduction({
  required double prixProprietaire,
  required double fraisService,
  required int nuits,
}) {
  double tauxReductionProprietaire = 0;
  double tauxReductionService = 0;

  if (nuits >= 1 && nuits <= 2) {
    tauxReductionProprietaire = 0.00;
    tauxReductionService = 0.00;
  } else if (nuits >= 3 && nuits <= 5) {
    tauxReductionProprietaire = 0.03;
    tauxReductionService = 0.00;
  } else if (nuits >= 6 && nuits <= 10) {
    tauxReductionProprietaire = 0.05;
    tauxReductionService = 0.00;
  } else if (nuits >= 11 && nuits <= 15) {
    tauxReductionProprietaire = 0.07;
    tauxReductionService = 0.01;
  } else if (nuits >= 16 && nuits <= 20) {
    tauxReductionProprietaire = 0.08;
    tauxReductionService = 0.02;
  } else if (nuits >= 21 && nuits <= 30) {
    tauxReductionProprietaire = 0.10;
    tauxReductionService = 0.02;
  } else if (nuits > 30) {
    tauxReductionProprietaire = 0.12;
    tauxReductionService = 0.03;
  }

  double reductionProprietaireParNuit = prixProprietaire * tauxReductionProprietaire;
  double reductionServiceParNuit = fraisService * tauxReductionService;

  double sousTotal = (prixProprietaire + fraisService) * nuits;
  double totalReduction = (reductionProprietaireParNuit + reductionServiceParNuit) * nuits;
  double total = sousTotal - totalReduction;

  return {
    "total": total,
    "reductionProprietaire": reductionProprietaireParNuit * nuits,
    "reductionService": reductionServiceParNuit * nuits,
    "prixProTotal": prixProprietaire * nuits,
    "serviceTotal": fraisService * nuits,
    "totalReduction": totalReduction,
    "sousTotal": sousTotal,
  };
}