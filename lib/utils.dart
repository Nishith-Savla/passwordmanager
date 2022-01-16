import 'dart:async' show Future, FutureOr;
import 'dart:convert' show utf8;
import 'dart:typed_data' show Uint8List;

import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:crypto/crypto.dart' show Hmac, sha512256;
import 'package:encrypt/encrypt.dart' show Key;
import 'package:flutter/material.dart'
    show BuildContext, ScaffoldMessenger, SnackBar, Text;
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_dotenv/flutter_dotenv.dart' show dotenv;
import 'package:flutter_secure_storage/flutter_secure_storage.dart'
    show AndroidOptions, FlutterSecureStorage;
import 'package:passwordmanager/constants.dart';

Uint8List generateKey(String password, String pepper, Timestamp createdAt) {
  final key = utf8.encode(password + pepper + createdAt.toString());
  final hmacSha512256 = Hmac(sha512256, key);
  final encryptionKey =
      Key(hmacSha512256.convert(utf8.encode(password)).bytes as Uint8List)
          .bytes;
  return encryptionKey;
}

void copyToClipboard({
  required BuildContext context,
  required String name,
  required String data,
  void Function()? onCopy,
}) {
  Clipboard.setData(ClipboardData(text: data)).then((_) {
    onCopy?.call();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("$name has been copied to clipboard")),
    );
  });
}

// Local storage

const _storage = FlutterSecureStorage();

Future<String?> readFromStorage(String key) async =>
    await _storage.read(key: key, aOptions: _getAndroidOptions());

Future<void> writeToStorage(String key, String value) async => await _storage
    .write(key: key, value: value, aOptions: _getAndroidOptions());

AndroidOptions _getAndroidOptions() =>
    const AndroidOptions(encryptedSharedPreferences: true);

// Master password

Future<String> getMasterPassword() async =>
    await readFromStorage('byepass') ?? '';

Future<void> setMasterPassword(String password) async =>
    await writeToStorage('byepass', password);

String get pepper => dotenv.env['PEPPER']!;

// extension

extension Validation on String {
  String isEmailValid() {
    if (isEmpty) return "Email cannot be empty";

    if (!RegExp(emailRegex).hasMatch(this)) return "Invalid email";

    return "";
  }

  String isPasswordValid() {
    final _errors = [];
    if (isEmpty) return "Password cannot be empty";

    if (length < 8) {
      _errors.add(' • minimum 8 characters');
    }
    if (!RegExp(r'[a-z]').hasMatch(this)) {
      _errors.add(' • A lowercase letter');
    }
    if (!RegExp(r'[A-Z]').hasMatch(this)) {
      _errors.add(' • An uppercase letter');
    }
    if (!RegExp(r'[!@#\$&*~.-/:`]').hasMatch(this)) {
      _errors.add(' • A special character');
    }
    if (!RegExp(r'\d').hasMatch(this)) {
      _errors.add(' • A number');
    }

    if (_errors.isEmpty) return "";

    final _errorMessage = StringBuffer("Password must contain: \n");
    for (int i = 0; i < _errors.length; ++i) {
      if (i.isOdd) {
        _errorMessage.writeln(_errors[i]);
        continue;
      }

      _errorMessage.write(_errors[i] + '\t');
    }

    return _errorMessage.toString().trimRight();
  }

  String isNameValid() {
    if (isEmpty) return "Name field is empty";

    if (!RegExp(nameRegex).hasMatch(this)) {
      return "Invalid name. Use only letters and spaces";
    }

    return "";
  }
}

extension MapUtils<K, V> on Map<K, V> {
  Future<V> putIfAbsentAsync(K key, FutureOr<V> Function() action) async {
    final V? previous = this[key];
    final V current;
    if (previous == null) {
      current = await action();
      this[key] = current;
    } else {
      current = previous;
    }
    return current;
  }
}

// Future<void> setOptimalDisplayMode() async {
//   final List<DisplayMode> supported = await FlutterDisplayMode.supported;
//   final DisplayMode active = await FlutterDisplayMode.active;
//
//   final List<DisplayMode> sameResolution = supported
//       .where((DisplayMode m) =>
//           m.width == active.width && m.height == active.height)
//       .toList()
//     ..sort((DisplayMode a, DisplayMode b) =>
//         b.refreshRate.compareTo(a.refreshRate));
//
//   final DisplayMode mostOptimalMode =
//       sameResolution.isNotEmpty ? sameResolution.first : active;
//
//   await FlutterDisplayMode.setPreferredMode(mostOptimalMode);
// }
