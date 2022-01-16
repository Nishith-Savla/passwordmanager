import 'dart:typed_data' show Uint8List;

import 'package:cloud_firestore/cloud_firestore.dart' show Timestamp;
import 'package:flutter/material.dart';
import 'package:just_the_tooltip/just_the_tooltip.dart';
import 'package:passwordmanager/components/rounded_textfield.dart';
import 'package:passwordmanager/constants.dart' show purpleMaterialColor;
import 'package:passwordmanager/models/password_entry.dart';
import 'package:passwordmanager/utils.dart'
    show copyToClipboard, generateKey, getMasterPassword, pepper;
import 'package:timeago/timeago.dart' as timeago show format;
import 'package:url_launcher/url_launcher.dart' deferred as url_launcher;
import 'package:validators/validators.dart' show isURL;

class AlwaysDisabledFocusNode extends FocusNode {
  @override
  bool get hasFocus => false;
}

class ItemScreenArguments {
  final bool isEditable;
  final void Function(PasswordEntry) onSave;
  final void Function(PasswordEntry) onDelete;
  final PasswordEntry passwordEntry;

  ItemScreenArguments(
      this.isEditable, this.onSave, this.onDelete, this.passwordEntry);
}

class ItemScreen extends StatefulWidget {
  final bool isEditable;
  final void Function(PasswordEntry) onSave;
  final void Function(PasswordEntry)? onDelete;
  final PasswordEntry? passwordEntry;

  const ItemScreen({
    Key? key,
    required this.isEditable,
    this.passwordEntry,
    required this.onSave,
    this.onDelete,
  }) : super(key: key);

  factory ItemScreen.fromItemScreenArguments(
      ItemScreenArguments itemScreenArguments) {
    return ItemScreen(
      isEditable: itemScreenArguments.isEditable,
      passwordEntry: itemScreenArguments.passwordEntry,
      onSave: itemScreenArguments.onSave,
      onDelete: itemScreenArguments.onDelete,
    );
  }

  @override
  State<ItemScreen> createState() => _ItemScreenState();
}

class _ItemScreenState extends State<ItemScreen> {
  final _formKey = GlobalKey<FormState>();
  late bool _isEditable;
  late bool _isPasswordVisible;
  late final Uint8List _key;

  String _nameErrorMessage = "";
  String _emailErrorMessage = "";
  String _passwordErrorMessage = "";
  String _uriErrorMessage = "";

  final _nameErrorController = JustTheController();
  final _emailErrorController = JustTheController();
  final _passwordErrorController = JustTheController();
  final _uriErrorController = JustTheController();

  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;
  late final TextEditingController _uriController;

  late final Timestamp _createdAt;

  void _setDefaultValueToTextFields() {
    _nameController.text = widget.passwordEntry?.name ?? '';
    _emailController.text = widget.passwordEntry?.email ?? '';
    _passwordController.text = widget.passwordEntry == null ? '' : '        ';
    _uriController.text = widget.passwordEntry?.uri.toString() ?? '';
  }

  @override
  void initState() {
    super.initState();

    _isPasswordVisible = false;
    _isEditable = widget.isEditable;

    _nameController =
        TextEditingController(text: widget.passwordEntry?.name ?? '');

    _emailController =
        TextEditingController(text: widget.passwordEntry?.email ?? '');

    _passwordController = TextEditingController(
        text: widget.passwordEntry == null ? '' : '        ');

    _uriController =
        TextEditingController(text: widget.passwordEntry?.uri.toString() ?? '');

    _createdAt = widget.passwordEntry?.createdAt ?? Timestamp.now();

    getMasterPassword().then((_masterPassword) {
      _key = generateKey(_masterPassword, pepper, _createdAt);
    });
  }

