import 'package:flutter/material.dart';
import 'package:chillzone/pages/login.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
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
