import 'package:flutter/material.dart';
import 'package:shuttle_bus_fronted/services/api_service.dart';
import 'admin_bottom_bar.dart';
import '../user/signin01.dart';

class AdminStationPage extends StatefulWidget {
  const AdminStationPage({super.key});

  @override
  State<AdminStationPage> createState() => _AdminStationPageState();
}

class _AdminStationPageState extends State<AdminStationPage> {
  int currentIndex = 2;
  bool isLoading = true;
  List<dynamic> stations = [];
  String loadNote = "";
  String selectedStatusFilter = "ALL";

  @override
  void initState() {
    super.initState();
    fetchStations();
  }

  Future<void> fetchStations() async {
    setState(() {
      isLoading = true;
    });

    try {
      final data = await ApiService.getAdminStations();
      data.sort(
        (a, b) => _stationNumber(a["id"]).compareTo(_stationNumber(b["id"])),
      );

      setState(() {
        stations = data;
        loadNote = "";
        isLoading = false;
      });
    } catch (e) {
      await _loadPublicStationFallback(e.toString());
    }
  }

  Future<void> _loadPublicStationFallback(String adminError) async {
    try {
      final line1Stations = await ApiService.getStations("line1");
      final line2Stations = await ApiService.getStations("line2");
      final stationById = <String, dynamic>{};

      for (final station in [...line1Stations, ...line2Stations]) {
        final id = station["id"]?.toString() ?? "";
        if (id.isNotEmpty) {
          stationById[id] = station;
        }
      }

      final data = stationById.values.toList();
      data.sort(
        (a, b) => _stationNumber(a["id"]).compareTo(_stationNumber(b["id"])),
      );

      setState(() {
        stations = data;
        loadNote = _fallbackNote(adminError);
        isLoading = false;
      });

      _showMessage(loadNote);
    } catch (e) {
      setState(() {
        loadNote = "Load stations failed: ${_cleanError(adminError)}";
        isLoading = false;
      });
      _showMessage(loadNote);
    }
  }

  String _cleanError(String error) {
    return error.replaceFirst("Exception: ", "");
  }

  String _fallbackNote(String adminError) {
    final error = _cleanError(adminError);

    if (error.contains("Server error (not JSON)") ||
        error.contains("Admin station API not found")) {
      return "Showing seed station data. Restart backend to enable admin station editing API.";
    }

    return "Showing seed station data. Admin API error: $error";
  }

