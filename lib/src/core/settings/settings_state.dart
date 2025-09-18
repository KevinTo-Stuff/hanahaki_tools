// Package imports:
import 'package:equatable/equatable.dart';

class SettingsState extends Equatable {
  final bool isDarkMode;
  final String language;
  final bool notificationsEnabled;

  const SettingsState({
    required this.isDarkMode,
    required this.language,
    required this.notificationsEnabled,
  });

  SettingsState copyWith({
    bool? isDarkMode,
    String? language,
    bool? notificationsEnabled,
  }) {
    return SettingsState(
      isDarkMode: isDarkMode ?? this.isDarkMode,
      language: language ?? this.language,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }

  @override
  List<Object?> get props => [isDarkMode, language, notificationsEnabled];
}
