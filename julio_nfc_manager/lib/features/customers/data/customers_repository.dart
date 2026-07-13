import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firestore/firestore_date.dart';
import '../../../core/firestore/user_firestore.dart';
import '../domain/customer.dart';

class CustomersRepository {
  const CustomersRepository(this.store);

  final UserFirestore store;

  Stream<List<Customer>> watchAll() {
    return store.customers
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Customer.fromFirestore).toList());
  }

  Stream<Customer?> watchById(String id) {
    return store.customers.doc(id).snapshots().map((snapshot) {
      if (!snapshot.exists) {
        return null;
      }

      return Customer.fromFirestore(snapshot);
    });
  }

  Future<DocumentReference<Map<String, dynamic>>> create({
    required String name,
    required String cnpj,
  }) {
    return store.customers.add({
      'name': name.trim(),
      'cnpj': cnpj.trim(),
      ...createTimestamps(),
    });
  }

  Future<void> update({
    required String id,
    required String name,
    required String cnpj,
  }) {
    return store.customers.doc(id).update({
      'name': name.trim(),
      'cnpj': cnpj.trim(),
      ...updateTimestamp(),
    });
  }

  Future<void> delete(String id) {
    return store.customers.doc(id).delete();
  }
}
