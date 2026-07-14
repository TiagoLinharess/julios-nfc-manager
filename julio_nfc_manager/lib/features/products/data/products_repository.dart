import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/firestore/firestore_date.dart';
import '../../../core/firestore/user_firestore.dart';
import '../domain/product.dart';

class ProductsRepository {
  const ProductsRepository(this.store);

  final UserFirestore store;

  Stream<List<Product>> watchAll() {
    return store.products
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs.map(Product.fromFirestore).toList());
  }

  Stream<Product?> watchById(String id) {
    return store.products.doc(id).snapshots().map((snapshot) {
      if (!snapshot.exists) {
        return null;
      }

      return Product.fromFirestore(snapshot);
    });
  }

  Future<DocumentReference<Map<String, dynamic>>> create({
    required String name,
    required String pricePerKg,
  }) {
    return store.products.add({
      'name': name.trim(),
      'pricePerKg': pricePerKg.trim(),
      ...createTimestamps(),
    });
  }

  Future<void> update({
    required String id,
    required String name,
    required String pricePerKg,
  }) {
    return store.products.doc(id).update({
      'name': name.trim(),
      'pricePerKg': pricePerKg.trim(),
      ...updateTimestamp(),
    });
  }

  Future<void> delete(String id) {
    return store.products.doc(id).delete();
  }
}
