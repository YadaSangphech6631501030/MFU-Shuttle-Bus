import 'package:flutter/material.dart';
import 'AdminAccountPage.dart';
import 'AdminBusPages.dart';
import 'dashboard_report.dart';
import 'admin_homepage.dart';
import 'admin_station_page.dart';

class AdminBottomBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap; // ✅ เพิ่มตรงนี้

  const AdminBottomBar({
    super.key,
    required this.currentIndex,
    required this.onTap, // ✅ รับค่า
  });

  void _navigate(BuildContext context, int index) {
    Widget page;

    switch (index) {
      case 0:
        page = const AdminHomepage();
        break;
      case 1:
        page = const Adminbuspages();
        break;
      case 2:
        page = const AdminStationPage();
        break;
      case 3:
        page = const DashboardReport();
        break;
      case 4:
        page = const Adminaccountpage();
        break;
      default:
        page = const AdminHomepage();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 105,
      decoration: BoxDecoration(
        color: Color(0xFFD2232A),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 5,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
  _item(context, const Icon(Icons.home), "Home", 0),

  _item(
    context,
    Image.asset(
      'assets/bus.png',
      height: 24,
    ),
    "Bus",
    1,
  ),

  _item(context, const Icon(Icons.location_on_outlined), "Station", 2),
  _item(context, const Icon(Icons.warning_amber_rounded), "Reports", 3),
  _item(context, const Icon(Icons.person), "Account", 4),
],
      ),
    );
  }

  Widget _item(BuildContext context, Widget icon, String label, int index) {
  final isActive = currentIndex == index;

  return GestureDetector(
    onTap: () {
      onTap(index);
      _navigate(context, index);
    },
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive ? Colors.white.withOpacity(0.16) : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: IconTheme(
            data: const IconThemeData(color: Colors.white),
            child: icon,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
      ],
    ),
  );
}
}
