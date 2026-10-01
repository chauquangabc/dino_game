# Profile: local implementation

The UI keeps the existing portrait/landscape layout. `ProfilePage` owns UI state;
`ProfilePopup` receives that state and callbacks. No HTTP/backend is required.

## Product choices

- Initial avatar: **Baby Dino**. Spiderman is the first collection card.
- Initial local scenario: **demo**, matching the approved UI: Dino Trainer,
  12,500 coins, fragments `8/3/0/5/0`, Spiderman unlocked, Fragment Chest x2.
- Fragment rewards choose dinos below 8/8; when all are full each new fragment
  becomes 150 coins. Reaching 8/8 requires pressing UNLOCK. Unlocking keeps 8/8.
- Buying a dino or receiving one from Special Chest unlocks it without equipping it.
- CLAIM in the chest popup only acknowledges rewards already saved by opening.
  DONE/X returns to the Profile Chests tab.

## Where to change data

- `lib/feature/profile/domain/profile_catalog.dart`: dino order, IDs, names,
  species, rarity, descriptions, prices, name limit and title thresholds.
- `lib/feature/profile/data/profile_mock_data.dart`: demo/fresh scenario and seed.
  The seed runs once, and only fills absent keys. Changing the mode never resets
  an existing player's save. Fresh uses DINO98, 500 coins, no fragments/chests.
- `lib/feature/profile/domain/chest_catalog.dart`: chest names/order/assets,
  reward tables and booster weights from the standalone HTML.
- `tool/extract_profile_chest_assets.mjs`: reproducible extraction of chest-open,
  reward-panel and fragment art from the HTML. Run with `node` from this repo.
  The extractor refuses to replace an existing file with different bytes.

## Storage and migration

`GameLocalStore.shared` is the shared serialized writer for Profile, Store,
Lucky Wheel and Home avatar. Dependencies are registered in `core/di/injection.dart`;
repositories also accept a store for tests. `core/storage/game_local_store.dart`
defines the storage keys, retaining `line98_coins`, `line98_collection`,
`line98_chests`, `line98_tools`, `line98_profile` and existing game keys.

Canonical dino IDs are `spiderman`, `akatsuki`, `batman`, `captain`, `doraemon`.
Migration reads old `dino-*` IDs (Captain: `dino-captain-america`). Duplicate
fragment counts use max, ownership uses OR. Legacy piece counts move from the
inventory once. The old Home equipped-character key is consulted only on the
first migration, and only for a dino already owned. Existing unlocked dinos stay
unlocked even if an older Lucky Wheel implementation granted them automatically.

Transactions store absolute after-values in `line98_game_tx` or
`line98_chest_tx` before writing balances. A restarted repository replays the
journal before reading or modifying saves, so partial writes cannot re-grant a
reward. `line98_chest_result` retains the rolled reward screen until dismissed;
Open Again uses the previous result ID to reject duplicate requests. Lucky Wheel
claim receipts and rewards are part of the same transaction.

Do not add direct writes to these economy keys from another feature: use the
same store/collection rules. Read-modify-write operations in separate store
instances are intended only for isolated tests, not simultaneous app writers.

Home listens for shared-store changes and refreshes its map avatar and Profile
button. FIND MORE replaces Profile with `/store?category=chests`;
`/profile?tab=chests` opens Profile directly at inventory.

## Verification

Run `flutter test --no-pub --concurrency=1` and `dart analyze lib test`.
Tests cover migration, names/titles, unlock/equip, cross-feature purchases/rewards,
concurrent requests, interrupted chest writes, both orientations and navigation.
Widget tests render review images under ignored `build/profile_qa/`.

Backend work should replace repository data operations and server-side reward
resolution while retaining the UI/domain contract. Local mock data is not a
server-authoritative economy and is not used for real purchases or rankings.
