import 'package:flutter/material.dart';

class FluidPageClipper extends CustomClipper<Path> {
  const FluidPageClipper(this.offsets);

  final List<Offset> offsets;

  @override
  Path getClip(Size size) {
    final path = Path();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return true;
  }
}
