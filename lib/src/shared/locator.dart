// Package imports:
import 'package:get_it/get_it.dart';

// Project imports:
import 'package:hanahaki_tools/src/core/routing/app_router.dart';
import 'package:hanahaki_tools/src/shared/services/storage/local_storage.dart';
import 'package:hanahaki_tools/src/shared/services/storage/storage.dart';

final GetIt locator = GetIt.instance
  ..registerLazySingleton(() => AppRouter())
  ..registerLazySingleton<Storage>(() => LocalStorage());
