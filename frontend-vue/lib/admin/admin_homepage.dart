import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:google_fonts/google_fonts.dart';
import 'admin_bottom_bar.dart';
import 'admin_setting.dart';
import 'package:shuttle_bus_fronted/services/api_service.dart';
import 'package:shuttle_bus_fronted/services/route_asset_service.dart';
import '../user/bus_controller.dart';
import '../user/bus_page.dart';

class AdminHomepage extends StatefulWidget {
  const AdminHomepage({super.key});

  @override
  State<AdminHomepage> createState() => _AdminHomepageState();
}

class _AdminHomepageState extends State<AdminHomepage> {
  int currentIndex = 0;

  String selectedLine = "line1";
  GoogleMapController? mapController;
  double currentZoom = 16;

  Timer? stationTimer;
  Timer? busTimer;
  Timer? moveTimer;
  final TextEditingController searchController = TextEditingController();

  List<dynamic> busData = [];
  List<dynamic> stationData = [];
  List<Map<String, dynamic>> dbLine1Stations = [];
  List<Map<String, dynamic>> dbLine2Stations = [];
  Map<String, LatLng> busPositions = {};
  BitmapDescriptor stationMarkerIcon = BitmapDescriptor.defaultMarker;
  final Map<String, BitmapDescriptor> busMarkerIcons = {};
  static const Map<String, String> _busMarkerAssets = {
    "left": "assets/gemcar_left.png",
    "right": "assets/gemcar_right.png",
    "turnLeft": "assets/gemcar_turnleft.png",
    "turnRight": "assets/gemcar_turnright.png",
  };

  // statuses for bus
  Map<String, double> busProgress =
      {}; // เก็บ index ปัจจุบันใน route ของรถแต่ละคัน
  Map<String, DateTime?> busWaitUntil =
      {}; // เวลาที่รถจะเริ่มวิ่งต่อได้ (ใช้หยุดสถานี)
  Map<String, String?> lastStationId =
      {}; // จำว่าสถานีล่าสุดที่จอดคือที่ไหน (กันจอดซ้ำ)

  double speed = 1.2;
  List<LatLng> route = [];
  List<LatLng> route1 = [];
  List<LatLng> route2 = [];

