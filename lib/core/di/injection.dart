import 'package:dino/core/network/session_manager.dart';
import 'package:dino/core/storage/secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import '../network/dio_client.dart';
import '../storage/game_local_store.dart';
import '../../feature/profile/data/profile_repository.dart';
import '../../feature/profile/data/dino_collection_repository.dart';
import '../../feature/profile/data/chest_repository.dart';

final sl = GetIt.instance;

void configureDependencies() {
  sl.registerLazySingleton<GameLocalStore>(() => GameLocalStore.shared);
  sl.registerLazySingleton<ProfileRepository>(
    () => ProfileRepository(store: sl<GameLocalStore>()),
  );
  sl.registerLazySingleton<DinoCollectionRepository>(
    () => DinoCollectionRepository(store: sl<GameLocalStore>()),
  );
  sl.registerLazySingleton<ChestRepository>(
    () => ChestRepository(store: sl<GameLocalStore>()),
  );
  sl.registerLazySingleton<SecureStorage>(SecureStorage.new);

  sl.registerLazySingleton<SessionManager>(
    () => SessionManager(sl<SecureStorage>()),
  );

  sl.registerLazySingleton<DioClient>(() => DioClient(sl<SessionManager>()));

  sl.registerLazySingleton<Dio>(() => sl<DioClient>().create());
}
