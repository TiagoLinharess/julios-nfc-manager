import 'package:cloud_firestore/cloud_firestore.dart';

class UserFirestore {
  UserFirestore({
    required this.uid,
    FirebaseFirestore? firestore,
  }) : firestore = firestore ?? FirebaseFirestore.instance;

  final String uid;
  final FirebaseFirestore firestore;

  DocumentReference<Map<String, dynamic>> get userDoc {
    return firestore.collection('users').doc(uid);
  }

  CollectionReference<Map<String, dynamic>> get customers {
    return userDoc.collection('customers');
  }

  CollectionReference<Map<String, dynamic>> get products {
    return userDoc.collection('products');
  }

  CollectionReference<Map<String, dynamic>> get nfc {
    return userDoc.collection('nfc');
  }

  CollectionReference<Map<String, dynamic>> get nfcReturns {
    return userDoc.collection('nfcReturns');
  }
}
