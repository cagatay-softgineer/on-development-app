// lib/di/injection.dart

import 'package:get_it/get_it.dart';
import 'package:pomodoro/models/music_app.dart';

import 'package:pomodoro/services/main_api.dart';
import 'package:pomodoro/services/spotify_api.dart';

import 'package:pomodoro/data/datasources/local/button_params_local_ds.dart';
import 'package:pomodoro/data/repositories/button_params_repository.dart';

import 'package:pomodoro/viewmodels/button_params_viewmodel.dart';
import 'package:pomodoro/viewmodels/chain_viewmodel.dart';
import 'package:pomodoro/viewmodels/home_viewmodel.dart';
import 'package:pomodoro/viewmodels/navigation_viewmodel.dart';
import 'package:pomodoro/viewmodels/player_control_viewmodel.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  // ─── Core Services ─────────────────────────────────────────────────────────
  getIt.registerLazySingleton<MainAPI>(() => MainAPI());
  getIt.registerLazySingleton<SpotifyAPI>(() => SpotifyAPI());

  // ─── Data Sources & Repositories ───────────────────────────────────────────
  getIt.registerLazySingleton<ButtonParamsLocalDataSource>(
    () => ButtonParamsLocalDataSource(),
  );
  getIt.registerLazySingleton<ButtonParamsRepository>(
    () => ButtonParamsRepositoryImpl(getIt<ButtonParamsLocalDataSource>()),
  );

  // ─── ViewModels ────────────────────────────────────────────────────────────
  getIt.registerFactory<ButtonParamsViewModel>(
    () => ButtonParamsViewModel(getIt<ButtonParamsRepository>()),
  );

  getIt.registerFactory<ChainViewModel>(
    () => ChainViewModel(),
  );

  getIt.registerFactory<HomeViewModel>(
    () => HomeViewModel(),
  );

  getIt.registerFactory<NavigationViewModel>(
    () => NavigationViewModel(),
  );

  getIt.registerFactory<PlayerControlViewModel>(
    () => PlayerControlViewModel(
      selectedApp: MusicApp.spotify
    ),
  );
}
