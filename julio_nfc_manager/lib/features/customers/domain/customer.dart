import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firestore/firestore_date.dart';

class Customer {
  const Customer({
    required this.id,
    required this.name,
    required this.cnpj,
    required this.cnpjDigits,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String cnpj;
  final String cnpjDigits;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Customer.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? {};

    return Customer(
      id: snapshot.id,
      name: data['name'] as String? ?? '',
      cnpj: data['cnpj'] as String? ?? '',
      cnpjDigits: data['cnpjDigits'] as String? ?? '',
      createdAt: readFirestoreDate(data['createdAt']),
      updatedAt: readFirestoreDate(data['updatedAt']),
    );
  }
}
