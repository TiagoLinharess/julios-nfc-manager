import '../../../core/formatting/br_decimal_formatter.dart';
import '../../products/domain/product.dart';

class NfcProductSnapshot {
  const NfcProductSnapshot({
    required this.productId,
    required this.name,
    required this.pricePerKg,
  });

  final String productId;
  final String name;
  final String pricePerKg;

  factory NfcProductSnapshot.fromProduct(Product product) {
    return NfcProductSnapshot(
      productId: product.id,
      name: product.name,
      pricePerKg: product.pricePerKg,
    );
  }

  factory NfcProductSnapshot.fromMap(Map<String, dynamic> map) {
    return NfcProductSnapshot(
      productId: map['productId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      pricePerKg: formatBrDecimal(
        map['pricePerKg'] as String? ?? map['amountKg'] as String? ?? '',
      ),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'productId': productId,
      'name': name,
      'pricePerKg': pricePerKg,
    };
  }
}
