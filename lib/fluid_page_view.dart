import 'package:flutter/material.dart';

import 'clipped_fluid_page.dart';

class FluidPageView extends StatefulWidget {
  const FluidPageView({required this.children, Key? key})
      : assert(children.length > 1, 'Children length must be at least 2'),
        super(key: key);

  final List<Widget> children;

  @override
  State<FluidPageView> createState() => _FluidPageViewState();
}

class _FluidPageViewState extends State<FluidPageView> {
  int bottomIndex = 0;
  int topIndex = 1;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            widget.children.elementAt(bottomIndex),
            ClippedFluidPage(
              size: constraints.biggest,
              child: widget.children.elementAt(topIndex),
            ),
          ],
        );
      },
    );
  }
}
