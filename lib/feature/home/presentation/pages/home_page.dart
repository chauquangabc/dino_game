import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:go_router/go_router.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

extension HomeRouter on HomePage {
  static const path = '/home';

  static GoRoute goRoute() =>
      GoRoute(path: path, builder: (context, state) => HomePage());
}

class _HomePageState extends State<HomePage> {
  static const int _itemCount = 8;
  static const int _initialPrecacheCount = 3;

  bool _precacheStarted = false;
  bool _initialImagesReady = false;
  late int _decodeWidth;

  ImageProvider<Object> _imageProvider(int number) {
    return ResizeImage.resizeIfNeeded(
      _decodeWidth,
      null,
      AssetImage('assets/background/prehistoric-level-map-0$number-sharp.webp'),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_precacheStarted) return;

    _precacheStarted = true;
    final mediaQuery = MediaQuery.of(context);
    _decodeWidth = (mediaQuery.size.width * mediaQuery.devicePixelRatio)
        .round();
    _prepareInitialImages();
  }

  Future<void> _prepareInitialImages() async {
    try {
      await Future.wait(
        List.generate(
          _initialPrecacheCount,
          (index) => precacheImage(_imageProvider(_itemCount - index), context),
        ),
      );
    } catch (error, stackTrace) {
      // Không giữ native splash vĩnh viễn nếu một asset bị lỗi.
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'home asset preloader',
        ),
      );
    }

    if (!mounted) return;
    setState(() => _initialImagesReady = true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
      _precacheRemainingImages();
    });
  }

  Future<void> _precacheRemainingImages() async {
    for (
      var number = _itemCount - _initialPrecacheCount;
      number >= 1;
      number--
    ) {
      if (!mounted) return;
      try {
        await precacheImage(_imageProvider(number), context);
      } catch (error, stackTrace) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stackTrace,
            library: 'home asset preloader',
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialImagesReady) {
      // Widget vẫn đang được native splash che trong lúc decode ảnh đầu tiên.
      return const SizedBox.expand();
    }

    return Scaffold(
      body: ListView.builder(
        scrollCacheExtent: ScrollCacheExtent.pixels(500),
        itemCount: _itemCount,
        reverse: true,
        itemBuilder: (context, index) {
          return Image(
            image: _imageProvider(_itemCount - index),
            gaplessPlayback: true,
            width: double.infinity,
            fit: BoxFit.fitWidth,
            filterQuality: FilterQuality.medium,
          );
        },
      ),
    );
  }
}
