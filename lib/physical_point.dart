import 'package:flutter/material.dart';

class PhysicalPoint {
  PhysicalPoint({required this.position, required this.velocity, required this.force});

  Offset position;
  Offset velocity;
  Offset force;
}
