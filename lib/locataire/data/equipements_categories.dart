import 'package:flutter/material.dart';

class EquipementsCategories {
  static final Map<String, dynamic> data = {
    "cuisine": {
      "label": "Cuisine et salle à manger",
      "icon": Icons.kitchen,
      "description": "Espace où les clients peuvent cuisiner leurs repas",
      "items": {
        "refrigerateur": {
          "label": "Réfrigérateur",
          "icon": Icons.kitchen_outlined,
        },
        "micro_ondes": {
          "label": "Micro-ondes",
          "icon": Icons.microwave,
        },
        "four": {
          "label": "Four",
          "icon": Icons.local_fire_department,
        },
        "cuisiniere_gaz": {
          "label": "Cuisinière à gaz",
          "icon": Icons.local_fire_department_outlined,
        },
        "bouilloire": {
          "label": "Bouilloire",
          "icon": Icons.emoji_food_beverage,
        },
        "cafetiere": {
          "label": "Cafetière",
          "icon": Icons.coffee,
        },
        "grille_pain": {
          "label": "Grille-pain",
          "icon": Icons.bakery_dining,
        },
        "mixeur": {
          "label": "Mixeur",
          "icon": Icons.blender,
        },
        "lave_vaisselle": {
          "label": "Lave-vaisselle",
          "icon": Icons.dining,
        },
        "verres_vin": {
          "label": "Verres à vin",
          "icon": Icons.wine_bar,
        },
        "plats_argenterie": {
          "label": "Vaisselle & argenterie",
          "icon": Icons.restaurant,
          "description": "bols, baguettes, assiettes, tasses, etc"
        },
        "table_manger": {
          "label": "Table à manger",
          "icon": Icons.table_restaurant,
        },
        "bases_cuisine": {
          "label": "Bases de cuisine",
          "icon": Icons.kitchen,
          "description": "casseroles et poêles,etc"
        },
        "congelateur": {
          "label": "Congélateur",
          "icon": Icons.ac_unit,
        },
        "sechoir_vetements": {
          "label": "Séchoir à vêtements",
          "icon": Icons.dry,
        }
      }
    },
    "salle_de_bain": {
      "label": "Salle de bain",
      "icon": Icons.bathroom,
      "items": {
        "baignoire": {
          "label": "Baignoire",
          "icon": Icons.bathtub,
        },
        "shampooing": {
          "label": "Shampooing",
          "icon": Icons.spa,
        },
        "savon_corps": {
          "label": "Savon corporel",
          "icon": Icons.soap,
        },
        "seche_cheveux": {
          "label": "Sèche-cheveux",
          "icon": Icons.air,
        },
        "eau_chaude": {
          "label": "Eau chaude",
          "icon": Icons.water_drop,
        },
        "gel_douche": {
          "label": "Gel douche",
          "icon": Icons.shower,
        },
        "serviettes_draps": {
          "label": "Serviettes & draps",
          "icon": Icons.bed,
        }
      }
    },
    "securite": {
      "label": "Sécurité",
      "icon": Icons.security,
      "items": {
        "camera_exterieure": {
          "label": "Caméra extérieure",
          "icon": Icons.videocam,
        },
        "alarme_monoxyde_carbone": {
          "label": "Alarme monoxyde de carbone",
          "icon": Icons.warning,
        },
        "serrure_chambre": {
          "label": "Serrure sécurisée",
          "icon": Icons.lock,
        }
      }
    },
    "divers": {
      "label": "Équipements divers",
      "icon": Icons.more_horiz,
      "description": "Autres équipements à votre disposition",
      "items": {
        "television": {
          "label": "Télévision",
          "icon": Icons.tv,
        },
        "cintres": {
          "label": "Cintres",
          "icon": Icons.checkroom,
        },
        "fer_repasser": {
          "label": "Fer à repasser",
          "icon": Icons.iron,
        },
        "laveuse_gratuite": {
          "label": "Laveuse",
          "icon": Icons.local_laundry_service,
        },
        "secheuse_gratuite": {
          "label": "Sécheuse",
          "icon": Icons.dry_cleaning,
        },
        "produits_nettoyage": {
          "label": "Produits de nettoyage",
          "icon": Icons.cleaning_services,
        }
      }
    }
  };

  static String? getCategoryForKey(String key) {
    for (final category in data.keys) {
      final items = data[category]['items'] as Map<String, dynamic>;
      if (items.containsKey(key)) return category;
    }
    return null;
  }

  static String getLabelForKey(String key) {
    for (final category in data.keys) {
      final items = data[category]['items'] as Map<String, dynamic>;
      if (items.containsKey(key)) {
        return items[key]['label'] as String;
      }
    }
    return key;
  }

  static IconData getIconForKey(String key) {
    for (final category in data.keys) {
      final items = data[category]['items'] as Map<String, dynamic>;
      if (items.containsKey(key)) {
        return items[key]['icon'] as IconData;
      }
    }
    return Icons.help_outline;
  }

  // ✅ NOUVELLE MÉTHODE : Description dynamique selon l'état actif/inactif
  static String getDescriptionForKey(String key, {bool isActive = true}) {
    String baseDescription = '';

    for (final category in data.keys) {
      final items = data[category]['items'] as Map<String, dynamic>;
      if (items.containsKey(key)) {
        baseDescription = items[key]['description'] ?? '';
        break;
      }
    }

    switch (key) {
      case 'serrure_chambre':
        return isActive
            ? 'Toutes les portes des chambres ont des serrures'
            : "Les portes des chambres n'ont pas de serrure";

      case 'camera_exterieure':
        return isActive
            ? 'Le bâtiment est sous surveillance'
            : 'Pas de caméra';

      case 'laveuse_gratuite':
        return isActive
            ? 'Lave-linge à disposition gratuitement'
            : 'Lave-linge non disponible';

      case 'secheuse_gratuite':
        return isActive
            ? 'Sèche-linge gratuit'
            : 'Sèche-linge non disponible';

      case 'alarme_monoxyde_carbone':
        return isActive
            ? 'Détection des fuites de gaz'
            : 'Pas de détecteur de monoxyde de carbone';

      default:
        return baseDescription;
    }
  }

  static String getCategoryDescription(String categoryKey) {
    if (data.containsKey(categoryKey)) {
      return data[categoryKey]['description'] ?? '';
    }
    return '';
  }
}