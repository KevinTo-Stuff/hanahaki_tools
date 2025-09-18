// Package imports:
import 'package:flutter_bloc/flutter_bloc.dart';

// Project imports:
import 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit()
    : super(
        const SettingsState(
          isDarkMode: false,
          language: 'en',
          notificationsEnabled: true,
        ),
      );

  void toggleDarkMode() {
    emit(state.copyWith(isDarkMode: !state.isDarkMode));
  }

  void changeLanguage(String newLanguage) {
    emit(state.copyWith(language: newLanguage));
  }

  void setNotificationsEnabled(bool enabled) {
    emit(state.copyWith(notificationsEnabled: enabled));
  }
}
