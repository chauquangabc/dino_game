import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'profile_assets.dart';

enum ProfileTab { collection, chests }

class ProfilePopup extends StatefulWidget {
  const ProfilePopup({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  State<ProfilePopup> createState() => _ProfilePopupState();
}

class _ProfilePopupState extends State<ProfilePopup> {
  static const _dinos = [
    (
      name: 'Spiderman',
      asset: 'assets/character/dino-spiderman.webp',
      isUnlocked: true,
      fragments: 8,
      species: 'Triceratops',
      rarity: 'Rare',
    ),
    (
      name: 'Akatsuki',
      asset: 'assets/character/dino-akatsuki.webp',
      isUnlocked: false,
      fragments: 3,
      species: 'Stegosaurus',
      rarity: 'Epic',
    ),
    (
      name: 'Batman',
      asset: 'assets/character/dino-batman.webp',
      isUnlocked: false,
      fragments: 0,
      species: 'Triceratops',
      rarity: 'Epic',
    ),
    (
      name: 'Captain',
      asset: 'assets/character/dino-captain-america.webp',
      isUnlocked: false,
      fragments: 5,
      species: 'T-Rex',
      rarity: 'Rare',
    ),
    (
      name: 'Doraemon',
      asset: 'assets/character/dino-doraemon.webp',
      isUnlocked: false,
      fragments: 0,
      species: 'Triceratops',
      rarity: 'Legendary',
    ),
  ];

  static const _chests = [
    (asset: ProfileAssets.chestFragment, quantity: 2),
    (asset: ProfileAssets.chestGold, quantity: 0),
    (asset: ProfileAssets.chestItem, quantity: 0),
    (asset: ProfileAssets.chestMixed, quantity: 0),
    (asset: ProfileAssets.chestSpecial, quantity: 0),
  ];

  ProfileTab _tab = ProfileTab.collection;
  int _selected = 0;
  String _name = 'Dino Trainer';

  Future<void> _editName() async {
    final controller = TextEditingController(text: _name);
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xffffe2aa),
        title: const Text('Edit name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 18,
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (!mounted || value == null || value.trim().isEmpty) return;
    setState(() => _name = value.trim());
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: LayoutBuilder(
      builder: (context, constraints) {
        final landscape = constraints.maxWidth > constraints.maxHeight * 1.15;
        final Size size;
        if (landscape) {
          var height = math.min(constraints.maxHeight * .9, 620.0);
          var width = height * 1.595;
          if (width > constraints.maxWidth * .96) {
            width = constraints.maxWidth * .96;
            height = width / 1.595;
          }
          size = Size(width, height);
        } else {
          final width = math.max(
            220.0,
            math.min(
              math.min(constraints.maxWidth * .94, 520.0),
              constraints.maxHeight * .92 / 1.5,
            ),
          );
          size = Size(width, width * 1.5);
        }

        return Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: .72, end: 1),
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeOutBack,
            builder: (context, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: SizedBox.fromSize(
              size: size,
              child: landscape
                  ? _LandscapeProfile(
                      size: size,
                      tab: _tab,
                      selected: _selected,
                      name: _name,
                      onClose: widget.onClose,
                      onEdit: _editName,
                      onTab: (tab) => setState(() => _tab = tab),
                      onSelected: (index) => setState(() => _selected = index),
                    )
                  : _PortraitProfile(
                      size: size,
                      tab: _tab,
                      selected: _selected,
                      name: _name,
                      onClose: widget.onClose,
                      onEdit: _editName,
                      onTab: (tab) => setState(() => _tab = tab),
                      onSelected: (index) => setState(() => _selected = index),
                    ),
            ),
          ),
        );
      },
    ),
  );
}

class _PortraitProfile extends StatelessWidget {
  const _PortraitProfile({
    required this.size,
    required this.tab,
    required this.selected,
    required this.name,
    required this.onClose,
    required this.onEdit,
    required this.onTab,
    required this.onSelected,
  });

