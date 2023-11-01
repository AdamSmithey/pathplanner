import 'dart:math';

import 'package:pathplanner/path/path_constraints.dart';

class PathPoint {
  Point position;
  num? holonomicRotation;
  PathConstraints constraints;
  num distanceAlongPath;
  num maxV = double.infinity;

  PathPoint({
    required this.position,
    required this.holonomicRotation,
    required this.constraints,
    required this.distanceAlongPath,
  });

  void invert() {
    position = Point(-position.x, position.y);
    if(holonomicRotation != null) holonomicRotation = 180 - holonomicRotation!;
  }
}
