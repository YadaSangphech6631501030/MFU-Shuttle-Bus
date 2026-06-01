import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shuttle_bus_fronted/services/api_service.dart';
import 'admin_bottom_bar.dart';

class DashboardReport extends StatefulWidget {
  const DashboardReport({super.key});

  @override
  State<DashboardReport> createState() => _DashboardReportState();
}

class _DashboardReportState extends State<DashboardReport> {
  List reports = [];
  bool isLoading = true;

  int currentIndex = 2; // 🔥 ตั้ง index ให้ตรงกับ tab Report

  @override
  void initState() {
    super.initState();
    fetchReports();
  }

  Future<void> fetchReports() async {
    try {
      final data = await ApiService.getReports();

      setState(() {
        reports = data;
        isLoading = false;
      });
    } catch (e) {
      print("ERROR: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Color getStatusColor(String status) {
    switch (status) {
      case "pending":
        return Colors.orange;
      case "done":
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // Bottom Bar
      bottomNavigationBar: AdminBottomBar(
        currentIndex: currentIndex,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },
      ),

      appBar: AppBar(
        title: const Text("Report Dashboard"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        automaticallyImplyLeading: false, // 🔥 สำคัญ
      ),

      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : reports.isEmpty
          ? const Center(child: Text("ไม่มีข้อมูล"))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: reports.length,
              itemBuilder: (context, index) {
                final r = reports[index];

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r["type"] ?? "-",
                        style: GoogleFonts.kanit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),

                      Text(
                        r["detail"] ?? "-",
                        style: GoogleFonts.kanit(fontSize: 14),
                      ),
                      const SizedBox(height: 6),

                      Text(
                        "📍 ${r["location"] ?? "-"}",
                        style: GoogleFonts.kanit(fontSize: 12),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        "👤 ${r["user"]?["username"] ?? "Unknown"}",
                        style: GoogleFonts.kanit(
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      
                      const SizedBox(height: 10),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: getStatusColor(r["status"]),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              r["status"],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),

                          const SizedBox(width: 10),

                          if (r["status"] == "pending")
                            GestureDetector(
                              onTap: () async {
                                try {
                                  await ApiService.confirmReport(
                                    r["_id"].toString(),
                                  );
                                  fetchReports(); // refresh
                                } catch (e) {
                                  print("CONFIRM ERROR: $e");
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  "Confirm",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),

                      Text(
                        r["time"] != null
                            ? r["time"].toString().substring(0, 16)
                            : "-",
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
