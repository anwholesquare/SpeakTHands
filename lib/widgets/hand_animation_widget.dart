import 'package:flutter/material.dart';
import '../themes/app_theme.dart';
import '../models/gesture_model.dart';

class HandAnimationWidget extends StatefulWidget {
  final FingerType highlightedFinger;
  final Duration animationDuration;

  const HandAnimationWidget({
    super.key,
    required this.highlightedFinger,
    this.animationDuration = const Duration(milliseconds: 1000),
  });

  @override
  State<HandAnimationWidget> createState() => _HandAnimationWidgetState();
}

class _HandAnimationWidgetState extends State<HandAnimationWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      height: 300,
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.dividerColor.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: CustomPaint(
        painter: HandPainter(
          highlightedFinger: widget.highlightedFinger,
          pulseAnimation: _pulseAnimation,
        ),
      ),
    );
  }
}

class HandPainter extends CustomPainter {
  final FingerType highlightedFinger;
  final Animation<double> pulseAnimation;

  HandPainter({
    required this.highlightedFinger,
    required this.pulseAnimation,
  }) : super(repaint: pulseAnimation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 2;

    // Hand palm
    final palmPath = Path();
    palmPath.addRRect(RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.7),
        width: size.width * 0.4,
        height: size.height * 0.25,
      ),
      const Radius.circular(20),
    ));

    paint.color = AppTheme.surfaceColor;
    canvas.drawPath(palmPath, paint);

    // Draw fingers
    _drawFinger(canvas, size, FingerType.thumb, Offset(size.width * 0.25, size.height * 0.6));
    _drawFinger(canvas, size, FingerType.indexFinger, Offset(size.width * 0.35, size.height * 0.3));
    _drawFinger(canvas, size, FingerType.middle, Offset(size.width * 0.5, size.height * 0.25));
    _drawFinger(canvas, size, FingerType.ring, Offset(size.width * 0.65, size.height * 0.3));
    _drawFinger(canvas, size, FingerType.pinky, Offset(size.width * 0.75, size.height * 0.4));
  }

  void _drawFinger(Canvas canvas, Size size, FingerType finger, Offset position) {
    final paint = Paint()..style = PaintingStyle.fill;
    
    final isHighlighted = finger == highlightedFinger;
    final scale = isHighlighted ? pulseAnimation.value : 1.0;
    
    // Finger color
    paint.color = isHighlighted 
        ? AppTheme.secondaryColor.withOpacity(0.8)
        : AppTheme.textSecondary.withOpacity(0.6);

    // Draw finger segments
    final fingerWidth = 20.0 * scale;
    final segmentHeight = finger == FingerType.thumb ? 25.0 : 35.0;
    
    for (int i = 0; i < 3; i++) {
      final segmentY = position.dy + (i * segmentHeight * 0.8);
      final segmentRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(position.dx, segmentY),
          width: fingerWidth,
          height: segmentHeight,
        ),
        const Radius.circular(10),
      );
      
      canvas.drawRRect(segmentRect, paint);
    }

    // Draw finger tip
    if (isHighlighted) {
      final tipPaint = Paint()
        ..color = AppTheme.secondaryColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      
      canvas.drawCircle(
        Offset(position.dx, position.dy - segmentHeight),
        fingerWidth / 2 + 5,
        tipPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
} 