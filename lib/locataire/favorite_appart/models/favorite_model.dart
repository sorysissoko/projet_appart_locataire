class FavoriteModel {
  final String id;
  final String appartementId;
  final Map<String, dynamic> appartement; // Contient les infos brutes de l'appartement

  FavoriteModel({
    required this.id,
    required this.appartementId,
    required this.appartement,
  });

  factory FavoriteModel.fromJson(Map<String, dynamic> json) {
    return FavoriteModel(
      id: json['id'].toString(),
      appartementId: json['appartement_id'].toString(),
      appartement: json['appartements'] as Map<String, dynamic>? ?? {},
    );
  }
}