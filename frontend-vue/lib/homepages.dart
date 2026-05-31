import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shuttle_bus_fronted/bus_station.dart';
import 'package:shuttle_bus_fronted/custom_bottom_bar.dart';
import 'package:shuttle_bus_fronted/report_pages.dart';
import 'package:shuttle_bus_fronted/services/api_service.dart';
import 'package:shuttle_bus_fronted/bus_controller.dart';

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
      final data = await ApiService.getStations(selectedLine);
      setState(() {
        stationData = data;
      });
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

//line 1
  final List<Map<String, dynamic>> line1 = [
    {
"id": "station1",
"name": "Station 01 (จุดหอพักลำดวน 2)",
"lat": 20.058823,
"lng": 99.898419,
},
    {
"id": "station2",
"name": "Station 02(จุดพักลำดวน 7 ขาเข้า)",
"lat": 20.057030,
"lng": 99.896919,
},
    {
"id": "station3",
"name": "Station 03 (จุด หอพักจีน ขาเข้า)",
"lat": 20.050870176213458,
"lng": 99.8913375758622,
},
    {
"id": "station4",
"name": "Station 04 (จุด ศูนย์จีน ขาเข้า)",
"lat": 20.048895164537097,
"lng": 99.89132709650245,
},
    {
"id": "station5",
"name": "Station 05 (จุด ลานจอดหอพัก F)",
"lat": 20.048215214947664,
"lng": 99.89322591378016,
},
    {
"id": "station6",
"name": "Station 06 (จุด อาคารโรงอาหาร D1)",
"lat": 20.04736,
"lng": 99.893283,
},
    {
"id": "station7",
"name": "Station 07 (จุด สระน้ำวงรี ลานดาว)",
"lat": 20.045606104291842,
"lng": 99.89153621441135,
},
    {
"id": "station8",
"name": "Station 08 (จุด อาคารโรงอาหาร E2 ขาเข้า)",
"lat": 20.04399637202456,
"lng": 99.893402801156,
},
    {
"id": "station9",
"name": "Station 09 (จุด อาคารเรียนรวม C3 C2 และ หอประชุมสมเด็จย่า C4)",
"lat": 20.043895277649657,
"lng": 99.89521575716422,
},
    {
"id": "station10",
"name": "Station 10 (จุด อาคารเรียนรวม C5 )",
"lat": 20.043346224233225,
"lng": 99.89513551300819,
},
    {
"id": "station11",
"name": "Station 11 (จุด อาคาร m - square)",
"lat": 20.045780781087203,
"lng": 99.89135359185909,
},
    {
"id": "station12",
"name": "Station 12 (จุด ศูนย์จีน ขาออก)",
"lat": 20.048830,
"lng": 99.891330,
},
    {
"id": "station13",
"name": "Station 13 (จุด หอพักจีน ขาออก)",
"lat": 20.050779,
"lng": 99.891138,
},
    {
"id": "station14",
"name": "Station 14 (จุด สนามกีฬากลาง)",
"lat": 20.054763275437402,
"lng": 99.89454537873918,
},
    {
"id": "station15",
"name": "Station 15 (จุด หอพักลำดวน 7 ขาออก)",
"lat": 20.056749,
"lng": 99.897073,
},
    {
"id": "station16",
"name": "Station 16 (จุด ครัวลำดวน)",
"lat": 20.058276924103307,
"lng": 99.89811278167763,
},
  ];

