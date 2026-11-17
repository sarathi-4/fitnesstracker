import 'package:flutter/material.dart';

class AppColors {
  // Brand Colors (Inpand Technologies Palette: Vibrant Tech Blue & Energetic Green)
  static const Color primaryBlue = Color(0xFF0379CE); // #0379CE Inpand Blue
  static const Color accentGreen = Color(0xFF14A847); // #14A847 Inpand Green
  static const Color cyanAccent = Color(0xFF0284C7);

  // Backward compatibility alias: primaryOrange routes to primaryBlue
  static const Color primaryOrange = Color(0xFF0379CE);
  static const Color orangeGradientStart = Color(0xFF0379CE);
  static const Color orangeGradientEnd = Color(0xFF14A847);

  // Neutral Colors (Dark & High Contrast on Crisp White)
  static const Color backgroundWhite = Color(0xFFFFFFFF); // Pure white as requested
  static const Color textBlack = Color(0xFF111827); // Rich deep charcoal
  static const Color textDark = Color(0xFF111827); // Deep modern black
  static const Color textGrey = Color(0xFF374151); // Dark legible charcoal
  static const Color dotInactive = Color(0xFFD1D5DB);
  static const Color borderBlack = Color(0xFF111827);
  static const Color greyCircle = Color(0xFFF1F5F9);
  static const Color navGrey = Color(0xFF475569); // Slate grey for navigation labels
  
  // Soft tinted card backgrounds
  static const Color bannerBg = Color(0xFFF0F7FF); // Soft blue tint
  static const Color trophyCardBg = Color(0xFFF0FDF4); // Soft emerald green tint
  static const Color cardBorder = Color(0xFFE2E8F0);

  // Gradients
  static const LinearGradient brandGradient = LinearGradient(
    colors: [primaryBlue, accentGreen],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient blueGradient = LinearGradient(
    colors: [Color(0xFF0284C7), Color(0xFF0379CE)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient greenGradient = LinearGradient(
    colors: [Color(0xFF16A34A), Color(0xFF14A847)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Backward-compatible alias
  static const LinearGradient orangeGradient = brandGradient;
}
