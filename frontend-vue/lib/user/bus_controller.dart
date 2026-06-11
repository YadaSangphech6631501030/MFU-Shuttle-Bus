import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class BusController {
  BusController._private();
  static final BusController instance = BusController._private();

  List<dynamic> busData = [];

  Map<String, LatLng> busPositions = {};
  Map<String, double> busProgress = {};
  Map<String, int> busETA = {};
  Map<String, int> stationETA = {};
  Map<String, DateTime?> busWaitUntil = {};
  Map<String, String?> lastStationId = {};

  Timer? moveTimer;

  double speed = 0.3;
  List<LatLng> route = [];

  void start() {
    moveTimer ??= Timer.periodic(const Duration(milliseconds: 100), (_) {
      move();
    });
  }

  // ✅ logic การวิ่ง (ย้ายมาจากหน้า Home)
  void move() {
    if (route.isEmpty || busData.isEmpty) return;

    final now = DateTime.now();

    for (int i = 0; i < busData.length; i++) {
      final id = busData[i]["busNumber"].toString();

      // WAIT
      if (busWaitUntil[id] != null && now.isBefore(busWaitUntil[id]!)) {
        continue;
      }

      double currentProgress = busProgress[id] ?? (i * 20.0);
      double nextProgress = currentProgress + speed;

      // LOOP
      if (nextProgress >= route.length - 1) {
        nextProgress = 0;
      }

      busProgress[id] = nextProgress;

      int idx = nextProgress.floor();
      double t = nextProgress - idx;

      LatLng p1 = route[idx];
      LatLng p2 = route[idx + 1];

      busPositions[id] = LatLng(
        p1.latitude + (p2.latitude - p1.latitude) * t,
        p1.longitude + (p2.longitude - p1.longitude) * t,
      );
    }
  }

  void updateBuses(List<dynamic> data) {
    busData = data;

    for (var bus in data) {
      final id = bus["busNumber"].toString();

      busPositions.putIfAbsent(id, () => const LatLng(0, 0));
      busProgress.putIfAbsent(id, () => 0);
      busWaitUntil.putIfAbsent(id, () => null);
      lastStationId.putIfAbsent(id, () => null);
    }

    final activeIds = data.map((b) => b["busNumber"].toString()).toSet();

    busPositions.removeWhere((k, _) => !activeIds.contains(k));
    busProgress.removeWhere((k, _) => !activeIds.contains(k));
    busWaitUntil.removeWhere((k, _) => !activeIds.contains(k));
    lastStationId.removeWhere((k, _) => !activeIds.contains(k));
  }

  void setRoute(List<LatLng> newRoute) {
    route = newRoute;
  }
}
