import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firestore/firestore_date.dart';
import '../../../core/firestore/user_firestore.dart';
import '../domain/nfc_product_snapshot.dart';
import '../domain/nfc_record.dart';

class NfcRepository {
  const NfcRepository(this.store);

  final UserFirestore store;

  Stream<List<NfcRecord>> watchAll() {
    return store.nfc
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(NfcRecord.fromFirestore).toList());
  }

  Stream<NfcRecord?> watchById(String id) {
    return store.nfc.doc(id).snapshots().map((snapshot) {
      if (!snapshot.exists) {
        return null;
      }

      return NfcRecord.fromFirestore(snapshot);
    });
  }

  Future<DocumentReference<Map<String, dynamic>>> create({
    required String code,
    required String date,
    required String customerId,
    required List<NfcProductSnapshot> products,
    required int amount,
  }) {
    return store.nfc.add({
      'code': code.trim(),
      'date': date.trim(),
      'products': products.map((product) => product.toMap()).toList(),
      'customerId': customerId,
      'amount': amount,
      ...createTimestamps(),
    });
  }

  Future<void> update({
    required String id,
    required String code,
    required String date,
    required String customerId,
    required List<NfcProductSnapshot> products,
    required int amount,
  }) {
    return store.nfc.doc(id).update({
      'code': code.trim(),
      'date': date.trim(),
      'products': products.map((product) => product.toMap()).toList(),
      'customerId': customerId,
      'amount': amount,
      ...updateTimestamp(),
    });
  }

  Future<void> delete(String id) {
    return store.nfc.doc(id).delete();
  }
}
