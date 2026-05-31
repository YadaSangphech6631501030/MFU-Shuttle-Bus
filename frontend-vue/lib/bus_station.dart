import 'package:flutter/material.dart';
import 'package:shuttle_bus_fronted/bus_time.dart';

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
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "MFU Transit",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // สาย 1
                const LineSection(
                  title: "สาย 1",
                  stations: [
                    "01 จุดหอพักลำดวน 2",
                    "02 จุดพักลำดวน 7 ขาเข้า",
                    "03 จุด หอพักจีน ขาเข้า",
                    "04 จุด ศูนย์จีน ขาเข้า",
                    "05 จุด ลานจอดหอพัก F",
                    "06 จุด อาคารโรงอาหาร D1",
                    "07 จุด สระน้ำวงรี ลานดาว",
                    "08 จุด อาคารโรงอาหาร E2 ขาเข้า",
                    "09 จุด อาคารเรียนรวม C3 C2 และ หอประชุมสมเด็จย่า C4",
                    "10 จุด อาคารเรียนรวม C5",
                    "11 จุด อาคาร m - square",
                    "12 จุด ศูนย์จีน ขาออก",
                    "13 จุด หอพักจีน ขาออก",
                    "14 จุด สนามกีฬากลาง",
                    "15 จุด หอพักลำดวน 7 ขาออก",
                    "16 จุด ครัวลำดวน",
                  ],
                ),

                const SizedBox(height: 16),

                // สาย 2
                const LineSection(
                  title: "สาย 2 (โรงพยาบาลแม่ฟ้าหลวง)",
                  stations: [
                    "01 จุดหอพักลำดวน 2",
                    "02 จุดพักลำดวน 7 ขาเข้า",
                    "03 จุด หอพักจีน ขาเข้า",
                    "04 จุด ศูนย์จีน ขาเข้า",
                    "05 จุด ลานจอดหอพัก F",
                    "06 จุด อาคารโรงอาหาร D1",
                    "07 จุด สระน้ำวงรี ลานดาว",
                    "08 จุด อาคารโรงอาหาร E2 ขาเข้า",
                    "09 จุด โรงพยาบาลแม่ฟ้าหลวง",
                    "10 จุด อาคาร m - square",
                    "11 จุด ศูนย์จีน ขาออก",
                    "12 จุด หอพักจีน ขาออก",
                    "13 จุด สนามกีฬากลาง",
                    "14 จุด หอพักลำดวน 7 ขาออก",
                    "15 จุด ครัวลำดวน",
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

  @override
  Widget build(BuildContext context) {
    final filtered = widget.stations
        .where((s) => s.toLowerCase().contains(search.toLowerCase()))
        .toList();

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
              color: isOpen ? Colors.black87 : Colors.black,
              borderRadius: BorderRadius.circular(18),
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
                Icon(
                  isOpen
                      ? Icons.remove_circle_outline
                      : Icons.add_circle_outline,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  widget.title,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
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
                                trailing: const Icon(
                                  Icons.arrow_forward_ios,
                                  size: 14,
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          BusTimePage(stationName: station),
                                    ),
                                  );
                                },
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
