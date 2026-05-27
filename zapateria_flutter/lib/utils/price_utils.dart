import 'package:intl/intl.dart';

String formatPrice(double price) {
  return NumberFormat('#,##0.00', 'es_MX').format(price);
}

String formatCurrency(double price) {
  return NumberFormat.currency(locale: 'es_MX', symbol: '\$ ', decimalDigits: 2).format(price);
}

double parsePrice(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) {
    final clean = value.replaceAll(RegExp(r'[^\d.]'), '');
    return double.tryParse(clean) ?? 0.0;
  }
  return 0.0;
}
