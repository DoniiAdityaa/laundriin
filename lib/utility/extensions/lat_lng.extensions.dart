import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';

extension LatLngExtension on LatLng {
  Future<Placemark?> getPlacemark() async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        return placemarks.first;
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  Future<String?> getAddress() async {
    try {
      List<Placemark> placemarks =
          await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark placemark = placemarks[0];
        return "${placemark.street}, ${placemark.locality}, ${placemark.administrativeArea}";
      } else {
        return null;
      }
    } catch (e) {
      print("Error getting address: $e");
      return null;
    }
  }
}
