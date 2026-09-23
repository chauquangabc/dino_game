import 'package:dino/feature/home/presentation/pages/home_page.dart';
import 'package:dino/feature/farm/presentation/pages/farm_page.dart';
import 'package:dino/feature/lucky_wheel/presentation/pages/lucky_wheel_page.dart';
import 'package:dino/feature/profile/presentation/pages/profile_page.dart';
import 'package:dino/feature/ranking/presentation/pages/ranking_page.dart';
import 'package:dino/feature/store/presentation/pages/store_page.dart';
import 'package:go_router/go_router.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: HomeRouter.path,
  routes: [
    HomeRouter.goRoute(),
    ProfileRouter.goRoute(),
    StoreRouter.goRoute(),
    FarmRouter.goRoute(),
    LuckyWheelRouter.goRoute(),
    RankingRouter.goRoute(),
  ],
);
