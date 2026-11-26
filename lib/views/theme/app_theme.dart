import 'package:flutter/material.dart';

/// Warna khusus desain "navy glass" yang tidak ada di [ColorScheme].
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.bgTop,
    required this.bgBottom,
    required this.glass,
    required this.glassBorder,
    required this.panelTop,
    required this.panelBottom,
    required this.accent,
    required this.onAccent,
    required this.muted,
  });

  /// Gradasi latar belakang layar.
  final Color bgTop;
  final Color bgBottom;

  /// Kartu transparan di atas latar.
  final Color glass;
  final Color glassBorder;

  /// Panel terang (seperti panel "Statistics" pada referensi).
  final Color panelTop;
  final Color panelBottom;

  /// Aksen emas untuk tombol penting.
  final Color accent;
  final Color onAccent;

  /// Teks sekunder di atas latar.
  final Color muted;

  static const dark = AppPalette(
    bgTop: Color(0xFF2A4A78),
    bgBottom: Color(0xFF142C4C),
    glass: Color(0x1AFFFFFF),
    glassBorder: Color(0x26FFFFFF),
    panelTop: Color(0xFFEEF3FB),
    panelBottom: Color(0xFFD5E0F1),
    accent: Color(0xFFF2BE4B),
    onAccent: Color(0xFF3B2A00),
    muted: Color(0xB3FFFFFF),
  );

  static const light = AppPalette(
    bgTop: Color(0xFFE4ECF8),
    bgBottom: Color(0xFFC3D3EC),
    glass: Color(0x99FFFFFF),
    glassBorder: Color(0xCCFFFFFF),
    panelTop: Color(0xFFFFFFFF),
    panelBottom: Color(0xFFF1F5FC),
    accent: Color(0xFFF2BE4B),
    onAccent: Color(0xFF3B2A00),
    muted: Color(0xFF5B6E8C),
  );

  static AppPalette of(BuildContext context) =>
      Theme.of(context).extension<AppPalette>() ?? dark;

  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      bgTop: l(bgTop, other.bgTop),
      bgBottom: l(bgBottom, other.bgBottom),
      glass: l(glass, other.glass),
      glassBorder: l(glassBorder, other.glassBorder),
      panelTop: l(panelTop, other.panelTop),
      panelBottom: l(panelBottom, other.panelBottom),
      accent: l(accent, other.accent),
      onAccent: l(onAccent, other.onAccent),
      muted: l(muted, other.muted),
    );
  }
}

const _navyText = Color(0xFF17304F);

class AppTheme {
  AppTheme._();

  static const radius = 24.0;

  static ThemeData get dark => _build(
        brightness: Brightness.dark,
        palette: AppPalette.dark,
        scheme: const ColorScheme.dark(
          primary: Color(0xFFA9C8F5),
          onPrimary: Color(0xFF0F2744),
          primaryContainer: Color(0xFF305A8E),
          onPrimaryContainer: Colors.white,
          secondary: Color(0xFFF2BE4B),
          onSecondary: Color(0xFF3B2A00),
          secondaryContainer: Color(0xFF305A8E),
          onSecondaryContainer: Colors.white,
          surface: Color(0xFF1C3A60),
          onSurface: Colors.white,
          onSurfaceVariant: Color(0xB3FFFFFF),
          surfaceContainerHighest: Color(0xFF274B78),
          outline: Color(0x55FFFFFF),
          outlineVariant: Color(0x26FFFFFF),
          error: Color(0xFFFF8A80),
          inverseSurface: Color(0xFFEEF3FB),
          onInverseSurface: _navyText,
        ),
      );

  static ThemeData get light => _build(
        brightness: Brightness.light,
        palette: AppPalette.light,
        scheme: const ColorScheme.light(
          primary: Color(0xFF2A4A78),
          onPrimary: Colors.white,
          primaryContainer: Color(0xFFD3E1F6),
          onPrimaryContainer: _navyText,
          secondary: Color(0xFFE0A82E),
          onSecondary: Color(0xFF3B2A00),
          secondaryContainer: Color(0xFFD3E1F6),
          onSecondaryContainer: _navyText,
          surface: Color(0xFFF5F8FD),
          onSurface: _navyText,
          onSurfaceVariant: Color(0xFF5B6E8C),
          surfaceContainerHighest: Color(0xFFE3EBF7),
          outline: Color(0xFF9AAAC4),
          outlineVariant: Color(0x332A4A78),
          error: Color(0xFFD32F2F),
          inverseSurface: Color(0xFF1C3A60),
          onInverseSurface: Colors.white,
        ),
      );

  /// Tema terang untuk isi panel terang ([FrostPanel]) di mode gelap.
  static ThemeData get panel => light;

  static ThemeData _build({
    required Brightness brightness,
    required AppPalette palette,
    required ColorScheme scheme,
  }) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      fontFamily: 'Poppins',
    );
    final text = base.textTheme.apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: BorderSide(color: palette.glassBorder),
    );

    return base.copyWith(
      textTheme: text,
      extensions: [palette],
      scaffoldBackgroundColor: palette.bgBottom,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        foregroundColor: scheme.onSurface,
        titleTextStyle: text.titleLarge?.copyWith(fontWeight: FontWeight.w600),
      ),
      cardTheme: CardThemeData(
        color: palette.glass,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: shape,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurface,
        textColor: scheme.onSurface,
      ),
      dividerTheme: DividerThemeData(color: palette.glassBorder),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.glass,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: palette.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: palette.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.primary, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: palette.accent,
          foregroundColor: palette.onAccent,
          minimumSize: const Size.fromHeight(52),
          textStyle: text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          side: BorderSide(color: palette.glassBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: scheme.primary),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
      ),
      popupMenuTheme: PopupMenuThemeData(color: scheme.surface),
      drawerTheme: DrawerThemeData(
        backgroundColor: palette.bgBottom,
        surfaceTintColor: Colors.transparent,
      ),
      navigationDrawerTheme: NavigationDrawerThemeData(
        backgroundColor: palette.bgBottom,
        surfaceTintColor: Colors.transparent,
        indicatorColor: palette.glass,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: text.bodyMedium?.copyWith(
          color: scheme.onInverseSurface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
      ),
    );
  }
}
