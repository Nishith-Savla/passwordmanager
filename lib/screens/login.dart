import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart'
    show JustTheController, TooltipStatus;
import 'package:passwordmanager/components/background.dart';
import 'package:passwordmanager/components/rounded_button.dart';
import 'package:passwordmanager/components/rounded_textfield.dart';
import 'package:passwordmanager/constants.dart';
import 'package:passwordmanager/firebase/authentication.dart';
import 'package:passwordmanager/utils.dart';

class Login extends StatefulWidget {
  const Login({Key? key}) : super(key: key);

  @override
  _LoginState createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _formKey = GlobalKey<FormState>();

  String _email = "";
  String _password = "";

  bool _isPasswordVisible = false;
  bool _isPasswordFocused = false;

  String _emailErrorMessage = "";
  String _passwordErrorMessage = "";

  final _emailErrorController = JustTheController();
  final _passwordErrorController = JustTheController();

  Future<bool> _validate() async {
    _formKey.currentState!.validate();
    if (await Future.delayed(
      const Duration(milliseconds: 50),
      () {
        if (_email.isNotEmpty &&
            _emailErrorMessage.isEmpty &&
            _passwordErrorMessage.isEmpty) {
          debugPrint(_email);
          debugPrint(_password);
          _formKey.currentState!.save();
          return true;
        }
        return false;
      },
    )) return true;

    if (_emailErrorMessage.isNotEmpty) {
      _emailErrorController.showTooltip();
    }
    if (_passwordErrorMessage.isNotEmpty) {
      _passwordErrorController.showTooltip();
    }
    return false;
  }

  void _login() async {
    if (!await _validate()) return;
    final auth = Authentication();
    final authResult = await auth.signInWithEmailAndPassword(
        email: _email, password: _password);
    final error = authResult.error;
    if (error != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    } else {
      await setMasterPassword(_password);
      Navigator.pushNamedAndRemoveUntil(
        context,
        auth.isEmailVerified ? '/home' : '/verifyEmail',
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      body: Background(
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "LOGIN",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
                SizedBox(
                  height: size.height * 0.03,
                ),
                SvgPicture.asset(
                  "assets/icons/login.svg",
                  height: size.height * 0.35,
                ),
                SizedBox(
                  height: size.height * 0.03,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: RoundedTextFormField(
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    keyboardType: TextInputType.emailAddress,
                    labelText: "Enter email address",
                    autofillHints: const [AutofillHints.email],
                    icon: Icons.email_outlined,
                    tooltipMessage: _emailErrorMessage,
                    tooltipController: _emailErrorController,
                    validator: (email) {
                      WidgetsBinding.instance!.addPostFrameCallback(
                        (_) => setState(
                          () => _emailErrorMessage =
                              email!.isEmpty ? 'Email cannot be empty' : '',
                        ),
                      );
                    },
                    onChanged: (email) {
                      if (_emailErrorController.value ==
                          TooltipStatus.isShowing) {
                        _emailErrorController.hideTooltip();
                      }
                      _email = email!;
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5.0),
                  child: Focus(
                    onFocusChange: (hasFocus) =>
                        setState(() => _isPasswordFocused = hasFocus),
                    child: RoundedTextFormField(
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      labelText: "Enter password",
                      icon: Icons.lock_outlined,
                      tooltipMessage: _passwordErrorMessage,
                      tooltipController: _passwordErrorController,
                      obscureText: _isPasswordVisible,
                      keyboardType: TextInputType.visiblePassword,
                      autofillHints: const [AutofillHints.password],
                      suffixIcon: _isPasswordFocused
                          ? IconButton(
                              onPressed: () {
                                setState(() =>
                                    _isPasswordVisible = !_isPasswordVisible);
                              },
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                size: 20,
                              ),
                            )
                          : null,
                      validator: (password) {
                        WidgetsBinding.instance!.addPostFrameCallback(
                          (_) => setState(() => _passwordErrorMessage =
                              password!.isEmpty
                                  ? 'Password cannot be empty'
                                  : ''),
                        );
                      },
                      onChanged: (password) {
                        if (_passwordErrorController.value ==
                            TooltipStatus.isShowing) {
                          _passwordErrorController.hideTooltip();
                        }
                        _password = password!;
                      },
                    ),
                  ),
                ),
                RoundedButton(text: "LOGIN", onPressed: _login),
                SizedBox(height: size.height * 0.02),
                Center(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 16),
                      children: <TextSpan>[
                        TextSpan(
                          text: "Don't have an account? ",
                          style: TextStyle(
                              color: Theme.of(context).brightness ==
                                      Brightness.light
                                  ? Colors.black
                                  : Colors.white),
                        ),
                        TextSpan(
                          text: "Sign Up",
                          style: TextStyle(
                            color: purpleMaterialColor,
                            fontWeight: FontWeight.bold,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Navigator.pushNamed(context, '/signup');
                            },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
