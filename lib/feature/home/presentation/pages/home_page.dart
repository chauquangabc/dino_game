import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/ui/responsive/app_responsive.dart';
import '../../../farm/presentation/pages/farm_page.dart';
import '../../data/level_progress_repository.dart';
import '../../data/map_character_repository.dart';
import '../../domain/map_character_config.dart';
import '../../domain/map_level_config.dart';
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

  final LevelProgressRepository _progressRepository = LevelProgressRepository();
  final MapCharacterRepository _characterRepository = MapCharacterRepository();

  bool _precacheStarted = false;
  bool _homeReady = false;
  late int _initialDecodeWidth;
  int _unlockedLevel = 1;
  int _avatarLevel = 1;
  bool _avatarMoving = false;
  MapCharacter _selectedCharacter = MapCharacterConfig.babyDino;

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
    _initializeHome();
  }

  Future<void> _initializeHome() async {
    final progressFuture = _progressRepository.load();
    final characterFuture = _characterRepository.loadEquipped();
    final imagesFuture = _prepareInitialImages();

    final progress = await progressFuture;
    final character = await characterFuture;
    await _precacheInitialCharacters(character);
    await imagesFuture;

    if (!mounted) return;
    setState(() {
      _unlockedLevel = progress.unlockedLevel;
      _avatarLevel = progress.avatarLevel;
      _selectedCharacter = character;
      _homeReady = true;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      FlutterNativeSplash.remove();
      _precacheRemainingImages();
    });
  }

  Future<void> _precacheInitialCharacters(MapCharacter character) async {
    final assets = <String>{MapCharacterConfig.babyDino.asset, character.asset};
    for (final asset in assets) {
      if (!mounted) return;
      try {
        await precacheImage(AssetImage(asset), context);
      } catch (error, stackTrace) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stackTrace,
            library: 'home character preloader',
          ),
        );
      }
    }
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

  Future<void> _selectLevel(int level) async {
    if (level > _unlockedLevel || _avatarMoving) return;
    if (level == _avatarLevel) return;

    setState(() {
      _avatarMoving = true;
      _avatarLevel = level;
    });

    final saveFuture = _progressRepository.saveAvatarLevel(
      level,
      unlockedLevel: _unlockedLevel,
    );
    await Future.wait([
      saveFuture,
      Future<void>.delayed(const Duration(milliseconds: 720)),
    ]);
    if (!mounted) return;
    setState(() => _avatarMoving = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_homeReady) return const SizedBox.expand();

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
                    unlockedLevel: _unlockedLevel,
                    avatarLevel: _avatarLevel,
                    character: _selectedCharacter,
                    interactionEnabled: !_avatarMoving,
                    onLevelSelected: _selectLevel,
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

class _LevelMap extends StatefulWidget {
  const _LevelMap({
    required this.itemCount,
    required this.decodeWidth,
    required this.imageProvider,
    required this.unlockedLevel,
    required this.avatarLevel,
    required this.character,
    required this.interactionEnabled,
    required this.onLevelSelected,
  });

  final int itemCount;
  final int decodeWidth;
  final ImageProvider<Object> Function(int number, int decodeWidth)
  imageProvider;
  final int unlockedLevel;
  final int avatarLevel;
  final MapCharacter character;
  final bool interactionEnabled;
  final ValueChanged<int> onLevelSelected;

  @override
  State<_LevelMap> createState() => _LevelMapState();
}

class _LevelMapState extends State<_LevelMap> {
  final ScrollController _scrollController = ScrollController();

  Size? _lastViewport;
  int? _lastFocusedLevel;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scheduleFocus({
    required Size viewport,
    required double scale,
    required bool animate,
  }) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;

      final point = MapLevelConfig.points[widget.unlockedLevel - 1];
      final target = point.dy * scale - viewport.height / 2;
      final maxExtent = _scrollController.position.maxScrollExtent;
      final offset = target.clamp(0.0, maxExtent);

      if (animate) {
        _scrollController.animateTo(
          offset,
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutCubic,
        );
      } else {
        _scrollController.jumpTo(offset);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewPadding = MediaQuery.viewPaddingOf(context);

    return Padding(
      padding: EdgeInsets.only(
        top: viewPadding.top,
        bottom: viewPadding.bottom,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final viewport = Size(constraints.maxWidth, constraints.maxHeight);
          final scale = math.max(
            viewport.width / MapLevelConfig.sourceWidth,
            viewport.height / MapLevelConfig.segmentHeight,
          );
          final renderedWidth = MapLevelConfig.sourceWidth * scale;
          final segmentHeight = MapLevelConfig.segmentHeight * scale;
          final mapHeight = MapLevelConfig.sourceHeight * scale;
          final offsetX = (viewport.width - renderedWidth) / 2;
          final nodeSize = math.max(40.0, math.min(92.0, 88 * scale));

          final focusChanged = _lastFocusedLevel != widget.unlockedLevel;
          final viewportChanged = _lastViewport != viewport;
          if (focusChanged || viewportChanged) {
            final animate = _lastFocusedLevel != null && focusChanged;
            _lastFocusedLevel = widget.unlockedLevel;
            _lastViewport = viewport;
            _scheduleFocus(viewport: viewport, scale: scale, animate: animate);
          }

          return SingleChildScrollView(
            key: const PageStorageKey('home-level-map'),
            controller: _scrollController,
            child: SizedBox(
              width: viewport.width,
              height: mapHeight,
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  for (var i = 0; i < widget.itemCount; i++)
                    Positioned(
                      left: offsetX,
                      top: i * segmentHeight,
                      width: renderedWidth,
                      height: segmentHeight + 1,
                      child: Image(
                        image: widget.imageProvider(i + 1, widget.decodeWidth),
                        gaplessPlayback: true,
                        fit: BoxFit.fill,
                        filterQuality: FilterQuality.medium,
                      ),
                    ),
                  for (var i = 0; i < MapLevelConfig.points.length; i++)
                    _buildCheckpoint(
                      index: i,
                      scale: scale,
                      offsetX: offsetX,
                      nodeSize: nodeSize,
                    ),
                  _MapCharacterAvatar(
                    level: widget.avatarLevel,
                    character: widget.character,
                    scale: scale,
                    offsetX: offsetX,
                    nodeSize: nodeSize,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCheckpoint({
    required int index,
    required double scale,
    required double offsetX,
    required double nodeSize,
  }) {
    final level = index + 1;
    final point = MapLevelConfig.points[index];
    final status = MapLevelConfig.statusOf(level, widget.unlockedLevel);

    return Positioned(
      left: offsetX + point.dx * scale - nodeSize / 2,
      top: point.dy * scale - nodeSize * .56,
      width: nodeSize,
      height: nodeSize,
      child: _LevelCheckpoint(
        level: level,
        status: status,
        interactionEnabled: widget.interactionEnabled,
        onTap: () => widget.onLevelSelected(level),
      ),
    );
  }
}

class _MapCharacterAvatar extends StatefulWidget {
  const _MapCharacterAvatar({
    required this.level,
    required this.character,
    required this.scale,
    required this.offsetX,
    required this.nodeSize,
  });

  final int level;
  final MapCharacter character;
  final double scale;
  final double offsetX;
  final double nodeSize;

  @override
  State<_MapCharacterAvatar> createState() => _MapCharacterAvatarState();
}

class _MapCharacterAvatarState extends State<_MapCharacterAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _hopController;
  late final Animation<double> _hop;

  @override
  void initState() {
    super.initState();
    _hopController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _hop = TweenSequence<double>(
      [
        TweenSequenceItem(tween: Tween(begin: 0, end: -.16), weight: 1),
        TweenSequenceItem(tween: Tween(begin: -.16, end: 0), weight: 1),
        TweenSequenceItem(tween: Tween(begin: 0, end: -.16), weight: 1),
        TweenSequenceItem(tween: Tween(begin: -.16, end: 0), weight: 1),
      ],
    ).animate(CurvedAnimation(parent: _hopController, curve: Curves.easeInOut));
  }

  @override
  void didUpdateWidget(covariant _MapCharacterAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.level != widget.level) {
      _hopController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _hopController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final point = MapLevelConfig.points[widget.level - 1];
    final avatarSize = widget.nodeSize * 1.25;
    final bottomY = point.dy * widget.scale + widget.nodeSize * .06;

    return AnimatedPositioned(
      key: const ValueKey('home-map-character'),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeInOut,
      left: widget.offsetX + point.dx * widget.scale - avatarSize / 2,
      top: bottomY - avatarSize,
      width: avatarSize,
      height: avatarSize,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _hop,
          builder: (context, child) => Transform.translate(
            offset: Offset(0, _hop.value * avatarSize),
            child: child,
          ),
          child: Image.asset(
            widget.character.asset,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
          ),
        ),
      ),
    );
  }
}

class _LevelCheckpoint extends StatefulWidget {
  const _LevelCheckpoint({
    required this.level,
    required this.status,
    required this.interactionEnabled,
    required this.onTap,
  });

  final int level;
  final MapLevelStatus status;
  final bool interactionEnabled;
  final VoidCallback onTap;

  @override
  State<_LevelCheckpoint> createState() => _LevelCheckpointState();
}

class _LevelCheckpointState extends State<_LevelCheckpoint>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _shakeController;
  late final Animation<double> _pulse;
  late final Animation<Offset> _shake;

  static const _lockedFilter = ColorFilter.matrix([
    .1233,
    .4148,
    .0419,
    0,
    0,
    .1233,
    .4148,
    .0419,
    0,
    0,
    .1233,
    .4148,
    .0419,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ]);

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1250),
    );
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _pulse = Tween<double>(begin: 1, end: 1.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _shake =
        TweenSequence<Offset>([
          TweenSequenceItem(
            tween: Tween(begin: Offset.zero, end: const Offset(-.03, 0)),
            weight: 1,
          ),
          TweenSequenceItem(
            tween: Tween(
              begin: const Offset(-.03, 0),
              end: const Offset(.03, 0),
            ),
            weight: 1,
          ),
          TweenSequenceItem(
            tween: Tween(
              begin: const Offset(.03, 0),
              end: const Offset(-.02, 0),
            ),
            weight: 1,
          ),
          TweenSequenceItem(
            tween: Tween(
              begin: const Offset(-.02, 0),
              end: const Offset(.02, 0),
            ),
            weight: 1,
          ),
          TweenSequenceItem(
            tween: Tween(begin: const Offset(.02, 0), end: Offset.zero),
            weight: 1,
          ),
        ]).animate(
          CurvedAnimation(parent: _shakeController, curve: Curves.easeInOut),
        );
    _syncPulse();
  }

  @override
  void didUpdateWidget(covariant _LevelCheckpoint oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.status != widget.status) _syncPulse();
  }

  void _syncPulse() {
    if (widget.status == MapLevelStatus.current) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
      _pulseController.value = 0;
    }
  }

  void _handleTap() {
    if (!widget.interactionEnabled) return;
    if (widget.status == MapLevelStatus.locked) {
      _shakeController.forward(from: 0);
      return;
    }
    widget.onTap();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locked = widget.status == MapLevelStatus.locked;
    final completed = widget.status == MapLevelStatus.completed;
    final checkpoint = Image.asset(
      completed
          ? 'assets/level/level-checkpoint-completed.webp'
          : 'assets/level/level-checkpoint.webp',
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
    );

    return Semantics(
      button: true,
      enabled: !locked,
      label: locked ? 'Level ${widget.level} locked' : 'Level ${widget.level}',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _handleTap,
        child: SlideTransition(
          position: _shake,
          child: ScaleTransition(
            scale: _pulse,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Positioned.fill(
                  child: locked
                      ? ColorFiltered(
                          colorFilter: _lockedFilter,
                          child: checkpoint,
                        )
                      : checkpoint,
                ),
                if (locked)
                  const FractionallySizedBox(
                    widthFactor: .36,
                    heightFactor: .36,
                    child: FittedBox(
                      fit: BoxFit.contain,
                      child: Icon(
                        Icons.lock_rounded,
                        color: Colors.white,
                        shadows: [
                          Shadow(
                            color: Colors.black87,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Transform.translate(
                    offset: const Offset(0, -2),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '${widget.level}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          shadows: [
                            Shadow(
                              color: Color(0xff75420c),
                              offset: Offset(0, 2),
                            ),
                            Shadow(color: Color(0xff4a2707), blurRadius: 4),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
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
      _HudAction(
        'Profile',
        'assets/HUD/ring_profile_background.webp',
        onProfile,
      ),
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
