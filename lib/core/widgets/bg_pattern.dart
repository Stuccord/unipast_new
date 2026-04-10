import 'package:flutter/material.dart';

class UniPastBackground extends StatelessWidget {
  final Widget child;
  final bool isDark;

  const UniPastBackground({
    super.key,
    required this.child,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: CustomPaint(
            painter: _BackgroundPatternPainter(isDark: isDark),
          ),
        ),
        child,
      ],
    );
  }
}

class _BackgroundPatternPainter extends CustomPainter {
  final bool isDark;

  _BackgroundPatternPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final iconPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    // Subtle opacity for the watermark pattern
    final color = isDark 
        ? Colors.white.withAlpha(5) 
        : Colors.black.withAlpha(2);

    iconPainter.text = TextSpan(
      text: String.fromCharCode(Icons.menu_book_rounded.codePoint),
      style: TextStyle(
        fontSize: 32,
        fontFamily: Icons.menu_book_rounded.fontFamily,
        package: Icons.menu_book_rounded.fontPackage,
        color: color,
      ),
    );
    iconPainter.layout();

    const double spacing = 120.0;
    
    for (double y = -spacing; y < size.height + spacing; y += spacing) {
      for (double x = -spacing; x < size.width + spacing; x += spacing) {
        // Offset x on alternating rows to create a scattered diamond pattern
        final double xOffset = (y / spacing % 2 == 0) ? 0 : spacing / 2;
        
        canvas.save();
        canvas.translate(x + xOffset, y);
        canvas.rotate(-0.2); // slight tilt
        iconPainter.paint(canvas, Offset.zero);
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
