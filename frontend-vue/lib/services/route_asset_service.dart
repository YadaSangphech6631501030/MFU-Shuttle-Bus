import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RouteAssetService {
  static const String line1RouteAsset =
      'assets/routes/polyline_line1_mfu.geojson';
  static const String line2RouteAsset =
      'assets/routes/polyline_line2_mfu.geojson';

  static Future<List<LatLng>> loadLine1Route() {
    return loadGeoJsonRoute(line1RouteAsset);
  }

  static Future<List<LatLng>> loadLine2Route() {
    return loadGeoJsonRoute(line2RouteAsset);
  }

  static Future<List<LatLng>> loadRouteForLine(String line) {
    if (line == 'line1') return loadLine1Route();
    if (line == 'line2') return loadLine2Route();
    return Future.value([]);
  }

  static Future<List<LatLng>> loadGeoJsonRoute(String assetPath) async {
    try {
      final rawGeoJson = await rootBundle.loadString(assetPath);
      final geoJson = jsonDecode(rawGeoJson);
      final coordinates = _extractCoordinates(geoJson);

      return coordinates
          .whereType<List>()
          .where((point) => point.length >= 2)
          .map((point) {
            final lng = _toDouble(point[0]);
            final lat = _toDouble(point[1]);
            return LatLng(lat, lng);
          })
          .toList();
    } catch (_) {
      return [];
    }
  }

  static List<dynamic> _extractCoordinates(dynamic geoJson) {
    if (geoJson is! Map) return [];

    final type = geoJson['type'];
    if (type == 'FeatureCollection') {
      final features = geoJson['features'];
      if (features is! List || features.isEmpty) return [];
      return _extractCoordinates(features.first);
    }

    if (type == 'Feature') {
      return _extractCoordinates(geoJson['geometry']);
    }

    if (type == 'LineString') {
      final coordinates = geoJson['coordinates'];
      return coordinates is List ? coordinates : [];
    }

    return [];
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.parse(value.toString());
  }
}
