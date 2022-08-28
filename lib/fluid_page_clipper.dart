import 'package:flutter/material.dart';

class FluidPageClipper extends CustomClipper<Path> {
  const FluidPageClipper(this.offsets);

  final List<Offset> offsets;

  @override
  Path getClip(Size size) {
    final path = Path();

    path.moveTo(offsets.first.dx, offsets.first.dy);

    for (int i = 1; i < offsets.length - 2; i++) {
      var xc = (offsets[i].dx + offsets[i + 1].dx) / 2;
      var yc = (offsets[i].dy + offsets[i + 1].dy) / 2;
      path.quadraticBezierTo(offsets[i].dx, offsets[i].dy, xc, yc);
    }

    path.quadraticBezierTo(
      offsets[offsets.length - 2].dx,
      offsets[offsets.length - 2].dy,
      offsets[offsets.length - 1].dx,
      offsets[offsets.length - 1].dy,
    );

    path.lineTo(size.width, size.height);
    path.lineTo(size.width, 0);

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) {
    return true;
  }
}
