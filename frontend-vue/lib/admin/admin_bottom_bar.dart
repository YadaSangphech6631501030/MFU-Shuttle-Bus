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
          _item(
            context,
            outlineIcon: Icons.home_outlined,
            filledIcon: Icons.home,
            label: "Home",
            index: 0,
          ),
          _busItem(context),
          _item(
            context,
            outlineIcon: Icons.location_on_outlined,
            filledIcon: Icons.location_on,
            label: "Station",
            index: 2,
          ),
          _item(
            context,
            outlineIcon: Icons.warning_amber_outlined,
            filledIcon: Icons.warning_amber_rounded,
            label: "Reports",
            index: 3,
          ),
          _item(
            context,
            outlineIcon: Icons.person_outline,
            filledIcon: Icons.person,
            label: "Account",
            index: 4,
          ),
        ],
      ),
    );
  }

  Widget _item(
    BuildContext context, {
    required IconData outlineIcon,
    required IconData filledIcon,
    required String label,
    required int index,
  }) {
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
            
            child: Icon(
              isActive ? filledIcon : outlineIcon,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _busItem(BuildContext context) {
    final isActive = currentIndex == 1;

    return GestureDetector(
      onTap: () {
        onTap(1);
        _navigate(context, 1);
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.white.withOpacity(0.16)
                  : Colors.transparent,
              shape: BoxShape.circle,
            ),
            child: Image.asset('assets/bus.png', height: 24),
          ),
          const SizedBox(height: 4),
          const Text(
            "Bus",
            style: TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
