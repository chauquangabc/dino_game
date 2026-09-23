import 'package:dino/feature/home/presentation/pages/home_page.dart';
import 'package:go_router/go_router.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: HomeRouter.path,
  routes: [HomeRouter.goRoute()],
);
