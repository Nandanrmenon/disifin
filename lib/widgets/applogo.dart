import 'package:flutter/material.dart';

class AppLogo extends StatefulWidget {
  final double? size;
  const AppLogo({super.key, this.size});

  @override
  State<AppLogo> createState() => _AppLogoState();
}

class _AppLogoState extends State<AppLogo> {
  @override
  Widget build(BuildContext context) {
    return Image(
      width: widget.size ?? 48,
      height: widget.size ?? 48,
      image: AssetImage('res/logo.png'),
    );
  }
}
