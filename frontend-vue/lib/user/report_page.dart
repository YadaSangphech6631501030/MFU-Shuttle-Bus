import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shuttle_bus_fronted/services/api_service.dart';
import 'package:shuttle_bus_fronted/services/language_service.dart';
import 'homepages.dart';

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
    if (type == "Feedback") {
      openFeedbackForm(title: title);
      return;
    }

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
                    _t(en: "Help & Feedback", th: "ช่วยเหลือ & ข้อเสนอแนะ"),
                    style: GoogleFonts.kanit(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
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

  void openFeedbackForm({required String title}) {
    setState(() {
      selectedType = "Feedback";
    });

    int stationRating = 0;
    int busConditionRating = 0;
    int drivingSafetyRating = 0;
    int driverMannersRating = 0;
    int overallSatisfactionRating = 0;

    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _t(en: "Help & Feedback", th: "ช่วยเหลือ & ข้อเสนอแนะ"),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.kanit(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.kanit(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _ratingScaleLegend(),
                      const SizedBox(height: 12),
                      _feedbackRatingQuestion(
                        number: 1,
                        title: _t(
                          en: "Station service condition *",
                          th: "สภาพของสถานีที่ให้บริการระดับใด *",
                        ),
                        value: stationRating,
                        onChanged: (rating) {
                          setDialogState(() {
                            stationRating = rating;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      _feedbackRatingQuestion(
                        number: 2,
                        title: _t(
                          en: "Bus condition *",
                          th: "สภาพของรถที่ให้บริการระดับใด *",
                        ),
                        value: busConditionRating,
                        onChanged: (rating) {
                          setDialogState(() {
                            busConditionRating = rating;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      _feedbackRatingQuestion(
                        number: 3,
                        title: _t(
                          en: "Driving manners and passenger safety *",
                          th: "มารยาทในการขับขี่ของพนักงานขับรถและความปลอดภัยในการโดยสาร ระดับใด *",
                        ),
                        value: drivingSafetyRating,
                        onChanged: (rating) {
                          setDialogState(() {
                            drivingSafetyRating = rating;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      _feedbackRatingQuestion(
                        number: 4,
                        title: _t(
                          en: "Driver politeness and conduct *",
                          th: "กิริยามารยาทของพนักงานขับรถมีความเหมาะสม สุภาพเรียบร้อย ระดับใด *",
                        ),
                        value: driverMannersRating,
                        onChanged: (rating) {
                          setDialogState(() {
                            driverMannersRating = rating;
                          });
                        },
                      ),
                      const SizedBox(height: 8),
                      _feedbackRatingQuestion(
                        number: 5,
                        title: _t(
                          en: "Overall MFU shuttle bus satisfaction *",
                          th: "ท่านมีความพึงพอใจต่อการให้บริการของรถโดยสารรับ-ส่ง ภายในมหาวิทยาลัย แม่ฟ้าหลวง ระดับใด *",
                        ),
                        value: overallSatisfactionRating,
                        onChanged: (rating) {
                          setDialogState(() {
                            overallSatisfactionRating = rating;
                          });
                        },
                      ),
                      const SizedBox(height: 14),
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

                              if (stationRating == 0 ||
                                  busConditionRating == 0 ||
                                  drivingSafetyRating == 0 ||
                                  driverMannersRating == 0 ||
                                  overallSatisfactionRating == 0) {
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      _t(
                                        en: "Please complete all required fields",
                                        th: "กรุณากรอกข้อมูลที่จำเป็นให้ครบ",
                                      ),
                                    ),
                                  ),
                                );
                                return;
                              }

                              final feedbackDetail =
                                  "Station service rating: $stationRating/5 "
                                  "(${_ratingDescription(stationRating)})\n"
                                  "Bus condition rating: $busConditionRating/5 "
                                  "(${_ratingDescription(busConditionRating)})\n"
                                  "Driving manners and safety rating: $drivingSafetyRating/5 "
                                  "(${_ratingDescription(drivingSafetyRating)})\n"
                                  "Driver politeness rating: $driverMannersRating/5 "
                                  "(${_ratingDescription(driverMannersRating)})\n"
                                  "Overall satisfaction rating: $overallSatisfactionRating/5 "
                                  "(${_ratingDescription(overallSatisfactionRating)})";
                              final result = await ApiService.sendReport(
                                selectedType ?? "Feedback",
                                feedbackDetail,
                                "",
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
      },
    );
  }

  String _ratingDescription(int rating) {
    switch (rating) {
      case 1:
        return _t(en: "1 Needs improvement", th: "1 ควรปรับปรุง");
      case 2:
        return _t(en: "2 Poor", th: "2 น้อย");
      case 3:
        return _t(en: "3 Average", th: "3 ปานกลาง");
      case 4:
        return _t(en: "4 Good", th: "4 ดี");
      case 5:
        return _t(en: "5 Excellent", th: "5 ดีมาก");
      default:
        return "";
    }
  }

  Widget _ratingScaleLegend() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _t(
          en: "1 Needs improvement  •  2 Poor  •  3 Average  •  4 Good  •  5 Excellent",
          th: "1 ควรปรับปรุง  •  2 น้อย  •  3 ปานกลาง  •  4 ดี  •  5 ดีมาก",
        ),
        textAlign: TextAlign.center,
        style: GoogleFonts.kanit(
          color: Colors.grey.shade700,
          fontSize: 11,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _feedbackRatingQuestion({
    required int number,
    required String title,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E8E8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: Color(0xFFD2232A),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  "$number",
                  style: GoogleFonts.kanit(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.kanit(
                    fontSize: 13,
                    height: 1.25,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: value == 0
                      ? Colors.grey.shade200
                      : const Color(0xFFFFF3D6),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  value == 0 ? "-" : "$value/5",
                  style: GoogleFonts.kanit(
                    color: value == 0
                        ? Colors.grey.shade600
                        : const Color(0xFFD2232A),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              final rating = index + 1;
              final isSelected = rating <= value;

              return IconButton(
                constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                padding: EdgeInsets.zero,
                icon: Icon(
                  isSelected ? Icons.star_rounded : Icons.star_border_rounded,
                  color: isSelected
                      ? const Color(0xFFFFB300)
                      : Colors.grey.shade400,
                  size: 26,
                ),
                onPressed: () => onChanged(rating),
              );
            }),
          ),
        ],
      ),
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
                      child: Transform.translate(
                        offset: const Offset(0, -6),
                        child: Center(
                          child: Text(
                            _t(
                              en: "Help & Feedback",
                              th: "ช่วยเหลือ & ข้อเสนอแนะ",
                            ),
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
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
                    Positioned(
                      right: 24,
                      top: backButtonTop,
                      child: SizedBox(
                        width: backButtonSize,
                        height: backButtonSize,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(
                            Icons.home_rounded,
                            color: Color(0xFF757575),
                            size: 25,
                          ),
                          onPressed: () {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const Homepages(),
                              ),
                              (route) => false,
                            );
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
                buildReportItem(
                  Icons.star,
                  "Feedback",
                  _t(en: "Feedback", th: "ส่งข้อเสนอแนะ"),
                  Colors.green,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
