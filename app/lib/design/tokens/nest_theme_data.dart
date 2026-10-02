import 'package:flutter/material.dart';

import 'nest_spacing.dart';
import 'nest_theme.dart';
import 'nest_typography.dart';

/// Material `ThemeData` derived from the tokens, for the few Material widgets
/// used directly (a switch, a date picker, a snackbar).
ThemeData nestThemeData(NestTheme nest) {
  final colors = nest.colors;
  final text = nest.text;
  final pill = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(NestRadius.pill),
  );
  final scheme = ColorScheme(
    brightness: nest.brightness,
    primary: colors.accent,
    onPrimary: colors.onAccent,
    primaryContainer: colors.accentSoft,
    onPrimaryContainer: colors.accentInk,
    secondary: colors.secondary,
    onSecondary: colors.onSecondary,
    secondaryContainer: colors.secondarySoft,
    onSecondaryContainer: colors.secondaryInk,
    tertiary: colors.highlight,
    error: colors.danger,
    onError: colors.onDanger,
    errorContainer: colors.dangerSoft,
    onErrorContainer: colors.danger,
    surface: colors.surface,
    onSurface: colors.ink,
    onSurfaceVariant: colors.inkSecondary,
    surfaceContainerHighest: colors.surfaceTint,
    surfaceContainerLow: colors.canvas,
    outline: colors.outlineStrong,
    outlineVariant: colors.outline,
    shadow: Colors.black,
    scrim: colors.scrim,
    inverseSurface: colors.ink,
    onInverseSurface: colors.surface,
    inversePrimary: colors.accentSoft,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: nest.brightness,
    colorScheme: scheme,
    fontFamily: NestTextStyles.fontFamily,
    scaffoldBackgroundColor: colors.canvas,
    canvasColor: colors.canvas,
    splashFactory: InkRipple.splashFactory,
    extensions: [nest],
    textTheme: TextTheme(
      displaySmall: text.display,
      headlineSmall: text.headline,
      titleLarge: text.title,
      titleMedium: text.bodyStrong,
      bodyLarge: text.body,
      bodyMedium: text.bodySecondary,
      labelLarge: text.button,
      labelMedium: text.label,
      bodySmall: text.caption,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      foregroundColor: colors.ink,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: text.screenTitle,
    ),
    cardTheme: CardThemeData(
      color: colors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(NestRadius.xl),
        side: BorderSide(color: colors.outline),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: colors.accent,
        foregroundColor: colors.onAccent,
        minimumSize: const Size.fromHeight(NestSize.controlLarge),
        textStyle: text.button,
        shape: pill,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colors.ink,
        side: BorderSide(color: colors.outlineStrong),
        minimumSize: const Size.fromHeight(NestSize.controlLarge),
        textStyle: text.button,
        shape: pill,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: colors.accentInk,
        textStyle: text.button,
        shape: pill,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colors.canvas,
      hintStyle: text.body.copyWith(color: colors.inkTertiary),
      labelStyle: text.label.copyWith(color: colors.inkSecondary),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: NestSpace.xl,
        vertical: NestSpace.lg,
      ),
      border: _inputBorder(colors.outline),
      enabledBorder: _inputBorder(colors.outline),
      focusedBorder: _inputBorder(colors.accent, width: NestStroke.focus),
      errorBorder: _inputBorder(colors.danger),
      focusedErrorBorder: _inputBorder(colors.danger, width: NestStroke.focus),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: colors.surface,
      selectedColor: colors.secondary,
      side: BorderSide(color: colors.outline),
      labelStyle: text.label,
      shape: pill,
      showCheckmark: false,
    ),
    dividerTheme: DividerThemeData(
      color: colors.outline,
      thickness: NestStroke.hairline,
      space: NestStroke.hairline,
    ),
    listTileTheme: ListTileThemeData(
      iconColor: colors.accentInk,
      textColor: colors.ink,
      titleTextStyle: text.bodyStrong,
      subtitleTextStyle: text.caption,
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: colors.surface,
      surfaceTintColor: Colors.transparent,
      modalBarrierColor: colors.scrim,
      showDragHandle: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(NestRadius.xxl),
        ),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: colors.ink,
      contentTextStyle: text.body.copyWith(color: colors.surface),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(NestRadius.md),
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: colors.accent,
      circularTrackColor: colors.accentSoft,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStatePropertyAll(colors.surface),
      trackColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? colors.accent
            : colors.outlineStrong,
      ),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? colors.accent
            : colors.surface,
      ),
      checkColor: WidgetStatePropertyAll(colors.onAccent),
      side: BorderSide(color: colors.outlineStrong, width: NestStroke.focus),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(NestRadius.sm / 2),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: colors.surface,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: text.title,
      contentTextStyle: text.bodySecondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(NestRadius.xxl),
      ),
    ),
  );
}

OutlineInputBorder _inputBorder(
  Color color, {
  double width = NestStroke.hairline,
}) => OutlineInputBorder(
  borderRadius: BorderRadius.circular(NestRadius.lg),
  borderSide: BorderSide(color: color, width: width),
);
