import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shuttle_bus_fronted/services/api_service.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ReportPage extends StatefulWidget {
  const ReportPage({super.key});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;


  String? selectedType;

  final TextEditingController detailController = TextEditingController();
  final TextEditingController locationController = TextEditingController();

  // =========================
  // 📡 SEND TO BACKEND
  // =========================
  Future<void> sendReport() async {
    try {
      final response = await http.post(
        Uri.parse("http://10.0.2.2:3000/api/report"), // emulator
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "type": selectedType,
          "detail": detailController.text,
          "location": locationController.text,
          "time": DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        print("✅ Report sent");
      } else {
        print("❌ Failed: ${response.body}");
      }
    } catch (e) {
      print("❌ Error: $e");
    }
  }

  // =========================
  // 📌 OPEN FORM DIALOG
  // =========================
  void openReportForm(String title) {
    setState(() {
      selectedType = title;
      detailController.clear();
      locationController.clear();
    });

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    "Report Problem",
                    style: GoogleFonts.kanit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 5),

                  Text(
                    title,
                    style: GoogleFonts.kanit(fontSize: 14, color: Colors.grey),
                  ),

                  const SizedBox(height: 15),

                  // 📍 LOCATION
                  TextField(
                    controller: locationController,
                    decoration: InputDecoration(
                      hintText: "Location (optional)",
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // 📝 DETAIL
                  TextField(
                    controller: detailController,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: "Describe the problem...",
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  // BUTTONS
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          "Cancel",
                          style: TextStyle(color: Colors.red),
                        ),
                      ),

                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: () async {
                          final result = await ApiService.sendReport(
                            selectedType ?? "",
                            detailController.text,
                            locationController.text,
                          );

                          if (result == null) {
                            Navigator.pop(context);
                            showSuccessPopup();
                          } else {
                            print("ERROR: $result");
                          }
                        },
                        child: const Text(
                          "Send",
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // =========================
  // ✅ SUCCESS POPUP
  // =========================
  void showSuccessPopup() {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 60),
                SizedBox(height: 10),
                Text(
                  "Success",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 5),
                Text("Report sent successfully"),
              ],
            ),
          ),
        );
      },
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    });
  }

  // =========================
  // 📦 CARD ITEM
  // =========================
  Widget buildReportItem(IconData icon, String title, Color color) {
    return GestureDetector(
      onTap: () => openReportForm(title),
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
            Text(title, style: GoogleFonts.kanit(fontSize: 13)),
          ],
        ),
      ),
    );
  }

  // =========================
  // 🧹 CLEAN UP
  // =========================
  @override
  void dispose() {
    detailController.dispose();
    locationController.dispose();
    super.dispose();
  }

  // =========================
  // 🧱 UI
  // =========================
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
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
            Navigator.pop(context);
          },
        ),
        title: const Text("Report Problem"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.count(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.6,
          children: [
            buildReportItem(Icons.car_crash, "Accident", Colors.red),
            buildReportItem(Icons.directions_car, "Breakdown", Colors.red),
            buildReportItem(Icons.construction, "Construction", Colors.orange),
            buildReportItem(Icons.block, "Road Closed", Colors.orange),
            buildReportItem(Icons.warning, "Obstacle", Colors.amber),
            buildReportItem(Icons.email, "Complaint", Colors.blue),
          ],
        ),
      ),
    );
  }
}
