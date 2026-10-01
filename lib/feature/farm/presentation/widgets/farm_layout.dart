import 'dart:math' as math;

import 'package:flutter/widgets.dart';

({Size size, Offset offset}) farmCoverGeometry(Size viewport, Size source) {
  final scale = math.max(
    viewport.width / source.width,
    viewport.height / source.height,
  );
  final size = Size(source.width * scale, source.height * scale);
  return (
    size: size,
    offset: Offset(
      (viewport.width - size.width) / 2,
      (viewport.height - size.height) / 2,
    ),
  );
}

String farmDuration(Duration duration) {
  final seconds = math.max(0, duration.inSeconds);
  return '${(seconds ~/ 3600).toString().padLeft(2, '0')}:'
      '${((seconds % 3600) ~/ 60).toString().padLeft(2, '0')}:'
      '${(seconds % 60).toString().padLeft(2, '0')}';
}
