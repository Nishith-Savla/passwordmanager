import 'package:flutter/material.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart'
    show JustTheController, TooltipStatus;
import 'package:passwordmanager/components/rounded_textfield.dart';
import 'package:passwordmanager/utils.dart' show Validation;

class Profile extends StatefulWidget {
  final String name;
  final String email;
  final void Function({String? name, String? email}) onUpdate;

  const Profile({
    Key? key,
    required this.name,
    required this.email,
    required this.onUpdate,
  }) : super(key: key);

  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  bool _isEditable = false;
  String _name = "";
  String _email = "";

  String _nameErrorMessage = "";
  String _emailErrorMessage = "";

  final _nameErrorController = JustTheController();
  final _emailErrorController = JustTheController();

  @override
  void initState() {
    super.initState();
    _name = widget.name;
    _email = widget.email;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Theme.of(context).brightness == Brightness.light
            ? Colors.black
            : Colors.white,
        actions: [
          _isEditable
              ? IconButton(
                  icon: const Icon(Icons.check_outlined),
                  onPressed: () => widget.onUpdate(name: _name, email: _email),
                )
              : IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => setState(() => _isEditable = !_isEditable),
                ),
        ],
      ),
      body: Center(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: RoundedTextFormField(
                initialValue: _name,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                keyboardType: TextInputType.name,
                labelText: "Enter your name",
                autofillHints: const [AutofillHints.name],
                icon: Icons.person_outlined,
                tooltipMessage: _nameErrorMessage,
                tooltipController: _nameErrorController,
                validator: (name) {
                  WidgetsBinding.instance!.addPostFrameCallback(
                    (_) =>
                        setState(() => _nameErrorMessage = name!.isNameValid()),
                  );
                },
                onChanged: (name) {
                  if (_nameErrorController.value == TooltipStatus.isShowing) {
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
                initialValue: _email,
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
                  if (_emailErrorController.value == TooltipStatus.isShowing) {
                    _emailErrorController.hideTooltip();
                  }
                  _email = email!;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
