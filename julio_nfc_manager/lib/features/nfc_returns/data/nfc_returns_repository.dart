import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firestore/firestore_date.dart';
import '../../../core/firestore/user_firestore.dart';
import '../../nfc/domain/nfc_record.dart';
import '../domain/nfc_return.dart';

class NfcReturnsRepository {
  const NfcReturnsRepository(this.store);

  final UserFirestore store;

  Stream<List<NfcReturn>> watchAll() {
    return store.nfcReturns
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(NfcReturn.fromFirestore).toList());
  }

  Stream<List<NfcReturn>> watchByNfcId(String nfcId) {
    return store.nfcReturns
        .where('nfcId', isEqualTo: nfcId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(NfcReturn.fromFirestore).toList());
  }

  Future<DocumentReference<Map<String, dynamic>>> create({
    required String code,
    required String date,
    required NfcRecord nfc,
  }) {
    return store.nfcReturns.add({
      'code': code.trim(),
      'date': date.trim(),
      'products': nfc.products.map((product) => product.toMap()).toList(),
      ...NfcReturn.nfcSnapshot(nfc),
      ...createTimestamps(),
    });
  }

  Future<void> update({
    required String id,
    required String code,
    required String date,
    required NfcRecord nfc,
  }) {
    return store.nfcReturns.doc(id).update({
      'code': code.trim(),
      'date': date.trim(),
      'products': nfc.products.map((product) => product.toMap()).toList(),
      ...NfcReturn.nfcSnapshot(nfc),
      ...updateTimestamp(),
    });
  }

  Future<void> delete(String id) {
    return store.nfcReturns.doc(id).delete();
  }
}
