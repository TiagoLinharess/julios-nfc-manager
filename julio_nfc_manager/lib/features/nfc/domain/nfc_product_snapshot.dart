import '../../products/domain/product.dart';

class NfcProductSnapshot {
  const NfcProductSnapshot({
    required this.productId,
    required this.name,
    required this.amountKg,
  });

  final String productId;
  final String name;
  final String amountKg;

  factory NfcProductSnapshot.fromProduct(Product product) {
    return NfcProductSnapshot(
      productId: product.id,
      name: product.name,
      amountKg: product.amountKg,
    );
  }

  factory NfcProductSnapshot.fromMap(Map<String, dynamic> map) {
    return NfcProductSnapshot(
      productId: map['productId'] as String? ?? '',
      name: map['name'] as String? ?? '',
      amountKg: map['amountKg'] as String? ?? '',
    );
  }

  Map<String, Object?> toMap() {
    return {
      'productId': productId,
      'name': name,
      'amountKg': amountKg,
    };
  }
}
