import 'package:cloud_firestore/cloud_firestore.dart';

DateTime readFirestoreDate(Object? value) {
  if (value is Timestamp) {
    return value.toDate();
  }

  if (value is DateTime) {
    return value;
  }

  return DateTime.fromMillisecondsSinceEpoch(0);
}

Map<String, Object?> createTimestamps() {
  return {
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  };
}

Map<String, Object?> updateTimestamp() {
  return {
    'updatedAt': FieldValue.serverTimestamp(),
  };
}
