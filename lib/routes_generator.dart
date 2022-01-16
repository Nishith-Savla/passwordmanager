import 'package:flutter/material.dart';
import 'package:passwordmanager/screens/change_password.dart';
import 'package:passwordmanager/screens/generate.dart';
import 'package:passwordmanager/screens/home.dart';
import 'package:passwordmanager/screens/login.dart';
import 'package:passwordmanager/screens/signup.dart';
import 'package:passwordmanager/screens/verify_email.dart';

class RoutesGenerator {
  static Route<dynamic> generateRoute(RouteSettings settings) {
    final args = settings.arguments;
    switch (settings.name) {
      case '/home':
        return MaterialPageRoute(builder: (_) => const HomePage());
      case '/signup':
        return MaterialPageRoute(builder: (_) => const Signup());
      case '/login':
        return MaterialPageRoute(builder: (_) => const Login());
      case '/verifyEmail':
        return MaterialPageRoute(builder: (_) => const VerifyEmail());
      case '/changePassword':
        return MaterialPageRoute(builder: (_) => const ChangePassword());
      case '/generate':
        if (args is GenerateType) {
          return MaterialPageRoute(
            builder: (_) => Generate(generateType: args),
          );
        }
        return _errorRoute();
      default:
        return _errorRoute();
    }
  }

  static Route<dynamic> _errorRoute() {
    return MaterialPageRoute(builder: (_) {
      return const Scaffold(
        body: Center(
          child: Text('Screen not available'),
        ),
      );
    });
  }
}
