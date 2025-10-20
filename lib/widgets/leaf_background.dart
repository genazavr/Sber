import 'dart:math';
import 'package:flutter/material.dart';

/// Фон с живыми листьями.
/// Параметры:
/// - child: контент поверх листьев
/// - offsetFactor: насколько далеко листья "разлетаются"
/// - waveSpeed: скорость покачивания (влияет на частоту волны)
/// - moveDuration: длительность основного движения/старта листьев
class LeafBackground extends StatefulWidget {
  final Widget child;
  final double offsetFactor;
  final double waveSpeed;
  final Duration moveDuration;

  const LeafBackground({
    super.key,
    required this.child,
    this.offsetFactor = 1.0,
    this.waveSpeed = 0.6,
    this.moveDuration = const Duration(seconds: 5),
  });

  @override
  State<LeafBackground> createState() => _LeafBackgroundState();
}

class _LeafBackgroundState extends State<LeafBackground>
    with TickerProviderStateMixin {
  late AnimationController _moveController;
  late AnimationController _waveController;
  final int _leafCount = 16;
  final List<_Leaf> _leaves = [];

  @override
  void initState() {
    super.initState();

    // "Разлёт" / стартовое движение
    _moveController = AnimationController(
      vsync: this,
      duration: widget.moveDuration,
    )..forward();

    // постоянное спокойное колыхание
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat(reverse: true);

    // генерируем листья один раз
    for (int i = 0; i < _leafCount; i++) {
      _leaves.add(_Leaf.random());
    }
  }

  @override
  void dispose() {
    _moveController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedBuilder(
          animation: Listenable.merge([_moveController, _waveController]),
          builder: (context, _) {
            final moveProgress = Curves.easeInOut.transform(_moveController.value);
            return Stack(
              children: _leaves.map((leaf) {
                final wave = sin(
                  _waveController.value * 2 * pi * widget.waveSpeed +
                      leaf.waveOffset,
                ) *
                    6;

                final dx = leaf.start.dx +
                    (leaf.side == LeafSide.left
                        ? -leaf.endOffset * widget.offsetFactor * moveProgress
                        : leaf.endOffset * widget.offsetFactor * moveProgress);
                final dy = leaf.start.dy + wave;

                return Positioned(
                  left: dx,
                  top: dy,
                  child: Transform.rotate(
                    angle: leaf.rotation + wave * 0.02,
                    child: Image.asset(
                      'assets/images/leaf.png',
                      width: leaf.size,
                      height: leaf.size,
                      color: leaf.color.withOpacity(0.95),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
        // контент поверх листьев
        widget.child,
      ],
    );
  }
}

enum LeafSide { left, right }

class _Leaf {
  final Offset start;
  final double endOffset;
  final double size;
  final double rotation;
  final LeafSide side;
  final Color color;
  final double waveOffset;

  _Leaf({
    required this.start,
    required this.endOffset,
    required this.size,
    required this.rotation,
    required this.side,
    required this.color,
    required this.waveOffset,
  });

  factory _Leaf.random() {
    final rand = Random();
    final side = rand.nextBool() ? LeafSide.left : LeafSide.right;
    final shades = [
      Colors.green.shade600,
      Colors.green.shade700,
      Colors.green.shade800,
      Colors.lightGreen.shade700,
      Colors.teal.shade700,
    ];

    return _Leaf(
      start: Offset(rand.nextDouble() * 400, rand.nextDouble() * 900),
      endOffset: 60 + rand.nextDouble() * 120,
      size: 28 + rand.nextDouble() * 52,
      rotation: rand.nextDouble() * pi * 2,
      side: side,
      color: shades[rand.nextInt(shades.length)],
      waveOffset: rand.nextDouble() * 2 * pi,
    );
  }
}
