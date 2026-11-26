import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Api yang terus menyala di belakang [child] selama [active] true.
/// Dipakai sebagai penanda tab yang sedang aktif.
class BurnGlow extends StatefulWidget {
  const BurnGlow({super.key, required this.active, required this.child});
  final bool active;
  final Widget child;

  @override
  State<BurnGlow> createState() => _BurnGlowState();
}

class _BurnGlowState extends State<BurnGlow> with TickerProviderStateMixin {
  /// Besar api 0..1: menyala saat aktif, padam saat tidak.
  late final AnimationController _heat = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 600),
    reverseDuration: const Duration(milliseconds: 350),
    value: widget.active ? 1 : 0,
  );

  /// Detak gerakan lidah api yang berulang.
  late final AnimationController _loop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  late final List<_Flame> _flames = () {
    final r = math.Random();
    return List.generate(14, (i) => _Flame.random(r, i / 14));
  }();

  @override
  void initState() {
    super.initState();
    _heat.addStatusListener((s) {
      if (s == AnimationStatus.dismissed) _loop.stop();
    });
    if (widget.active) _loop.repeat();
  }

  @override
  void didUpdateWidget(BurnGlow old) {
    super.didUpdateWidget(old);
    if (widget.active == old.active) return;
    if (widget.active) {
      if (!_loop.isAnimating) _loop.repeat();
      _heat.forward();
    } else {
      _heat.reverse();
    }
  }

  @override
  void dispose() {
    _heat.dispose();
    _loop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_heat, _loop]),
      child: widget.child,
      builder: (context, child) {
        final heat = Curves.easeOut.transform(_heat.value);
        if (heat == 0) return child!;
        return Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // Api digambar DI BELAKANG simbol.
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _FirePainter(_flames, _loop.value, heat),
                ),
              ),
            ),
            child!,
          ],
        );
      },
    );
  }
}

class _Flame {
  _Flame(this.dx, this.speed, this.size, this.phase, this.wobble);

  factory _Flame.random(math.Random r, double phase) => _Flame(
        (r.nextDouble() - 0.5) * 1.1,
        0.8 + r.nextDouble() * 0.5,
        7 + r.nextDouble() * 6,
        phase,
        r.nextDouble() * math.pi * 2,
      );

  final double dx;
  final double speed;
  final double size;
  final double phase;
  final double wobble;
}

class _FirePainter extends CustomPainter {
  _FirePainter(this.flames, this.t, this.heat);
  final List<_Flame> flames;
  final double t;
  final double heat;

  static const _colors = [
    Color(0xFFFFE27A),
    Color(0xFFFFA726),
    Color(0xFFFF5722),
    Color(0x00B71C1C),
  ];

  Color _fireColor(double p) {
    final s = p * (_colors.length - 1);
    final i = s.floor().clamp(0, _colors.length - 2);
    return Color.lerp(_colors[i], _colors[i + 1], s - i)!;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final flicker = 0.85 + 0.15 * math.sin(t * math.pi * 8);

    // Cahaya bara.
    canvas.drawCircle(
      center.translate(0, size.height * 0.1),
      size.shortestSide * 0.75,
      Paint()
        ..color =
            const Color(0xFFFF7A1A).withValues(alpha: 0.5 * heat * flicker)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    // Lidah api naik dari bawah simbol, terus berulang.
    final base = center.dy + size.height * 0.55;
    final rise = size.height * 1.3 * heat;
    for (final f in flames) {
      final p = (t * f.speed + f.phase) % 1.0;
      final y = base - rise * p;
      final x = center.dx +
          f.dx * size.width * 0.55 * (1 - p * 0.6) +
          math.sin(f.wobble + p * math.pi * 3) * 2.5;
      final r = f.size * heat * (1 - p * 0.65);
      final color = _fireColor(p);
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, y), width: r * 1.2, height: r * 2.3),
        Paint()
          ..color = color.withValues(alpha: color.a * heat)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );
    }
  }

  @override
  bool shouldRepaint(_FirePainter old) => old.t != t || old.heat != heat;
}
