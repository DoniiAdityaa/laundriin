import 'package:flutter/material.dart';
import 'package:laundriin/ui/color.dart';
import 'package:laundriin/ui/style.dart';
import 'package:laundriin/ui/typography.dart';

class AppTheme {
  // Settings Light Theme
  static ThemeData get light {
    return ThemeData(
      dividerTheme: DividerThemeData(color: primaryColor),
      fontFamily: "DIN14",
      useMaterial3: true,
      colorScheme: const ColorScheme(
        brightness: Brightness.light,
        primary: primaryColor,
        onPrimary: black50,
        primaryContainer: primaryColor,
        onPrimaryContainer: black50,
        secondary: secondaryColor,
        onSecondary: black50,
        secondaryContainer: secondaryColor,
        onSecondaryContainer: black50,
        error: errorColor,
        onError: black50,
        surface: bgColor,
        onSurface: textNeutralPrimary,
      ),
      textTheme: TextTheme(
        displayLarge: lBold.copyWith(color: textNeutralPrimary),
        displayMedium: mlBold.copyWith(color: textNeutralPrimary),
        displaySmall: mBold.copyWith(color: textNeutralPrimary),
        headlineLarge: lSemiBold.copyWith(color: textNeutralPrimary),
        headlineMedium: mlSemiBold.copyWith(color: textNeutralPrimary),
        headlineSmall: mSemiBold.copyWith(color: textNeutralPrimary),
        titleLarge: smMedium.copyWith(color: textNeutralPrimary),
        titleMedium: sMedium.copyWith(color: textNeutralPrimary),
        titleSmall: xsMedium.copyWith(color: textNeutralPrimary),
        bodyLarge: smRegular.copyWith(color: textNeutralPrimary),
        bodyMedium: sRegular.copyWith(color: textNeutralPrimary),
        bodySmall: xsRegular.copyWith(color: textNeutralPrimary),
        labelLarge: sRegular.copyWith(color: textNeutralPrimary),
        labelMedium: xsRegular.copyWith(color: textNeutralPrimary),
        labelSmall: xxsRegular.copyWith(color: textNeutralPrimary),
      ),
      elevatedButtonTheme: elevatedButtonThemeData,
      outlinedButtonTheme: outlinedButtonThemeData,
      scaffoldBackgroundColor: bgColor,
      inputDecorationTheme: inputDecorationTheme,
      appBarTheme: appbarTheme,
      actionIconTheme: actionIconThemeData,
      textButtonTheme: textButtonThemeData,
    );
  }

  static ThemeData get dark {
    return ThemeData(
        dividerTheme: DividerThemeData(
          color: transparentColor,
        ),
        fontFamily: "DIN14",
        useMaterial3: true,
        colorScheme: const ColorScheme(
            brightness: Brightness.light,
            primary: primaryColor,
            onPrimary: black50,
            primaryContainer: primaryColor,
            onPrimaryContainer: black50,
            secondary: secondaryColor,
            onSecondary: black50,
            secondaryContainer: secondaryColor,
            onSecondaryContainer: black50,
            error: errorColor,
            onError: black50,
            surface: bgColor,
            onSurface: textNeutralPrimary),
        textTheme: TextTheme(
          displayLarge: lBold.copyWith(color: textNeutralPrimary),
          displayMedium: mlBold.copyWith(color: textNeutralPrimary),
          displaySmall: mBold.copyWith(color: textNeutralPrimary),
          headlineLarge: lSemiBold.copyWith(color: textNeutralPrimary),
          headlineMedium: mlSemiBold.copyWith(color: textNeutralPrimary),
          headlineSmall: mSemiBold.copyWith(color: textNeutralPrimary),
          titleLarge: smMedium.copyWith(color: textNeutralPrimary),
          titleMedium: sMedium.copyWith(color: textNeutralPrimary),
          titleSmall: xsMedium.copyWith(color: textNeutralPrimary),
          bodyLarge: smRegular.copyWith(color: textNeutralPrimary),
          bodyMedium: sRegular.copyWith(color: textNeutralPrimary),
          bodySmall: xsRegular.copyWith(color: textNeutralPrimary),
          labelLarge: sRegular.copyWith(color: textNeutralPrimary),
          labelMedium: xsRegular.copyWith(color: textNeutralPrimary),
          labelSmall: xxsRegular.copyWith(color: textNeutralPrimary),
        ),
        elevatedButtonTheme: elevatedButtonThemeData,
        outlinedButtonTheme: outlinedButtonThemeData,
        scaffoldBackgroundColor: bgColor,
        inputDecorationTheme: inputDecorationTheme,
        appBarTheme: appbarTheme,
        actionIconTheme: actionIconThemeData,
        textButtonTheme: textButtonThemeData);
  }
}

class AsabaColorScheme extends ColorScheme {
  const AsabaColorScheme(
      {required super.brightness,
      required super.primary,
      required super.onPrimary,
      required super.secondary,
      required super.onSecondary,
      required super.error,
      required super.onError,
      required super.surface,
      required super.onSurface});
}

class AsabaTextTheme extends TextTheme {
  const AsabaTextTheme({required super.bodyLarge});
}
