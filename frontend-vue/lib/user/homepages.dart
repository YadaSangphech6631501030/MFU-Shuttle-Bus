import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import 'bus_station.dart';
import 'custom_bottom_bar.dart';
import 'package:shuttle_bus_fronted/services/api_service.dart';
import 'bus_controller.dart';
import 'user_setting.dart';

class Homepages extends StatefulWidget {
  const Homepages({super.key});

  @override
  State<Homepages> createState() => _HomepagesState();
}

class _HomepagesState extends State<Homepages> {
    int currentIndex = 0;

  String selectedLine = "line1";
  final MapController mapController = MapController();
  double currentZoom = 16;

  Timer? stationTimer;
  Timer? busTimer;
  Timer? moveTimer;
  final TextEditingController searchController = TextEditingController();

  List<dynamic> busData = [];
  List<dynamic> stationData = [];
  Map<String, LatLng> busPositions = {};

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
                  )
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
      final lines = await Future.wait([
        ApiService.getStations("line1"),
        ApiService.getStations("line2"),
      ]);
      final stationById = <String, dynamic>{};

      for (final station in [...lines[0], ...lines[1]]) {
        final id = station["id"]?.toString() ?? "";
        if (id.isNotEmpty) {
          stationById[id] = station;
        }
      }

      if (!mounted) return;

      setState(() {
        line1
          ..clear()
          ..addAll(
            lines[0].map((station) => Map<String, dynamic>.from(station)),
          );
        line2
          ..clear()
          ..addAll(
            lines[1].map((station) => Map<String, dynamic>.from(station)),
          );
        stationData = stationById.values.toList();
      });

      updateAllRoutes();
    } catch (e) {
      print("API ERROR: $e");
    }
  }

