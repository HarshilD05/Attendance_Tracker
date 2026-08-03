import 'package:flutter/material.dart';
import 'package:another_flushbar/flushbar.dart';

void showErrorSnackBar(BuildContext context, String message) {
  Flushbar(
    messageText: Text(
      message,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    ),
    icon: const Icon(
      Icons.error_outline,
      color: Colors.white,
    ),
    backgroundColor: Colors.redAccent,
    duration: const Duration(seconds: 2),
    flushbarPosition: FlushbarPosition.TOP,
    margin: const EdgeInsets.all(16),
    borderRadius: BorderRadius.circular(8),
    animationDuration: const Duration(milliseconds: 500),
  ).show(context);
}
