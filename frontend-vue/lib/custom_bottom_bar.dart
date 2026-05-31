import 'package:flutter/material.dart';
import 'package:shuttle_bus_fronted/account_user.dart';
import 'package:shuttle_bus_fronted/homepages.dart';
import 'package:shuttle_bus_fronted/bus_page.dart';

class CustomBottomBar extends StatelessWidget {
  final int currentIndex;

  const CustomBottomBar({super.key, required this.currentIndex});

  void _navigate(BuildContext context, int index) {
    if (index == currentIndex) return;

    Widget page;

    switch (index) {
      case 0:
        page = const Homepages();
        break;
      case 1:
        page = const BusPage();
        break;
      case 2:
        page = const AccountUser();
        break;
      default:
        page = const Homepages();
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => page),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 5),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _item(context, Icons.home, "Home", 0),
          _busItem(context),
          _item(context, Icons.person, "Account", 2),
        ],
      ),
    );
  }

  Widget _item(BuildContext context, IconData icon, String label, int index) {
    final isActive = currentIndex == index;

    return GestureDetector(
      onTap: () => _navigate(context, index),
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
            child: Icon(icon, color: isActive ? Colors.black : Colors.black),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: Colors.black, fontSize: 12)),
        ],
      ),
    );
  }

  // Bus Menu
  Widget _busItem(BuildContext context) {
    final isActive = currentIndex == 1;

    return GestureDetector(
      onTap: () => _navigate(context, 1),
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
            child: Image.asset('assets/bus.png', height: 24),
          ),
          const SizedBox(height: 4),
          Text("Bus", style: TextStyle(color: Colors.black, fontSize: 12)),
        ],
      ),
    );
  }
}
