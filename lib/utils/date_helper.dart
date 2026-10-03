import 'package:intl/intl.dart';

class DateHelper {
  static String toJalali(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';

    try {
      final date = DateTime.parse(dateStr);
      final formatter = DateFormat('yyyy/MM/dd', 'fa');
      return formatter.format(date);
    } catch (e) {
      return dateStr;
    }
  }

  static String toJalaliWithTime(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';

    try {
      final date = DateTime.parse(dateStr);
      final formatter = DateFormat('yyyy/MM/dd - HH:mm', 'fa');
      return formatter.format(date);
    } catch (e) {
      return dateStr;
    }
  }

  static String nowJalali() {
    final formatter = DateFormat('yyyy/MM/dd', 'fa');
    return formatter.format(DateTime.now());
  }
}