  //BusTimeline
  Widget busTimeline(List<Map<String, dynamic>> stations, double progress) {
    int currentIndex = progress.floor();
    double t = progress - currentIndex;

    return Column(
      children: [
        Row(
          children: List.generate(stations.length * 2 - 1, (i) {
            // DOT
            if (i % 2 == 0) {
              int index = i ~/ 2;

              bool passed = index < currentIndex;
              bool current = index == currentIndex;

              return Column(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: current
                          ? Colors.amber
                          : passed
                          ? Colors.grey
                          : Colors.white,
                      border: Border.all(color: Colors.amber),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    stations[index]["name"].toString().split("(")[0],
                    style: const TextStyle(fontSize: 10),
                  ),
                ],
              );
            }

            // LINE
            return Expanded(
              child: Container(
                height: 3,
                color: Colors.grey.shade300,
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: (i ~/ 2) == currentIndex ? t : 1.0,
                  child: Container(color: Colors.amber),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget buildReportItem(IconData icon, String title, Color color) {
    return GestureDetector(
      onTap: () {
        print("เลือก: $title");
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: color,
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(title, style: GoogleFonts.kanit(fontSize: 14)),
          ],
        ),
      ),
    );
  }

  // fetch station
  Future<void> fetchStations() async {
    try {
      final line1Data = await ApiService.getStations("line1");
      final line2Data = await ApiService.getStations("line2");
      final stationById = <String, dynamic>{};

      for (final station in [...line1Data, ...line2Data]) {
        final id = station["id"]?.toString() ?? "";
        if (id.isNotEmpty) {
          stationById[id] = station;
        }
      }

      setState(() {
        dbLine1Stations = line1Data
            .map((station) => Map<String, dynamic>.from(station))
            .toList();
        dbLine2Stations = line2Data
            .map((station) => Map<String, dynamic>.from(station))
            .toList();
        stationData = stationById.values.toList();
      });

      updateAllRoutes();
    } catch (e) {
      print("API ERROR: $e");
    }
  }

  //Markers color by status
  double getMarkerHue(String status) {
    switch (status) {
      case "LOW":
        return BitmapDescriptor.hueGreen;
      case "MEDIUM":
        return BitmapDescriptor.hueOrange;
      case "HIGH":
        return BitmapDescriptor.hueRed;
      default:
        return BitmapDescriptor.hueAzure;
    }
  }

  double distanceBetween(LatLng from, LatLng to) {
    return const ll.Distance().as(
      ll.LengthUnit.Meter,
      ll.LatLng(from.latitude, from.longitude),
      ll.LatLng(to.latitude, to.longitude),
    );
  }

  BitmapDescriptor busIconFor(String id) {
    final sprite = BusController.instance.busSprites[id] ?? "right";
    return busMarkerIcons[sprite] ??
        busMarkerIcons["right"] ??
        BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
  }

  List<Map<String, dynamic>> getSelectedLine() {
    return selectedLine == "line1" ? dbLine1Stations : dbLine2Stations;
  }

  Future<List<LatLng>> fetchRealRoute() async {
    final points = getSelectedLine();

    if (points.isEmpty) return [];

    String coords = points.map((p) => "${p["lng"]},${p["lat"]}").join(";");

    final url =
        "https://router.project-osrm.org/route/v1/driving/$coords?overview=full&geometries=geojson";

    try {
      final res = await http.get(Uri.parse(url));
      final data = jsonDecode(res.body);

      if (data["routes"] == null || data["routes"].isEmpty) {
        print("❌ fallback route");
        return points.map((p) => LatLng(p["lat"], p["lng"])).toList();
      }

      final routeCoords = data["routes"][0]["geometry"]["coordinates"];

      return routeCoords.map<LatLng>((c) {
        return LatLng(c[1], c[0]);
      }).toList();
    } catch (e) {
      print("❌ ROUTE ERROR: $e");
      return points.map((p) => LatLng(p["lat"], p["lng"])).toList();
    }
  }

  List<Map<String, dynamic>> getAllLines() {
    final stationById = <String, Map<String, dynamic>>{};

    for (final station in [...dbLine1Stations, ...dbLine2Stations]) {
      final id = station["id"]?.toString() ?? "";
      if (id.isNotEmpty) {
        stationById[id] = station;
      }
    }

    return stationById.values.toList();
  }

  List<LatLng> getLineLatLngs(List<Map<String, dynamic>> points) {
    return points.map((p) => LatLng(p["lat"], p["lng"])).toList();
  }

  List<LatLng> densifyRoadRoute(
    List<LatLng> points, {
    int segmentsPerEdge = 10,
  }) {
    if (points.length < 2) return points;

    final result = <LatLng>[];
    for (var i = 0; i < points.length - 1; i++) {
      final start = points[i];
      final end = points[i + 1];

      for (var step = 0; step < segmentsPerEdge; step++) {
        final t = step / segmentsPerEdge;
        result.add(
          LatLng(
            start.latitude + ((end.latitude - start.latitude) * t),
            start.longitude + ((end.longitude - start.longitude) * t),
          ),
        );
      }
    }
    result.add(points.last);
    return result;
  }

  Future<List<LatLng>> fetchRouteForPoints(
    List<Map<String, dynamic>> points,
  ) async {
    if (points.isEmpty) return [];

    String coords = points.map((p) => "${p["lng"]},${p["lat"]}").join(";");

    final url =
        "https://router.project-osrm.org/route/v1/driving/$coords?overview=full&geometries=geojson";

    try {
      final res = await http.get(Uri.parse(url));
      final data = jsonDecode(res.body);

      if (data["routes"] == null || data["routes"].isEmpty) {
        print("route fallback");
        return getLineLatLngs(points);
      }

      final routeCoords = data["routes"][0]["geometry"]["coordinates"];

      return routeCoords.map<LatLng>((c) {
        return LatLng(c[1], c[0]);
      }).toList();
    } catch (e) {
      print("ROUTE ERROR: $e");
      return getLineLatLngs(points);
    }
  }

  Future<List<LatLng>> fetchRouteForLine(
    String line,
    List<Map<String, dynamic>> points,
  ) async {
    final assetRoute = await RouteAssetService.loadRouteForLine(line);
    if (assetRoute.isNotEmpty) return assetRoute;

    return fetchRouteForPoints(points);
  }

  Future<void> loadStationMarkerIcon() async {
    final icon = await BitmapDescriptor.asset(
      const ImageConfiguration(),
      "assets/bus_stop_2.png",
      width: 54,
      height: 54,
    );

    if (!mounted) return;

    setState(() {
      stationMarkerIcon = icon;
    });
  }

  Future<void> loadBusMarkerIcons() async {
    final icons = <String, BitmapDescriptor>{};

    for (final entry in _busMarkerAssets.entries) {
      icons[entry.key] = await BitmapDescriptor.asset(
        const ImageConfiguration(),
        entry.value,
        width: 53,
        height: 53,
      );
    }

    if (!mounted) return;

    setState(() {
      busMarkerIcons
        ..clear()
        ..addAll(icons);
    });
  }

  @override
  void dispose() {
    stationTimer?.cancel();
    busTimer?.cancel();
    moveTimer?.cancel();
    mapController?.dispose();
    searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    loadStationMarkerIcon();
    loadBusMarkerIcons();
    updateAllRoutes();
    fetchStations();
    fetchBuses();

    BusController.instance.start();

    stationTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => fetchStations(),
    );
    busTimer = Timer.periodic(const Duration(seconds: 10), (_) => fetchBuses());

    moveTimer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      moveSmooth();
      updateAllStationETA();
      updateBusETA();
    });
  }

  Widget _infoRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: GoogleFonts.kanit(fontSize: 15)),
          Text(
            value,
            style: GoogleFonts.kanit(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _cctvPreview(Map<String, dynamic> station) {
    final stationTitle = station["name"].toString().split("(")[0].trim();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 18),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade800),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.24),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(13),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.grey.shade900, Colors.black],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 12,
              left: 12,
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: Color(0xFFD2232A),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "CCTV",
                    style: GoogleFonts.kanit(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              right: 12,
              top: 10,
              child: Text(
                stationTitle,
                style: GoogleFonts.kanit(
                  color: Colors.grey.shade400,
                  fontSize: 12,
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.videocam_outlined,
                    color: Colors.grey.shade500,
                    size: 42,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Camera feed pending",
                    style: GoogleFonts.kanit(
                      color: Colors.grey.shade400,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  //fetch bus
  Future<void> fetchBuses() async {
    try {
      final data = await ApiService.getBuses();

      setState(() {
        busData = data;
      });

      BusController.instance.updateBuses(data);
    } catch (e) {
      print("BUS ERROR: $e");
    }
  }

  // Calculate ETA to station
  double calculateETA(LatLng stationLatLng) {
    double minMinutes = double.infinity;

    for (var bus in BusController.instance.busData) {
      final id = bus["busNumber"].toString();

      final pos = BusController.instance.busPositions[id];
      if (pos == null) continue;

      double distMeters = distanceBetween(pos, stationLatLng);

      double speedMeterPerSec = 10;

      double timeSec = distMeters / speedMeterPerSec;
      double timeMin = timeSec / 60;

      if (timeMin < minMinutes) {
        minMinutes = timeMin;
      }
    }

    if (minMinutes == double.infinity) return 0;
    return minMinutes;
  }

  //updates ETA station
  void updateAllStationETA() {
    for (var station in getSelectedLine()) {
      final stationId = station["id"];

      double minMinutes = double.infinity;

      for (var bus in BusController.instance.busData) {
        final id = bus["busNumber"].toString();
        final pos = BusController.instance.busPositions[id];

        if (pos == null) continue;

        double dist = distanceBetween(
          pos,
          LatLng(station["lat"], station["lng"]),
        );

        double timeMin = (dist / 5) / 60;

        if (timeMin < minMinutes) {
          minMinutes = timeMin;
        }
      }

      BusController.instance.stationETA[stationId] = minMinutes.isFinite
          ? minMinutes.toInt()
          : 0;
    }
  }

  // Bus movement logic
  void moveSmooth() {
    final buses = BusController.instance.busData;

    if (route.isEmpty || buses.isEmpty) return;

    setState(() {
      double spacing = route.length / buses.length;
      double safeGap = route.length / 50;

      for (int i = 0; i < buses.length; i++) {
        final id = buses[i]["busNumber"].toString();
        final now = DateTime.now();

        // ✅ WAIT
        if (BusController.instance.busWaitUntil[id] != null &&
            now.isBefore(BusController.instance.busWaitUntil[id]!)) {
          continue;
        }

        // ✅ initial spacing
        double currentProgress =
            BusController.instance.busProgress[id] ?? (i * spacing);

        double nextProgress = currentProgress + speed;

        // ✅ COLLISION (soft)
        bool blocked = false;
        for (var otherBus in buses) {
          final otherId = otherBus["busNumber"].toString();
          if (id == otherId) continue;

          double otherProgress =
              BusController.instance.busProgress[otherId] ?? 0;

          double gap = otherProgress - currentProgress;

          if (gap > 0 && gap < safeGap) {
            blocked = true;
            break;
          }
        }

        if (blocked) continue;

        // ✅ LOOP (วน)
        int idx = nextProgress.floor();

        if (idx >= route.length - 1) {
          BusController.instance.busProgress[id] = 0;
          BusController.instance.busPositions[id] = route[0];
          BusController.instance.updateBusVisualState(id, route, 0);
          continue;
        }

        BusController.instance.busProgress[id] = nextProgress;

        double t = nextProgress - idx;

        LatLng p1 = route[idx];
        LatLng p2 = route[idx + 1];

        LatLng newPos = LatLng(
          p1.latitude + (p2.latitude - p1.latitude) * t,
          p1.longitude + (p2.longitude - p1.longitude) * t,
        );

        BusController.instance.busPositions[id] = newPos;
        BusController.instance.updateBusVisualState(id, route, idx);

        // ✅ STOP AT STATION
        for (var station in getSelectedLine()) {
          LatLng stationLatLng = LatLng(station["lat"], station["lng"]);

          double dist = distanceBetween(newPos, stationLatLng);

          if (dist < 15 &&
              BusController.instance.lastStationId[id] != station["id"]) {
            BusController.instance.busWaitUntil[id] = now.add(
              const Duration(seconds: 2),
            );

            BusController.instance.lastStationId[id] = station["id"];
            break;
          } else if (dist > 50 &&
              BusController.instance.lastStationId[id] == station["id"]) {
            BusController.instance.lastStationId[id] = null;
          }
        }
      }
    });
  }

  Future<void> updateAllRoutes() async {
    final newRoute1 = await fetchRouteForLine("line1", dbLine1Stations);
    final newRoute2 = await fetchRouteForLine("line2", dbLine2Stations);

    setState(() {
      route1 = newRoute1.isNotEmpty
          ? densifyRoadRoute(newRoute1)
          : getLineLatLngs(dbLine1Stations);
      route2 = newRoute2.isNotEmpty
          ? densifyRoadRoute(newRoute2)
          : getLineLatLngs(dbLine2Stations);
    });

    updateRoute();
  }

  void updateRoute() async {
    final newRoute = await fetchRouteForLine(selectedLine, getSelectedLine());

    setState(() {
      route = densifyRoadRoute(newRoute);
    });
  }

  void updateBusETA() {
    for (var bus in BusController.instance.busData) {
      final id = bus["busNumber"].toString();
      final pos = BusController.instance.busPositions[id];

      if (pos == null) continue;

      double minMinutes = double.infinity;

      for (var station in getSelectedLine()) {
        double dist = distanceBetween(
          pos,
          LatLng(station["lat"], station["lng"]),
        );

        double timeMin = (dist / 5) / 60;

        if (timeMin < minMinutes) {
          minMinutes = timeMin;
        }
      }

      BusController.instance.busETA[id] = minMinutes.isFinite
          ? minMinutes.ceil()
          : 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // bottom bar
      bottomNavigationBar: AdminBottomBar(
        currentIndex: currentIndex,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },
      ),

      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: const LatLng(20.045, 99.894),
              zoom: currentZoom,
            ),
            onMapCreated: (controller) => mapController = controller,
            onCameraMove: (position) => currentZoom = position.zoom,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            polylines: {
              Polyline(
                polylineId: const PolylineId("line2"),
                points: route2.isNotEmpty
                    ? route2
                    : getLineLatLngs(dbLine2Stations),
                color: Colors.grey.shade700,
                width: 2,
              ),
              Polyline(
                polylineId: const PolylineId("line1"),
                points: route1.isNotEmpty
                    ? route1
                    : getLineLatLngs(dbLine1Stations),
                color: const Color(0xFFBC9945),
                width: 2,
              ),
            },
            markers: {
              ...getAllLines().map((station) {
                Map<String, dynamic>? stationMatch;

                try {
                  stationMatch = stationData.firstWhere(
                    (s) => s["id"] == station["id"],
                  );
                } catch (e) {
                  stationMatch = null;
                }

                int waiting = stationMatch?["waiting"] ?? 0;
                String status = stationMatch?["status"] ?? "LOW";

                return Marker(
                  markerId: MarkerId("station-${station["id"]}"),
                  position: LatLng(station["lat"], station["lng"]),
                  icon: stationMarkerIcon,
                  infoWindow: InfoWindow(
                    title: station["name"]?.toString(),
                    snippet: "$waiting passengers - $status",
                  ),
                  onTap: () {
                    double eta = calculateETA(
                      LatLng(station["lat"], station["lng"]),
                    );

                    int displayETA = eta.ceil();

                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      enableDrag: false,
                      showDragHandle: false,
                      backgroundColor: Colors.white,
                      builder: (context) {
                        return SingleChildScrollView(
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.vertical(
                                top: Radius.circular(24),
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 70,
                                  height: 5,
                                  margin: const EdgeInsets.only(bottom: 12),
                                ),

                                // Header + close button
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Station Name
                                    Expanded(
                                      child: Text(
                                        station["name"],
                                        style: GoogleFonts.kanit(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),

                                    // close button
                                    GestureDetector(
                                      onTap: () => Navigator.pop(context),
                                      child: Container(
                                        padding: const EdgeInsets.all(6),

                                        child: const Icon(
                                          Icons.close,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 20),

                                Column(
                                  children: [
                                    _infoRow(
                                      "👥 จำนวนผู้โดยสาร",
                                      "$waiting คน",
                                    ),
                                    _infoRow("⏱ รถจะมาถึง", "$displayETA นาที"),
                                    _infoRow("🚦 ความแออัด", status),
                                    _infoRow("📢 สถานะ", "ปกติ"),
                                  ],
                                ),
                                _cctvPreview(station),
                                const SizedBox(height: 24),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              }),
              ...BusController.instance.busData
                  .where((bus) {
                    final id = bus["busNumber"].toString();
                    return BusController.instance.busPositions[id] != null;
                  })
                  .map((bus) {
                    final id = bus["busNumber"].toString();
                    final pos = BusController.instance.busPositions[id]!;

                    return Marker(
                      markerId: MarkerId("bus-$id"),
                      position: pos,
                      anchor: const Offset(0.5, 0.5),
                      zIndexInt: 10,
                      icon: busIconFor(id),
                      infoWindow: InfoWindow(title: "Bus $id"),
                    );
                  }),
            },
          ),

          // Zoom Map Button
          Positioned(
            bottom: 50,
            right: 20,
            child: Column(
              children: [
                // Zoom In
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.add),
                    onPressed: () =>
                        mapController?.animateCamera(CameraUpdate.zoomIn()),
                  ),
                ),

                const SizedBox(height: 10),

                // Zoom Out
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.remove),
                    onPressed: () =>
                        mapController?.animateCamera(CameraUpdate.zoomOut()),
                  ),
                ),
              ],
            ),
          ),

          // Search station tab below app bar
          Positioned(
            top: 130,
            left: 40,
            right: 40,
            child: Container(
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.18),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextField(
                controller: searchController,
                readOnly: true,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const BusPage()),
                  );
                },
                decoration: InputDecoration(
                  hintText: 'Where to ?',
                  hintStyle: GoogleFonts.kanit(fontSize: 18),
                  prefixIcon: const Icon(Icons.search, color: Colors.black54),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 18,
                    horizontal: 16,
                  ),
                ),
                style: GoogleFonts.kanit(fontSize: 14),
                textInputAction: TextInputAction.search,
                onSubmitted: (value) {},
              ),
            ),
          ),

          // App bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 120,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top,
                left: 16,
                right: 16,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // ร้องเรียน menu
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: 'MFU ',
                          style: GoogleFonts.kanit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFD2232A),
                          ),
                        ),
                        TextSpan(
                          text: 'SHUTTLE BUS',
                          style: GoogleFonts.kanit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFBC9945),
                          ),
                        ),
                        TextSpan(
                          text: ' Admin',
                          style: GoogleFonts.kanit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Menu button
                  IconButton(
                    icon: const Icon(Icons.menu, color: Color(0xFFD2232A)),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AdminSetting(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
