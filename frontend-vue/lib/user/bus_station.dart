import 'package:flutter/material.dart';

class BusStationPage extends StatelessWidget {
  const BusStationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    IconButton(
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
                    const Expanded(
                      child: Center(
                        child: Text(
                          "MFU TRANSIT",
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),

                const SizedBox(height: 20),

                // สาย 1
                const LineSection(
                  title: "สาย 1",
                  stations: [
                    "01 จุดหอพักลำดวน 2",
                    "02 จุดพักลำดวน 7 ขาเข้า",
                    "03 แยกบ้านพักบุคลากร",
                    "04 อาคารพิพิธภัณฑ์ D2",
                    "05 หอพักจีน ขาเข้า",
                    "06 ศูนย์จีน ขาเข้า",
                    "07 ลานจอด F",
                    "08 อาคาร D1",
                    "09 สระน้ำวงรี",
                    "10 อาคาร E2 ขาเข้า",
                    "11 หอประชุม C4",
                    "12 อาคาร C5",
                    "13 อาคาร E2 ขาออก",
                    "14 อาคาร M-Square",
                    "15 ศูนย์จีน ขาออก",
                    "16 หอพักจีน ขาออก",
                    "17 ศุนย์ลำดวน",
                    "18 ทางเข้า สระว่ายน้ำ",
                    "19 หอพักลำดวน 7 ขาเข้า",
                    "20 ศูนย์อาหารลำดวน",
                    "21 มินิมาร์ทลำดวน",
                    "22 โรงพยาบาล มใแม่ฟ้าหลวง",
                  ],
                ),

                const SizedBox(height: 16),

                // สาย 2
                const LineSection(
                  title: "สาย 2 (โรงพยาบาลแม่ฟ้าหลวง)",
                  stations: [
                    "01 จุดหอพักลำดวน 2",
                    "02 จุดพักลำดวน 7 ขาเข้า",
                    "03 แยกบ้านพักบุคลากร",
                    "04 อาคารพิพิธภัณฑ์ D2",
                    "05 หอพักจีน ขาเข้า",
                    "06 ศูนย์จีน ขาเข้า",
                    "07 ลานจอด F",
                    "08 อาคาร D1",
                    "09 สระน้ำวงรี",
                    "10 อาคาร E2 ขาเข้า",
                    "11 หอประชุม C4",
                    "12 อาคาร C5",
                    "13 อาคาร E2 ขาออก",
                    "14 อาคาร M-Square",
                    "15 ศูนย์จีน ขาออก",
                    "16 หอพักจีน ขาออก",
                    "17 ศุนย์ลำดวน",
                    "18 ทางเข้า สระว่ายน้ำ",
                    "19 หอพักลำดวน 7 ขาเข้า",
                    "20 ศูนย์อาหารลำดวน",
                    "21 มินิมาร์ทลำดวน",
                    "22 โรงพยาบาล มใแม่ฟ้าหลวง",
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  } //
}

class LineSection extends StatefulWidget {
  final String title;
  final List<String> stations;

  const LineSection({super.key, required this.title, required this.stations});

  @override
  State<LineSection> createState() => _LineSectionState();
}

class _LineSectionState extends State<LineSection> {
  String search = "";
  bool isOpen = false;

  Color _getLineColor() {
    if (widget.title.contains("สาย 1")) {
      return const Color(0xFFD4AF37); // Gold color for Line 1
    } else if (widget.title.contains("สาย 2")) {
      return const Color(0xFFE53935); // Red color for Line 2
    }
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.stations
        .where((s) => s.toLowerCase().contains(search.toLowerCase()))
        .toList();

    final lineColor = _getLineColor();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // popup open/close
        GestureDetector(
          onTap: () {
            setState(() {
              isOpen = !isOpen;
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: lineColor,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                if (isOpen)
                  const BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: isOpen
                      ? const Icon(
                          Icons.remove,
                          color: Colors.white,
                          size: 16,
                        )
                      : const Icon(
                          Icons.add,
                          color: Colors.white,
                          size: 16,
                        ),
                ),
                const SizedBox(width: 12),
                Text(
                  widget.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 10),

        AnimatedCrossFade(
          duration: const Duration(milliseconds: 200),
          crossFadeState: isOpen
              ? CrossFadeState.showFirst
              : CrossFadeState.showSecond,

          firstChild: Column(
            children: [
              // Search
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 4),
                  ],
                ),
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      search = value;
                    });
                  },
                  decoration: const InputDecoration(
                    hintText: "Find Station...",
                    prefixIcon: Icon(Icons.search),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Station List
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xffEDEDED),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 4),
                  ],
                ),
                child: Column(
                  children: filtered.isEmpty
                      ? [
                          const Padding(
                            padding: EdgeInsets.all(16),
                            child: Text("ไม่พบสถานี"),
                          ),
                        ]
                      : filtered.map((station) {
                          return Column(
                            children: [
                              ListTile(
                                title: Text(station),
                              ),
                              const Divider(height: 1),
                            ],
                          );
                        }).toList(),
                ),
              ),
            ],
          ),
          secondChild: const SizedBox.shrink(),
        ),
      ],
    );
  }
}
