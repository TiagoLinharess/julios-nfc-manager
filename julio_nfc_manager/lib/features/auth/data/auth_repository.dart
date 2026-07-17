import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

const _googleSignInServerClientId =
    '441378487264-m3m1lu0et9rq6n2hd5rmubiv4rpi920o.apps.googleusercontent.com';

class AuthRepository {
  AuthRepository({
    FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  }) : firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       firestore = firestore ?? FirebaseFirestore.instance,
       googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final FirebaseAuth firebaseAuth;
  final FirebaseFirestore firestore;
  final GoogleSignIn googleSignIn;

  bool _googleSignInInitialized = false;

  Stream<User?> authStateChanges() {
    return firebaseAuth.authStateChanges();
  }

  Future<void> _initializeGoogleSignIn() async {
    if (_googleSignInInitialized) {
      return;
    }

    await googleSignIn.initialize(serverClientId: _googleSignInServerClientId);
    _googleSignInInitialized = true;
  }

  Future<UserCredential> signInWithGoogle() async {
    await _initializeGoogleSignIn();

    if (!googleSignIn.supportsAuthenticate()) {
      throw StateError('Google Sign-In is not supported on this platform.');
    }

    final googleUser = await googleSignIn.authenticate();
    final googleAuth = googleUser.authentication;
    final idToken = googleAuth.idToken;

    if (idToken == null) {
      throw StateError('Google Sign-In did not return an ID token.');
    }

    final credential = GoogleAuthProvider.credential(idToken: idToken);
    final userCredential = await firebaseAuth.signInWithCredential(credential);
    await _upsertUserProfile(userCredential.user);

    return userCredential;
  }

  Future<void> _upsertUserProfile(User? user) async {
    if (user == null) {
      return;
    }

    await firestore.collection('users').doc(user.uid).set({
      'displayName': user.displayName,
      'email': user.email,
      'photoUrl': user.photoURL,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> signOut() async {
    await _initializeGoogleSignIn();
    await Future.wait([firebaseAuth.signOut(), googleSignIn.signOut()]);
  }
}
