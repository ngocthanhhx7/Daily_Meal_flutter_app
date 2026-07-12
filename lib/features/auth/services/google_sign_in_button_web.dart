import 'package:flutter/material.dart';
import 'package:google_sign_in_web/web_only.dart' as google_web;

Widget buildGoogleSignInButton({required VoidCallback? onPressed}) {
  return IgnorePointer(
    ignoring: onPressed == null,
    child: Opacity(
      opacity: onPressed == null ? 0.5 : 1,
      child: google_web.renderButton(),
    ),
  );
}
