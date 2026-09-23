import 'package:dino/core/network/session_manager.dart';
import 'package:dino/core/storage/secure_storage.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';

import '../network/dio_client.dart';

final sl = GetIt.instance;

void configureDependencies() {
  sl.registerLazySingleton<SecureStorage>(SecureStorage.new);

  sl.registerLazySingleton<SessionManager>(
    () => SessionManager(sl<SecureStorage>()),
  );

  sl.registerLazySingleton<DioClient>(() => DioClient(sl<SessionManager>()));

  sl.registerLazySingleton<Dio>(() => sl<DioClient>().create());
}
