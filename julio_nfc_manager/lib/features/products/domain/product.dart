import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/formatting/br_decimal_formatter.dart';
import '../../../core/firestore/firestore_date.dart';

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.pricePerKg,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String pricePerKg;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Product.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? {};

    return Product(
      id: snapshot.id,
      name: data['name'] as String? ?? '',
      pricePerKg: formatBrDecimal(
        data['pricePerKg'] as String? ?? data['amountKg'] as String? ?? '',
      ),
      createdAt: readFirestoreDate(data['createdAt']),
      updatedAt: readFirestoreDate(data['updatedAt']),
    );
  }
}
