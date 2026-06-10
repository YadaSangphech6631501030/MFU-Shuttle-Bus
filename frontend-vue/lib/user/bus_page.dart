import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shuttle_bus_fronted/services/api_service.dart';
import 'custom_bottom_bar.dart';
import 'homepages.dart';

class BusPage extends StatefulWidget {
  const BusPage({super.key});

  @override
  State<BusPage> createState() => _BusPageState();
}

class _BusPageState extends State<BusPage> {
  final TextEditingController fromController = TextEditingController();

  final TextEditingController toController = TextEditingController();

  bool showSuggestions = false;

  //
  String activeField = '';

  List<String> busStations = [];

  List<String> filteredStations = [];
  bool showResult = false;

  @override
  void initState() {
    super.initState();
    _loadStations();
  }

  Future<void> _loadStations() async {
    try {
      final lines = await Future.wait([
        ApiService.getStations("line1"),
        ApiService.getStations("line2"),
      ]);
      final stationsById = <String, dynamic>{};

      for (final station in [...lines[0], ...lines[1]]) {
        final id = station["id"]?.toString() ?? "";
        if (id.isNotEmpty) {
          stationsById[id] = station;
        }
      }

      final stations = stationsById.values.toList();
      stations.sort(
        (a, b) => _stationNumber(a["id"]).compareTo(_stationNumber(b["id"])),
      );

      if (!mounted) return;

      setState(() {
        busStations = stations
            .map<String>((station) => station["name"]?.toString().trim() ?? "")
            .where((name) => name.isNotEmpty)
            .toList();

        final query = activeField == "from"
            ? fromController.text
            : toController.text;
        if (query.trim().isNotEmpty) {
          filteredStations = busStations
              .where(
                (station) =>
                    station.toLowerCase().contains(query.toLowerCase()),
              )
              .toList();
          showSuggestions = filteredStations.isNotEmpty;
        }
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Failed to load stations")));
    }
  }

  int _stationNumber(dynamic id) {
    final number = RegExp(r'\d+').firstMatch(id?.toString() ?? "")?.group(0);
    return int.tryParse(number ?? "") ?? 9999;
  }

  final List<Map<String, dynamic>> buses = [
    {"bus": "Bus 04", "time": 1},
    {"bus": "Bus 07", "time": 2},
    {"bus": "Bus 09", "time": 3},
  ];

  void searchStation(String value, String field) {
    activeField = field;

    setState(() {
      showResult = false;
    });

    if (value.trim().isEmpty) {
      setState(() {
        showSuggestions = false;
        filteredStations.clear();
        showResult = false;
      });
      return;
    }

    List<String> results;

    if (value.trim() == 'จุด') {
      results = busStations;
    } else {
      results = busStations.where((station) {
        return station.toLowerCase().contains(value.toLowerCase());
      }).toList();
    }

    setState(() {
      filteredStations = results;
      showSuggestions = results.isNotEmpty;
    });
  }

  void selectStation(String item) {
    if (activeField == 'from') {
      fromController.text = item;
    } else {
      toController.text = item;
    }

    setState(() {
      showSuggestions = false;

      if (fromController.text.isNotEmpty && toController.text.isNotEmpty) {
        showResult = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 70,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Icon(
              Icons.arrow_back_ios,
              color: Colors.black,
              size: 20,
            ),
          ),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const Homepages()),
              );
            }
          },
        ),
        title: const Text(
          'Find Station',
          style: TextStyle(
            color: Colors.black,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // จุดแดง เส้น จุดเหลือง
                  Column(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ), //
                      Container(width: 2, height: 38, color: Colors.grey),
                      Container(
                        width: 12,
                        height: 12,
                        color: const Color(0xFFC5A437),
                      ),
                    ],
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // FROM
                        _buildInput(
                          title: 'From',
                          hint: 'Where ?',
                          controller: fromController,
                          field: 'from',
                        ),

                        const SizedBox(height: 10),

                        // TO
                        _buildInput(
                          title: 'To',
                          hint: 'Where to ?',
                          controller: toController,
                          field: 'to',
                        ),
                        const SizedBox(height: 24),

                        if (showResult) ...[
                          Text(
                            'Fastest buses',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
                            ),
                          ),

                          const SizedBox(height: 16),

                          _busCard("Bus 04", 1),
                          _busCard("Bus 07", 2),
                          _busCard("Bus 09", 3),
                        ],
                        // Dropdown
                        if (showSuggestions)
                          Container(
                            margin: const EdgeInsets.only(top: 8, left: 4),
                            constraints: const BoxConstraints(maxHeight: 220),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.12),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Scrollbar(
                              child: ListView.separated(
                                shrinkWrap: true,
                                itemCount: filteredStations.length,
                                separatorBuilder: (_, __) => Divider(
                                  height: 1,
                                  color: Colors.grey.shade200,
                                ),
                                itemBuilder: (context, index) {
                                  final item = filteredStations[index];

                                  return InkWell(
                                    onTap: () => selectStation(item),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 14,
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.directions_bus,
                                            size: 18,
                                            color: Colors.grey,
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              item,
                                              style: const TextStyle(
                                                fontSize: 13,
                                              ),
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
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _busCard(String busName, int minute) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: busName == "Bus 04" ? Colors.green : Colors.grey.shade300,
          width: 2,
        ),
        boxShadow: const [
          BoxShadow(color: Color.fromARGB(31, 255, 204, 204), blurRadius: 4),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.directions_bus, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              busName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
          ),
          Text('$minute min', style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildInput({
    required String title,
    required String hint,
    required TextEditingController controller,
    required String field,
  }) {
    return Container(
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE6E6E6),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: (value) {
                setState(() {});

                searchStation(value, field);
              },
              decoration: InputDecoration(
                hintText: hint,
                border: InputBorder.none,

                suffixIcon: controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          controller.clear();

                          searchStation('', field);

                          setState(() {
                            showSuggestions = false;
                            filteredStations.clear();
                            showResult = false;
                          });
                        },
                      )
                    : null,

                hintStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
