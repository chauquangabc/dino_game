import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/ui/responsive/app_responsive.dart';
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
  static const _initialPrecacheCount = 5;

  bool _precacheStarted = false;
  bool _initialImagesReady = false;
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
    if (_precacheStarted) return;

    _precacheStarted = true;
    final mediaQuery = MediaQuery.of(context);
    _initialDecodeWidth = _decodeWidthFor(
      mediaQuery.size,
      mediaQuery.devicePixelRatio,
    );
    _prepareInitialImages();
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
    if (!_initialImagesReady) return const SizedBox.expand();

    return Scaffold(
      backgroundColor: Colors.blue[600],
      body: LayoutBuilder(
        builder: (context, constraints) {
          final mediaQuery = MediaQuery.of(context);
          final viewport = Size(constraints.maxWidth, constraints.maxHeight);
          final decodeWidth = _decodeWidthFor(
            viewport,
            mediaQuery.devicePixelRatio,
          );

          return Stack(
            children: [
              Align(
                alignment: Alignment.center,
                child: SizedBox(
                  height: viewport.height,
                  child: _LevelMap(
                    itemCount: _itemCount,
                    decodeWidth: decodeWidth,
                    imageProvider: _imageProvider,
                  ),
                ),
              ),
              Positioned(
                top: mediaQuery.padding.top,
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
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    return ListView.builder(
      key: const PageStorageKey('home-level-map'),
      padding: EdgeInsets.only(
        // top: 0,
        top: MediaQuery.viewPaddingOf(context).top,
        left: 0,
        right: 0,
        bottom: bottomInset,
      ),
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

  static const double _panelAspect = 809 / 1945;

  static const List<double> _slotXs = [
    0.15,
    0.3239,
    0.4995,
    0.6756,
    0.85,
  ]; //PositionX icon
  static const double _slotY = 0.533; //PositionY icon
  static const double _labelY = 0.79; //PositionY label
  static const double _slotRatio = 0.14; //Size icon
  static const double _labelRatioW = 0.18;
  static const double _labelRatioH = 0.038;

  @override
  Widget build(BuildContext context) {
    final landscape = viewport.width > viewport.height;
    final heightLimit = viewport.height * (landscape ? .38 : .42);
    final double width = math.min(
      math.min(viewport.width * .75, 540.0),
      heightLimit * 2.4,
    );
    final double height = width * _panelAspect;

    final actions = [
      _HudAction('Profile', 'assets/HUD/ring-profile-empty.webp', onProfile),
      _HudAction('Store', 'assets/HUD/store-icon.webp', onStore),
      _HudAction('Farm', 'assets/HUD/icon-dinosaur-farm.webp', onFarm),
      _HudAction('Lucky', 'assets/HUD/icon-lucky-wheel.webp', onLucky),
      _HudAction('Ranking', 'assets/HUD/leaderboard-icon.webp', onRanking),
    ];

    final slotSize = width * _slotRatio;

    return Center(
      child: SizedBox(
        width: width,
        height: height,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Image.asset(
                'assets/HUD/board_hud.webp',
                fit: BoxFit.fill,
                filterQuality: FilterQuality.medium,
              ),
            ),
            for (var i = 0; i < actions.length; i++) ...[
              // Icon trên bệ đá của từng ô.
              Positioned(
                left: (_slotXs[i] - _slotRatio / 2) * width,
                top: _slotY * height - slotSize / 2,
                width: slotSize,
                height: slotSize,
                child: _HudButton(action: actions[i]),
              ),
              // Bảng tên dưới bệ đá.
              Positioned(
                left: (_slotXs[i] - _labelRatioW / 2) * width,
                top: _labelY * height - (width * _labelRatioH) / 2,
                width: width * _labelRatioW,
                height: width * _labelRatioH,
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      actions[i].label,
                      maxLines: 1,
                      style: TextStyle(
                        color: const Color(0xff7a3f14),
                        fontSize: math.max(8, width * .03),
                        fontWeight: FontWeight.w700,
                        letterSpacing: .5,
                        shadows: const [
                          Shadow(color: Colors.white70, blurRadius: 1),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HudAction {
  const _HudAction(this.label, this.asset, this.onTap);

  final String label;
  final String asset;
  final VoidCallback onTap;
}

class _HudButton extends StatelessWidget {
  const _HudButton({required this.action});

  final _HudAction action;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: action.label,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: action.onTap,
        child: Image.asset(
          action.asset,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.medium,
        ),
      ),
    );
  }
}
