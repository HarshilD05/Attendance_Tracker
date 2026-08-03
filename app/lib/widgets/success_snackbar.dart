import 'package:flutter/material.dart';
import 'package:another_flushbar/flushbar.dart';

void showSuccessSnackBar(BuildContext context, String message) {
  Flushbar(
    messageText: Text(
      message,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    ),
    icon: const Icon(
      Icons.check_circle,
      color: Colors.white,
    ),
    backgroundColor: Colors.green.shade600,
    duration: const Duration(seconds: 2),
    flushbarPosition: FlushbarPosition.TOP,
    margin: const EdgeInsets.all(16),
    borderRadius: BorderRadius.circular(8),
    animationDuration: const Duration(milliseconds: 500),
  ).show(context);
}
