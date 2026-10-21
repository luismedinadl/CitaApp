import 'package:flutter/material.dart';
import 'package:google_sign_in_web/web_only.dart' as google_web;

class GoogleButton extends StatelessWidget {
  const GoogleButton({super.key});

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 44,
    child: google_web.renderButton(),
  );
}
