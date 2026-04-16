import 'dart:math' as math;
import 'package:flutter/material.dart';

class _GL {
  static const bg         = Color(0xFF05080F);
  static const surface    = Color(0xFF0D1526);
  static const card       = Color(0xFF111D35);
  static const divider    = Color(0xFF1E2F50);
  static const primary    = Color(0xFF00E5CC);
  static const secondary  = Color(0xFF7C3AED);
  static const accent     = Color(0xFFFFB800);
  static const text       = Color(0xFFE2EAF4);
  static const textMuted  = Color(0xFF7B8BAA);
  static const danger     = Color(0xFFFF4560);
}

class GMTheme {
  static const bg = _GL.bg;
  static const surface = _GL.surface;
  static const card = _GL.card;
  static const divider = _GL.divider;
  static const primary = _GL.primary;
  static const secondary = _GL.secondary;
  static const accent = _GL.accent;
  static const text = _GL.text;
  static const textMuted = _GL.textMuted;
  static const danger = _GL.danger;
  
  static BoxShadow glowPrimary = BoxShadow(
    color: _GL.primary.withAlpha(50),
    blurRadius: 20,
    offset: const Offset(0, 8),
  );
  
  static BoxDecoration glassBox = BoxDecoration(
    color: _GL.card.withAlpha(180),
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: _GL.divider),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withAlpha(100),
        blurRadius: 30,
        offset: const Offset(0, 10),
      )
    ],
  );
}

class AnimatedNeuralBg extends StatefulWidget {
  const AnimatedNeuralBg({super.key});

  @override
  State<AnimatedNeuralBg> createState() => _AnimatedNeuralBgState();
}

class _AnimatedNeuralBgState extends State<AnimatedNeuralBg> with SingleTickerProviderStateMixin {
  late final AnimationController _rotateCtrl;

  @override
  void initState() {
    super.initState();
    _rotateCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 40))..repeat();
  }

  @override
  void dispose() {
    _rotateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _rotateCtrl,
      builder: (_, __) => CustomPaint(
        painter: _NeuralHomePainter(_rotateCtrl.value),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _NeuralHomePainter extends CustomPainter {
  final double t;
  _NeuralHomePainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final rng = math.Random(1234);
    
    // Generate nodes across the screen
    final nodes = List.generate(24, (i) {
      final angle = (i / 24) * 2 * math.pi + t * math.pi * (i % 2 == 0 ? 1 : -1);
      final rX = size.width * (0.3 + 0.2 * rng.nextDouble());
      final rY = size.height * (0.3 + 0.3 * rng.nextDouble());
      
      return Offset(
        size.width / 2 + math.cos(angle) * rX,
        size.height / 2 + math.sin(angle) * rY,
      );
    });

    // Draw connections
    final linePaint = Paint()
      ..color = GMTheme.primary.withAlpha(8)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < nodes.length; i++) {
      for (int j = i + 1; j < nodes.length; j++) {
        final dist = (nodes[i] - nodes[j]).distance;
        if (dist < 200) {
          canvas.drawLine(nodes[i], nodes[j], linePaint);
        }
      }
    }

    // Draw glowing nodes
    for (final n in nodes) {
      final glow = Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10)
        ..color = GMTheme.primary.withAlpha(20);
      canvas.drawCircle(n, 8, glow);
      canvas.drawCircle(n, 2, Paint()..color = GMTheme.primary.withAlpha(60));
    }

    // Large ambient background glows
    canvas.drawCircle(
      Offset(size.width * 0.8, size.height * 0.1),
      250,
      Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 120)
        ..color = GMTheme.secondary.withAlpha(15),
    );

    canvas.drawCircle(
      Offset(size.width * 0.2, size.height * 0.7),
      300,
      Paint()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 140)
        ..color = GMTheme.primary.withAlpha(10),
    );
  }

  @override
  bool shouldRepaint(_NeuralHomePainter old) => old.t != t;
}
