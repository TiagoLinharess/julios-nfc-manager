import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/formatting/br_decimal_formatter.dart';
import '../../../core/firestore/firestore_date.dart';
import 'nfc_product_snapshot.dart';

class NfcRecord {
  const NfcRecord({
    required this.id,
    required this.code,
    required this.date,
    required this.products,
    required this.customerId,
    required this.totalValue,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String code;
  final String date;
  final List<NfcProductSnapshot> products;
  final String customerId;
  final String totalValue;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory NfcRecord.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? {};
    final rawProducts = data['products'];

    return NfcRecord(
      id: snapshot.id,
      code: data['code'] as String? ?? '',
      date: data['date'] as String? ?? '',
      products: rawProducts is List
          ? rawProducts
              .whereType<Map>()
              .map((product) => NfcProductSnapshot.fromMap(
                    Map<String, dynamic>.from(product),
                  ))
              .toList()
          : const [],
      customerId: data['customerId'] as String? ?? '',
      totalValue: formatBrDecimal(
        data['totalValue'] as String? ?? data['amount']?.toString() ?? '',
      ),
      createdAt: readFirestoreDate(data['createdAt']),
      updatedAt: readFirestoreDate(data['updatedAt']),
    );
  }
}
