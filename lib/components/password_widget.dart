import 'dart:typed_data' show Uint8List;

import 'package:flutter/material.dart';
import 'package:passwordmanager/constants.dart' show darkBlueishColor;
import 'package:passwordmanager/models/password_entry.dart';
import 'package:passwordmanager/screens/home.dart';
import 'package:passwordmanager/screens/item_screen.dart';
import 'package:passwordmanager/utils.dart';

class PasswordWidget extends StatelessWidget {
  final PasswordEntry entry;
  late final String faviconPath;
  final VoidCallback onView;
  late final Uint8List _passKey;

  PasswordWidget(
      {Key? key,
      required this.entry,
      required this.onView,
      required Uint8List passwordKey})
      : super(key: key) {
    _passKey = passwordKey;
    try {
      faviconPath = "${entry.uri.origin}/favicon.ico";
    } on StateError {
      faviconPath = "";
    }
  }

  @override
  int get hashCode => hashValues(entry, faviconPath);

  @override
  bool operator ==(Object other) {
    return other is PasswordWidget &&
        other.entry == entry &&
        other.faviconPath == faviconPath;
  }

  Widget _buildImageError(_, __, ___) => const Icon(Icons.language, size: 30);

  Widget get _icon {
    return CircleAvatar(
      backgroundColor: Colors.transparent,
      foregroundColor: darkBlueishColor,
      radius: 15,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25.0),
        child: Image.network(
          faviconPath,
          loadingBuilder: (BuildContext context, Widget child,
              ImageChunkEvent? loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
          errorBuilder: _buildImageError,
          height: 30,
          width: 30,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  ListTile _bottomSheetItem(IconData icon, String title, VoidCallback onTap) {
    return ListTile(
      dense: true,
      leading: Icon(icon, size: 30.0),
      title: Text(title, style: const TextStyle(fontSize: 16.0)),
      onTap: onTap,
    );
  }

  void showActionsModalBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.0)),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(10.0),
          height: 330.0,
          child: Column(
            children: [
              ListTile(
                dense: true,
                leading: _icon,
                title: Text(
                  entry.name,
                  style: const TextStyle(fontSize: 18.0),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.close_outlined),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),
              Divider(
                color: Colors.grey.shade500,
              ),
              _bottomSheetItem(
                Icons.copy_outlined,
                "Copy email",
                () {
                  copyToClipboard(
                    context: context,
                    data: entry.email,
                    name: "Email",
                    onCopy: Navigator.of(context).pop,
                  );
                },
              ),
              _bottomSheetItem(
                Icons.copy_outlined,
                "Copy password",
                () async {
                  copyToClipboard(
                    context: context,
                    data: entry.getPassword(_passKey),
                    name: "Password",
                    onCopy: Navigator.of(context).pop,
                  );
                },
              ),
              _bottomSheetItem(
                Icons.info_outline,
                "View details",
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ItemScreen(
                      passwordEntry: entry,
                      isEditable: false,
                      onSave: (PasswordEntry entry) =>
                          repository.updateEntry(entry),
                      onDelete: repository.deleteEntry,
                    ),
                  ),
                ),
              ),
              _bottomSheetItem(
                Icons.edit_outlined,
                "Edit",
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ItemScreen(
                      passwordEntry: entry,
                      isEditable: true,
                      onSave: (PasswordEntry entry) =>
                          repository.updateEntry(entry),
                      onDelete: repository.deleteEntry,
                    ),
                  ),
                ),
              ),
              _bottomSheetItem(
                Icons.delete_outline,
                "Delete",
                () {
                  repository.deleteEntry(entry);
                  Navigator.pop(context);
                },
              )
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onLongPress: () => showActionsModalBottomSheet(context),
      dense: true,
      contentPadding: const EdgeInsets.symmetric(vertical: 1),
      minLeadingWidth: 0.0,
      leading: _icon,
      onTap: onView,
      title: Text(
        entry.name,
        style: const TextStyle(
          fontSize: 16.0,
          fontWeight: FontWeight.w500,
          letterSpacing: .5,
          height: 1.5,
        ),
      ),
      subtitle: Text(
        entry.email,
        style: const TextStyle(
          fontSize: 14.0,
          fontWeight: FontWeight.w400,
          height: 1.5,
        ),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.more_vert_outlined),
        onPressed: () => showActionsModalBottomSheet(context),
      ),
    );
  }

  @override
  String toStringShort() => "PasswordWidget<${entry.name}>";
}
