// Flutter imports:
import 'package:flutter/material.dart';

const lightColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: Color(0xFFB76E79), // darker pastel pink
  onPrimary: Color(0xFFFFFFFF),
  primaryContainer: Color(0xFFA05268), // even darker pastel pink
  onPrimaryContainer: Color(0xFFFFFFFF),
  secondary: Color(0xFFC97A99), // muted pastel pink accent
  onSecondary: Color(0xFFFFFFFF),
  secondaryContainer: Color(0xFF8D4F5A), // deep muted pink
  onSecondaryContainer: Color(0xFFFFFFFF),
  tertiary: Color(0xFFD8A7B1), // soft pastel pink
  onTertiary: Color(0xFF4A148C),
  tertiaryContainer: Color(0xFFB76E79),
  onTertiaryContainer: Color(0xFFFFFFFF),
  error: Color(0xFFB3261E),
  onError: Color(0xFFFFFFFF),
  errorContainer: Color(0xFFF9DEDC),
  onErrorContainer: Color(0xFF410E0B),
  outline: Color(0xFFC97A99),
  surface: Color.fromARGB(
    255,
    255,
    255,
    255,
  ), // pastel pink surface, slightly darker
  onSurface: Color.fromARGB(255, 0, 0, 0),
  onSurfaceVariant: Color(0xFFA05268),
  inverseSurface: Color(0xFF8D4F5A),
  onInverseSurface: Color(0xFFF2D4D7),
  inversePrimary: Color(0xFFC97A99),
  shadow: Color(0xFF000000),
  surfaceTint: Color(0xFFB76E79),
  outlineVariant: Color(0xFFD8A7B1),
  scrim: Color(0xFF000000),
);

const darkColorScheme = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFFD0BCFF),
  onPrimary: Color(0xFF381E72),
  primaryContainer: Color(0xFF4F378B),
  onPrimaryContainer: Color(0xFFEADDFF),
  secondary: Color(0xFFCCC2DC),
  onSecondary: Color(0xFF332D41),
  secondaryContainer: Color(0xFF4A4458),
  onSecondaryContainer: Color(0xFFE8DEF8),
  tertiary: Color(0xFFEFB8C8),
  onTertiary: Color(0xFF492532),
  tertiaryContainer: Color(0xFF633B48),
  onTertiaryContainer: Color(0xFFFFD8E4),
  error: Color(0xFFF2B8B5),
  onError: Color(0xFF601410),
  errorContainer: Color(0xFF8C1D18),
  onErrorContainer: Color(0xFFF9DEDC),
  outline: Color(0xFF938F99),
  surface: Color.fromARGB(255, 37, 37, 41),
  onSurface: Color.fromARGB(255, 226, 227, 216),
  onSurfaceVariant: Color(0xFFCAC4D0),
  inverseSurface: Color(0xFFE6E1E5),
  onInverseSurface: Color(0xFF313033),
  inversePrimary: Color(0xFF6750A4),
  shadow: Color(0xFF000000),
  surfaceTint: Color(0xFFD0BCFF),
  outlineVariant: Color(0xFF49454F),
  scrim: Color(0xFF000000),
);
