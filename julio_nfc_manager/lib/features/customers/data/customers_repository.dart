import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firestore/firestore_date.dart';
import '../../../core/firestore/user_firestore.dart';
import '../../../core/validation/cnpj_validator.dart';
import '../domain/customer.dart';

class DuplicateCustomerCnpjException implements Exception {
  const DuplicateCustomerCnpjException();
}

class CustomersRepository {
  const CustomersRepository(this.store);

  final UserFirestore store;

  Stream<List<Customer>> watchAll() {
    return store.customers
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Customer.fromFirestore).toList());
  }

  Future<List<Customer>> getAll() async {
    final snapshot = await store.customers.orderBy('name').get();
    return snapshot.docs.map(Customer.fromFirestore).toList();
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
  }) async {
    final customerRef = store.customers.doc();
    final cnpjDigits = onlyDigits(cnpj);
    final cnpjRef = store.customerCnpjs.doc(cnpjDigits);

    await store.firestore.runTransaction((transaction) async {
      final cnpjSnapshot = await transaction.get(cnpjRef);

      if (cnpjSnapshot.exists) {
        throw const DuplicateCustomerCnpjException();
      }

      transaction.set(customerRef, {
        'name': name.trim(),
        'cnpj': cnpj.trim(),
        'cnpjDigits': cnpjDigits,
        ...createTimestamps(),
      });
      transaction.set(cnpjRef, {
        'customerId': customerRef.id,
        ...createTimestamps(),
      });
    });

    return customerRef;
  }

  Future<void> update({
    required String id,
    required String name,
    required String cnpj,
  }) async {
    final customerRef = store.customers.doc(id);
    final nextCnpjDigits = onlyDigits(cnpj);

    await store.firestore.runTransaction((transaction) async {
      final customerSnapshot = await transaction.get(customerRef);

      if (!customerSnapshot.exists) {
        return;
      }

      final data = customerSnapshot.data() ?? {};
      final currentCnpjDigits = data['cnpjDigits'] as String? ??
          onlyDigits(data['cnpj'] as String? ?? '');

      if (currentCnpjDigits != nextCnpjDigits) {
        final nextCnpjRef = store.customerCnpjs.doc(nextCnpjDigits);
        final nextCnpjSnapshot = await transaction.get(nextCnpjRef);

        if (nextCnpjSnapshot.exists) {
          throw const DuplicateCustomerCnpjException();
        }

        if (currentCnpjDigits.isNotEmpty) {
          transaction.delete(store.customerCnpjs.doc(currentCnpjDigits));
        }

        transaction.set(nextCnpjRef, {
          'customerId': id,
          ...createTimestamps(),
        });
      }

      transaction.update(customerRef, {
        'name': name.trim(),
        'cnpj': cnpj.trim(),
        'cnpjDigits': nextCnpjDigits,
        ...updateTimestamp(),
      });
    });
  }

  Future<void> delete(String id) async {
    final customerRef = store.customers.doc(id);

    await store.firestore.runTransaction((transaction) async {
      final customerSnapshot = await transaction.get(customerRef);

      if (!customerSnapshot.exists) {
        return;
      }

      final data = customerSnapshot.data() ?? {};
      final cnpjDigits = data['cnpjDigits'] as String? ?? '';

      transaction.delete(customerRef);

      if (cnpjDigits.isNotEmpty) {
        transaction.delete(store.customerCnpjs.doc(cnpjDigits));
      }
    });
  }
}
