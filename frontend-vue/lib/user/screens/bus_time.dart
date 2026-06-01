import 'package:flutter/material.dart';

class BusTimePage extends StatelessWidget {
  final String stationName;

  const BusTimePage({super.key, required this.stationName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const SizedBox(height: 10),

              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const SizedBox(width: 10),

                    // 🔥 dynamic station
                    Expanded(
                      child: Text(
                        stationName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Table
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xffEDEDED),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _header("เลขรถ")),
                        const SizedBox(width: 8),
                        Expanded(child: _header("เวลาถึง")),
                      ],
                    ),
                    const SizedBox(height: 12),

                    _row("01", "กำลังเข้าสถานี"),
                    _row("02", "3 นาที"),
                    _row("03", "8 นาที"),
                    _row("04", "15 นาที"),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[400],
        borderRadius: BorderRadius.circular(20),
      ),
      alignment: Alignment.center,
      child: Text(text),
    );
  }

  Widget _row(String bus, String time) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 60, child: Text(bus, textAlign: TextAlign.center)),
          const SizedBox(width: 80),
          Expanded(child: Text(time, textAlign: TextAlign.center)),
        ],
      ),
    );
  }
}
