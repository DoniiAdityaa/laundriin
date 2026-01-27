import 'dart:math';

class DeliveryEstimate {
  final double distanceKm;
  final double travelTimeMinutes;
  final double totalEstimateMinutes;
  final String formattedEstimate;

  DeliveryEstimate({
    required this.distanceKm,
    required this.travelTimeMinutes,
    required this.totalEstimateMinutes,
    required this.formattedEstimate,
  });
}

DeliveryEstimate estimateDeliveryTime({
  required double latOrigin,
  required double lonOrigin,
  required double latDestination,
  required double lonDestination,
  int prepTimeMinutes = 15,
  int pickupDelayMinutes = 5,
  double averageSpeedKmh = 35.0, // motor
}) {
  // Rumus Haversine
  const earthRadius = 6371.0; // km
  final dLat = _toRadians(latDestination - latOrigin);
  final dLon = _toRadians(lonDestination - lonOrigin);

  final a =
      pow(sin(dLat / 2), 2) + cos(_toRadians(latOrigin)) * cos(_toRadians(latDestination)) * pow(sin(dLon / 2), 2);

  final c = 2 * atan2(sqrt(a), sqrt(1 - (a)));
  final distance = earthRadius * c;

  // Waktu tempuh dalam menit
  final travelTime = (distance / averageSpeedKmh) * 60;
  final totalTime = prepTimeMinutes + pickupDelayMinutes + travelTime;

  // Format hh:mm
  final hours = totalTime.toInt() ~/ 60;
  final minutes = totalTime.toInt() % 60;
  final formatted = hours > 0 ? '$hours jam $minutes menit' : '$minutes menit';

  return DeliveryEstimate(
    distanceKm: double.parse(distance.toStringAsFixed(2)),
    travelTimeMinutes: double.parse(travelTime.toStringAsFixed(1)),
    totalEstimateMinutes: double.parse(totalTime.toStringAsFixed(1)),
    formattedEstimate: formatted,
  );
}

double _toRadians(double degree) => degree * pi / 180;
