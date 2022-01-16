import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:passwordmanager/screens/home.dart';
import 'package:passwordmanager/utils.dart';

class Authentication {
  late final FirebaseAuth _firebaseAuth;
  late final FirebaseFirestore _firebaseFirestore;

  Authentication(
      {FirebaseAuth? firebaseAuth, FirebaseFirestore? firebaseFirestore}) {
    _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;
    _firebaseFirestore = firebaseFirestore ?? FirebaseFirestore.instance;
  }

  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  Future<String?> addUserWithEmailAndPassword(
      {required String email,
      required String password,
      required String collectionPath,
      Map<String, dynamic>? values}) async {
    String? error;

    final AuthenticationResult authResult =
        await createUserWithEmailAndPassword(email: email, password: password);

    if (authResult.error != null && authResult.error!.isNotEmpty) {
      return authResult.error;
    }
    if (authResult.userCredential == null) return null;

    final data = <String, dynamic>{};
    data['email'] = email;
    data['createdAt'] =
        authResult.userCredential!.user?.metadata.creationTime ??
            FieldValue.serverTimestamp();
    if (values != null) data.addAll(values);

    await _firebaseFirestore
        .collection(collectionPath)
        .doc(authResult.userCredential!.user!.uid)
        .set({...data}).catchError((e) => error = e);

    return error;
  }

  Future<AuthenticationResult> createUserWithEmailAndPassword(
      {required String email, required String password}) async {
    UserCredential? userCredential;
    String? error;
    try {
      userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
          email: email, password: password);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        error = 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        error = 'Wrong password provided for that user.';
      } else {
        error = e.message;
      }
    } catch (e) {
      error = e.toString();
    }
    return AuthenticationResult(userCredential: userCredential, error: error);
  }

  Future<AuthenticationResult> signInWithEmailAndPassword(
      {required String email, required String password}) async {
    UserCredential? userCredential;
    String? error;
    try {
      userCredential = await _firebaseAuth.signInWithEmailAndPassword(
          email: email, password: password);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        error = 'No user found for that email.';
      } else if (e.code == 'wrong-password') {
        error = 'Wrong password provided for that user.';
      } else {
        error = e.message;
      }
    }
    return AuthenticationResult(userCredential: userCredential, error: error);
  }

  Future<void> sendEmailVerification(User? user) async {
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  Future<void> verifyCurrentUser() async {
    if (!isEmailVerified) {
      User? user = _firebaseAuth.currentUser;
      user!.reload();
      await sendEmailVerification(user);
    }
  }

  Future<String?> updateEmail(String email) async {
    final User? user = _firebaseAuth.currentUser;
    try {
      await user?.updateEmail(email);
      return "Profile updated";
    } on FirebaseAuthException catch (e) {
      if (e.code == "email-already-in-use") {
        return "Email Already In Use";
      }
    }
  }

  Future<String?> changePassword(
      String currentPassword, String newPassword) async {
    final User? user = _firebaseAuth.currentUser;
    final cred = EmailAuthProvider.credential(
        email: user?.email ?? "", password: currentPassword);

    try {
      await user!.reauthenticateWithCredential(cred);
      await user.updatePassword(newPassword);
      await setMasterPassword(newPassword);
      await repository.updateAllEntriesPasswords(currentPassword, newPassword);
      return "Password changed successfully!";
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found') {
        return 'No user found for that email.';
      }
      if (e.code == 'wrong-password') {
        return 'Wrong password provided for that user.';
      }
      if (e.code == 'weak-password') {
        return 'The password provided is too weak.';
      }
      return e.message;
    }
  }

  bool isUserLoggedIn() => _firebaseAuth.currentUser != null;

  bool get isEmailVerified {
    final user = _firebaseAuth.currentUser;
    user!.reload();
    return user.emailVerified;
  }

  User? get currentUser => _firebaseAuth.currentUser;
}

class AuthenticationResult {
  UserCredential? userCredential;
  String? error;

  AuthenticationResult({required this.userCredential, this.error});

  factory AuthenticationResult.fromJson(Map<String, dynamic> json) {
    return AuthenticationResult(
      userCredential: json['userCredential'],
      error: json['error'],
    );
  }
}
