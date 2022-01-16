import 'package:flutter/material.dart';
import 'package:passwordmanager/constants.dart';

class RoundedButton extends StatelessWidget {
  final String text;
  final Function() onPressed;
  late final Color color, textColor;

  RoundedButton({
    Key? key,
    required this.text,
    required this.onPressed,
    Color? color,
    this.textColor = Colors.white,
  }) : super(key: key) {
    this.color = color ?? purpleMaterialColor;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      width: MediaQuery.of(context).size.width * 0.9,
      child: ElevatedButton(
        onPressed: onPressed,
        child: Text(text, style: TextStyle(color: textColor)),
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          primary: color,
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
        ),
      ),
    );
  }
}
