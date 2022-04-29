import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:passwordmanager/constants.dart';
import 'package:passwordmanager/firebase/authentication.dart';
import 'package:passwordmanager/routes_generator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  await dotenv.load(fileName: ".env");
  final auth = Authentication();
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    // theme: ThemeData(
    //     primarySwatch: purpleMaterialColor,
    //     inputDecorationTheme: const InputDecorationTheme(
    //       labelStyle: TextStyle(color: Colors.black),
    //       hintStyle: TextStyle(color: Colors.black),
    //     ),
    //     appBarTheme: const AppBarTheme(foregroundColor: Colors.black)),
    darkTheme: ThemeData(
      brightness: Brightness.dark,
      colorScheme:
          const ColorScheme.dark().copyWith(secondary: purpleMaterialColor),
      // switchTheme: SwitchThemeData(overlayColor: purpleMaterialColor),
    ),
    themeMode: ThemeMode.system,
    initialRoute: auth.isUserLoggedIn()
        ? auth.isEmailVerified
            ? "/home"
            : "/verifyEmail"
        : "/login",
    onGenerateRoute: RoutesGenerator.generateRoute,
  ));
}