  final Size size;
  final ProfileTab tab;
  final int selected;
  final String name;
  final VoidCallback onClose;
  final VoidCallback onEdit;
  final ValueChanged<ProfileTab> onTab;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final w = size.width;
    final h = size.height;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: RotatedBox(
            quarterTurns: 1,
            child: Image.asset(
              ProfileAssets.panel,
              fit: BoxFit.fill,
              filterQuality: FilterQuality.medium,
            ),
          ),
        ),
        _Header(left: .20 * w, top: -.03 * h, width: .60 * w),
        _Close(left: .83 * w, top: .015 * h, size: .11 * w, onTap: onClose),
        _Avatar(left: .13 * w, top: .10 * h, width: .3 * w),
        _ProfileRows(
          left: .42 * w,
          top: .11 * h,
          width: .4 * w,
          rowOffsets: [0, .06 * h, .12 * h],
          name: name,
        ),
        _Edit(left: .77 * w, top: .1 * h, size: .1 * w, onTap: onEdit),
        _Tabs(
          left: .29 * w,
          top: .31 * size.height,
          width: .42 * w,
          tab: tab,
          onTab: onTab,
        ),
        _CollectionArea(
          left: (tab == ProfileTab.collection ? .08 : .11) * w,
          top: (tab == ProfileTab.collection ? .40 : .37) * h,
          width: (tab == ProfileTab.collection ? .78 : .72) * w,
          height: (tab == ProfileTab.collection ? .40 : .57) * h,
          columns: tab == ProfileTab.collection ? 3 : 2,
          tab: tab,
          selected: selected,
          onSelected: onSelected,
        ),
        if (tab == ProfileTab.collection)
          Positioned(
            left: .1 * w,
            right: .15 * w,
            top: .75 * size.height,
            height: .13 * size.height,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 62, child: _Detail.inline(selected: selected)),
                const Expanded(flex: 31, child: _Action.inline()),
              ],
            ),
          ),
      ],
    );
  }
}

class _LandscapeProfile extends StatelessWidget {
  const _LandscapeProfile({
    required this.size,
    required this.tab,
    required this.selected,
    required this.name,
    required this.onClose,
    required this.onEdit,
    required this.onTab,
    required this.onSelected,
  });

