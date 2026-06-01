import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import '../widgets/custom_bottom_bar.dart';

class BusPage extends StatefulWidget {
  const BusPage({super.key});

  @override
  State<BusPage> createState() => _BusPageState();
}

class _BusPageState extends State<BusPage> {
  int currentIndex = 1;

  final Random random = Random();
  Timer? timer;

  List<Map<String, dynamic>> buses = [
    {
      "name": "Bus 01",
      "line": "Line 1",
      "station": "C3",
      "minutes": 3,
      "status": "running",
    },
    {
      "name": "Bus 02",
      "line": "Line 2",
      "station": "E2",
      "minutes": 5,
      "status": "medium",
    },
    {
      "name": "Bus 03",
      "line": "Line 1",
      "station": "M-Square",
      "minutes": 10,
      "status": "stop",
    },
    {
      "name": "Bus 04",
      "line": "Line 2",
      "station": "Lamduan",
      "minutes": 4,
      "status": "running",
    },
    {
      "name": "Bus 05",
      "line": "Line 1",
      "station": "C5",
      "minutes": 6,
      "status": "medium",
    },
    {
      "name": "Bus 06",
      "line": "Line 2",
      "station": "D1",
      "minutes": 8,
      "status": "stop",
    },
  ];

  @override
  void initState() {
    super.initState();

    timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      setState(() {
        for (var bus in buses) {
          bus["minutes"] = random.nextInt(10) + 1;
          bus["status"] = randomStatus();
        }
      });
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  String randomStatus() {
    final r = random.nextInt(3);
    switch (r) {
      case 0:
        return "running";
      case 1:
        return "medium";
      default:
        return "stop";
    }
  }

  Color getStatusColor(String status) {
    switch (status) {
      case "running":
        return Colors.green;
      case "medium":
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String getStatusText(String status) {
    switch (status) {
      case "running":
        return "Running";
      case "medium":
        return "Arriving";
      default:
        return "Stopped";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: CustomBottomBar(currentIndex: 1),
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Bus Status"),
        backgroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: buses.length,
            itemBuilder: (context, index) {
              final bus = buses[index];

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.directions_bus,
                      size: 40,
                      color: getStatusColor(bus["status"]),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "${bus["name"]}: ${getStatusText(bus["status"])}",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: getStatusColor(bus["status"]),
                            ),
                          ),
                          Text("Line : ${bus["line"]}"),
                          Text("Next Station : ${bus["station"]}"),
                          Text("Time Arrive : ${bus["minutes"]} min"),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}