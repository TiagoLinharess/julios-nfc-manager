import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firestore/firestore_date.dart';
import '../../nfc/domain/nfc_product_snapshot.dart';
import '../../nfc/domain/nfc_record.dart';

class NfcReturn {
  const NfcReturn({
    required this.id,
    required this.code,
    required this.date,
    required this.products,
    required this.nfcId,
    required this.nfcCode,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String code;
  final String date;
  final List<NfcProductSnapshot> products;
  final String nfcId;
  final String nfcCode;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory NfcReturn.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final data = snapshot.data() ?? {};
    final rawProducts = data['products'];

    return NfcReturn(
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
      nfcId: data['nfcId'] as String? ?? '',
      nfcCode: data['nfcCode'] as String? ?? '',
      createdAt: readFirestoreDate(data['createdAt']),
      updatedAt: readFirestoreDate(data['updatedAt']),
    );
  }

  static Map<String, Object?> nfcSnapshot(NfcRecord nfc) {
    return {
      'nfcId': nfc.id,
      'nfcCode': nfc.code,
    };
  }
}
