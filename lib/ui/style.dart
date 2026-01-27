import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:laundriin/ui/color.dart';
import 'package:laundriin/ui/dimension.dart';
import 'package:laundriin/ui/typography.dart';

final ElevatedButtonThemeData elevatedButtonThemeData = ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(spacing3)),
        padding: const EdgeInsets.symmetric(
            horizontal: spacing4, vertical: spacing3),
        foregroundColor: textButtonPrimary,
        backgroundColor: bgButtonPrimaryDefault,
        disabledForegroundColor: textDisabled,
        disabledBackgroundColor: bgDisabled,
        textStyle: xsMedium,
        minimumSize: const Size(0, 0)));

final OutlinedButtonThemeData outlinedButtonThemeData = OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(spacing3)),
        padding: const EdgeInsets.symmetric(
            horizontal: spacing4, vertical: spacing3),
        foregroundColor: textNeutralPrimary,
        textStyle: xsMedium,
        minimumSize: const Size(0, 0)));

ButtonStyle elevatedButtonLargeStyle = ElevatedButton.styleFrom(
    padding:
        const EdgeInsets.symmetric(horizontal: space500, vertical: space400),
    textStyle: smMedium,
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius300)));

ButtonStyle outlinedButtonLargeStyle = OutlinedButton.styleFrom(
    padding:
        const EdgeInsets.symmetric(horizontal: space500, vertical: space400),
    textStyle: smMedium,
    shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius300)));

InputDecorationTheme inputDecorationTheme = InputDecorationTheme(
    hintStyle: sRegular.copyWith(color: textNeutralSecondary),
    labelStyle: sMedium.copyWith(color: textNeutralPrimary),
    counterStyle: sMedium.copyWith(color: textNeutralPrimary),
    floatingLabelBehavior: FloatingLabelBehavior.always,
    fillColor: WidgetStateColor.resolveWith(
      (Set<WidgetState> states) {
        if (states.contains(WidgetState.disabled)) {
          return bgDisabled;
        } else {
          return Colors.transparent;
        }
      },
    ),
    filled: true,
    contentPadding: const EdgeInsets.symmetric(
      horizontal: spacing6,
      vertical: spacing4,
    ),
    enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius300),
        borderSide: const BorderSide(
          color: borderFormDefault,
        )),
    focusColor: borderButtonOutlinedFocused,
    disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius300),
        borderSide: const BorderSide(color: borderDisabled)),
    focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius300),
        borderSide: const BorderSide(color: borderButtonOutlinedFocused)),
    focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius300),
        borderSide: const BorderSide(color: borderFormDanger)),
    errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(borderRadius300),
        borderSide: const BorderSide(color: borderFormDanger)));

AppBarTheme appbarTheme = AppBarTheme(
  surfaceTintColor: Colors.white,
  centerTitle: false,
  titleTextStyle: mMedium.copyWith(color: textNeutralPrimary),
);

ActionIconThemeData actionIconThemeData = ActionIconThemeData(
  backButtonIconBuilder: (BuildContext context) => SvgPicture.asset(
    "assets/images/ic_chevron_left.svg",
    width: 20,
    height: 20,
  ),
);

TextButtonThemeData textButtonThemeData = TextButtonThemeData(
  style: TextButton.styleFrom(
      foregroundColor: textButtonInfoDefault, textStyle: sMedium),
);

InputDecoration inputDecoration([bool? enabled]) {
  final fadedStyle = TextStyle(
    color: bgFillNeutral,
    fontSize: 14,
    height: 1.6,
  );

  return InputDecoration(
    fillColor: Colors.transparent,
    filled: true,
    prefixStyle: fadedStyle,
    hintStyle: fadedStyle,
    contentPadding: const EdgeInsets.only(
      right: 14,
      top: 10,
      bottom: 14,
      left: 8,
    ),
    enabled: enabled ?? true,
    border: OutlineInputBorder(
      borderSide: const BorderSide(color: borderNeutral),
      borderRadius: BorderRadius.circular(12),
    ),
    enabledBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: borderNeutral),
      borderRadius: BorderRadius.circular(12),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: primaryColor, width: 2),
      borderRadius: BorderRadius.circular(12),
    ),
    disabledBorder: OutlineInputBorder(
      borderSide: const BorderSide(color: borderNeutral),
      borderRadius: BorderRadius.circular(12),
    ),
    errorBorder: OutlineInputBorder(
      borderSide: BorderSide(
        color: bgFillDanger,
      ),
      borderRadius: BorderRadius.circular(12),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderSide: BorderSide(
        color: bgFillDanger,
      ),
      borderRadius: BorderRadius.circular(12),
    ),
  );
}
