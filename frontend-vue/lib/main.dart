import 'package:flutter/material.dart';
import 'package:shuttle_bus_fronted/signin01.dart';
import 'bus_controller.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  BusController.instance.start();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Signin01(),
    );
  }
}
