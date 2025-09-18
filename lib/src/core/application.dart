// Flutter imports:
import 'package:flutter/material.dart';

// Package imports:
import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

// Project imports:
import 'package:hanahaki_tools/src/core/environment.dart';
import 'package:hanahaki_tools/src/core/routing/app_router.dart';
import 'package:hanahaki_tools/src/core/settings/settings_cubit.dart';
import 'package:hanahaki_tools/src/core/settings/settings_state.dart';
import 'package:hanahaki_tools/src/core/theme/app_theme.dart';
import 'package:hanahaki_tools/src/shared/locator.dart';

class Application extends StatelessWidget {
  final AppRouter _appRouter;

  Application({super.key, AppRouter? appRouter})
    : _appRouter = appRouter ?? locator<AppRouter>();

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SettingsCubit>(
      create: (_) => SettingsCubit(),
      child: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          return MaterialApp.router(
            title: Environment.appName,
            routerConfig: _appRouter.config(
              navigatorObservers: () => [AutoRouteObserver()],
            ),
            theme: state.isDarkMode ? AppTheme.darkTheme : AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
