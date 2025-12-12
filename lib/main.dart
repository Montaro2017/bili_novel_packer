import 'package:bili_novel_packer/page/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});


  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: .fromSeed(seedColor: Colors.deepPurple),
        fontFamily: "MiSans",
        fontFamilyFallback: [
          'MiSans',
          'Helvetica Neue',
          'PingFang SC',
          'Source Han Sans SC',
          'Noto Sans CJK SC',
        ],
      ),
      initialRoute: '/home',
      routes: routes,
    );
  }
}
