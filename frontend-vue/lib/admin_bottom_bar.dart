import 'package:flutter/material.dart';
import 'package:shuttle_bus_fronted/AdminAccountPage.dart';
import 'package:shuttle_bus_fronted/AdminBusPages.dart';
import 'package:shuttle_bus_fronted/account_user.dart';
import 'package:shuttle_bus_fronted/bus_page.dart';
import 'package:shuttle_bus_fronted/dashboard_report.dart';
import 'admin_homepage.dart';

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
        page = const DashboardReport();
        break;
      case 3:
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
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white,
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

  _item(context, const Icon(Icons.warning_amber_rounded), "Reports", 2),
  _item(context, const Icon(Icons.person), "Account", 3),
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
            color: isActive ? Colors.grey.shade200 : Colors.transparent,
            shape: BoxShape.circle,
          ),
          child: icon,
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    ),
  );
}
}