//Markers color by status
  Color getColor(String status) {
    switch (status) {
      case "LOW":
        return Colors.green;
      case "MEDIUM":
        return Colors.orange;
      case "HIGH":
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  final List<Map<String, dynamic>> line1 = [];
  final List<Map<String, dynamic>> line2 = [];

  List<Map<String, dynamic>> getSelectedLine() {
    return selectedLine == "line1" ? line1 : line2;
  }

  List<Map<String, dynamic>> getAllLines() {
    final stationById = <String, Map<String, dynamic>>{};

    for (final station in [...line1, ...line2]) {
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

  Future<List<LatLng>> fetchRouteForPoints(List<Map<String, dynamic>> points) async {
    if (points.isEmpty) return [];

    String coords = points.map((p) => "${p["lng"]},${p["lat"]}").join(";");

    final url =
        "https://router.project-osrm.org/route/v1/driving/$coords?overview=full&geometries=geojson";

    try {
      final res = await http.get(Uri.parse(url));
      final data = jsonDecode(res.body);

      if (data["routes"] == null || data["routes"].isEmpty) {
        print("❌ fallback route");
        return getLineLatLngs(points);
      }

      final routeCoords = data["routes"][0]["geometry"]["coordinates"];

      return routeCoords.map<LatLng>((c) {
        return LatLng(c[1], c[0]);
      }).toList();
    } catch (e) {
      print("❌ ROUTE ERROR: $e");
      return getLineLatLngs(points);
    }
  }

  Future<List<LatLng>> fetchRealRoute() async {
    return fetchRouteForPoints(getSelectedLine());
  }

  @override
  void initState() {
    super.initState();
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

  @override
  void dispose() {
    stationTimer?.cancel();
    busTimer?.cancel();
    moveTimer?.cancel();
    searchController.dispose();
    super.dispose();
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

      double distMeters = const Distance().as(
        LengthUnit.Meter,
        pos,
        stationLatLng,
      );

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

        double dist = const Distance().as(
          LengthUnit.Meter,
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

      // ✅ STOP AT STATION
      for (var station in getSelectedLine()) {
        LatLng stationLatLng = LatLng(station["lat"], station["lng"]);

        double dist = const Distance().as(
          LengthUnit.Meter,
          newPos,
          stationLatLng,
        );

        if (dist < 15 &&
            BusController.instance.lastStationId[id] != station["id"]) {
          BusController.instance.busWaitUntil[id] =
              now.add(const Duration(seconds: 2));

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
    final newRoute1 = await fetchRouteForPoints(line1);
    final newRoute2 = await fetchRouteForPoints(line2);

    if (!mounted) return;

    setState(() {
      route1 = newRoute1.isNotEmpty
          ? catmullRomSpline(newRoute1, segments: 10)
          : getLineLatLngs(line1);
      route2 = newRoute2.isNotEmpty
          ? catmullRomSpline(newRoute2, segments: 10)
          : getLineLatLngs(line2);
    });

    updateRoute();
  }

  Future<void> updateRoute() async {
    final newRoute = await fetchRealRoute();

    if (!mounted) return;

    setState(() {
      route = newRoute.isNotEmpty
          ? catmullRomSpline(newRoute, segments: 10)
          : [];
    });
  }

  void updateBusETA() {
    for (var bus in BusController.instance.busData) {
      final id = bus["busNumber"].toString();
      final pos = BusController.instance.busPositions[id];

      if (pos == null) continue;

      double minMinutes = double.infinity;

      for (var station in getSelectedLine()) {
        double dist = const Distance().as(
          LengthUnit.Meter,
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

  List<LatLng> catmullRomSpline(List<LatLng> points, {int segments = 10}) {
    List<LatLng> result = [];
    for (int i = 0; i < points.length - 1; i++) {
      LatLng p0 = i > 0 ? points[i - 1] : points[i];
      LatLng p1 = points[i];
      LatLng p2 = points[i + 1];
      LatLng p3 = i < points.length - 2 ? points[i + 2] : points[i + 1];

      for (int j = 0; j <= segments; j++) {
        double t = j / segments;
        double tt = t * t;
        double ttt = tt * t;

        double lat =
            0.5 *
            ((2 * p1.latitude) +
                (-p0.latitude + p2.latitude) * t +
                (2 * p0.latitude -
                        5 * p1.latitude +
                        4 * p2.latitude -
                        p3.latitude) *
                    tt +
                (-p0.latitude +
                        3 * p1.latitude -
                        3 * p2.latitude +
                        p3.latitude) *
                    ttt);

        double lng =
            0.5 *
            ((2 * p1.longitude) +
                (-p0.longitude + p2.longitude) * t +
                (2 * p0.longitude -
                        5 * p1.longitude +
                        4 * p2.longitude -
                        p3.longitude) *
                    tt +
                (-p0.longitude +
                        3 * p1.longitude -
                        3 * p2.longitude +
                        p3.longitude) *
                    ttt);

        result.add(LatLng(lat, lng));
      }
    }
    result.add(points.last);
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
//bottom bar => custom_bottom_bar.dart
      bottomNavigationBar: CustomBottomBar(currentIndex: 0),

      body: Stack(
        children: [
          FlutterMap(
            mapController: mapController,
            options: MapOptions(
              initialCenter: const LatLng(20.045, 99.894),
              initialZoom: currentZoom,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    "https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png",
                subdomains: ['a', 'b', 'c', 'd'],
              ),
            
              // Route Lines for both line1 and line2
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: route2.isNotEmpty ? route2 : getLineLatLngs(line2),
                    color: Colors.grey.shade700,
                    strokeWidth: 2,
                  ),
                  Polyline(
                    points: route1.isNotEmpty ? route1 : getLineLatLngs(line1),
                    color: Color(0xFFBC9945),
                    strokeWidth: 2,
                  ),
                ],
              ),

              // Stations Markers
              MarkerLayer(
                markers: getAllLines().map((station) {
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
                    point: LatLng(station["lat"], station["lng"]),
                    width: 60,
                    height: 60,
                    alignment: Alignment.center,
                    child: GestureDetector(
                      onTap: () {
                        double eta = calculateETA(
                          LatLng(station["lat"], station["lng"]),
                        );

                        int displayETA = eta.ceil();

                        showModalBottomSheet(
                          context: context,
                          isScrollControlled: false,
                          enableDrag: false,
                          showDragHandle: false,
                          backgroundColor: Colors.white,
                          builder: (context) {
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.fromLTRB(
                                16,
                                16,
                                16,
                                24,
                              ),
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                                        "👥 Amount waiting ",
                                        "$waiting people",
                                      ),
                                      _infoRow(
                                        "⏱ The car will arrive in",
                                        "$displayETA minutes",
                                      ),
                                      _infoRow("🚦 Crowding", status),
                                      _infoRow("📢 Status", "Normal"),
                                    ],
                                  ),
                                  const SizedBox(height: 50),
                                  
                                  
                                ],
                              ),
                            );
                          },
                        );
                      },
                      child: Container(
                        width: 40,
                        height: 40,
                        alignment: Alignment.center,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Icon(
                              Icons.circle,
                              size: 42,
                              color: getColor(status).withOpacity(0.40),
                            ),
                            ClipOval(
                              child: Image.asset(
                                'assets/dindin.png',
                                width: 25,
                                height: 25,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              // BUS
              MarkerLayer(
                markers: BusController.instance.busData.map((bus) {
                  final id = bus["busNumber"].toString();
                  final pos = BusController.instance.busPositions[id];

                  if (pos == null) {
                    return const Marker(point: LatLng(0, 0), child: SizedBox());
                  }

                  return Marker(
                    point: pos,
                    width: 50,
                    height: 50,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Image.asset('assets/bus.png', width: 45, height: 45),

                        Positioned(
                          top: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              id,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ],
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
                    onPressed: () {
                      setState(() {
                        currentZoom += 0.5;
                      });
                      mapController.move(
                        mapController.camera.center,
                        currentZoom,
                      );
                    },
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
                    onPressed: () {
                      setState(() {
                        currentZoom -= 0.5;
                      });
                      mapController.move(
                        mapController.camera.center,
                        currentZoom,
                      );
                    },
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
                onSubmitted: (value) {
                },
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
                  
                  // Title text
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
                      ],
                    ),
                  ),

                  // Menu button
                  IconButton(
                    icon: const Icon(
                      Icons.menu,
                      color: Color(0xFFD2232A),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const UserSetting(),
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
