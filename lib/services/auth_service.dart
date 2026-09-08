import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  bool _googleSignInInicializado = false;

  User? get currentUser => _auth.currentUser;

  Future<void> _asegurarGoogleSignInInicializado() async {
    if (!_googleSignInInicializado) {
      await GoogleSignIn.instance.initialize();
      _googleSignInInicializado = true;
    }
  }

  // --- LOGIN DE CLIENTE CON GOOGLE ---
  Future<User?> signInWithGoogle() async {
    try {
      await _asegurarGoogleSignInInicializado();

      final GoogleSignInAccount googleUser = await GoogleSignIn.instance.authenticate();
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        await _crearDocumentoClienteSiNoExiste(user);
      }

      return user;
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return null; // el usuario cerró la ventana, no es un error real
      }
      print('Error en Google Sign-In: ${e.description}');
      return null;
    } catch (e) {
      print('Error inesperado en Google Sign-In: $e');
      return null;
    }
  }

  Future<void> _crearDocumentoClienteSiNoExiste(User user) async {
    final docRef = _db.collection('usuarios').doc(user.uid);
    final docSnapshot = await docRef.get();

    if (!docSnapshot.exists) {
      await docRef.set({
        'nombre': user.displayName ?? '',
        'email': user.email ?? '',
        'rol': 'cliente',
        'creadoEn': FieldValue.serverTimestamp(),
      });
    }
  }

  // --- LOGIN DE BARBERO CON EMAIL/CONTRASEÑA ---
  Future<User?> signInBarbero(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on FirebaseAuthException catch (e) {
      print('Error en login de barbero: ${e.message}');
      return null;
    }
  }

  // --- OBTENER EL ROL DEL USUARIO ACTUAL ---
  Future<String?> obtenerRol(String uid) async {
    final doc = await _db.collection('usuarios').doc(uid).get();
    if (doc.exists) {
      return doc.data()?['rol'] as String?;
    }
    return null;
  }

  // --- CERRAR SESIÓN ---
  Future<void> signOut() async {
    await GoogleSignIn.instance.signOut();
    await _auth.signOut();
  }
}