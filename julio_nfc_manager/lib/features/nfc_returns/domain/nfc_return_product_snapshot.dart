import '../../../core/formatting/br_decimal_formatter.dart';
import '../../nfc/domain/nfc_product_snapshot.dart';

class NfcReturnProductSnapshot {
  const NfcReturnProductSnapshot({
    required this.productId,
    required this.name,
    required this.pricePerKg,
    required this.quantityKg,
  });

  final String productId;
  final String name;
  final String pricePerKg;
  final String quantityKg;

  factory NfcReturnProductSnapshot.fromNfcProduct(
    NfcProductSnapshot product, {
    required String quantityKg,
  }) {
    return NfcReturnProductSnapshot(
      productId: product.productId,
      name: product.name,
      pricePerKg: product.pricePerKg,
      quantityKg: formatBrDecimal(quantityKg),
    );
  }

  factory NfcReturnProductSnapshot.fromMap(Map<String, dynamic> map) {
    return NfcReturnProductSnapshot(
      productId: map['productId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      pricePerKg: formatBrDecimal(map['pricePerKg']?.toString() ?? ''),
      quantityKg: formatBrDecimal(map['quantityKg']?.toString() ?? ''),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'productId': productId,
      'name': name,
      'pricePerKg': pricePerKg,
      'quantityKg': quantityKg,
    };
  }
}