  int _stationNumber(dynamic id) {
    final value = id?.toString() ?? "";
    final number = RegExp(r'\d+').firstMatch(value)?.group(0);
    return int.tryParse(number ?? "") ?? 9999;
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _goToSignIn() {
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const Signin01()),
      (route) => false,
    );
  }

  bool _isSessionExpired(String message) {
    return message.contains("Session expired") ||
        message.contains("Please sign in again");
  }

  String _linesText(dynamic lines) {
    if (lines is List) {
      return lines.join(", ");
    }

    return "-";
  }

  String _coordinateText(Map<String, dynamic> station) {
    final lat = double.tryParse(station["lat"]?.toString() ?? "");
    final lng = double.tryParse(station["lng"]?.toString() ?? "");

    if (lat == null || lng == null) return "-";

    return "${lat.toStringAsFixed(6)}, ${lng.toStringAsFixed(6)}";
  }

  List<dynamic> get filteredStations {
    if (selectedStatusFilter == "ALL") return stations;

    return stations
        .where(
          (station) => station["status"]?.toString() == selectedStatusFilter,
        )
        .toList();
  }

  Color _statusColor(String status) {
    if (status == "HIGH") return Colors.red;
    if (status == "MEDIUM") return Colors.orange;
    return Colors.green;
  }

  Widget _statusFilterButton() {
    final filterColor = selectedStatusFilter == "ALL"
        ? Colors.black
        : _statusColor(selectedStatusFilter);

    return PopupMenuButton<String>(
      initialValue: selectedStatusFilter,
      onSelected: (value) {
        setState(() {
          selectedStatusFilter = value;
        });
      },
      itemBuilder: (context) => const [
        PopupMenuItem(value: "ALL", child: Text("All")),
        PopupMenuItem(value: "LOW", child: Text("LOW")),
        PopupMenuItem(value: "MEDIUM", child: Text("MEDIUM")),
        PopupMenuItem(value: "HIGH", child: Text("HIGH")),
      ],
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: filterColor.withOpacity(0.12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: filterColor),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              selectedStatusFilter == "ALL" ? "All" : selectedStatusFilter,
              style: TextStyle(
                color: filterColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.keyboard_arrow_down, color: filterColor, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _statusOption(
    String option,
    String selectedStatus,
    ValueChanged<String> onSelected,
  ) {
    final color = _statusColor(option);
    final isSelected = selectedStatus == option;

    return Expanded(
      child: InkWell(
        onTap: () => onSelected(option),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.14) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : Colors.grey.shade300,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isSelected) ...[
                Icon(Icons.check_circle, color: color, size: 16),
                const SizedBox(width: 6),
              ],
              Text(
                option,
                style: TextStyle(
                  color: isSelected ? color : Colors.grey.shade700,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteStation(Map<String, dynamic> station) async {
    final id = station["id"]?.toString() ?? "";
    if (id.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Delete station"),
          content: Text("Delete $id from database?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    final error = await ApiService.deleteAdminStation(id);
    if (error != null) {
      _showMessage(error);
      if (_isSessionExpired(error)) _goToSignIn();
      return;
    }

    _showMessage("Station deleted");
    fetchStations();
  }

  Future<void> _showStationForm(Map<String, dynamic>? station) async {
    final isEdit = station != null;
    final idController = TextEditingController(
      text: station?["id"]?.toString() ?? "",
    );
    final nameController = TextEditingController(
      text: station?["name"]?.toString() ?? "",
    );
    final latController = TextEditingController(
      text: station?["lat"]?.toString() ?? "",
    );
    final lngController = TextEditingController(
      text: station?["lng"]?.toString() ?? "",
    );
    final waitingController = TextEditingController(
      text: station?["waiting"]?.toString() ?? "0",
    );
    final cameraController = TextEditingController(
      text: station?["cameraUrl"]?.toString() ?? "",
    );

    final stationLines = station?["lines"];
    bool line1 = stationLines is List ? stationLines.contains("line1") : true;
    bool line2 = stationLines is List ? stationLines.contains("line2") : false;
    String status = station?["status"]?.toString() ?? "LOW";
    if (!["LOW", "MEDIUM", "HIGH"].contains(status)) {
      status = "LOW";
    }
    bool isSaving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            Future<void> saveStation() async {
              if (isSaving) return;

              final lat = double.tryParse(latController.text.trim());
              final lng = double.tryParse(lngController.text.trim());
              final waiting = int.tryParse(waitingController.text.trim());
              final lines = <String>[if (line1) "line1", if (line2) "line2"];

              if (idController.text.trim().isEmpty ||
                  nameController.text.trim().isEmpty ||
                  lat == null ||
                  lng == null ||
                  waiting == null ||
                  lines.isEmpty) {
                _showMessage("Please fill station data");
                return;
              }

              setSheetState(() {
                isSaving = true;
              });

              final payload = {
                "id": idController.text.trim(),
                "name": nameController.text.trim(),
                "lat": lat,
                "lng": lng,
                "lines": lines,
                "waiting": waiting,
                "status": status,
                "cameraUrl": cameraController.text.trim(),
              };

              final error = isEdit
                  ? await ApiService.updateAdminStation(
                      station["id"].toString(),
                      payload,
                    )
                  : await ApiService.createAdminStation(payload);

              setSheetState(() {
                isSaving = false;
              });

              if (error != null) {
                _showMessage(error);
                if (_isSessionExpired(error)) _goToSignIn();
                return;
              }

              Navigator.pop(sheetContext);
              _showMessage(isEdit ? "Station updated" : "Station created");
              fetchStations();
            }

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Text(
                          isEdit ? "Edit Station" : "Add Station",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(sheetContext),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _field("Station ID", idController, "station18"),
                    _field("Station Name", nameController, "Station 18"),
                    Row(
                      children: [
                        Expanded(
                          child: _field("Latitude", latController, "20.000000"),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _field(
                            "Longitude",
                            lngController,
                            "99.000000",
                          ),
                        ),
                      ],
                    ),
                    _field("Waiting", waitingController, "0"),
                    const SizedBox(height: 8),
                    const Text(
                      "Lines",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        Checkbox(
                          value: line1,
                          activeColor: const Color(0xFFBC9945),
                          checkColor: Colors.white,
                          onChanged: (value) {
                            setSheetState(() {
                              line1 = value ?? false;
                            });
                          },
                        ),
                        const Text("Line 1"),
                        const SizedBox(width: 16),
                        Checkbox(
                          value: line2,
                          activeColor: Colors.grey.shade700,
                          checkColor: Colors.white,
                          onChanged: (value) {
                            setSheetState(() {
                              line2 = value ?? false;
                            });
                          },
                        ),
                        const Text("Line 2"),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Status",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _statusOption("LOW", status, (value) {
                          setSheetState(() {
                            status = value;
                          });
                        }),
                        const SizedBox(width: 8),
                        _statusOption("MEDIUM", status, (value) {
                          setSheetState(() {
                            status = value;
                          });
                        }),
                        const SizedBox(width: 8),
                        _statusOption("HIGH", status, (value) {
                          setSheetState(() {
                            status = value;
                          });
                        }),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _field("CCTV IP / URL", cameraController, "rtsp://..."),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: isSaving ? null : saveStation,
                        icon: Icon(
                          isSaving ? Icons.hourglass_empty : Icons.save,
                        ),
                        label: Text(isSaving ? "Saving..." : "Save Station"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFD2232A),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _field(String label, TextEditingController controller, String hint) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: hint,
              filled: true,
              fillColor: Colors.grey.shade100,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: AdminBottomBar(
        currentIndex: currentIndex,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },
      ),
      appBar: AppBar(
        title: const Text("Station Management"),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                _statusFilterButton(),
                const Spacer(),
                Row(
                  children: [
                    IconButton(
                      onPressed: fetchStations,
                      icon: const Icon(Icons.refresh),
                    ),
                    IconButton(
                      onPressed: () => _showStationForm(null),
                      icon: const Icon(Icons.add_location_alt_outlined),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredStations.isEmpty
                ? _emptyState()
                : Column(
                    children: [
                      if (loadNote.isNotEmpty)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            loadNote,
                            style: TextStyle(
                              color: Colors.orange.shade900,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                          itemCount: filteredStations.length,
                          itemBuilder: (context, index) {
                            final station = Map<String, dynamic>.from(
                              filteredStations[index],
                            );
                            return _stationCard(station);
                          },
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFD2232A),
        foregroundColor: Colors.white,
        onPressed: () => _showStationForm(null),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.location_off_outlined,
            size: 46,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 12),
          Text(
            "No stations",
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _stationCard(Map<String, dynamic> station) {
    final status = station["status"]?.toString() ?? "LOW";
    final statusColor = status == "HIGH"
        ? Colors.red
        : status == "MEDIUM"
        ? Colors.orange
        : Colors.green;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFD2232A).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.location_on_outlined,
              color: Color(0xFFD2232A),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  station["name"]?.toString() ?? "-",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  station["id"]?.toString() ?? "-",
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _chip(Icons.route_outlined, _linesText(station["lines"])),
                    _chip(
                      Icons.people_outline,
                      "${station["waiting"] ?? 0} waiting",
                    ),
                    _chip(Icons.my_location, _coordinateText(station)),
                    _statusChip(status, statusColor),
                    if ((station["cameraUrl"]?.toString() ?? "").isNotEmpty)
                      _chip(Icons.videocam_outlined, "CCTV ready"),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _showStationForm(station),
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            onPressed: () => _deleteStation(station),
            icon: const Icon(Icons.delete_outline, color: Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade700),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
