import 'package:flutter/gestures.dart' show TapGestureRecognizer;
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart'
    show JustTheController, TooltipStatus;
import 'package:passwordmanager/components/background.dart';
import 'package:passwordmanager/components/rounded_button.dart';
import 'package:passwordmanager/components/rounded_textfield.dart';
import 'package:passwordmanager/constants.dart' show purpleMaterialColor;
import 'package:passwordmanager/firebase/authentication.dart';
import 'package:passwordmanager/utils.dart' show Validation, setMasterPassword;

class Signup extends StatefulWidget {
  const Signup({Key? key}) : super(key: key);

  @override
  _SignupState createState() => _SignupState();
}

class _SignupState extends State<Signup> {
  final _formKey = GlobalKey<FormState>();
  bool _isPasswordVisible = true;
  bool _isPasswordFocused = false;
  bool _isConfirmPasswordFocused = false;

  String _name = "";
  String _email = "";
  String _password = "";
  String _confirmPassword = "";

  String _nameErrorMessage = "";
  String _emailErrorMessage = "";
  String _passwordErrorMessage = "";
  String _confirmPasswordErrorMessage = "";

  final _nameErrorController = JustTheController();
  final _emailErrorController = JustTheController();
  final _passwordErrorController = JustTheController();
  final _confirmPasswordErrorController = JustTheController();

  Future<bool> _validate() async {
    _formKey.currentState!.validate();
    if (await Future.delayed(
      const Duration(milliseconds: 50),
      () {
        if (_name.isNotEmpty &&
            _nameErrorMessage.isEmpty &&
            _confirmPasswordErrorMessage.isEmpty &&
            _passwordErrorMessage.isEmpty &&
            _emailErrorMessage.isEmpty) {
          debugPrint(_name);
          debugPrint(_email);
          debugPrint(_password);
          debugPrint(_confirmPassword);
          _formKey.currentState!.save();
          return true;
        }
        return false;
      },
    )) return true;

    if (_nameErrorMessage.isNotEmpty) {
      _nameErrorController.showTooltip();
    }
    if (_emailErrorMessage.isNotEmpty) {
      _emailErrorController.showTooltip();
    }
    if (_confirmPasswordErrorMessage.isNotEmpty) {
      _confirmPasswordErrorController.showTooltip();
    }
    if (_passwordErrorMessage.isNotEmpty) {
      _passwordErrorController.showTooltip();
    }
    return false;
  }

  void _signup() async {
    if (!await _validate()) return;
    final auth = Authentication();
    final error = await auth.addUserWithEmailAndPassword(
      email: _email,
      password: _password,
      collectionPath: 'users',
      values: {'name': _name},
    );
    if (error != null && error.isNotEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Sign up successful')));
      auth.verifyCurrentUser();
      setMasterPassword(_password);
      Navigator.pushReplacementNamed(context, '/verifyEmail');
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
                  "SIGN UP",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),

                SizedBox(
                  height: size.height * 0.01,
                ),
                SvgPicture.asset(
                  "assets/icons/signup.svg",
                  height: size.height * 0.25,
                ),
                SizedBox(
                  height: size.height * 0.01,
                ),

                // Name
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: RoundedTextFormField(
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    keyboardType: TextInputType.name,
                    labelText: "Enter your name",
                    autofillHints: const [AutofillHints.name],
                    icon: Icons.person_outlined,
                    tooltipMessage: _nameErrorMessage,
                    tooltipController: _nameErrorController,
                    validator: (name) {
                      WidgetsBinding.instance!.addPostFrameCallback(
                        (_) => setState(
                            () => _nameErrorMessage = name!.isNameValid()),
                      );
                    },
                    onChanged: (name) {
                      if (_nameErrorController.value ==
                          TooltipStatus.isShowing) {
                        _nameErrorController.hideTooltip();
                      }
                      _name = name!;
                    },
                  ),
                ),

                // Email
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
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
                          () => _emailErrorMessage = email!.isEmailValid(),
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

                // Password
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Focus(
                    onFocusChange: (hasFocus) =>
                        setState(() => _isPasswordFocused = hasFocus),
                    child: RoundedTextFormField(
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      labelText: "Enter password",
                      icon: Icons.lock_outlined,
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
                      tooltipMessage: _passwordErrorMessage,
                      tooltipController: _passwordErrorController,
                      validator: (password) {
                        WidgetsBinding.instance!.addPostFrameCallback(
                          (_) => setState(() => _passwordErrorMessage =
                              password!.isPasswordValid()),
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

                // Confirm Password
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Focus(
                    onFocusChange: (hasFocus) {
                      setState(() => _isConfirmPasswordFocused = hasFocus);
                    },
                    child: RoundedTextFormField(
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      labelText: "Confirm your password",
                      icon: Icons.lock_outlined,
                      obscureText: _isPasswordVisible,
                      keyboardType: TextInputType.visiblePassword,
                      autofillHints: const [AutofillHints.password],
                      suffixIcon: _isConfirmPasswordFocused
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
                      tooltipMessage: _confirmPasswordErrorMessage,
                      tooltipController: _confirmPasswordErrorController,
                      validator: (confirmPassword) {
                        WidgetsBinding.instance!.addPostFrameCallback(
                          (_) {
                            setState(() => _confirmPasswordErrorMessage =
                                confirmPassword!.isEmpty
                                    ? 'Confirm Password cannot be empty'
                                    : confirmPassword == _password
                                        ? ''
                                        : "Passwords don't match");
                          },
                        );
                      },
                      onChanged: (confirmPassword) {
                        if (_confirmPasswordErrorController.value ==
                            TooltipStatus.isShowing) {
                          _confirmPasswordErrorController.hideTooltip();
                        }
                        _confirmPassword = confirmPassword!;
                      },
                    ),
                  ),
                ),
                RoundedButton(text: "SIGN UP", onPressed: _signup),
                SizedBox(height: size.height * 0.02),
                Center(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 16),
                      children: <TextSpan>[
                        TextSpan(
                          text: "Already have an account? ",
                          style: TextStyle(color: Theme.of(context).brightness == Brightness.light ? Colors.black : Colors.white),
                        ),
                        TextSpan(
                          text: "Login",
                          style: TextStyle(
                            color: purpleMaterialColor,
                            fontWeight: FontWeight.bold,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Navigator.pushNamed(context, '/login');
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