  Future<bool> _validate() async {
    _formKey.currentState!.validate();
    if (await Future.delayed(
      const Duration(milliseconds: 50),
      () {
        if (_nameController.text.isNotEmpty &&
            _nameErrorMessage.isEmpty &&
            _uriErrorMessage.isEmpty &&
            _passwordErrorMessage.isEmpty &&
            _emailErrorMessage.isEmpty) {
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
    if (_uriErrorMessage.isNotEmpty) {
      _uriErrorController.showTooltip();
    }
    if (_passwordErrorMessage.isNotEmpty) {
      _passwordErrorController.showTooltip();
    }
    return false;
  }

  void _onSave() async {
    if (!await _validate()) return;

    String uri = _uriController.text;
    if (!uri.contains("://")) {
      uri = "http://$uri";
    }

    if (widget.passwordEntry == null) {
      widget.onSave(PasswordEntry(
        _nameController.text,
        email: _emailController.text,
        createdAt: _createdAt,
        url: uri,
        key: _key,
        password: _passwordController.text,
      ));
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("New entry for ${_nameController.text} created"),
      ));
      Navigator.of(context).pop();
      return;
    }

    bool updated = false;
    if (_nameController.text != widget.passwordEntry!.name) {
      widget.passwordEntry!.name = _nameController.text;
      debugPrint("name updated");
      updated = true;
    }
    if (_emailController.text != widget.passwordEntry!.email) {
      widget.passwordEntry!.email = _emailController.text;
      debugPrint("email updated");
      updated = true;
    }
    if (uri != widget.passwordEntry!.uri.toString()) {
      widget.passwordEntry!.uri = Uri.parse(uri);
      debugPrint("uri updated");
      updated = true;
    }
    if (_passwordController.text.trim() != "" &&
        widget.passwordEntry!.getPassword(_key) != _passwordController.text) {
      widget.passwordEntry!.setPassword(_passwordController.text, _key);
      debugPrint("password updated");
      updated = true;
    }

    if (updated) {
      widget.passwordEntry!.lastUpdated = Timestamp.now();
      widget.onSave(widget.passwordEntry!);
    }

    setState(() => _isEditable = false);
  }

  void _onDelete() {
    widget.onDelete?.call(widget.passwordEntry!);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "${_isEditable ? widget.passwordEntry == null ? 'Add' : 'Edit' : 'View'}"
          " item",
        ),
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          _isEditable
              ? IconButton(
                  icon: const Icon(Icons.check_outlined),
                  onPressed: _onSave,
                )
              : IconButton(
                  icon: const Icon(Icons.delete_outlined),
                  onPressed: _onDelete,
                ),
        ],
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.only(top: 20, left: 30),
                child: const Text(
                  'Item Information',
                  style: TextStyle(fontSize: 16),
                ),
                alignment: Alignment.centerLeft,
              ),
              RoundedTextFormField(
                autovalidateMode: AutovalidateMode.onUserInteraction,
                keyboardType: TextInputType.name,
                labelText: 'Name',
                controller: _nameController,
                icon: Icons.language_outlined,
                disabled: !_isEditable,
                tooltipMessage: _nameErrorMessage,
                tooltipController: _nameErrorController,
                focusNode: _isEditable ? null : AlwaysDisabledFocusNode(),
                validator: (name) {
                  WidgetsBinding.instance!.addPostFrameCallback(
                    (_) => setState(
                      () => _nameErrorMessage =
                          name!.isEmpty ? 'Name cannot be empty' : '',
                    ),
                  );
                },
              ),
              SizedBox(height: size.height * 0.015),
              RoundedTextFormField(
                autovalidateMode: AutovalidateMode.onUserInteraction,
                labelText: 'Username',
                controller: _emailController,
                icon: Icons.person_outlined,
                disabled: !_isEditable,
                focusNode: _isEditable ? null : AlwaysDisabledFocusNode(),
                tooltipMessage: _emailErrorMessage,
                tooltipController: _emailErrorController,
                suffixIcon: IconButton(
                  icon: const Icon(
                    Icons.content_copy_outlined,
                    color: Colors.black,
                    size: 20,
                  ),
                  padding: const EdgeInsets.only(left: 16),
                  constraints: const BoxConstraints(),
                  onPressed: () => copyToClipboard(
                    context: context,
                    name: "Username",
                    data: _emailController.text,
                  ),
                ),
                validator: (email) {
                  WidgetsBinding.instance!.addPostFrameCallback(
                    (_) => setState(
                      () => _emailErrorMessage =
                          email!.isEmpty ? 'Username cannot be empty' : '',
                    ),
                  );
                },
              ),
              SizedBox(height: size.height * 0.015),
              RoundedTextFormField(
                autovalidateMode: AutovalidateMode.onUserInteraction,
                labelText: 'Password',
                controller: _passwordController,
                obscureText: !_isPasswordVisible,
                icon: Icons.lock_outlined,
                disabled: !_isEditable,
                focusNode: _isEditable ? null : AlwaysDisabledFocusNode(),
                tooltipMessage: _passwordErrorMessage,
                tooltipController: _passwordErrorController,
                suffixIcon: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: Colors.black,
                        size: 20,
                      ),
                      padding: const EdgeInsets.only(right: 8),
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        setState(
                            () => _isPasswordVisible = !_isPasswordVisible);
                        if (widget.passwordEntry != null &&
                            !_isEditable &&
                            _isPasswordVisible) {
                          _passwordController.text =
                              widget.passwordEntry!.getPassword(_key);
                        }
                      },
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.content_copy_outlined,
                        color: Colors.black,
                        size: 20,
                      ),
                      padding: const EdgeInsets.only(left: 8),
                      constraints: const BoxConstraints(),
                      onPressed: () => copyToClipboard(
                        context: context,
                        name: "Password",
                        data: widget.passwordEntry?.getPassword(_key) ??
                            _passwordController.text,
                      ),
                    ),
                  ],
                ),
                validator: (password) {
                  WidgetsBinding.instance!.addPostFrameCallback(
                    (_) => setState(
                      () => _passwordErrorMessage =
                          password!.isEmpty ? 'Password cannot be empty' : '',
                    ),
                  );
                },
              ),
              SizedBox(height: size.height * 0.015),
              Container(
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.only(top: 20, left: 30),
                child: const Text(
                  "URIs",
                  style: TextStyle(fontSize: 16),
                ),
              ),
              RoundedTextFormField(
                autovalidateMode: AutovalidateMode.onUserInteraction,
                focusNode: _isEditable ? null : AlwaysDisabledFocusNode(),
                labelText: 'Website',
                controller: _uriController,
                icon: Icons.link_outlined,
                disabled: !_isEditable,
                tooltipMessage: _uriErrorMessage,
                tooltipController: _uriErrorController,
                suffixIcon: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    IconButton(
                      icon: const Icon(
                        Icons.launch_outlined,
                        color: Colors.black,
                        size: 20,
                      ),
                      padding: const EdgeInsets.only(right: 8),
                      constraints: const BoxConstraints(),
                      onPressed: () async {
                        await url_launcher.loadLibrary();
                        await url_launcher.launch(
                          _uriController.text,
                          forceSafariVC: false,
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.content_copy_outlined,
                        color: Colors.black,
                        size: 20,
                      ),
                      padding: const EdgeInsets.only(left: 8),
                      constraints: const BoxConstraints(),
                      onPressed: () => copyToClipboard(
                        context: context,
                        name: "Url",
                        data: _uriController.text,
                      ),
                    ),
                  ],
                ),
                validator: (url) {
                  WidgetsBinding.instance!.addPostFrameCallback((timeStamp) {
                    setState(() => _uriErrorMessage = isURL(
                          url,
                          protocols: const [
                            'http',
                            'https',
                            'ftp',
                            'sftp',
                            'androidapp'
                          ],
                        )
                            ? ''
                            : 'Invalid URL');
                  });
                },
              ),
              if (!_isEditable && widget.passwordEntry != null)
                Container(
                  padding: const EdgeInsets.only(left: 30, top: 10),
                  alignment: Alignment.centerLeft,
                  child: Text(
                      "Last updated: ${timeago.format(widget.passwordEntry!.lastUpdated.toDate())}",
                      style: Theme.of(context).textTheme.overline),
                ),
            ],
          ),
        ),
      ),
      floatingActionButton: widget.passwordEntry == null
          ? null
          : FloatingActionButton(
              heroTag: "item",
              backgroundColor: purpleMaterialColor,
              onPressed: () {
                setState(() => _isEditable = !_isEditable);
                if (!_isEditable) _setDefaultValueToTextFields();
              },
              child: Icon(_isEditable ? Icons.clear : Icons.edit_outlined),
            ),
    );
  }
}
