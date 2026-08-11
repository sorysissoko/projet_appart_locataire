import 'package:intl/intl.dart';

String formatPrice(num price) {
  final formatter = NumberFormat("#,###", "fr_FR");
  return "${formatter.format(price)} FCFA";
}

num safeParsePrice(dynamic value) {
  if (value == null) return 0;
  if (value is num) return value;
  if (value is String) return num.tryParse(value) ?? 0;
  return 0;
}

String getDisponibiliteFromDates({DateTime? dateDebut, DateTime? dateFin}) {
  if (dateDebut == null || dateFin == null) return "Indisponible";
  final now = DateTime.now();
  final debut = DateTime(dateDebut.year, dateDebut.month, dateDebut.day);
  final fin = DateTime(dateFin.year, dateFin.month, dateFin.day);
  final today = DateTime(now.year, now.month, now.day);

  if (today.isAfter(fin)) return "Indisponible";
  if (!today.isBefore(debut)) return "Disponible maintenant";
  return "Disponible le ${debut.day.toString().padLeft(2, '0')}/${debut.month.toString().padLeft(2, '0')}/${debut.year}";
}