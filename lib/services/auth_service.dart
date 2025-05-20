import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<User?> signUp(String email, String password) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await _db.collection('users').doc(userCredential.user!.uid).set({
      'theme': 'light',
      'language': 'en',
    });
    return userCredential.user;
  }

  Future<User?> signIn(String email, String password) async {
    final userCredential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return userCredential.user;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<Map<String, String>> loadUserPreferences(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (doc.exists) {
      final data = doc.data()!;
      return {
        'theme': data['theme'] ?? 'light',
        'language': data['language'] ?? 'en',
      };
    } else {
      return {
        'theme': 'light',
        'language': 'en',
      };
    }
  }

  Future<void> saveUserPreferences(String uid, String theme, String language) async {
    await _db.collection('users').doc(uid).update({
      'theme': theme,
      'language': language,
    });
  }
}
