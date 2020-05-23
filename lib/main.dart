import 'package:flutter/material.dart';
import 'package:chillzone/pages/login.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChillZone',
      theme: ThemeData(
        primaryColor: Colors.white,
      ),
      home: Login(title: 'ChillZone'),
    );
  }
}
