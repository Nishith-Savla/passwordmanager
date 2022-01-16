import 'package:flutter/material.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart'
    show JustTheController, TooltipStatus;
import 'package:passwordmanager/components/rounded_textfield.dart';
import 'package:passwordmanager/utils.dart' show Validation;

class ChangePassword extends StatefulWidget {
  const ChangePassword({Key? key}) : super(key: key);

  @override
  State<ChangePassword> createState() => _ChangePasswordState();
}

class _ChangePasswordState extends State<ChangePassword> {
  bool _isPasswordVisible = false;

  String _password = "";
  String _confirmPassword = "";

  String _passwordErrorMessage = "";
  String _confirmPasswordErrorMessage = "";

  final _passwordErrorController = JustTheController();
  final _confirmPasswordErrorController = JustTheController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Column(
          children: [
            RoundedTextFormField(
              autovalidateMode: AutovalidateMode.onUserInteraction,
              labelText: "Enter password",
              icon: Icons.lock_outlined,
              obscureText: _isPasswordVisible,
              keyboardType: TextInputType.visiblePassword,
              autofillHints: const [AutofillHints.password],
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() => _isPasswordVisible = !_isPasswordVisible);
                },
                icon: Icon(
                  _isPasswordVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.black,
                  size: 20,
                ),
              ),
              tooltipMessage: _passwordErrorMessage,
              tooltipController: _passwordErrorController,
              validator: (password) {
                WidgetsBinding.instance!.addPostFrameCallback(
                  (_) => setState(() =>
                      _passwordErrorMessage = password!.isPasswordValid()),
                );
              },
              onChanged: (password) {
                if (_passwordErrorController.value == TooltipStatus.isShowing) {
                  _passwordErrorController.hideTooltip();
                }
                _password = password!;
              },
            ),
          ],
        ),
      ),
    );
  }
}
