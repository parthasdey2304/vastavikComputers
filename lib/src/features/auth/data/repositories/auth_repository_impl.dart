import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuth _firebaseAuth;

  AuthRepositoryImpl({FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  @override
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  @override
  User? get currentUser => _firebaseAuth.currentUser;

  @override
  Future<UserCredential> signInWithEmailAndPassword(String email, String password) async {
    return await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<UserCredential> createUserWithEmailAndPassword(String email, String password) async {
    return await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<UserCredential> signInWithGoogle() async {
    final provider = GoogleAuthProvider();
    provider.setCustomParameters({'prompt': 'select_account'});
    
    // For Web and Windows, Firebase Auth handles the OAuth flow directly
    if (kIsWeb) {
      return await _firebaseAuth.signInWithPopup(provider);
    } else if (defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.macOS || defaultTargetPlatform == TargetPlatform.linux) {
      return await _firebaseAuth.signInWithProvider(provider);
    } else {
      // For iOS and Android, use the native google_sign_in plugin
      final GoogleSignInAccount googleUser = await GoogleSignIn.instance.authenticate();

      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final GoogleSignInClientAuthorization? authz = await googleUser.authorizationClient.authorizationForScopes([]);
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: authz?.accessToken,
        idToken: googleAuth.idToken,
      );
      return await _firebaseAuth.signInWithCredential(credential);
      throw Exception('Google Sign-In aborted by user');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // Ignore if not signed in or not supported
    }
    await _firebaseAuth.signOut();
  }
}