//line 2
  final List<Map<String, dynamic>> line2 = [
    {
"id": "station1",
"name": "Station 01 (จุดหอพักลำดวน 2)",
"lat": 20.058823,
"lng": 99.898419,
},
    {
"id": "station2",
"name": "Station 02(จุดพักลำดวน 7 ขาเข้า)",
"lat": 20.057081156842653,
"lng": 99.89702395554524,
},
    {
"id": "station3",
"name": "Station 03 (จุด หอพักจีน ขาเข้า)",
"lat": 20.050870176213458,
"lng": 99.8913375758622,
},
    {
"id": "station4",
"name": "Station 04 (จุด ศูนย์จีน ขาเข้า)",
"lat": 20.048895164537097,
"lng": 99.89132709650245,
},
    {
"id": "station5",
"name": "Station 05 (จุด ลานจอดหอพัก F)",
"lat": 20.048215214947664,
"lng": 99.89322591378016,
},
    {
"id": "station6",
"name": "Station 06 (จุด อาคารโรงอาหาร D1)",
"lat": 20.04736,
"lng": 99.893283,
},
    {
"id": "station7",
"name": "Station 07 (จุด สระน้ำวงรี ลานดาว)",
"lat": 20.045606104291842,
"lng": 99.89153621441135,
},
    {
"id": "station8",
"name": "Station 08 (จุด อาคารโรงอาหาร E2 ขาเข้า)",
"lat": 20.04399637202456,
"lng": 99.893402801156,
},
    {
"id": "station17",
"name": "Station 09 (จุด โรงพยาบาลแม่ฟ้าหลวง)",
"lat": 20.041278409327774,
"lng": 99.89430864493072,
},
    {
"id": "station10",
"name": "Station 10 (จุด อาคาร m - square)",
"lat": 20.045780781087203,
"lng": 99.89135359185909,
},
    {
"id": "station11",
"name": "Station 11 (จุด ศูนย์จีน ขาออก)",
"lat": 20.048830,
"lng": 99.891330,
},
    {
"id": "station12",
"name": "Station 12 (จุด หอพักจีน ขาออก)",
"lat": 20.050779,
"lng": 99.891138,
},
    {
"id": "station13",
"name": "Station 13 (จุด สนามกีฬากลาง)",
"lat": 20.054763275437402,
"lng": 99.89454537873918,
},
    {
"id": "station14",
"name": "Station 14 (จุด หอพักลำดวน 7 ขาออก)",
"lat": 20.056749,
"lng": 99.897073,
},
    {
"id": "station15",
"name": "Station 15 (จุด ครัวลำดวน)",
"lat": 20.058276924103307,
"lng": 99.89811278167763,
},
  ];

  List<Map<String, dynamic>> getSelectedLine() {
    return selectedLine == "line1" ? line1 : line2;
}
Future<List<LatLng>> fetchRealRoute() async {
  final points = getSelectedLine();

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

  @override
  void dispose() {
    stationTimer?.cancel();
    busTimer?.cancel();
    moveTimer?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    updateRoute();
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
void updateRoute() async {
  final newRoute = await fetchRealRoute();

  if (newRoute.isNotEmpty) {
    setState(() {
      route = catmullRomSpline(newRoute, segments: 10);
    });
  }
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
            
              // Route Line
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: route,
                    color: selectedLine == "line1"
                        ? Colors
                              .grey // line1
                        : Colors.lightGreen, // line 2
                    strokeWidth: 4,
                  ),
                ],
              ),

              // Stations Markers
              MarkerLayer(
                markers: getSelectedLine().map((station) {
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

                  double eta = calculateETA(
                    LatLng(station["lat"], station["lng"]),
                  );

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
                                        "👥 จำนวนผู้โดยสาร",
                                        "$waiting คน",
                                      ),
                                      _infoRow(
                                        "⏱ รถจะมาถึง",
                                        "$displayETA นาที",
                                      ),
                                      _infoRow("🚦 ความแออัด", status),
                                      _infoRow("📢 สถานะ", "ปกติ"),
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
                              size: 40,
                              color: getColor(status),
                              shadows: [
                                Shadow(
                                  color: getColor(status).withOpacity(0.6),
                                  blurRadius: 15,
                                ),
                              ],
                            ),
                            ClipOval(
                              child: Image.asset(
                                'assets/dindin.png',
                                width: 30,
                                height: 30,
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

          //Selected Line Button
          Positioned(
            top: 150,
            left: 20,
            child: Column(
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedLine == "line1"
                        ? Colors.black
                        : Colors.white,
                    foregroundColor: selectedLine == "line1"
                        ? Colors.white
                        : Colors.black,
                    side: const BorderSide(color: Colors.white),
                  ),
                  onPressed: () {
                    setState(() {
                      selectedLine = "line1";
                    });
                    updateRoute();
                    fetchStations();
                  },
                  child: const Text("Line 1"),
                ),

                const SizedBox(width: 10),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedLine == "line2"
                        ? Colors.green
                        : Colors.white,
                    foregroundColor: selectedLine == "line2"
                        ? Colors.white
                        : Colors.black,
                    side: const BorderSide(color: Colors.white),
                  ),
                  onPressed: () {
                    setState(() {
                      selectedLine = "line2";
                    });
                    updateRoute();
                    fetchStations();
                  },
                  child: const Text("Line 2"),
                ),
              ],
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
                  IconButton(
                    icon: const Icon(Icons.warning_amber_rounded),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ReportPage(),
                        ),
                      );
                    },
                  ),

                  // Menu button
                  IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const BusStationPage(),
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