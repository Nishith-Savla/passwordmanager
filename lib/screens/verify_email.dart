import 'dart:async' show Timer;
import 'dart:io' show Platform;

import 'package:android_intent_plus/android_intent.dart' show AndroidIntent;
import 'package:android_intent_plus/flag.dart' show Flag;
import 'package:flutter/material.dart';
import 'package:passwordmanager/firebase/authentication.dart';

class VerifyEmail extends StatefulWidget {
  const VerifyEmail({Key? key}) : super(key: key);

  @override
  _VerifyEmailState createState() => _VerifyEmailState();
}

class _VerifyEmailState extends State<VerifyEmail> {
  final auth = Authentication();
  late final Timer timer;

  @override
  void initState() {
    super.initState();
    auth.verifyCurrentUser();

    timer = Timer.periodic(
      const Duration(seconds: 3),
      (timer) {
        if (auth.isEmailVerified) {
          timer.cancel();
          Navigator.pushNamedAndRemoveUntil(
              context, '/home', (Route<dynamic> route) => false);
        } else if (timer.tick % 20 == 0) {
          auth.verifyCurrentUser();
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify your email'),
        automaticallyImplyLeading: false,
      ),
      body: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(10.0),
        child: Column(
          children: [
            Text(
                'An verification link has been to ${auth.currentUser!.email}. \n'
                'Please open it and once done, switch back to the App'),
            if (Platform.isAndroid)
              ElevatedButton(
                child: const Text('Open Mail'),
                onPressed: () {
                  const intent = AndroidIntent(
                    action: 'android.intent.action.MAIN',
                    category: 'android.intent.category.APP_EMAIL',
                    flags: [Flag.FLAG_ACTIVITY_NEW_TASK],
                  );
                  intent
                      .launch()
                      .then((_) => debugPrint("success"))
                      .catchError((e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString())),
                    );
                  });
                },
              ),
            ElevatedButton(
              child: const Text('Logout'),
              onPressed: () async {
                timer.cancel();
                await auth.signOut();
                Navigator.pushReplacementNamed(context, '/login');
              },
            )
          ],
        ),
      ),
    );
  }
}
