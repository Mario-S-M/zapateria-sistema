import 'package:uuid/uuid.dart';

const _uuid = Uuid();

String generateBarcode() {
  final uuid = _uuid.v4().replaceAll('-', '').substring(0, 12);
  return uuid.replaceAllMapped(RegExp(r'[^0-9]'), (m) => (m.start % 10).toString());
}

bool validateBarcode(String barcode) {
  return RegExp(r'^\d{12,13}$').hasMatch(barcode);
}

String formatBarcode(String barcode) {
  if (barcode.length == 13) {
    return '${barcode.substring(0, 3)}-${barcode.substring(3, 7)}-${barcode.substring(7, 12)}-${barcode.substring(12)}';
  }
  if (barcode.length == 12) {
    return '${barcode.substring(0, 3)}-${barcode.substring(3, 6)}-${barcode.substring(6, 10)}-${barcode.substring(10)}';
  }
  return barcode;
}
