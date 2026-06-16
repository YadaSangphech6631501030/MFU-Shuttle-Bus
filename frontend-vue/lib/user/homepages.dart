import 'dart:convert';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shuttle_bus_fronted/services/api_service.dart';
import 'bus_controller.dart';
import 'user_setting.dart';

class Homepages extends StatefulWidget {
  final LatLng? initialMapTarget;
  final double initialMapZoom;

  const Homepages({
    super.key,
    this.initialMapTarget,
    this.initialMapZoom = 17.35,
  });

  @override
  State<Homepages> createState() => _HomepagesState();
}

class _HomepagesState extends State<Homepages> {
  static const String _favoriteStationsKey = 'favorite_stations';
  static const LatLng _mSquareStationCenter = LatLng(
    20.045780781087203,
    99.89135359185909,
  );
  static const double _defaultMapZoom = 17.35;

  int currentIndex = 0;

  String selectedLine = "all";
  GoogleMapController? mapController;
  double currentZoom = _defaultMapZoom;

  Timer? stationTimer;
  Timer? busTimer;
  Timer? moveTimer;
  final TextEditingController fromSearchController = TextEditingController();
  final TextEditingController searchController = TextEditingController();

  List<dynamic> busData = [];
  List<dynamic> stationData = [];
  List<Map<String, dynamic>> filteredStations = [];
  Set<String> favoriteStationIds = {};
  Map<String, dynamic>? selectedFromStation;
  Map<String, dynamic>? selectedStation;
  String activeSearchField = "to";
  bool showStationSuggestions = false;
  Map<String, LatLng> busPositions = {};
  BitmapDescriptor stationMarkerIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor selectedStationMarkerIcon = BitmapDescriptor.defaultMarker;
  final Map<String, BitmapDescriptor> stationDensityIcons = {};
  final Map<String, BitmapDescriptor> selectedStationDensityIcons = {};

