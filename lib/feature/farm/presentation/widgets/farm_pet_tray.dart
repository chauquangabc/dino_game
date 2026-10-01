import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/farm_catalog.dart';
import '../../domain/farm_pet.dart';
import '../../domain/farm_state.dart';
import 'farm_assets.dart';

class FarmPetTray extends StatelessWidget {
  const FarmPetTray({super.key, required this.state, required this.onSelect});

  final FarmState state;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final pets = FarmCatalog.pets
        .where((pet) => state.ownedPetIds.contains(pet.id))
        .toList();
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, viewport) {
          final landscape = viewport.maxWidth > viewport.maxHeight * 1.15;
          final trayWidth = landscape
              ? math.min(viewport.maxWidth * .3, 440.0)
              : math.min(
                  math.min(viewport.maxWidth * .92, viewport.maxHeight * 1.05),
                  520.0,
                );
          final maxColumns = landscape ? 5 : 3;
          final rows = math.max(1, (pets.length / maxColumns).ceil());
          final columns = math.max(1, (pets.length / rows).ceil());
          final headerWidth = math.min(
            trayWidth * .62,
            math.max(trayWidth * .40, viewport.maxWidth * .46),
          );
          var cardWidth = math.min(
            trayWidth / (columns * 1.02 - .02),
            trayWidth * .34,
          );
          cardWidth = math.min(
            cardWidth,
            math.max(
              40,
              (viewport.maxHeight * .62 -
                      headerWidth / 3.05 -
                      trayWidth * .05) /
                  (rows * .8),
            ),
          );
          final gap = cardWidth * .02;
          return Align(
            alignment: Alignment.bottomCenter,
            child: SingleChildScrollView(
              reverse: true,
              padding: EdgeInsets.only(bottom: trayWidth * .02),
              child: SizedBox(
                width: trayWidth,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _PetTrayHeader(width: headerWidth),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: gap,
                      runSpacing: 0,
                      children: [
                        for (final pet in pets)
                          FarmPetCard(
                            width: cardWidth,
                            pet: pet,
                            selected: state.selectedPetId == pet.id,
                            onTap: () => onSelect(pet.id),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PetTrayHeader extends StatelessWidget {
  const _PetTrayHeader({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: width,
    child: AspectRatio(
      aspectRatio: 3.05,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(FarmAssets.petTrayHeader, fit: BoxFit.fill),
          Align(
            alignment: const Alignment(0, .2),
            child: FractionallySizedBox(
              widthFactor: .68,
              heightFactor: .34,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: const Text(
                  'PICK YOUR DINO',
                  style: TextStyle(
                    color: Color(0xfffff6dc),
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class FarmPetCard extends StatelessWidget {
  const FarmPetCard({
    super.key,
    required this.width,
    required this.pet,
    required this.selected,
    required this.onTap,
  });

  final double width;
  final FarmPet pet;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: pet.name,
    child: GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: width,
        child: AspectRatio(
          aspectRatio: 1.25,
          child: LayoutBuilder(
            builder: (context, constraints) => Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  left: constraints.maxWidth * .145,
                  right: constraints.maxWidth * .145,
                  top: constraints.maxHeight * .145,
                  height: constraints.maxHeight * .6,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                        constraints.maxWidth * .075,
                      ),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: selected
                            ? const [Color(0xffffef9c), Color(0xff9bdc69)]
                            : const [Color(0xffd8f4dc), Color(0xff8fcf86)],
                      ),
                      border: Border.all(
                        color: selected
                            ? const Color(0xffffdf4d)
                            : const Color(0x8890bd73),
                        width: constraints.maxWidth * .012,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x552b5a28),
                          blurRadius: 5,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Image.asset(
                    selected
                        ? FarmAssets.petCardSelected
                        : FarmAssets.petCardNormal,
                    fit: BoxFit.fill,
                  ),
                ),
                Positioned(
                  left: constraints.maxWidth * .13,
                  right: constraints.maxWidth * .13,
                  top: constraints.maxHeight * .12,
                  height: constraints.maxHeight * .63,
                  child: Transform.scale(scale: 0.85,child: Image.asset(pet.thumbnail, fit: BoxFit.contain)),
                ),
                Positioned(
                  left: constraints.maxWidth * .15,
                  width: constraints.maxWidth * .70,
                  top: constraints.maxHeight * .745,
                  height: constraints.maxHeight * .128,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      pet.name,
                      maxLines: 1,
                      style: TextStyle(
                        color: const Color(0xffffedc0),
                        fontSize: constraints.maxWidth * .10,
                        fontWeight: FontWeight.w900,
                        shadows: const [
                          Shadow(
                            color: Color(0xff4b2207),
                            offset: Offset(0, 1),
                          ),
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
    ),
  );
}
