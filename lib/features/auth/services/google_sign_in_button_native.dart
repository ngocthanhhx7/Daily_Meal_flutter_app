import 'package:flutter/material.dart';

Widget buildGoogleSignInButton({required VoidCallback? onPressed}) {
  return OutlinedButton.icon(
    onPressed: onPressed,
    icon: const Icon(Icons.g_mobiledata_rounded, size: 28),
    label: const Text('Tiếp tục với Google'),
  );
}
