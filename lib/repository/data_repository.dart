import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:passwordmanager/models/password_entry.dart';
import 'package:passwordmanager/utils.dart';

class DataRepository {
  late final CollectionReference collection;

  DataRepository(
      {String collection = "users", String subCollection = "Default"}) {
    this.collection = FirebaseFirestore.instance
        .collection(collection)
        .doc(FirebaseAuth.instance.currentUser!.uid)
        .collection('Default');
  }

  Stream<QuerySnapshot> getStream() {
    collection.snapshots().forEach((QuerySnapshot element) {
      for (final e in element.docs) {
        debugPrint(e.id);
      }
    });
    return collection.snapshots();
  }

  Future<DocumentReference> addEntry(PasswordEntry entry) {
    return collection.add(entry.toJson());
  }

  void updateEntry(PasswordEntry entry) async {
    await collection.doc(entry.referenceId).update(entry.toJson());
  }

  void deleteEntry(PasswordEntry entry) async {
    await collection.doc(entry.referenceId).delete();
  }

  Future<void> updateAllEntriesPasswords(
      String oldPassword, String newPassword) async {
    debugPrint("hello");
    Timestamp createdAt;
    PasswordEntry entry;
    String _pass;
    Uint8List _key;
    WriteBatch batch = FirebaseFirestore.instance.batch();

    final QuerySnapshot<Object?> querySnapshot = await collection.get();

    for (var docSnapshot in querySnapshot.docs) {
      debugPrint("START: " + docSnapshot.reference.id);

      createdAt = (docSnapshot.data() as Map<String, dynamic>)['createdAt'];

      _key = generateKey(oldPassword, pepper, createdAt);
      debugPrint("OLD KEY: " + _key.toString());

      entry = PasswordEntry.fromSnapshot(docSnapshot, key: _key);
      _pass = entry.getPassword(_key);

      _key = generateKey(newPassword, pepper, createdAt);
      debugPrint("NEW KEY: " + _key.toString());

      entry.setPassword(_pass, _key);

      batch.update(docSnapshot.reference, entry.toJson());

      debugPrint("END: " + docSnapshot.reference.id);
    }

    return batch.commit();
  }
}
