import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

Future<void> main() async {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  static const int _itemCount = 8;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);

    final screenWidth = mediaQuery.size.width;
    final dpr = mediaQuery.devicePixelRatio;

    // cacheWidth dùng physical pixel
    final decodeWidth = (screenWidth * dpr).round();

    return Scaffold(
      body: ListView.builder(
        scrollCacheExtent: ScrollCacheExtent.pixels(500),
        itemCount: _itemCount,
        reverse: true,
        itemBuilder: (context, index) {
          return Image.asset(
            gaplessPlayback: true,
            'assets/background/prehistoric-level-map-0${_itemCount - index}-sharp.webp',
            width: double.infinity,
            fit: BoxFit.fitWidth,
            cacheWidth: decodeWidth,
            filterQuality: FilterQuality.medium,
          );
        },
      ),
    );
  }
}