  final Size size;
  final ProfileTab tab;
  final int selected;
  final String name;
  final VoidCallback onClose;
  final VoidCallback onEdit;
  final ValueChanged<ProfileTab> onTab;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final w = size.width, h = size.height;
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned.fill(
          child: Image.asset(
            ProfileAssets.panel,
            fit: BoxFit.fill,
            filterQuality: FilterQuality.medium,
          ),
        ),
        _Header(left: .055 * w, top: .055 * h, width: .285 * w),
        _Close(left: .886 * w, top: .088 * h, size: .066 * w, onTap: onClose),
        _Avatar(left: .0696 * w, top: .17 * h, width: .2627 * w),
        _ProfileRows(
          left: .08 * w,
          top: .5548 * h,
          width: .2413 * w,
          rowOffsets: [0, .084 * h, .1635 * h],
          name: name,
        ),
        _Edit(left: .28 * w, top: .54 * h, size: .056 * w, onTap: onEdit),
        _Tabs(
          left: .505 * w,
          top: .178 * h,
          width: .28 * w,
          tab: tab,
          onTab: onTab,
        ),
        _CollectionArea(
          left: (tab == ProfileTab.collection ? .38 : .365) * w,
          top: (tab == ProfileTab.collection ? .26 : .315) * h,
          width: (tab == ProfileTab.collection ? .50 : .53) * w,
          height: (tab == ProfileTab.collection ? .52 : .60) * h,
          columns: 3,
          tab: tab,
          selected: selected,
          onSelected: onSelected,
        ),
        if (tab == ProfileTab.collection)
          Positioned(
            left: .395 * w,
            right: .1 * w,
            top: .725 * h,
            height: .19 * h,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(flex: 33, child: _Detail.inline(selected: selected)),
                SizedBox(width: .015 * w),
                const Expanded(flex: 19, child: _Action.inline()),
              ],
            ),
          ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.left, required this.top, required this.width});

  final double left, top, width;

  @override
  Widget build(BuildContext context) => Positioned(
    left: left,
    top: top,
    width: width,
    child: AspectRatio(
      aspectRatio: 3.05,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(ProfileAssets.header, fit: BoxFit.fill),
          Align(
            alignment: Alignment(0, 0.2),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'DINO PROFILE',
                style: TextStyle(
                  color: const Color(0xfffff6dc),
                  fontSize: width * .09,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                  shadows: const [
                    Shadow(
                      color: Color(0xff7a3a10),
                      offset: Offset(0, 2),
                      blurRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _Close extends StatelessWidget {
  const _Close({
    required this.left,
    required this.top,
    required this.size,
    required this.onTap,
  });

  final double left, top, size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Positioned(
    left: left,
    top: top,
    width: size,
    height: size,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Image.asset(ProfileAssets.close),
    ),
  );
}

class _Edit extends StatelessWidget {
  const _Edit({
    required this.left,
    required this.top,
    required this.size,
    required this.onTap,
  });

  final double left, top, size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Positioned(
    left: left,
    top: top,
    width: size,
    height: size,
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Image.asset(ProfileAssets.edit),
    ),
  );
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.left, required this.top, required this.width});

  static const _assetRatio = 1297 / 1213;

  final double left, top, width;

  @override
  Widget build(BuildContext context) => Positioned(
    left: left,
    top: top,
    width: width,
    height: width / _assetRatio,
    child: Stack(
      alignment: Alignment.center,
      children: [
        Align(
          alignment: const Alignment(.01, -.025),
          child: SizedBox.square(
            dimension: width * .69,
            child: ClipOval(
              child: ColoredBox(
                color: const Color(0xff58bfff),
                child: Padding(
                  padding: EdgeInsets.all(width * .055),
                  child: Image.asset(
                    'assets/character/babyDino.webp',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: Image.asset(ProfileAssets.avatarRing, fit: BoxFit.contain),
        ),
      ],
    ),
  );
}

class _ProfileRows extends StatelessWidget {
  const _ProfileRows({
    required this.left,
    required this.top,
    required this.width,
    required this.rowOffsets,
    required this.name,
  });

  static const _rowRatio = 1607 / 275;

  final double left, top, width;
  final List<double> rowOffsets;
  final String name;

  @override
  Widget build(BuildContext context) {
    final rowHeight = width / _rowRatio;
    final rows = [
      (icon: Icons.person_rounded, text: name, asset: null),
      (icon: null, text: '12,500', asset: ProfileAssets.coin),
      (icon: Icons.star_rounded, text: 'Rookie', asset: null),
    ];
    return Positioned(
      left: left,
      top: top,
      width: width,
      height: rowOffsets.last + rowHeight,
      child: Stack(
        children: List.generate(
          rows.length,
          (index) => Positioned(
            left: 0,
            right: 0,
            top: rowOffsets[index],
            height: rowHeight,
            child: _row(
              icon: rows[index].icon,
              asset: rows[index].asset,
              text: rows[index].text,
              height: rowHeight,
              index: index,
            ),
          ),
        ),
      ),
    );
  }

  Widget _row({
    required IconData? icon,
    required String? asset,
    required String text,
    required double height,
    required int index,
  }) => SizedBox(
    height: height,
    child: Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(ProfileAssets.row, fit: BoxFit.fill),
        Positioned(
          left: height * .2,
          top: height * .15,
          width: height * .6,
          height: height * .6,
          child: asset != null
              ? Image.asset(asset, fit: BoxFit.contain)
              : Icon(
                  icon,
                  size: height * (index == 2 ? .56 : .52),
                  color: index == 0 ? Color(0xff6b3a12) : Colors.yellowAccent,
                ),
        ),
        Positioned(
          left: height * 1.05,
          right: height * .30,
          top: 0,
          bottom: 0,
          child: Align(
            alignment: Alignment.centerLeft,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                text,
                maxLines: 1,
                style: TextStyle(
                  color: const Color(0xff6b3a12),
                  fontSize: height * .64,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _Tabs extends StatelessWidget {
  const _Tabs({
    required this.left,
    required this.top,
    required this.width,
    required this.tab,
    required this.onTab,
  });

  final double left, top, width;
  final ProfileTab tab;
  final ValueChanged<ProfileTab> onTab;

  @override
  Widget build(BuildContext context) => Positioned(
    left: left,
    top: top,
    width: width,
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _tab(ProfileTab.collection, ProfileAssets.collection, .5926),
        _tab(ProfileTab.chests, ProfileAssets.chests, .4074),
      ],
    ),
  );

  Widget _tab(ProfileTab value, String asset, double factor) => Expanded(
    flex: (factor * 10000).round(),
    child: GestureDetector(
      onTap: () => onTab(value),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 160),
        opacity: tab == value ? 1 : .55,
        child: Image.asset(asset, fit: BoxFit.fitWidth),
      ),
    ),
  );
}

class _CollectionArea extends StatelessWidget {
  const _CollectionArea({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.columns,
    required this.tab,
    required this.selected,
    required this.onSelected,
  });

  final double left, top, width, height;
  final int columns;
  final ProfileTab tab;
  final int selected;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: left,
      top: top,
      width: width,
      height: height,
      child: ClipRect(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCollection = tab == ProfileTab.collection;
            final dataLength = isCollection
                ? _ProfilePopupState._dinos.length
                : _ProfilePopupState._chests.length;
            final itemCount = dataLength + 1;
            final rows = (itemCount / columns).ceil();
            final cardHeightFactor = isCollection ? .9 : .8;
            final gapFactor = isCollection ? .06 : 0;
            final crossAxisOverlapFactor = isCollection ? .08 : 0.0;
            final horizontalOverflowFactor = isCollection ? .1176 : 0.1;
            final verticalOverflowFactor = isCollection
                ? cardHeightFactor * .164
                : 0.1;
            final widthUnits =
                columns -
                (columns - 1) * crossAxisOverlapFactor +
                horizontalOverflowFactor;
            final widthLimitedCard = constraints.maxWidth / widthUnits;
            final heightUnits =
                rows * cardHeightFactor +
                (rows - 1) * gapFactor +
                verticalOverflowFactor;
            final heightLimitedCard = constraints.maxHeight / heightUnits;
            final cardWidth = math.min(widthLimitedCard, heightLimitedCard);
            final cardHeight = cardWidth * cardHeightFactor;
            final spacing = cardWidth * gapFactor;
            final crossAxisOverlap = cardWidth * crossAxisOverlapFactor;
            final horizontalInset = isCollection ? cardWidth * .0588 : 0.0;
            final topInset = isCollection ? cardHeight * .131 : 0.0;
            final bottomInset = isCollection ? cardHeight * .033 : 0.0;
            final gridWidth =
                cardWidth * columns - crossAxisOverlap * (columns - 1);
            final gridHeight =
                cardHeight * rows + spacing * math.max(0, rows - 1);

            return Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: gridWidth + horizontalInset * 2,
                height: gridHeight + topInset + bottomInset,
                child: GridView.builder(
                  padding: EdgeInsets.fromLTRB(
                    horizontalInset,
                    topInset,
                    horizontalInset,
                    bottomInset,
                  ),
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: _OverlappingGridDelegate(
                    crossAxisCount: columns,
                    crossAxisOverlap: crossAxisOverlap,
                    mainAxisSpacing: spacing,
                    childMainAxisExtent: cardHeight,
                  ),
                  itemCount: itemCount,
                  itemBuilder: (context, index) => isCollection
                      ? _DinoCard(
                          index: index,
                          selected: selected == index,
                          onTap: () => onSelected(index),
                        )
                      : _ChestCard(index: index),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _OverlappingGridDelegate extends SliverGridDelegate {
  const _OverlappingGridDelegate({
    required this.crossAxisCount,
    required this.crossAxisOverlap,
    required this.mainAxisSpacing,
    required this.childMainAxisExtent,
  });

  final int crossAxisCount;
  final double crossAxisOverlap;
  final double mainAxisSpacing;
  final double childMainAxisExtent;

  @override
  SliverGridLayout getLayout(SliverConstraints constraints) {
    final totalOverlap = crossAxisOverlap * (crossAxisCount - 1);
    final childCrossAxisExtent =
        (constraints.crossAxisExtent + totalOverlap) / crossAxisCount;

    return SliverGridRegularTileLayout(
      crossAxisCount: crossAxisCount,
      mainAxisStride: childMainAxisExtent + mainAxisSpacing,
      crossAxisStride: childCrossAxisExtent - crossAxisOverlap,
      childMainAxisExtent: childMainAxisExtent,
      childCrossAxisExtent: childCrossAxisExtent,
      reverseCrossAxis: axisDirectionIsReversed(constraints.crossAxisDirection),
    );
  }

  @override
  bool shouldRelayout(_OverlappingGridDelegate oldDelegate) =>
      crossAxisCount != oldDelegate.crossAxisCount ||
      crossAxisOverlap != oldDelegate.crossAxisOverlap ||
      mainAxisSpacing != oldDelegate.mainAxisSpacing ||
      childMainAxisExtent != oldDelegate.childMainAxisExtent;
}

class _DinoCard extends StatelessWidget {
  const _DinoCard({
    required this.index,
    required this.selected,
    required this.onTap,
  });

  final int index;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final future = index == _ProfilePopupState._dinos.length;
    final d = future ? null : _ProfilePopupState._dinos[index];
    final locked = future || (d!.fragments == 0);
    final skin = selected
        ? ProfileAssets.cardSelected
        : ProfileAssets.cardLocked;
    return GestureDetector(
      onTap: future ? null : onTap,
      child: LayoutBuilder(
        builder: (context, constraints) => Stack(
          clipBehavior: Clip.none,
          children: [
            if (selected)
              Positioned(
                left: -constraints.maxWidth * .0588,
                top: -constraints.maxHeight * .131,
                width: constraints.maxWidth * 1.1176,
                height: constraints.maxHeight * 1.164,
                child: Image.asset(skin, fit: BoxFit.fill),
              )
            else
              Positioned(
                left: -constraints.maxWidth * .0588,
                top: -constraints.maxHeight * .12,
                width: constraints.maxWidth * 1.1176,
                height: constraints.maxHeight * 1.154,
                child: Image.asset(skin, fit: BoxFit.fill),
              ),
            Positioned(
              left: constraints.maxWidth * .13,
              right: constraints.maxWidth * .13,
              top: constraints.maxHeight * .08,
              height: constraints.maxHeight * .63,
              child: future
                  ? const Center(
                      child: Text(
                        '?',
                        style: TextStyle(
                          color: Color(0xff7fe7f5),
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    )
                  : ColorFiltered(
                      colorFilter: locked
                          ? const ColorFilter.matrix([
                              .3,
                              .3,
                              .3,
                              0,
                              0,
                              .3,
                              .3,
                              .3,
                              0,
                              0,
                              .3,
                              .3,
                              .3,
                              0,
                              0,
                              0,
                              0,
                              0,
                              1,
                              0,
                            ])
                          : const ColorFilter.mode(
                              Colors.transparent,
                              BlendMode.dst,
                            ),
                      child: Image.asset(d!.asset, fit: BoxFit.contain),
                    ),
            ),
            Positioned(
              left: constraints.maxWidth * .15,
              right: constraints.maxWidth * .15,
              top: constraints.maxHeight * .72,
              height: constraints.maxHeight * .18,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  future ? 'SOON' : '${d!.fragments}/8',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: constraints.maxWidth * .09,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    shadows: const [
                      Shadow(color: Colors.black54, offset: Offset(0, 2)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChestCard extends StatelessWidget {
  const _ChestCard({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final future = index == _ProfilePopupState._chests.length;
    final chest = future ? null : _ProfilePopupState._chests[index];

    return LayoutBuilder(
      builder: (context, constraints) => Stack(
        children: [
          Positioned.fill(
            child: Image.asset(ProfileAssets.cardNormal, fit: BoxFit.fill),
          ),
          Positioned(
            left: constraints.maxWidth * .12,
            right: constraints.maxWidth * .12,
            top: constraints.maxHeight * .02,
            bottom: constraints.maxHeight * .15,
            child: future
                ? Center(
                    child: Icon(
                      Icons.question_mark_rounded,
                      color: Colors.blueAccent,
                      size:
                          math.min(
                            constraints.maxWidth,
                            constraints.maxHeight,
                          ) *
                          .38,
                    ),
                  )
                : Transform.scale(
                    scale: 0.75,
                    child: Image.asset(chest!.asset, fit: BoxFit.contain),
                  ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: constraints.maxHeight * .1,
            child: Center(
              child: Text(
                future ? 'SOON' : 'x${chest!.quantity}',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: constraints.maxWidth * .1,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({
    required this.left,
    required this.top,
    required this.width,
    required this.selected,
  });

  const _Detail.inline({required this.selected})
    : left = null,
      top = null,
      width = null;

  final double? left, top, width;
  final int selected;

  @override
  Widget build(BuildContext context) {
    final i = math.min(selected, _ProfilePopupState._dinos.length - 1);
    final d = _ProfilePopupState._dinos[i];
    final rarityColor = switch (d.rarity.toLowerCase()) {
      'common' => const Color(0xff6b8f3a),
      'rare' => const Color(0xff2f7fd8),
      'legendary' => const Color(0xffd8781a),
      _ => const Color(0xff8a3fd0),
    };
    Widget content(double contentWidth, {double? contentHeight}) {
      final panel = Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(ProfileAssets.detail, fit: BoxFit.fill),
          Positioned(
            left: contentWidth * .03,
            top: contentWidth * .025,
            width: contentWidth * .18,
            bottom: contentWidth * .025,
            child: Image.asset(d.asset, fit: BoxFit.contain),
          ),
          Positioned(
            left: contentWidth * .25,
            right: contentWidth * .29,
            top: contentWidth * .1,
            child: FittedBox(
              alignment: Alignment.centerLeft,
              fit: BoxFit.scaleDown,
              child: Text(
                d.name,
                style: TextStyle(
                  color: const Color(0xff5a2d0c),
                  fontSize: contentWidth * .075,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          Positioned(
            left: contentWidth * .25,
            right: contentWidth * .29,
            bottom: contentWidth * .1,
            child: Text(
              d.species,
              style: TextStyle(
                color: const Color(0xff7a4a1a),
                fontSize: contentWidth * .065,
              ),
            ),
          ),
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) => Stack(
                children: [
                  Positioned(
                    left: constraints.maxWidth * .718,
                    top: constraints.maxHeight * .398,
                    width: constraints.maxWidth * .24,
                    height: constraints.maxHeight * .245,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            rarityColor,
                            rarityColor,
                            Color.lerp(rarityColor, Colors.black, .22)!,
                          ],
                          stops: const [0, .78, 1],
                        ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            d.rarity.toUpperCase(),
                            maxLines: 1,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize:
                                  contentWidth *
                                  (MediaQuery.orientationOf(context) ==
                                          Orientation.landscape
                                      ? .05
                                      : .044),
                              height: 1,
                              letterSpacing: contentWidth * .00175,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
      if (contentHeight != null) {
        return SizedBox(
          width: contentWidth,
          height: contentHeight,
          child: panel,
        );
      }
      return AspectRatio(aspectRatio: 3.0, child: panel);
    }

    if (width == null) {
      return LayoutBuilder(
        builder: (context, constraints) =>
            content(constraints.maxWidth, contentHeight: constraints.maxHeight),
      );
    }
    return Positioned(
      left: left,
      top: top,
      width: width,
      child: content(width!),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action({required this.left, required this.top, required this.width});

  const _Action.inline() : left = null, top = null, width = null;

  // The button asset has less transparent vertical padding than the detail
  // asset. Keep the painted borders the same visual height when both widgets
  // share a stretched Row.
  static const _inlineHeightFactor = .7;

  final double? left, top, width;

  Widget _content(double contentWidth, {double? contentHeight}) {
    final panel = Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.hardEdge,
      children: [
        Image.asset(ProfileAssets.findMore, fit: BoxFit.fill),
        Positioned.fill(
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: contentWidth * .16,
              vertical: contentWidth * .055,
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                'FIND MORE',
                maxLines: 1,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: contentWidth * .11,
                  fontWeight: FontWeight.w900,
                  shadows: const [
                    Shadow(color: Color(0xff006070), offset: Offset(0, 2)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
    if (contentHeight != null) {
      return SizedBox(width: contentWidth, height: contentHeight, child: panel);
    }
    return AspectRatio(aspectRatio: 1959 / 768, child: panel);
  }

  @override
  Widget build(BuildContext context) {
    if (width == null) {
      return LayoutBuilder(
        builder: (context, constraints) => Center(
          child: _content(
            constraints.maxWidth,
            contentHeight: constraints.maxHeight * _inlineHeightFactor,
          ),
        ),
      );
    }
    return Positioned(
      left: left,
      top: top,
      width: width,
      child: _content(width!),
    );
  }
}
