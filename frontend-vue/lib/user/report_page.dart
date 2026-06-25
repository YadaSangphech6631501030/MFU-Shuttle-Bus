import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shuttle_bus_fronted/services/api_service.dart';
import 'package:shuttle_bus_fronted/services/language_service.dart';

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

  String _t({required String en, required String th}) {
    return LanguageService.text(en: en, th: th);
  }

  // =========================
  // 📌 OPEN FORM DIALOG
  // =========================
  void openReportForm({required String type, required String title}) {
    setState(() {
      selectedType = type;
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
                    _t(en: "Report Problem", th: "แจ้งปัญหา"),
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
                      hintText: _t(
                        en: "Location (optional)",
                        th: "สถานที่ (ไม่บังคับ)",
                      ),
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
                      hintText: _t(
                        en: "Describe the problem...",
                        th: "อธิบายปัญหา...",
                      ),
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
                        child: Text(
                          _t(en: "Cancel", th: "ยกเลิก"),
                          style: const TextStyle(color: Colors.red),
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
                          final navigator = Navigator.of(context);
                          final messenger = ScaffoldMessenger.of(context);
                          final result = await ApiService.sendReport(
                            selectedType ?? "",
                            detailController.text,
                            locationController.text,
                          );

                          if (!mounted) return;
                          if (result == null) {
                            navigator.pop();
                            showSuccessPopup();
                          } else {
                            messenger.showSnackBar(
                              SnackBar(content: Text(result)),
                            );
                          }
                        },
                        child: Text(
                          _t(en: "Send", th: "ส่ง"),
                          style: const TextStyle(color: Colors.white),
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
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 60),
                const SizedBox(height: 10),
                Text(
                  _t(en: "Success", th: "สำเร็จ"),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _t(
                    en: "Report sent successfully",
                    th: "ส่งรายงานเรียบร้อยแล้ว",
                  ),
                ),
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
  Widget buildReportItem(
    IconData icon,
    String type,
    String title,
    Color color,
  ) {
    return GestureDetector(
      onTap: () => openReportForm(type: type, title: title),
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
    return ValueListenableBuilder<String>(
      valueListenable: LanguageService.notifier,
      builder: (context, selectedLanguage, _) {
        final topPadding = MediaQuery.of(context).padding.top;
        const homeAppBarHeight = 88.0;
        const backButtonSize = 44.0;
        final backButtonTop =
            (topPadding +
                    ((homeAppBarHeight - topPadding - backButtonSize) / 2))
                .clamp(0.0, homeAppBarHeight - backButtonSize);

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(homeAppBarHeight),
            child: Material(
              color: Colors.white,
              elevation: 0,
              child: Container(
                height: homeAppBarHeight,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    bottom: BorderSide(color: Color(0xFFE0E0E0), width: 1),
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      top: topPadding,
                      child: Center(
                        child: Text(
                          _t(en: "Report Problem", th: "แจ้งปัญหา"),
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 16,
                      top: backButtonTop,
                      child: SizedBox(
                        width: backButtonSize,
                        height: backButtonSize,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: Colors.black,
                              size: 18,
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          body: Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.6,
              children: [
                buildReportItem(
                  Icons.car_crash,
                  "Accident",
                  _t(en: "Accident", th: "อุบัติเหตุ"),
                  Colors.red,
                ),
                buildReportItem(
                  Icons.directions_car,
                  "Breakdown",
                  _t(en: "Breakdown", th: "รถเสีย"),
                  Colors.red,
                ),
                buildReportItem(
                  Icons.construction,
                  "Construction",
                  _t(en: "Construction", th: "ก่อสร้าง"),
                  Colors.orange,
                ),
                buildReportItem(
                  Icons.block,
                  "Road Closed",
                  _t(en: "Road Closed", th: "ปิดถนน"),
                  Colors.orange,
                ),
                buildReportItem(
                  Icons.warning,
                  "Obstacle",
                  _t(en: "Obstacle", th: "สิ่งกีดขวาง"),
                  Colors.amber,
                ),
                buildReportItem(
                  Icons.email,
                  "Complaint",
                  _t(en: "Complaint", th: "ร้องเรียน"),
                  Colors.blue,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
