import '../../../core/formatting/br_decimal_formatter.dart';
import '../../products/domain/product.dart';

class NfcProductSnapshot {
  const NfcProductSnapshot({
    required this.productId,
    required this.name,
    required this.pricePerKg,
    required this.quantityKg,
  });

  final String productId;
  final String name;
  final String pricePerKg;
  final String quantityKg;

  factory NfcProductSnapshot.fromProduct(
    Product product, {
    required String quantityKg,
  }) {
    return NfcProductSnapshot(
      productId: product.id,
      name: product.name,
      pricePerKg: product.pricePerKg,
      quantityKg: formatBrDecimal(quantityKg),
    );
  }

  factory NfcProductSnapshot.fromMap(Map<String, dynamic> map) {
    return NfcProductSnapshot(
      productId: map['productId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      pricePerKg: formatBrDecimal(
        map['pricePerKg'] as String? ?? map['amountKg'] as String? ?? '',
      ),
      quantityKg: formatBrDecimal(map['quantityKg'] as String? ?? '1'),
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
