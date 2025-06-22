// import 'dart:async';

// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:smartfarming_bapeltan/common/app_colors.dart';
// import 'package:smartfarming_bapeltan/screens/home.dart';
// import 'package:smartfarming_bapeltan/screens/login_screen.dart';

// class SplashScreen extends StatefulWidget {
//   const SplashScreen({Key? key}) : super(key: key);

//   @override
//   State<SplashScreen> createState() => _SplashScreenState();
// }

// class _SplashScreenState extends State<SplashScreen> {
//   @override
//   void initState() {
//     super.initState();
//     autoLogin();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Container(
//           height: double.infinity,
//           width: double.infinity,
//           color: Colors.white,
//           child: Stack(
//             children: [
//               Center(
//     child: Container(
//   height: 130,
//   width: 130,
//   decoration: BoxDecoration(
//       image: DecorationImage(
//           image: AssetImage('assets/images/logo.png'))),
// )),
//               Padding(
//                 padding: EdgeInsets.only(bottom: 50),
//                 child: Align(
//                   alignment: Alignment.bottomCenter,
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       Container(
//                         height: 50,
//                         width: 50,
//                         // color: AppColor.kuning,
//                         decoration: BoxDecoration(
//                             image: DecorationImage(
//                                 image: AssetImage('assets/images/kementan.png'),
//                                 fit: BoxFit.cover)),
//                       ),
//                       SizedBox(
//                         width: 14,
//                       ),
//                       Text(
//                         "BPP Lampung\nterdepan memberi manfaat",
//                         style: TextStyle(
//                             fontWeight: FontWeight.bold,
//                             color: AppColor.hijau1),
//                       )
//                     ],
//                   ),
//                 ),
//               )
//             ],
//           )),
//     );
//   }

//   Future<void> autoLogin() async {
//     SharedPreferences pref = await SharedPreferences.getInstance();
//     int? userId = pref.getInt('id');

//     if (userId == null) {
//       /// delay 3 second
//       Timer(
//         const Duration(seconds: 3),
//         () => Navigator.of(context).pushReplacement(
//           MaterialPageRoute(
//             builder: (BuildContext context) => const LoginScreen(),
//           ),
//         ),
//       );
//     } else {
//       /// delay 3 second
//       Timer(
//         const Duration(seconds: 3),
//         () => Navigator.of(context).pushReplacement(
//           MaterialPageRoute(
//             builder: (BuildContext context) => const Home(),
//           ),
//         ),
//       );
//     }
//   }
// }

// ignore_for_file: prefer_const_constructors

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartfarming_bapeltan/common/app_colors.dart';
import 'package:smartfarming_bapeltan/screens/home.dart';
import 'package:smartfarming_bapeltan/screens/login_screen.dart';

class SplashScreen extends StatefulWidget {
  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  double _fontSize = 2;
  double _containerSize = 1.5;
  double _textOpacity = 0.0;
  double _containerOpacity = 0.0;

  late AnimationController _controller;
  late Animation<double> animation1;

  @override
  void initState() {
    super.initState();

    _initBlock();

    _controller =
        AnimationController(vsync: this, duration: Duration(seconds: 3));

    animation1 = Tween<double>(begin: 80, end: 20).animate(CurvedAnimation(
        parent: _controller, curve: Curves.fastLinearToSlowEaseIn))
      ..addListener(() {
        setState(() {
          _textOpacity = 1.0;
        });
      });

    _controller.forward();

    Timer(Duration(seconds: 2), () {
      setState(() {
        _fontSize = 1.06;
      });
    });

    Timer(Duration(seconds: 2), () {
      setState(() {
        _containerSize = 2;
        _containerOpacity = 1;
      });
    });

    Timer(Duration(seconds: 1), () {
      setState(() {
        // Navigator.pushReplacement(context, PageTransition(LoginScreen()));
        autoLogin();
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double _width = MediaQuery.of(context).size.width;
    double _height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Column(
            children: [
              AnimatedContainer(
                  duration: Duration(milliseconds: 2000),
                  curve: Curves.fastLinearToSlowEaseIn,
                  height: _height * 0.92 / _fontSize),
              AnimatedOpacity(
                duration: Duration(milliseconds: 1000),
                opacity: _textOpacity,
                // child: Text(
                //   'BPPL',
                //   style: TextStyle(
                //     color: AppColor.hijau1,
                //     fontWeight: FontWeight.bold,
                //     fontSize: animation1.value,
                //   ),
                // ),
                child: Column(
                  children: [
                    Text(
                      "from",
                      style: TextStyle(
                          color: AppColor.abu, fontWeight: FontWeight.bold),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          height: 50,
                          width: 50,
                          // color: AppColor.kuning,
                          decoration: BoxDecoration(
                              image: DecorationImage(
                                  image:
                                      AssetImage('assets/images/kementan.png'),
                                  fit: BoxFit.cover)),
                        ),
                        SizedBox(
                          width: 14,
                        ),
                        Text(
                          "BPP Lampung\nTerdepan Memberi Manfaat",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColor.hijau1,
                          ),
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          Center(
            child: AnimatedOpacity(
              duration: Duration(milliseconds: 2000),
              curve: Curves.fastLinearToSlowEaseIn,
              opacity: _containerOpacity,
              child: AnimatedContainer(
                duration: Duration(milliseconds: 2000),
                curve: Curves.fastLinearToSlowEaseIn,
                height: _width / _containerSize,
                width: _width / _containerSize,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(30),
                ),
                // child: Image.asset('assets/images/logo.png')
                child: Column(
                  children: [
                    Container(
                      height: 130,
                      width: 130,
                      decoration: BoxDecoration(
                          image: DecorationImage(
                              image: AssetImage('assets/images/logo.png'))),
                    ),
                    SizedBox(
                      height: 12,
                    ),
                    Text(
                      "Low Cost",
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color.fromARGB(255, 209, 155, 54)),
                    ),
                    Text(
                      "SmartFarming",
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColor.hijau1),
                    ),
                  ],
                ),
                // child: Text(
                //   'YOUR APP\'S LOGO',
                // ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> autoLogin() async {
    SharedPreferences pref = await SharedPreferences.getInstance();
    int? userId = pref.getInt('id');

    if (userId == null) {
      /// delay 3 second
      Timer(
        const Duration(seconds: 3),
        () => Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (BuildContext context) => const LoginScreen(),
          ),
        ),
      );
    } else {
      /// delay 3 second
      Timer(
        const Duration(seconds: 3),
        () => Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (BuildContext context) => const Home(),
          ),
        ),
      );
    }
  }
}

Future<void> _initBlock() async {
  SharedPreferences pref = await SharedPreferences.getInstance();
  pref.setBool('blocked', false);
}

class PageTransition extends PageRouteBuilder {
  final Widget page;

  PageTransition(this.page)
      : super(
          pageBuilder: (context, animation, anotherAnimation) => page,
          transitionDuration: Duration(milliseconds: 2000),
          transitionsBuilder: (context, animation, anotherAnimation, child) {
            animation = CurvedAnimation(
              curve: Curves.fastLinearToSlowEaseIn,
              parent: animation,
            );
            return Align(
              alignment: Alignment.bottomCenter,
              child: SizeTransition(
                sizeFactor: animation,
                child: page,
                axisAlignment: 0,
              ),
            );
          },
        );
}
