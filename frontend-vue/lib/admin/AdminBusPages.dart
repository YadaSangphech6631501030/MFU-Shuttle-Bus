import 'package:flutter/material.dart';
import 'admin_bottom_bar.dart';

class Adminbuspages extends StatefulWidget {
  const Adminbuspages({super.key});

  @override
  State<Adminbuspages> createState() => _AdminbuspagesState();
}

class _AdminbuspagesState extends State<Adminbuspages> {
  int currentIndex = 1;
  String selectedStatusFilter = "all";

  final List<Map<String, String>> buses = List.generate(16, (index) {
    final busNumber = (index + 1).toString().padLeft(2, '0');

    return {
      "name": "Bus $busNumber",
      "status": index % 4 == 0 ? "offline" : "online",
      "latestLocation": "-",
    };
  });

  Color getStatusColor(String status) {
    return status == "online" ? Colors.green : Colors.grey;
  }

  String getStatusText(String status) {
    return status == "online" ? "Online" : "Offline";
  }

  List<Map<String, String>> get filteredBuses {
    if (selectedStatusFilter == "all") return buses;

    return buses
        .where((bus) => bus["status"] == selectedStatusFilter)
        .toList();
  }

  String get filterTitle {
    switch (selectedStatusFilter) {
      case "online":
        return "Online Buses";
      case "offline":
        return "Offline Buses";
      default:
        return "All Buses";
    }
  }

  Color getFilterColor(String value) {
    if (value == "online") return Colors.green;
    if (value == "offline") return Colors.grey.shade700;
    return Color(0xFFD2232A);
  }

  String getFilterLabel(String value) {
    if (value == "online") return "Online";
    if (value == "offline") return "Offline";
    return "All";
  }

  Widget buildFilterButton() {
    final selectedColor = getFilterColor(selectedStatusFilter);

    return PopupMenuButton<String>(
      initialValue: selectedStatusFilter,
      onSelected: (value) {
        setState(() {
          selectedStatusFilter = value;
        });
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: "all", child: Text("All")),
        const PopupMenuItem(value: "online", child: Text("Online")),
        const PopupMenuItem(value: "offline", child: Text("Offline")),
      ],
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selectedColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selectedColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              getFilterLabel(selectedStatusFilter),
              style: TextStyle(
                color: selectedColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.keyboard_arrow_down,
              color: selectedColor,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: AdminBottomBar(
        currentIndex: currentIndex,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },
      ),
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Admin Bus Status"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    "$filterTitle (${filteredBuses.length})",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                buildFilterButton(),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.builder(
                itemCount: filteredBuses.length,
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 220,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.15,
                ),
                itemBuilder: (context, index) {
                  final bus = filteredBuses[index];
                  final status = bus["status"] ?? "offline";
                  final statusColor = getStatusColor(status);

                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.directions_bus,
                                color: statusColor,
                                size: 26,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                getStatusText(status),
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          bus["name"] ?? "-",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Latest location",
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          bus["latestLocation"] ?? "-",
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
