import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:passwordmanager/firebase/authentication.dart';
import 'package:passwordmanager/screens/profile.dart';

class Settings extends StatelessWidget {
  late final Authentication auth;
  late final String name;

  Settings({Key? key}) : super(key: key) {
    auth = Authentication();
    FirebaseFirestore.instance
        .collection('users')
        .doc(auth.currentUser!.uid)
        .get()
        .then((snapshot) {
      name = (snapshot.data() as Map<String, dynamic>)['name'];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        toolbarHeight: 60,
        automaticallyImplyLeading: false,
        elevation: 0,
        title: const Text('Settings'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          ListTile(
            title: const Text('Account'),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Profile(
                    name: name,
                    email: auth.currentUser!.email!,
                    onUpdate: ({String? name, String? email}) async {
                      FirebaseFirestore.instance
                          .collection('users')
                          .doc(auth.currentUser!.uid)
                          .update({'name': name, 'email': email});
                      if (email != null) auth.updateEmail(email);
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Profile Updated")));
                    }),
              ),
            ),
          ),
          /*
          TODO: allow changing passwords
          ListTile(
            title: const Text('Change master password'),
            onTap: () async {
              final result = await Authentication()
                  .changePassword('Password@123', 'Password@234');
              if (result != null) {
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text(result)));
              }
            },
          ),
           */
          ListTile(
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () {
              Authentication().signOut();
              Navigator.pushNamedAndRemoveUntil(
                  context, '/login', (Route<dynamic> route) => false);
            },
          ),
        ],
      ),
    );
  }
}
