import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// The JoinMe pin mark, optionally followed by the "JoinMe" wordmark.
class JoinMeLogo extends StatelessWidget {
  final double size;
  final bool showName;

  const JoinMeLogo({super.key, this.size = 40, this.showName = true});

  @override
  Widget build(BuildContext context) {
    final mark = Image.asset('assets/logo/joinme_mark.png', width: size, height: size);
    if (!showName) return mark;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        mark,
        SizedBox(width: size * 0.15),
        ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) => AppTheme.brandGradient.createShader(bounds),
          child: Text(
            'JoinMe',
            style: TextStyle(fontSize: size * 0.62, fontWeight: FontWeight.w800, letterSpacing: -0.5),
          ),
        ),
      ],
    );
  }
}
