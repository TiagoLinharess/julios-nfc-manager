import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/formatting/br_decimal_formatter.dart';
import '../../../core/firestore/firestore_date.dart';
import 'nfc_return_product_snapshot.dart';

class NfcReturnRecord {
  const NfcReturnRecord({
    required this.id,
    required this.code,
    required this.date,
    required this.totalValue,
    required this.products,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String code;
  final String date;
  final String totalValue;
  final List<NfcReturnProductSnapshot> products;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory NfcReturnRecord.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? {};
    final rawProducts = data['products'];

    return NfcReturnRecord(
      id: snapshot.id,
      code: data['code'] as String? ?? '',
      date: data['date'] as String? ?? '',
      totalValue: formatBrDecimal(data['totalValue']?.toString() ?? ''),
      products: rawProducts is List
          ? rawProducts
              .whereType<Map>()
              .map((product) => NfcReturnProductSnapshot.fromMap(
                    Map<String, dynamic>.from(product),
                  ))
              .toList()
          : const [],
      createdAt: readFirestoreDate(data['createdAt']),
      updatedAt: readFirestoreDate(data['updatedAt']),
    );
  }
}
