import 'package:intl/intl.dart';

class DateUtilsHelper {
  static String formatDateFrench(DateTime date) {
    final day = date.day;
    final monthNames = [
      'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
      'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
    ];
    final month = monthNames[date.month - 1];
    final year = date.year;
    final weekdayNames = [
      'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'
    ];
    final weekday = weekdayNames[date.weekday - 1];
    return '$weekday $day $month $year';
  }

  static String formatDateShortFR(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  static String formatDateLong(String? dateStr) {
    if (dateStr == null) return '---';
    try {
      final date = DateTime.parse(dateStr);
      final formatter = DateFormat('EEE d MMM yyyy', 'fr_FR');
      return formatter.format(date);
    } catch (e) {
      return dateStr;
    }
  }

  static num safeParsePrice(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value;
    if (value is String) return num.tryParse(value) ?? 0;
    return 0;
  }
}