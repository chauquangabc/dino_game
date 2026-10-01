import 'package:flutter/material.dart';

import '../../domain/farm_catalog.dart';
import '../../domain/farm_food.dart';
import '../../domain/farm_pet.dart';
import '../../domain/farm_state.dart';
import 'farm_assets.dart';
import 'farm_layout.dart';
import 'farm_pet_stage.dart';
import 'farm_toolbar.dart';

class FarmPortraitLayout extends StatelessWidget {
  const FarmPortraitLayout({
    super.key,
    required this.size,
    required this.safeTop,
    required this.state,
    required this.busy,
    required this.petHovered,
    required this.bounce,
    required this.onFeed,
    required this.onClaim,
    required this.onPets,
    required this.onClose,
    required this.onPetTap,
    required this.onPetHoverChanged,
    required this.onFoodDropped,
  });

  final Size size;
  final double safeTop;
  final FarmState state;
  final bool busy;
  final bool petHovered;
  final Animation<double> bounce;
  final VoidCallback onFeed, onClaim, onPets, onClose;
  final ValueChanged<Rect> onPetTap;
  final ValueChanged<bool> onPetHoverChanged;
  final ValueChanged<FarmFood> onFoodDropped;

  static const sourceSize = Size(1680, 1890);
  // Portrait-only coordinates measured on the source background.
  static const petPlacement = FarmPetPlacement(
    x: .500,
    feetY: .515,
    height: .1225,
  );

  @override
  Widget build(BuildContext context) {
    final cover = farmCoverGeometry(size, sourceSize);
    const placement = petPlacement;
    final petHeight = placement.height * cover.size.height;
    final petWidth = petHeight * 1.08;
    final feet = Offset(
      cover.offset.dx + placement.x * cover.size.width,
      cover.offset.dy + placement.feetY * cover.size.height,
    );
    final petRect = Rect.fromLTWH(
      (feet.dx - petWidth / 2).clamp(2, size.width - petWidth - 2),
      (feet.dy - petHeight).clamp(2, size.height - petHeight - 2),
      petWidth,
      petHeight,
    );
    final now = DateTime.now();
    final mood = state.moodAt(now);
    final pet = FarmCatalog.pet(state.selectedPetId);

    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(FarmAssets.portraitBackground, fit: BoxFit.cover),
        ),
        FarmPetStage(
          rect: petRect,
          assetPath: pet.assetFor(mood),
          health: state.healthAt(now),
          mood: mood,
          bounce: bounce,
          hovered: petHovered,
          onTap: () => onPetTap(petRect),
          onHoverChanged: onPetHoverChanged,
          onFoodDropped: onFoodDropped,
        ),
        Positioned.fill(
          child: FarmToolbar(
            viewport: size,
            safeTop: safeTop,
            state: state,
            busy: busy,
            onFeed: onFeed,
            onClaim: onClaim,
            onPets: onPets,
            onClose: onClose,
          ),
        ),
      ],
    );
  }
}
