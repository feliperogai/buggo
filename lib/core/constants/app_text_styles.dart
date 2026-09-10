import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  // Display (Nunito ExtraBold)
  static TextStyle get displayLarge => GoogleFonts.nunito(
        fontSize: 38,
        fontWeight: FontWeight.w900,
        color: AppColors.textPrimary,
        letterSpacing: 0,
      );

  static TextStyle get displayMedium => GoogleFonts.nunito(
        fontSize: 30,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        letterSpacing: 0,
      );

  static TextStyle get headlineLarge => GoogleFonts.nunito(
        fontSize: 26,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        letterSpacing: 0,
      );

  static TextStyle get headlineMedium => GoogleFonts.nunito(
        fontSize: 21,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  static TextStyle get headlineSmall => GoogleFonts.nunito(
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyLarge => GoogleFonts.nunito(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      );

  static TextStyle get bodyMedium => GoogleFonts.nunito(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: AppColors.textSecondary,
      );

  static TextStyle get bodySmall => GoogleFonts.nunito(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: AppColors.textMuted,
      );

  static TextStyle get labelLarge => GoogleFonts.nunito(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
        letterSpacing: 0,
      );

  static TextStyle get labelSmall => GoogleFonts.nunito(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.textMuted,
        letterSpacing: 0,
      );

  // Code (Fira Code)
  //
  // As ligaduras da Fira Code são desligadas de propósito. Com elas, `<<`,
  // `->`, `=>`, `!=`, `>=` e `::` viram um glifo colado só — bonito para quem
  // já programa, símbolo estranho para quem está aprendendo e ainda vai
  // digitar aqueles dois caracteres. Some justamente nas linguagens que mais
  // usam esses operadores: C++, Rust, Go, PHP, JavaScript, Kotlin, Swift.
  //
  // `liga` são as ligaduras padrão e `calt` as contextuais, que é onde a Fira
  // Code coloca os operadores. Precisa desligar as duas.
  static const _noLigatures = <FontFeature>[
    FontFeature.disable('liga'),
    FontFeature.disable('calt'),
  ];

  static TextStyle get code => GoogleFonts.firaCode(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: AppColors.primary,
        fontFeatures: _noLigatures,
      );

  static TextStyle get codeLarge => GoogleFonts.firaCode(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: AppColors.primary,
        fontFeatures: _noLigatures,
      );

  // Backward compat aliases for pixel styles that are still referenced
  static TextStyle get pixelHeadline => GoogleFonts.nunito(
        fontSize: 18,
        fontWeight: FontWeight.w800,
        color: AppColors.textPrimary,
      );

  static TextStyle get pixelBody => GoogleFonts.nunito(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      );

  static TextStyle get pixelSmall => GoogleFonts.nunito(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.textSecondary,
        letterSpacing: 0,
      );
}
