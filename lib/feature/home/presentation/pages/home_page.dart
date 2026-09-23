import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/ui/responsive/app_responsive.dart';
import '../../../../core/ui/widgets/app_splash.dart';
import '../../../farm/presentation/pages/farm_page.dart';
import '../../../lucky_wheel/presentation/pages/lucky_wheel_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../ranking/presentation/pages/ranking_page.dart';
import '../../../store/presentation/pages/store_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

extension HomeRouter on HomePage {
  static const path = '/home';

  static GoRoute goRoute() =>
      GoRoute(path: path, builder: (context, state) => const HomePage());
}

class _HomePageState extends State<HomePage> {
  static const _itemCount = 8;
  static const _initialPrecacheCount = 3;

  bool _precacheStarted = false;
  bool _initialImagesReady = false;
  bool _nativeSplashRemovalScheduled = false;
  late int _initialDecodeWidth;

  ImageProvider<Object> _imageProvider(int number, int decodeWidth) {
    return ResizeImage.resizeIfNeeded(
      decodeWidth,
      null,
      AssetImage('assets/background/prehistoric-level-map-0$number-sharp.webp'),
    );
  }

  int _decodeWidthFor(Size viewport, double pixelRatio) {
    final logicalWidth = math.min(viewport.width, AppResponsive.maxMapWidth);
    return (logicalWidth * pixelRatio).round();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _scheduleNativeSplashRemoval();
    if (_precacheStarted) return;

    _precacheStarted = true;
    final mediaQuery = MediaQuery.of(context);
    _initialDecodeWidth = _decodeWidthFor(
      mediaQuery.size,
      mediaQuery.devicePixelRatio,
    );
    _prepareInitialImages();
  }

  void _scheduleNativeSplashRemoval() {
    if (_nativeSplashRemovalScheduled) return;
    _nativeSplashRemovalScheduled = true;
    precacheImage(
      const AssetImage('assets/splash/splash.png'),
      context,
    ).whenComplete(() {
      if (!mounted) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        FlutterNativeSplash.remove();
      });
    });
  }

  Future<void> _prepareInitialImages() async {
    try {
      await Future.wait(
        List.generate(
          _initialPrecacheCount,
          (index) => precacheImage(
            _imageProvider(_itemCount - index, _initialDecodeWidth),
            context,
          ),
        ),
      );
    } catch (error, stackTrace) {
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
        await precacheImage(
          _imageProvider(number, _initialDecodeWidth),
          context,
        );
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
    if (!_initialImagesReady) return const AppSplash();

    return Scaffold(
      backgroundColor: const Color(0xff102d26),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final mediaQuery = MediaQuery.of(context);
          final viewport = Size(constraints.maxWidth, constraints.maxHeight);
          final decodeWidth = _decodeWidthFor(
            viewport,
            mediaQuery.devicePixelRatio,
          );
          final mapWidth = math.min(viewport.width, AppResponsive.maxMapWidth);

          return Stack(
            children: [
              const Positioned.fill(child: _MapSideBackground()),
              Align(
                alignment: Alignment.center,
                child: SizedBox(
                  width: mapWidth,
                  height: viewport.height,
                  child: _LevelMap(
                    itemCount: _itemCount,
                    decodeWidth: decodeWidth,
                    imageProvider: _imageProvider,
                  ),
                ),
              ),
              Positioned(
                top: mediaQuery.padding.top + 8,
                left: mediaQuery.padding.left + 8,
                right: mediaQuery.padding.right + 8,
                child: _HomeHud(
                  viewport: viewport,
                  onProfile: () => context.push(ProfileRouter.path),
                  onStore: () => context.push(StoreRouter.path),
                  onFarm: () => context.push(FarmRouter.path),
                  onLucky: () => context.push(LuckyWheelRouter.path),
                  onRanking: () => context.push(RankingRouter.path),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LevelMap extends StatelessWidget {
  const _LevelMap({
    required this.itemCount,
    required this.decodeWidth,
    required this.imageProvider,
  });

  final int itemCount;
  final int decodeWidth;
  final ImageProvider<Object> Function(int number, int decodeWidth)
  imageProvider;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      key: const PageStorageKey('home-level-map'),
      padding: EdgeInsets.zero,
      scrollCacheExtent: ScrollCacheExtent.pixels(500),
      itemCount: itemCount,
      reverse: true,
      itemBuilder: (context, index) {
        return Image(
          image: imageProvider(itemCount - index, decodeWidth),
          gaplessPlayback: true,
          width: double.infinity,
          fit: BoxFit.fitWidth,
          filterQuality: FilterQuality.medium,
        );
      },
    );
  }
}

class _MapSideBackground extends StatelessWidget {
  const _MapSideBackground();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xff071b17), Color(0xff1b4b36), Color(0xff071b17)],
        ),
      ),
    );
  }
}

