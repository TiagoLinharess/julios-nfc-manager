import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firestore/firestore_date.dart';
import '../../../core/firestore/user_firestore.dart';
import '../domain/nfc_return_product_snapshot.dart';
import '../domain/nfc_return_record.dart';

class NfcReturnsRepository {
  const NfcReturnsRepository(this.store);

  final UserFirestore store;

  Stream<List<NfcReturnRecord>> watchAll(String nfcId) {
    return store
        .nfcReturnsFor(nfcId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map(NfcReturnRecord.fromFirestore).toList();
    });
  }

  Stream<NfcReturnRecord?> watchById({
    required String nfcId,
    required String id,
  }) {
    return store.nfcReturnsFor(nfcId).doc(id).snapshots().map((snapshot) {
      if (!snapshot.exists) {
        return null;
      }

      return NfcReturnRecord.fromFirestore(snapshot);
    });
  }

  Future<DocumentReference<Map<String, dynamic>>> create({
    required String nfcId,
    required String code,
    required String date,
    required String totalValue,
    required List<NfcReturnProductSnapshot> products,
  }) {
    return store.nfcReturnsFor(nfcId).add({
      'code': code.trim(),
      'date': date.trim(),
      'totalValue': totalValue.trim(),
      'products': products.map((product) => product.toMap()).toList(),
      ...createTimestamps(),
    });
  }

  Future<void> delete({
    required String nfcId,
    required String id,
  }) {
    return store.nfcReturnsFor(nfcId).doc(id).delete();
  }

  Future<void> update({
    required String nfcId,
    required String id,
    required String code,
    required String date,
    required String totalValue,
    required List<NfcReturnProductSnapshot> products,
  }) {
    return store.nfcReturnsFor(nfcId).doc(id).update({
      'code': code.trim(),
      'date': date.trim(),
      'totalValue': totalValue.trim(),
      'products': products.map((product) => product.toMap()).toList(),
      ...updateTimestamp(),
    });
  }
}