  // statuses for bus
  Map<String, double> busProgress =
      {}; // ÃƒÂ Ã‚Â¹Ã¢â€šÂ¬ÃƒÂ Ã‚Â¸Ã‚ÂÃƒÂ Ã‚Â¹Ã¢â‚¬Â¡ÃƒÂ Ã‚Â¸Ã…Â¡ index ÃƒÂ Ã‚Â¸Ã¢â‚¬ÂºÃƒÂ Ã‚Â¸Ã‚Â±ÃƒÂ Ã‚Â¸Ã‹â€ ÃƒÂ Ã‚Â¸Ã‹â€ ÃƒÂ Ã‚Â¸Ã‚Â¸ÃƒÂ Ã‚Â¸Ã…Â¡ÃƒÂ Ã‚Â¸Ã‚Â±ÃƒÂ Ã‚Â¸Ã¢â€žÂ¢ÃƒÂ Ã‚Â¹Ã†â€™ÃƒÂ Ã‚Â¸Ã¢â€žÂ¢ route ÃƒÂ Ã‚Â¸Ã¢â‚¬Å¡ÃƒÂ Ã‚Â¸Ã‚Â­ÃƒÂ Ã‚Â¸Ã¢â‚¬Â¡ÃƒÂ Ã‚Â¸Ã‚Â£ÃƒÂ Ã‚Â¸Ã¢â‚¬â€œÃƒÂ Ã‚Â¹Ã‚ÂÃƒÂ Ã‚Â¸Ã¢â‚¬Â¢ÃƒÂ Ã‚Â¹Ã‹â€ ÃƒÂ Ã‚Â¸Ã‚Â¥ÃƒÂ Ã‚Â¸Ã‚Â°ÃƒÂ Ã‚Â¸Ã¢â‚¬Å¾ÃƒÂ Ã‚Â¸Ã‚Â±ÃƒÂ Ã‚Â¸Ã¢â€žÂ¢
  Map<String, DateTime?> busWaitUntil =
      {}; // ÃƒÂ Ã‚Â¹Ã¢â€šÂ¬ÃƒÂ Ã‚Â¸Ã‚Â§ÃƒÂ Ã‚Â¸Ã‚Â¥ÃƒÂ Ã‚Â¸Ã‚Â²ÃƒÂ Ã‚Â¸Ã¢â‚¬â€ÃƒÂ Ã‚Â¸Ã‚ÂµÃƒÂ Ã‚Â¹Ã‹â€ ÃƒÂ Ã‚Â¸Ã‚Â£ÃƒÂ Ã‚Â¸Ã¢â‚¬â€œÃƒÂ Ã‚Â¸Ã‹â€ ÃƒÂ Ã‚Â¸Ã‚Â°ÃƒÂ Ã‚Â¹Ã¢â€šÂ¬ÃƒÂ Ã‚Â¸Ã‚Â£ÃƒÂ Ã‚Â¸Ã‚Â´ÃƒÂ Ã‚Â¹Ã‹â€ ÃƒÂ Ã‚Â¸Ã‚Â¡ÃƒÂ Ã‚Â¸Ã‚Â§ÃƒÂ Ã‚Â¸Ã‚Â´ÃƒÂ Ã‚Â¹Ã‹â€ ÃƒÂ Ã‚Â¸Ã¢â‚¬Â¡ÃƒÂ Ã‚Â¸Ã¢â‚¬Â¢ÃƒÂ Ã‚Â¹Ã‹â€ ÃƒÂ Ã‚Â¸Ã‚Â­ÃƒÂ Ã‚Â¹Ã¢â‚¬Å¾ÃƒÂ Ã‚Â¸Ã¢â‚¬ÂÃƒÂ Ã‚Â¹Ã¢â‚¬Â° (ÃƒÂ Ã‚Â¹Ã†â€™ÃƒÂ Ã‚Â¸Ã…Â ÃƒÂ Ã‚Â¹Ã¢â‚¬Â°ÃƒÂ Ã‚Â¸Ã‚Â«ÃƒÂ Ã‚Â¸Ã‚Â¢ÃƒÂ Ã‚Â¸Ã‚Â¸ÃƒÂ Ã‚Â¸Ã¢â‚¬ÂÃƒÂ Ã‚Â¸Ã‚ÂªÃƒÂ Ã‚Â¸Ã¢â‚¬â€œÃƒÂ Ã‚Â¸Ã‚Â²ÃƒÂ Ã‚Â¸Ã¢â€žÂ¢ÃƒÂ Ã‚Â¸Ã‚Âµ)
  Map<String, String?> lastStationId =
      {}; // ÃƒÂ Ã‚Â¸Ã‹â€ ÃƒÂ Ã‚Â¸Ã‚Â³ÃƒÂ Ã‚Â¸Ã‚Â§ÃƒÂ Ã‚Â¹Ã‹â€ ÃƒÂ Ã‚Â¸Ã‚Â²ÃƒÂ Ã‚Â¸Ã‚ÂªÃƒÂ Ã‚Â¸Ã¢â‚¬â€œÃƒÂ Ã‚Â¸Ã‚Â²ÃƒÂ Ã‚Â¸Ã¢â€žÂ¢ÃƒÂ Ã‚Â¸Ã‚ÂµÃƒÂ Ã‚Â¸Ã‚Â¥ÃƒÂ Ã‚Â¹Ã‹â€ ÃƒÂ Ã‚Â¸Ã‚Â²ÃƒÂ Ã‚Â¸Ã‚ÂªÃƒÂ Ã‚Â¸Ã‚Â¸ÃƒÂ Ã‚Â¸Ã¢â‚¬ÂÃƒÂ Ã‚Â¸Ã¢â‚¬â€ÃƒÂ Ã‚Â¸Ã‚ÂµÃƒÂ Ã‚Â¹Ã‹â€ ÃƒÂ Ã‚Â¸Ã‹â€ ÃƒÂ Ã‚Â¸Ã‚Â­ÃƒÂ Ã‚Â¸Ã¢â‚¬ÂÃƒÂ Ã‚Â¸Ã¢â‚¬Å¾ÃƒÂ Ã‚Â¸Ã‚Â·ÃƒÂ Ã‚Â¸Ã‚Â­ÃƒÂ Ã‚Â¸Ã¢â‚¬â€ÃƒÂ Ã‚Â¸Ã‚ÂµÃƒÂ Ã‚Â¹Ã‹â€ ÃƒÂ Ã‚Â¹Ã¢â‚¬Å¾ÃƒÂ Ã‚Â¸Ã‚Â«ÃƒÂ Ã‚Â¸Ã¢â€žÂ¢ (ÃƒÂ Ã‚Â¸Ã‚ÂÃƒÂ Ã‚Â¸Ã‚Â±ÃƒÂ Ã‚Â¸Ã¢â€žÂ¢ÃƒÂ Ã‚Â¸Ã‹â€ ÃƒÂ Ã‚Â¸Ã‚Â­ÃƒÂ Ã‚Â¸Ã¢â‚¬ÂÃƒÂ Ã‚Â¸Ã¢â‚¬Â¹ÃƒÂ Ã‚Â¹Ã¢â‚¬Â°ÃƒÂ Ã‚Â¸Ã‚Â³)

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
                    cleanStationName(stations[index]),
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
        debugPrint(
          "ÃƒÂ Ã‚Â¹Ã¢â€šÂ¬ÃƒÂ Ã‚Â¸Ã‚Â¥ÃƒÂ Ã‚Â¸Ã‚Â·ÃƒÂ Ã‚Â¸Ã‚Â­ÃƒÂ Ã‚Â¸Ã‚Â: $title",
        );
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
      debugPrint("API ERROR: $e");
    }
  }

  double stationHeatWeight(dynamic waitingValue, String status) {
    final waiting = double.tryParse(waitingValue?.toString() ?? "") ?? 0;
    final waitingWeight = (waiting / 20).clamp(0.18, 1.0).toDouble();
    final statusWeight = switch (status.toUpperCase()) {
      "HIGH" => 1.0,
      "MEDIUM" => 0.62,
      _ => 0.28,
    };

    return waitingWeight > statusWeight ? waitingWeight : statusWeight;
  }

  String stationDensityLevel(dynamic waitingValue, String status) {
    final weight = stationHeatWeight(waitingValue, status);
    if (weight >= 0.78) return "HIGH";
    if (weight >= 0.48) return "MEDIUM";
    return "LOW";
  }

  BitmapDescriptor stationIconFor(
    dynamic waitingValue,
    String status,
    bool isSelected,
  ) {
    final level = stationDensityLevel(waitingValue, status);
    final icons = isSelected
        ? selectedStationDensityIcons
        : stationDensityIcons;
    return icons[level] ??
        (isSelected ? selectedStationMarkerIcon : stationMarkerIcon);
  }

  double distanceBetween(LatLng from, LatLng to) {
    return const ll.Distance().as(
      ll.LengthUnit.Meter,
      ll.LatLng(from.latitude, from.longitude),
      ll.LatLng(to.latitude, to.longitude),
    );
  }

  final List<Map<String, dynamic>> line1 = [];
  final List<Map<String, dynamic>> line2 = [];

  List<Map<String, dynamic>> getSelectedLine() {
    if (selectedLine == "all") return getAllLines();
    return selectedLine == "line1" ? line1 : line2;
  }

  List<LatLng> getSelectedLinePoints() {
    if (selectedLine == "all") return [];
    final selectedRoute = selectedLine == "line1" ? route1 : route2;
    return selectedRoute.isNotEmpty
        ? selectedRoute
        : getLineLatLngs(getSelectedLine());
  }

  Color lineColor(String line) {
    if (line == "line1") return const Color(0xFFBC9945);
    if (line == "line2") return Colors.grey.shade700;
    return Colors.black87;
  }

  String lineLabel(String line) {
    if (line == "line1") return "Line 1";
    if (line == "line2") return "Line 2";
    return "All";
  }

  bool stationInLine(Map<String, dynamic>? station, String line) {
    if (station == null) return true;
    if (line == "all") return true;
    final stationId = station["id"]?.toString();
    final stations = line == "line1" ? line1 : line2;
    return stations.any((item) => item["id"]?.toString() == stationId);
  }

  String lineForStation(Map<String, dynamic> station) {
    final stationId = station["id"]?.toString();
    if (line1.any((item) => item["id"]?.toString() == stationId)) {
      return "line1";
    }
    if (line2.any((item) => item["id"]?.toString() == stationId)) {
      return "line2";
    }
    return selectedLine;
  }

  void selectLine(String line) {
    final nextLine = selectedLine == line ? "all" : line;

    setState(() {
      selectedLine = nextLine;
      showStationSuggestions = false;
      filteredStations.clear();

      if (!stationInLine(selectedFromStation, nextLine)) {
        selectedFromStation = null;
        fromSearchController.clear();
      }

      if (!stationInLine(selectedStation, nextLine)) {
        selectedStation = null;
        searchController.clear();
      }
    });

    updateRoute();
  }

  Future<void> focusInitialMapTarget() async {
    final controller = mapController;
    if (controller == null) return;

    try {
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(
          widget.initialMapTarget ?? _mSquareStationCenter,
          widget.initialMapZoom,
        ),
      );
    } catch (e) {
      debugPrint("MAP CAMERA ERROR: $e");
    }
  }

  LatLngBounds lineBounds(List<LatLng> points) {
    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLng = points.first.longitude;
    var maxLng = points.first.longitude;

    for (final point in points) {
      if (point.latitude < minLat) minLat = point.latitude;
      if (point.latitude > maxLat) maxLat = point.latitude;
      if (point.longitude < minLng) minLng = point.longitude;
      if (point.longitude > maxLng) maxLng = point.longitude;
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  List<Map<String, dynamic>> getAllLines() {
    final stationById = <String, Map<String, dynamic>>{};

    for (final station in [...line1, ...line2]) {
      final id = station["id"]?.toString() ?? "";
      if (id.isNotEmpty) {
        stationById[id] = station;
      }
    }

    final stations = stationById.values.toList();
    stations.sort(
      (a, b) => _stationNumber(a["id"]).compareTo(_stationNumber(b["id"])),
    );
    return stations;
  }

  int _stationNumber(dynamic id) {
    final number = RegExp(r'\d+').firstMatch(id?.toString() ?? "")?.group(0);
    return int.tryParse(number ?? "") ?? 9999;
  }

  String stationDisplayName(dynamic station) {
    final raw = station is Map
        ? station["name"]?.toString().trim() ?? ""
        : station?.toString().trim() ?? "";

    var name = raw
        .replaceFirst(
          RegExp(
            r'^station\s*0*\d+\s*[:\-ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Å“ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â.]?\s*',
            caseSensitive: false,
          ),
          '',
        )
        .replaceFirst(
          RegExp(r'^0*\d+\s*[:\-ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Å“ÃƒÂ¢Ã¢â€šÂ¬Ã¢â‚¬Â.]?\s*'),
          '',
        )
        .replaceAll(RegExp(r'\s*\([^)]*\)\s*$'), '')
        .trim();

    return name.isEmpty ? raw : name;
  }

  String cleanStationName(dynamic station) {
    final raw = station is Map
        ? station["name"]?.toString().trim() ?? ""
        : station?.toString().trim() ?? "";

    final stationWithName = RegExp(
      r'^station\s*0*\d+\s*\((.*)\)\s*$',
      caseSensitive: false,
    ).firstMatch(raw);
    if (stationWithName != null) {
      return stationWithName.group(1)?.trim() ?? raw;
    }

    var name = raw.replaceFirst(
      RegExp(r'^station\s*0*\d+\s*[:\-.]?\s*', caseSensitive: false),
      '',
    );
    name = name.replaceFirst(RegExp(r'^0*\d+\s*[:\-.]?\s*'), '').trim();
    if (name.startsWith("(") && name.endsWith(")") && name.length > 2) {
      name = name.substring(1, name.length - 1).trim();
    }

    return name.isEmpty ? raw : name;
  }

  Future<void> searchStations(String value, String field) async {
    final query = value.trim().toLowerCase();
    final prefs = await SharedPreferences.getInstance();
    final favoriteStationIds = (prefs.getStringList(_favoriteStationsKey) ?? [])
        .toSet();

    if (!mounted) return;

    final stations = getAllLines();
    final matchedStations = query.isEmpty
        ? stations
        : stations.where((station) {
            final name = cleanStationName(station).toLowerCase();
            final id = station["id"]?.toString().toLowerCase() ?? "";
            return name.contains(query) || id.contains(query);
          }).toList();

    matchedStations.sort(
      (a, b) => _compareSearchStations(a, b, favoriteStationIds),
    );

    setState(() {
      activeSearchField = field;
      this.favoriteStationIds = favoriteStationIds;
      filteredStations = matchedStations;
      showStationSuggestions = filteredStations.isNotEmpty;
    });
  }

  int _compareSearchStations(
    Map<String, dynamic> a,
    Map<String, dynamic> b,
    Set<String> favoriteStationIds,
  ) {
    final aFavorite = favoriteStationIds.contains(a["id"]?.toString());
    final bFavorite = favoriteStationIds.contains(b["id"]?.toString());
    if (aFavorite != bFavorite) return aFavorite ? -1 : 1;

    final nameCompare = cleanStationName(
      a,
    ).toLowerCase().compareTo(cleanStationName(b).toLowerCase());
    if (nameCompare != 0) return nameCompare;

    return (a["id"]?.toString() ?? "").compareTo(b["id"]?.toString() ?? "");
  }

  void selectStation(Map<String, dynamic> station) {
    final stationName = cleanStationName(station);
    final stationLine = lineForStation(station);
    final shouldUpdateLine = selectedLine != stationLine;

    setState(() {
      selectedLine = stationLine;
      if (activeSearchField == "from") {
        selectedFromStation = station;
        fromSearchController.text = stationName;
      } else {
        selectedStation = station;
        searchController.text = stationName;
      }
      showStationSuggestions = false;
      filteredStations.clear();
    });

    if (shouldUpdateLine) {
      updateRoute();
    }

    mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(station["lat"], station["lng"]), 17),
    );
  }

  void resetStationSelection() {
    FocusScope.of(context).unfocus();

    setState(() {
      selectedFromStation = null;
      selectedStation = null;
      showStationSuggestions = false;
      filteredStations.clear();
      fromSearchController.clear();
      searchController.clear();
    });
  }

  Map<String, dynamic>? getNearestBusInfo(Map<String, dynamic>? station) {
    if (station == null) return null;

    final stationPosition = LatLng(station["lat"], station["lng"]);
    Map<String, dynamic>? nearestBus;
    LatLng? nearestPosition;
    double nearestDistance = double.infinity;

    for (final bus in BusController.instance.busData) {
      final id = bus["busNumber"].toString();
      final position = BusController.instance.busPositions[id];

      if (position == null) continue;
      if (position.latitude == 0 && position.longitude == 0) continue;

      final distance = distanceBetween(position, stationPosition);
      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearestBus = Map<String, dynamic>.from(bus);
        nearestPosition = position;
      }
    }

    if (nearestBus == null || nearestPosition == null) return null;

    final etaMinutes = (nearestDistance / 5 / 60).ceil();

    return {
      "bus": nearestBus,
      "position": nearestPosition,
      "distance": nearestDistance,
      "eta": etaMinutes < 1 ? 1 : etaMinutes,
    };
  }

  List<Map<String, dynamic>>? getTripLineStations() {
    final fromId = selectedFromStation?["id"]?.toString();
    final toId = selectedStation?["id"]?.toString();
    if (fromId == null || toId == null) return null;

    final lineOptions = [line1, line2];
    for (final line in lineOptions) {
      final hasFrom = line.any(
        (station) => station["id"]?.toString() == fromId,
      );
      final hasTo = line.any((station) => station["id"]?.toString() == toId);
      if (hasFrom && hasTo) return line;
    }

    return null;
  }

  double calculateRideDistanceMeters() {
    if (selectedFromStation == null || selectedStation == null) return 0;

    final points = getSelectedTripPoints();
    if (points.length < 2) return 0;
    double distance = 0;
    for (var i = 0; i < points.length - 1; i++) {
      distance += distanceBetween(points[i], points[i + 1]);
    }

    return distance;
  }

  int nearestRoutePointIndex(List<LatLng> routePoints, LatLng target) {
    var nearestIndex = 0;
    var nearestDistance = double.infinity;

    for (var i = 0; i < routePoints.length; i++) {
      final distance = distanceBetween(routePoints[i], target);
      if (distance < nearestDistance) {
        nearestDistance = distance;
        nearestIndex = i;
      }
    }

    return nearestIndex;
  }

  List<LatLng> getSelectedTripPoints() {
    if (selectedFromStation == null || selectedStation == null) return [];

    final tripLine = getTripLineStations();
    if (tripLine == null || tripLine.isEmpty) {
      return [
        LatLng(selectedFromStation!["lat"], selectedFromStation!["lng"]),
        LatLng(selectedStation!["lat"], selectedStation!["lng"]),
      ];
    }

    final fromId = selectedFromStation!["id"]?.toString();
    final toId = selectedStation!["id"]?.toString();
    final fromIndex = tripLine.indexWhere(
      (station) => station["id"]?.toString() == fromId,
    );
    final toIndex = tripLine.indexWhere(
      (station) => station["id"]?.toString() == toId,
    );

    if (fromIndex < 0 || toIndex < 0) return [];

    final lineRoute = identical(tripLine, line1) ? route1 : route2;
    if (lineRoute.length > 1) {
      final fromPosition = LatLng(
        selectedFromStation!["lat"],
        selectedFromStation!["lng"],
      );
      final toPosition = LatLng(
        selectedStation!["lat"],
        selectedStation!["lng"],
      );
      final routeFromIndex = nearestRoutePointIndex(lineRoute, fromPosition);
      final routeToIndex = nearestRoutePointIndex(lineRoute, toPosition);

      if (fromIndex <= toIndex && routeFromIndex <= routeToIndex) {
        return lineRoute.sublist(routeFromIndex, routeToIndex + 1);
      }
      if (fromIndex > toIndex && routeFromIndex > routeToIndex) {
        return [
          ...lineRoute.sublist(routeFromIndex),
          ...lineRoute.sublist(0, routeToIndex + 1),
        ];
      }
    }

    final fallbackPoints = <LatLng>[];
    int currentIndex = fromIndex;

    while (true) {
      final station = tripLine[currentIndex];
      fallbackPoints.add(LatLng(station["lat"], station["lng"]));

      if (currentIndex == toIndex) break;
      currentIndex = (currentIndex + 1) % tripLine.length;
    }

    return fallbackPoints;
  }

  int calculateRideMinutes() {
    final distance = calculateRideDistanceMeters();
    if (distance <= 0) return 0;
    final minutes = (distance / 5 / 60).ceil();
    return minutes < 1 ? 1 : minutes;
  }

  Widget buildTrackingPanel() {
    final fromStation = selectedFromStation;
    final toStation = selectedStation;
    final nearestInfo = getNearestBusInfo(fromStation);
    final fromName = fromStation == null
        ? "Choose start station"
        : cleanStationName(fromStation);
    final toName = toStation == null
        ? "Choose destination"
        : cleanStationName(toStation);
    final bus = nearestInfo?["bus"] as Map<String, dynamic>?;
    final busNumber = bus?["busNumber"]?.toString() ?? "-";
    final eta = nearestInfo?["eta"]?.toString() ?? "-";
    final rideMinutes = fromStation != null && toStation != null
        ? calculateRideMinutes().toString()
        : "-";
    final totalMinutes =
        fromStation != null && toStation != null && nearestInfo != null
        ? ((nearestInfo["eta"] as int) + calculateRideMinutes()).toString()
        : "-";
    final distance = nearestInfo == null
        ? "-"
        : "${((nearestInfo["distance"] as double) / 1000).toStringAsFixed(1)} km";

    return Positioned(
      left: 16,
      right: 16,
      bottom: 16,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 16,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    color: Color(0xFFD2232A),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.directions_bus,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "$fromName -> $toName",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.kanit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        fromStation == null || toStation == null
                            ? "Select From and To to calculate your trip"
                            : nearestInfo == null
                            ? "Waiting for bus location at your start station..."
                            : "Bus $busNumber reaches your start station in about $eta min",
                        style: GoogleFonts.kanit(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () {
                    setState(() {
                      selectedStation = null;
                      searchController.clear();
                      showStationSuggestions = false;
                      filteredStations.clear();
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(child: _trackingMetric("Wait", "$eta min")),
                Container(width: 1, height: 34, color: Colors.grey.shade200),
                Expanded(child: _trackingMetric("On bus", "$rideMinutes min")),
                Container(width: 1, height: 34, color: Colors.grey.shade200),
                Expanded(child: _trackingMetric("Total", "$totalMinutes min")),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              nearestInfo == null
                  ? "Distance to start station: -"
                  : "Nearest bus: Bus $busNumber, $distance from your start station",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.kanit(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _trackingMetric(String title, String value) {
    return Column(
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.kanit(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 2),
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.kanit(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildLineSelector() {
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE8E8E8)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.16),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _lineSelectorButton(line: "all"),
            const SizedBox(height: 5),
            _lineSelectorButton(line: "line1"),
            const SizedBox(height: 5),
            _lineSelectorButton(line: "line2"),
          ],
        ),
      ),
    );
  }

  Widget _lineSelectorButton({required String line}) {
    final isSelected = selectedLine == line;
    final color = lineColor(line);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => selectLine(line),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 84,
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? color : const Color(0xFFE4E4E4),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              line == "all"
                  ? Icons.route_rounded
                  : Icons.directions_bus_rounded,
              size: 18,
              color: isSelected ? Colors.white : color,
            ),
            const SizedBox(width: 5),
            Text(
              lineLabel(line),
              style: GoogleFonts.kanit(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
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
        debugPrint("all back route");
        return getLineLatLngs(points);
      }

      final routeCoords = data["routes"][0]["geometry"]["coordinates"];

      return routeCoords.map<LatLng>((c) {
        return LatLng(c[1], c[0]);
      }).toList();
    } catch (e) {
      debugPrint("ROUTE ERROR: $e");
      return getLineLatLngs(points);
    }
  }

  Future<List<LatLng>> fetchRealRoute() async {
    return fetchRouteForPoints(getSelectedLine());
  }

  Future<BitmapDescriptor> createStationDensityIcon(
    ui.Image source,
    Color color,
    double logicalSize,
  ) async {
    const canvasSize = 144.0;
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    const center = ui.Offset(canvasSize / 2, canvasSize / 2);

    canvas.drawCircle(
      center,
      68,
      ui.Paint()..color = Colors.white.withValues(alpha: 0.96),
    );
    canvas.drawCircle(
      center,
      65,
      ui.Paint()
        ..color = color
        ..style = ui.PaintingStyle.stroke
        ..strokeWidth = 10,
    );

    final sourceRect = ui.Rect.fromLTWH(
      source.width * 0.125,
      source.height * 0.117,
      source.width * 0.75,
      source.height * 0.75,
    );
    const destinationRect = ui.Rect.fromLTWH(9, 9, 126, 126);
    canvas.drawImageRect(
      source,
      sourceRect,
      destinationRect,
      ui.Paint()..filterQuality = ui.FilterQuality.high,
    );

    final renderedImage = await recorder.endRecording().toImage(
      canvasSize.toInt(),
      canvasSize.toInt(),
    );
    final pngData = await renderedImage.toByteData(
      format: ui.ImageByteFormat.png,
    );
    renderedImage.dispose();

    return BitmapDescriptor.bytes(
      pngData!.buffer.asUint8List(pngData.offsetInBytes, pngData.lengthInBytes),
      width: logicalSize,
      height: logicalSize,
    );
  }

  Future<void> loadStationMarkerIcons() async {
    final assetData = await rootBundle.load("assets/bus_stop_2.png");
    final codec = await ui.instantiateImageCodec(
      assetData.buffer.asUint8List(
        assetData.offsetInBytes,
        assetData.lengthInBytes,
      ),
      targetWidth: 128,
      targetHeight: 128,
    );
    final frame = await codec.getNextFrame();
    final source = frame.image;
    const colors = {
      "LOW": Color(0xFF00A84F),
      "MEDIUM": Color(0xFFFFA800),
      "HIGH": Color(0xFFE32636),
    };
    final normalIcons = <String, BitmapDescriptor>{};
    final selectedIcons = <String, BitmapDescriptor>{};

    for (final entry in colors.entries) {
      normalIcons[entry.key] = await createStationDensityIcon(
        source,
        entry.value,
        46,
      );
      selectedIcons[entry.key] = await createStationDensityIcon(
        source,
        entry.value,
        56,
      );
    }

    source.dispose();
    codec.dispose();

    if (!mounted) return;

    setState(() {
      stationDensityIcons
        ..clear()
        ..addAll(normalIcons);
      selectedStationDensityIcons
        ..clear()
        ..addAll(selectedIcons);
      stationMarkerIcon = normalIcons["LOW"]!;
      selectedStationMarkerIcon = selectedIcons["LOW"]!;
    });
  }

  @override
  void initState() {
    super.initState();
    currentZoom = widget.initialMapZoom;
    loadStationMarkerIcons();
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
    mapController?.dispose();
    fromSearchController.dispose();
    searchController.dispose();
    super.dispose();
  }

  void _showStationDetails({
    required Map<String, dynamic> station,
    required int waiting,
    required String status,
    required int arrivalMinutes,
  }) {
    final stationName = cleanStationName(station);
    final statusColor = _stationStatusColor(status);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        stationName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.kanit(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 36,
                        minHeight: 36,
                      ),
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Column(
                  children: [
                    _stationMetric(
                      icon: Icons.directions_bus_rounded,
                      label: "Bus Arrival",
                      value: "$arrivalMinutes min",
                    ),
                    const SizedBox(height: 8),
                    _stationMetric(
                      icon: Icons.people_outline,
                      label: "People Waiting",
                      value: "$waiting people",
                    ),
                    const SizedBox(height: 8),
                    _stationMetric(
                      icon: Icons.location_on_outlined,
                      label: "Station Status",
                      value: status.toUpperCase(),
                      valueColor: statusColor,
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _stationMetric({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: const Color(0xFFD2232A).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: const Color(0xFFD2232A)),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.kanit(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ),
        const SizedBox(width: 10),
        _stationMetricValue(value, valueColor),
      ],
    );
  }

  Widget _stationMetricValue(String value, Color? valueColor) {
    final textStyle = GoogleFonts.kanit(
      fontSize: 14,
      fontWeight: valueColor == null ? FontWeight.w500 : FontWeight.w700,
      color: valueColor ?? Colors.black54,
    );

    if (valueColor == null) {
      return Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.right,
        style: textStyle,
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: valueColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: textStyle,
      ),
    );
  }

  Color _stationStatusColor(String status) {
    switch (status.toUpperCase()) {
      case "HIGH":
        return const Color(0xFFD2232A);
      case "MEDIUM":
        return const Color(0xFFBC9945);
      default:
        return Colors.green.shade700;
    }
  }

  Widget _stationSearchField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required VoidCallback onTap,
    required ValueChanged<String> onChanged,
    required VoidCallback onClear,
    required TextInputAction textInputAction,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE9E9E9)),
      ),
      child: TextField(
        controller: controller,
        onTap: onTap,
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.kanit(fontSize: 14, color: Colors.black45),
          prefixIcon: Icon(icon, color: Colors.black54, size: 18),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 38,
            minHeight: 40,
          ),
          suffixIcon: controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: onClear,
                )
              : null,
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            vertical: 11,
            horizontal: 4,
          ),
        ),
        style: GoogleFonts.kanit(fontSize: 13, fontWeight: FontWeight.w500),
        textInputAction: textInputAction,
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
      debugPrint("BUS ERROR: $e");
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

        if (BusController.instance.busWaitUntil[id] != null &&
            now.isBefore(BusController.instance.busWaitUntil[id]!)) {
          continue;
        }

        double currentProgress =
            BusController.instance.busProgress[id] ?? (i * spacing);

        double nextProgress = currentProgress + speed;

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
    final newRoute1 = await fetchRouteForPoints(line1);
    final newRoute2 = await fetchRouteForPoints(line2);

    if (!mounted) return;

    setState(() {
      route1 = newRoute1.isNotEmpty
          ? densifyRoadRoute(newRoute1)
          : getLineLatLngs(line1);
      route2 = newRoute2.isNotEmpty
          ? densifyRoadRoute(newRoute2)
          : getLineLatLngs(line2);
    });

    updateRoute();
  }

  Future<void> updateRoute() async {
    final newRoute = await fetchRealRoute();

    if (!mounted) return;

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
    final selectedTripPoints = getSelectedTripPoints();
    final selectedLinePoints = getSelectedLinePoints();
    final activeLineColor = lineColor(selectedLine);
    final showAllLines = selectedLine == "all";
    final hasTrackingPanel =
        selectedFromStation != null || selectedStation != null;

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: widget.initialMapTarget ?? _mSquareStationCenter,
              zoom: currentZoom,
            ),
            onMapCreated: (controller) {
              mapController = controller;
              focusInitialMapTarget();
            },
            onCameraMove: (position) => currentZoom = position.zoom,
            onTap: (_) => resetStationSelection(),
            zoomControlsEnabled: false,
            minMaxZoomPreference: const MinMaxZoomPreference(15.8, 19),
            mapToolbarEnabled: false,
            myLocationButtonEnabled: false,
            polylines: {
              if (showAllLines) ...{
                Polyline(
                  polylineId: const PolylineId("line1"),
                  points: route1.isNotEmpty ? route1 : getLineLatLngs(line1),
                  color: lineColor("line1"),
                  width: 4,
                ),
                Polyline(
                  polylineId: const PolylineId("line2"),
                  points: route2.isNotEmpty ? route2 : getLineLatLngs(line2),
                  color: lineColor("line2"),
                  width: 4,
                ),
              } else if (selectedLinePoints.length > 1)
                Polyline(
                  polylineId: PolylineId(selectedLine),
                  points: selectedLinePoints,
                  color: activeLineColor,
                  width: 5,
                ),
              if (selectedTripPoints.length > 1)
                Polyline(
                  polylineId: const PolylineId("selected-station-route"),
                  points: selectedTripPoints,
                  color: const Color(0xFF1A73E8),
                  width: 5,
                ),
            },
            markers: {
              ...getSelectedLine().map((station) {
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
                final isSelected =
                    selectedStation?["id"]?.toString() ==
                        station["id"]?.toString() ||
                    selectedFromStation?["id"]?.toString() ==
                        station["id"]?.toString();

                return Marker(
                  markerId: MarkerId("station-${station["id"]}"),
                  position: LatLng(station["lat"], station["lng"]),
                  anchor: const Offset(0.5, 0.5),
                  zIndexInt: 2,
                  icon: stationIconFor(waiting, status, isSelected),
                  infoWindow: InfoWindow(
                    title: cleanStationName(station),
                    snippet: "$waiting people - $status",
                  ),
                  onTap: () {
                    final eta = calculateETA(
                      LatLng(station["lat"], station["lng"]),
                    );

                    _showStationDetails(
                      station: station,
                      waiting: waiting,
                      status: status,
                      arrivalMinutes: eta.ceil(),
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
                      zIndexInt: 10,
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueBlue,
                      ),
                      infoWindow: InfoWindow(title: "Bus $id"),
                    );
                  }),
            },
          ),

          if (hasTrackingPanel) buildTrackingPanel(),

          // Search station tab below app bar
          Positioned(
            top: 92,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFECECEC)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFFD2232A),
                                width: 3,
                              ),
                            ),
                          ),
                          Container(
                            width: 2,
                            height: 38,
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            color: const Color(0xFFE0E0E0),
                          ),
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade700,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _stationSearchField(
                              controller: fromSearchController,
                              hintText: "From station",
                              icon: Icons.my_location,
                              onTap: () => searchStations(
                                fromSearchController.text,
                                "from",
                              ),
                              onChanged: (value) =>
                                  searchStations(value, "from"),
                              onClear: () {
                                fromSearchController.clear();
                                setState(() {
                                  selectedFromStation = null;
                                  showStationSuggestions = false;
                                  filteredStations.clear();
                                });
                              },
                              textInputAction: TextInputAction.next,
                            ),
                            const SizedBox(height: 8),
                            _stationSearchField(
                              controller: searchController,
                              hintText: "To station",
                              icon: Icons.location_on_outlined,
                              onTap: () =>
                                  searchStations(searchController.text, "to"),
                              onChanged: (value) => searchStations(value, "to"),
                              onClear: () {
                                searchController.clear();
                                setState(() {
                                  selectedStation = null;
                                  showStationSuggestions = false;
                                  filteredStations.clear();
                                });
                              },
                              textInputAction: TextInputAction.search,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (showStationSuggestions)
                  Container(
                    margin: const EdgeInsets.only(top: 8),
                    constraints: const BoxConstraints(maxHeight: 260),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.14),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Scrollbar(
                      child: ListView.separated(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: filteredStations.length,
                        separatorBuilder: (context, index) =>
                            Divider(height: 1, color: Colors.grey.shade200),
                        itemBuilder: (context, index) {
                          final station = filteredStations[index];
                          final name = cleanStationName(station);
                          final isFavorite = favoriteStationIds.contains(
                            station["id"]?.toString(),
                          );

                          return InkWell(
                            onTap: () => selectStation(station),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 13,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    isFavorite
                                        ? Icons.favorite
                                        : Icons.directions_bus,
                                    size: 18,
                                    color: isFavorite
                                        ? const Color(0xFFD2232A)
                                        : Colors.grey,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      name,
                                      style: GoogleFonts.kanit(fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),

          Positioned(
            right: 16,
            bottom: hasTrackingPanel ? 176 : 24,
            child: _buildLineSelector(),
          ),

          // App bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 88,
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).padding.top,
                left: 16,
                right: 16,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
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
                    icon: const Icon(Icons.menu, color: Color(0xFFD2232A)),
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