class _HomeHud extends StatelessWidget {
  const _HomeHud({
    required this.viewport,
    required this.onProfile,
    required this.onStore,
    required this.onFarm,
    required this.onLucky,
    required this.onRanking,
  });

  final Size viewport;
  final VoidCallback onProfile;
  final VoidCallback onStore;
  final VoidCallback onFarm;
  final VoidCallback onLucky;
  final VoidCallback onRanking;

  @override
  Widget build(BuildContext context) {
    final landscape = viewport.width > viewport.height;
    final heightLimit = viewport.height * (landscape ? .38 : .42);
    final double width = math.min(
      math.min(viewport.width * .75, 540.0),
      heightLimit * 2.4,
    );
    final actions = [
      _HudAction('Profile', Icons.person_rounded, onProfile),
      _HudAction('Store', Icons.storefront_rounded, onStore),
      _HudAction('Farm', Icons.park_rounded, onFarm),
      _HudAction('Lucky', Icons.casino_rounded, onLucky),
      _HudAction('Ranking', Icons.emoji_events_rounded, onRanking),
    ];

    return Center(
      child: SizedBox(
        width: width,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Positioned(top: -18, left: width * .16, child: const _Rope()),
            Positioned(top: -18, right: width * .16, child: const _Rope()),
            Container(
              padding: EdgeInsets.fromLTRB(
                width * .035,
                width * .045,
                width * .035,
                width * .025,
              ),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xff9d5b2c), Color(0xff5b2f19)],
                ),
                borderRadius: BorderRadius.circular(width * .045),
                border: Border.all(
                  color: const Color(0xffffd36b),
                  width: math.max(2.0, width * .009),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x88000000),
                    blurRadius: 10,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final action in actions)
                    Expanded(
                      child: _HudButton(action: action, width: width),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Rope extends StatelessWidget {
  const _Rope();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 5,
      height: 24,
      decoration: BoxDecoration(
        color: const Color(0xffd1a15a),
        borderRadius: BorderRadius.circular(3),
        boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 2)],
      ),
    );
  }
}

class _HudAction {
  const _HudAction(this.label, this.icon, this.onTap);

  final String label;
  final IconData icon;
  final VoidCallback onTap;
}

class _HudButton extends StatelessWidget {
  const _HudButton({required this.action, required this.width});

  final _HudAction action;
  final double width;

  @override
  Widget build(BuildContext context) {
    final iconSize = width * .092;
    return Tooltip(
      message: action.label,
      child: InkWell(
        borderRadius: BorderRadius.circular(iconSize),
        onTap: action.onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: iconSize,
                height: iconSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xffffef9a), Color(0xffe58a2a)],
                  ),
                  border: Border.all(color: const Color(0xfffff0b5), width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black45,
                      blurRadius: 3,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Icon(
                  action.icon,
                  size: iconSize * .58,
                  color: const Color(0xff4b2716),
                ),
              ),
              const SizedBox(height: 3),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  action.label,
                  maxLines: 1,
                  style: TextStyle(
                    color: const Color(0xffffedb2),
                    fontSize: math.max(8, width * .025),
                    fontWeight: FontWeight.w800,
                    shadows: const [Shadow(color: Colors.black, blurRadius: 2)],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
