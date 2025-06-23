import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:smartfarming_bapeltan/screens/home.dart';
import 'package:smartfarming_bapeltan/screens/main_navigation.dart';
import 'package:smartfarming_bapeltan/screens/splash_screen.dart';

/// main program untuk memulai aplikasi
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp])
      .then((_) {
    runApp(const BapeltanApp());
  });
  // runApp(MaterialApp(
  //   home: Home(),
  // ));
}

class BapeltanApp extends StatelessWidget {
  const BapeltanApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "BapeltanApp",
      theme: ThemeData(
        fontFamily: 'Montserrat',
      ),
      home: SplashScreen(),
    );
  }
}
