import 'package:flutter/material.dart';

SnackBar elderSnackBar(
  String message, {
  Color? backgroundColor,
}) {
  return SnackBar(
    content: Text(message),
    behavior: SnackBarBehavior.floating,
    duration: const Duration(seconds: 4),
    backgroundColor: backgroundColor,
  );
}

