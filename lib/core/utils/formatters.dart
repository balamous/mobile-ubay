import 'package:intl/intl.dart';

class AppFormatters {
  /// Format amount with GNF suffix
  static String formatCurrency(double amount, {String symbol = 'GNF'}) {
    final formatter = NumberFormat('#,###', 'fr_FR');
    return '${formatter.format(amount)} $symbol';
  }

  /// Compact format: 1 500 000 → 1,5M GNF
  static String formatCurrencyCompact(double amount) {
    if (amount >= 1000000000) {
      return '${(amount / 1000000000).toStringAsFixed(1)}Md GNF';
    } else if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M GNF';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K GNF';
    }
    return '${amount.toStringAsFixed(0)} GNF';
  }

  /// Raw number formatting (no currency suffix, for inputs)
  static String formatNumber(double amount) {
    final formatter = NumberFormat('#,###', 'fr_FR');
    return formatter.format(amount);
  }

  static String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy', 'fr_FR').format(date);
  }

  static String formatDateTime(DateTime date) {
    return DateFormat('dd MMM yyyy, HH:mm', 'fr_FR').format(date);
  }

  static String formatTime(DateTime date) {
    return DateFormat('HH:mm').format(date);
  }

  static String formatRelativeDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Aujourd\'hui';
    if (diff.inDays == 1) return 'Hier';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays} jours';
    return DateFormat('dd MMM yyyy', 'fr_FR').format(date);
  }

  static String maskCardNumber(String number) {
    if (number.length < 4) return number;
    return '**** **** **** ${number.substring(number.length - 4)}';
  }

  /// Guinean phone number: 620 12 34 56
  static String formatPhoneNumber(String phone) {
    if (phone.length == 9) {
      return '${phone.substring(0, 3)} ${phone.substring(3, 5)} ${phone.substring(5, 7)} ${phone.substring(7, 9)}';
    }
    return phone;
  }
}
