import 'dart:math' as math;
import 'package:latlong2/latlong.dart';
import 'package:map_kit/models/poly_line_model.dart';
import 'package:map_kit/models/poly_line_point_model.dart';

class CirclePolylineModel extends PolyLineModel {
  final LatLng center;
  final double radius;

  CirclePolylineModel({
    required this.center,
    required this.radius,
    required super.color,
    super.strokeWidth,
    super.strokeColor,
    super.data,
    int? pointsCount,
  }) : super(

    points: _generateCirclePoints(
      center,
      radius,
      pointsCount,
    ),
  );

  /// Checks if a map tap occurred inside the boundaries of this circle.
  bool isPointInside(LatLng tapPoint) {
    const distance = Distance();
    final double distanceToTap = distance.as(LengthUnit.Meter, center, tapPoint);
    return distanceToTap <= radius;
  }

  /// Dynamically calculates the number of points based on the radius size.
  static int _calculateOptimalPoints(double radius) {
    const int minPoints = 36;

    const int maxPoints = 360;

    final int calculatedPoints = minPoints + (radius / 10).floor();

    return math.max(minPoints, math.min(maxPoints, calculatedPoints));
  }

  /// Calculates the LatLng coordinates around the center to draw the visual circle.
  static List<PolyLinePointModel> _generateCirclePoints(
      LatLng center, double radiusInMeters, int? pointsCount) {

    int tPointCount = pointsCount ?? _calculateOptimalPoints(radiusInMeters);
    final List<PolyLinePointModel> circlePoints = [];
    const double earthRadius = 6378137.0;
    final double d = radiusInMeters / earthRadius;

    final double lat1 = center.latitude * math.pi / 180.0;
    final double lng1 = center.longitude * math.pi / 180.0;

    for (int i = 0; i <= tPointCount; i++) {
      final double bearing = (360.0 / tPointCount) * i * math.pi / 180.0;

      final double lat2 = math.asin(
        math.sin(lat1) * math.cos(d) +
            math.cos(lat1) * math.sin(d) * math.cos(bearing),
      );

      final double lng2 = lng1 + math.atan2(
        math.sin(bearing) * math.sin(d) * math.cos(lat1),
        math.cos(d) - math.sin(lat1) * math.sin(lat2),
      );

      circlePoints.add(PolyLinePointModel(
        lat2 * 180.0 / math.pi,
        lng2 * 180.0 / math.pi,
        0.0,
      ));
    }

    return circlePoints;
  }
}