import 'dart:io';
import 'dart:ui' as ui;

import 'package:dino/core/storage/game_local_store.dart';
import 'package:dino/feature/profile/data/dino_collection_repository.dart';
import 'package:dino/feature/profile/data/profile_repository.dart';
import 'package:dino/feature/profile/domain/profile_state.dart';
import 'package:dino/feature/profile/presentation/pages/profile_page.dart';
import 'package:dino/feature/profile/presentation/widgets/chest_opening_popup.dart';
import 'package:dino/feature/profile/presentation/widgets/profile_popup.dart';
import 'package:dino/feature/store/data/store_repository.dart';
import 'package:dino/feature/store/domain/store_category.dart';
import 'package:dino/feature/store/presentation/pages/store_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'support/memory_secure_storage.dart';

void main() {
  setUpAll(() async {
    final icons = File(
      'C:/Users/admin/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
    );
    if (icons.existsSync()) {
      final loader = FontLoader('MaterialIcons')
        ..addFont(Future.value(ByteData.sublistView(icons.readAsBytesSync())));
      await loader.load();
    }
    final font = File('C:/Windows/Fonts/segoeui.ttf');
    if (font.existsSync()) {
      final loader = FontLoader('Roboto')
        ..addFont(Future.value(ByteData.sublistView(font.readAsBytesSync())));
      await loader.load();
    }
  });
  for (final size in [
    const Size(390, 844),
    const Size(844, 390),
    const Size(320, 568),
    const Size(768, 1024),
    const Size(1024, 768),
  ]) {
    testWidgets('Profile collection/chests fit ${size.width}x${size.height}', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = ProfileRepository(
        store: GameLocalStore(storage: MemorySecureStorage()),
      );
      final state = (await tester.runAsync(repo.load))!;
      for (final tab in ProfileTab.values) {
        final boundary = GlobalKey();
        await tester.pumpWidget(
          MaterialApp(
            home: RepaintBoundary(
              key: boundary,
              child: Scaffold(
                backgroundColor: const Color(0xff284532),
                body: ProfilePopup(
                  state: state.copyWith(tab: tab),
                  onClose: () {},
                  onEdit: () {},
                  onTab: (_) {},
                  onSelected: (_) {},
                  onAction: () {},
                  onChest: (_) {},
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('SOON'), findsOneWidget);
        final grid = tester.widget<GridView>(find.byType(GridView));
        expect(
          (grid.childrenDelegate as SliverChildBuilderDelegate).childCount,
          6,
        );
        if (size == const Size(390, 844) || size == const Size(844, 390)) {
          await settleImages(tester);
          await tester.runAsync(() async {
            final image =
                await (boundary.currentContext!.findRenderObject()
                        as RenderRepaintBoundary)
                    .toImage();
            final bytes = await image.toByteData(
              format: ui.ImageByteFormat.png,
            );
            final directory = Directory('build/profile_qa')
              ..createSync(recursive: true);
            File(
              '${directory.path}/${size.width.toInt()}-${tab.name}.png',
            ).writeAsBytesSync(bytes!.buffer.asUint8List());
            image.dispose();
          });
        }
      }
      await tester.pumpWidget(const SizedBox());
    });
  }

  testWidgets(
    'selection changes details, SOON cannot select, name persists, equip updates state',
    (tester) async {
      final store = GameLocalStore(storage: MemorySecureStorage());
      final repo = ProfileRepository(store: store);
      await tester.pumpWidget(MaterialApp(home: ProfilePage(repository: repo)));
      await tester.pumpAndSettle();
      expect(find.text('SET AVATAR'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('dino-akatsuki')));
      await tester.pumpAndSettle();
      expect(find.text('FIND MORE'), findsOneWidget);
      expect(find.text('Stegosaurus'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('dino-soon')));
      await tester.pumpAndSettle();
      expect(find.text('Stegosaurus'), findsOneWidget);
      await tester.runAsync(() async {
        await DinoCollectionRepository(
          store: store,
        ).addFragments('akatsuki', 5);
        await Future<void>.delayed(
          Duration.zero,
        ); // Flush real async store subscriptions.
      });
      await tester.pumpAndSettle();
      expect(find.text('UNLOCK'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('profile-action')));
      await tester.pumpAndSettle();
      expect(find.text('SET AVATAR'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('profile-action')));
      await tester.pumpAndSettle();
      expect(find.text('IN USE'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('profile-edit')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('profile-name-input')),
        '  New  Dino  ',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(find.text('New Dino'), findsOneWidget);
      final saved = (await tester.runAsync(repo.load))!;
      expect(saved.profile!.displayName, 'New Dino');
      expect(saved.profile!.equippedAvatarId, 'akatsuki');
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('empty catalog renders SOON without an index error', (
    tester,
  ) async {
    final repo = ProfileRepository(
      store: GameLocalStore(storage: MemorySecureStorage()),
    );
    final state = (await tester.runAsync(repo.load))!.copyWith(dinos: []);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProfilePopup(
            state: state,
            onClose: () {},
            onEdit: () {},
            onTab: (_) {},
            onSelected: (_) {},
            onAction: () {},
            onChest: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('SOON'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'chest overlay returns to CHESTS, x0 is disabled and rewards survive close',
    (tester) async {
      final repo = ProfileRepository(
        store: GameLocalStore(storage: MemorySecureStorage()),
      );
      final boundary = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          home: RepaintBoundary(
            key: boundary,
            child: ProfilePage(repository: repo, initialTab: ProfileTab.chests),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('chest_gold')));
      await tester.pumpAndSettle();
      expect(find.byType(ChestOpeningPopup), findsNothing);
      await tester.tap(find.byKey(const ValueKey('chest_fragment')));
      await tester.pumpAndSettle();
      expect(find.byType(ChestOpeningPopup), findsOneWidget);
      expect(find.text('Chests left: 1'), findsOneWidget);
      await settleImages(tester);
      await tester.runAsync(() async {
        final image =
            await (boundary.currentContext!.findRenderObject()
                    as RenderRepaintBoundary)
                .toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        Directory('build/profile_qa').createSync(recursive: true);
        File(
          'build/profile_qa/chest-opening.png',
        ).writeAsBytesSync(bytes!.buffer.asUint8List());
        image.dispose();
      });
      await tester.tap(find.byKey(const ValueKey('chest-OPEN AGAIN')));
      await tester.pumpAndSettle();
      expect(find.text('No chests left'), findsOneWidget);
      final button = tester.widget<GestureDetector>(
        find.byKey(const ValueKey('chest-OPEN AGAIN')),
      );
      expect(button.onTap, isNull);
      await tester.tap(find.byKey(const ValueKey('chest-CLAIM')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('chest-DONE')));
      await tester.pumpAndSettle();
      expect(find.byType(ChestOpeningPopup), findsNothing);
      expect(find.byKey(const ValueKey('chest_fragment')), findsOneWidget);
      expect((await tester.runAsync(repo.load))!.chestCount, 0);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('FIND MORE replaces Profile with Store on Chests tab', (
    tester,
  ) async {
    final store = GameLocalStore(storage: MemorySecureStorage());
    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, _) => Scaffold(
            body: TextButton(
              onPressed: () => context.push('/profile'),
              child: const Text('Open profile'),
            ),
          ),
        ),
        GoRoute(
          path: '/profile',
          builder: (_, _) =>
              ProfilePage(repository: ProfileRepository(store: store)),
        ),
        GoRoute(
          path: '/store',
          builder: (_, state) => StorePage(
            repository: StoreRepository(store: store),
            initialCategory: StoreCategory.values.byName(
              state.uri.queryParameters['category']!,
            ),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.text('Open profile'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('dino-akatsuki')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('profile-action')));
    await tester.pumpAndSettle();
    expect(find.byType(StorePage), findsOneWidget);
    expect(find.text('FRAGMENT CHEST'), findsOneWidget);
    expect(find.byType(ProfilePage), findsNothing);
    router.pop();
    await tester.pumpAndSettle();
    expect(find.text('Open profile'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}

Future<void> settleImages(WidgetTester tester) async {
  final pages = find.byType(ProfilePage);
  final context = tester.element(
    pages.evaluate().isEmpty ? find.byType(ProfilePopup).first : pages.first,
  );
  final providers = tester
      .widgetList<Image>(find.byType(Image))
      .map((image) => image.image)
      .toSet();
  await tester.runAsync(
    () => Future.wait(providers.map((image) => precacheImage(image, context))),
  );
  await tester.pumpAndSettle();
}
