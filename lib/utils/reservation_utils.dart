import 'dart:ui';


enum ReservationStatus { enAttente, confirmee, terminee, annulee, refuse }

num safeParsePrice(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value;
  if (value is String) return num.tryParse(value) ?? 0;
  return 0;
}

ReservationStatus determineReservationStatus(Map<String, dynamic> reservation) {
  final now = DateTime.now();
  final dateFin = reservation['date_fin'] != null
      ? DateTime.tryParse(reservation['date_fin'].toString())
      : null;
  final statut = reservation['statut']?.toString().toLowerCase() ?? 'en_attente';

  if (statut == 'annulee' || statut == 'annulée' || statut == 'refuse' ||
      statut == 'refusé') {
    return ReservationStatus.annulee;
  }

  if (dateFin != null && dateFin.isBefore(now)) {
    return ReservationStatus.terminee;
  }

  switch (statut) {
    case 'confirmee':
    case 'confirmée':
      return ReservationStatus.confirmee;
    case 'terminee':
    case 'terminée':
      return ReservationStatus.terminee;
    default:
      return ReservationStatus.enAttente;
  }
}

Map<String, dynamic> getStatusConfig(ReservationStatus status) {
  switch (status) {
    case ReservationStatus.enAttente:
      return {
        'label': 'En attente',
        'bg': const Color(0xFFFFF7E6),
        'border': const Color(0xFFFFD966),
        'dot': const Color(0xFFFFA500),
        'text': const Color(0xFFB45309),
      };
    case ReservationStatus.confirmee:
      return {
        'label': 'Confirmée',
        'bg': const Color(0xFFE6F7FF),
        'border': const Color(0xFF66C4FF),
        'dot': const Color(0xFF2E8B57),
        'text': const Color(0xFF0A5E2E),
      };
    case ReservationStatus.terminee:
      return {
        'label': 'Terminée',
        'bg': const Color(0xFFF3F4F6),
        'border': const Color(0xFFD1D5DB),
        'dot': const Color(0xFF6B7280),
        'text': const Color(0xFF374151),
      };
    case ReservationStatus.annulee:
    case ReservationStatus.refuse:
      return {
        'label': 'Annulée',
        'bg': const Color(0xFFFEF2F2),
        'border': const Color(0xFFFCA5A5),
        'dot': const Color(0xFFDC2626),
        'text': const Color(0xFF991B1B),
      };
  }
}