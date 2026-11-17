import 'package:flutter/material.dart';
import '../animations/app_animations.dart';
import '../constants/app_colors.dart';
import '../navigation/main_navigation_screen.dart';

/// Official JAIHIND RUNNERS CLUB Brand Logo widget.
/// Renders the official circular tricolor runners club emblem alongside
/// bold high-contrast typography. Tapping it navigates back to Home screen (Tab 0).
class JaihindBrandLogo extends StatelessWidget {
  final double fontSize;
  final double emblemHeight;
  final Color? color;
  final bool showEmblem;
  final bool showSubtitle;
  final bool isEmblemOnly;
  final VoidCallback? onTap;
  final bool enableTapToHome;

  const JaihindBrandLogo({
    super.key,
    this.fontSize = 22,
    this.emblemHeight = 28,
    this.color,
    this.showEmblem = true,
    this.showSubtitle = false,
    this.isEmblemOnly = false,
    this.onTap,
    this.enableTapToHome = true,
  });

  void _handleTap(BuildContext context) {
    if (onTap != null) {
      onTap!();
      return;
    }
    if (!enableTapToHome) return;

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
    final nav = MainNavigationScreen.of(context);
    nav?.switchTab(0);
  }

  @override
  Widget build(BuildContext context) {
    final Widget content = isEmblemOnly
        ? Image.asset(
            'assets/images/jaihind_logo_circle.png',
            width: emblemHeight,
            height: emblemHeight,
            fit: BoxFit.contain,
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (showEmblem) ...[
                Container(
                  width: emblemHeight,
                  height: emblemHeight,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset(
                    'assets/images/jaihind_logo_circle.png',
                    width: emblemHeight,
                    height: emblemHeight,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (color != null)
                    Text(
                      'JAIHIND',
                      style: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                        letterSpacing: 1.0,
                        color: color,
                        height: 1.05,
                      ),
                    )
                  else
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: fontSize,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                          letterSpacing: 1.0,
                          height: 1.05,
                        ),
                        children: const [
                          TextSpan(
                            text: 'JAI',
                            style: TextStyle(color: AppColors.primaryBlue),
                          ),
                          TextSpan(
                            text: 'HIND',
                            style: TextStyle(color: AppColors.accentGreen),
                          ),
                        ],
                      ),
                    ),
                  if (showSubtitle) ...[
                    const SizedBox(height: 1),
                    const Text(
                      'RUNNERS CLUB',
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                        color: Color(0xFF061A33),
                        height: 1.0,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          );

    if (enableTapToHome || onTap != null) {
      return BouncingTap(
        onTap: () => _handleTap(context),
        child: content,
      );
    }
    return content;
  }
}
