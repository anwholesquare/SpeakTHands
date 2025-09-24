import 'package:flutter/material.dart';
import '../themes/app_theme.dart';

class AppLogo extends StatefulWidget {
  final double size;
  final bool animated;
  final Color? primaryColor;
  final Color? secondaryColor;

  const AppLogo({
    super.key,
    this.size = 100,
    this.animated = false,
    this.primaryColor,
    this.secondaryColor,
  });

  @override
  State<AppLogo> createState() => _AppLogoState();
}

class _AppLogoState extends State<AppLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _waveAnimation;

  @override
  void initState() {
    super.initState();
    
    if (widget.animated) {
      _animationController = AnimationController(
        duration: const Duration(seconds: 2),
        vsync: this,
      );

      _pulseAnimation = Tween<double>(
        begin: 0.8,
        end: 1.2,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ));

      _waveAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.linear,
      ));

      _animationController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    if (widget.animated) {
      _animationController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.animated) {
      return AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _pulseAnimation.value,
            child: CustomPaint(
              size: Size(widget.size, widget.size),
              painter: LogoPainter(
                primaryColor: widget.primaryColor ?? AppTheme.primaryColor,
                secondaryColor: widget.secondaryColor ?? AppTheme.secondaryColor,
                waveProgress: _waveAnimation.value,
              ),
            ),
          );
        },
      );
    }

    return CustomPaint(
      size: Size(widget.size, widget.size),
      painter: LogoPainter(
        primaryColor: widget.primaryColor ?? AppTheme.primaryColor,
        secondaryColor: widget.secondaryColor ?? AppTheme.secondaryColor,
        waveProgress: 0.5,
      ),
    );
  }
}

class LogoPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;
  final double waveProgress;

  LogoPainter({
    required this.primaryColor,
    required this.secondaryColor,
    required this.waveProgress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Background circle with gradient
    final backgroundPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          primaryColor.withOpacity(0.2),
          primaryColor.withOpacity(0.1),
          Colors.transparent,
        ],
        stops: const [0.3, 0.7, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, backgroundPaint);

    // Draw stylized hand
    _drawHand(canvas, size);

    // Draw speech waves
    _drawSpeechWaves(canvas, size);

    // Draw center accent
    _drawCenterAccent(canvas, size);
  }

  void _drawHand(Canvas canvas, Size size) {
    final handPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;

    final handOutlinePaint = Paint()
      ..color = primaryColor.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final scale = size.width / 100;

    // Hand palm (simplified)
    final palmPath = Path();
    palmPath.moveTo(centerX - 15 * scale, centerY + 10 * scale);
    palmPath.quadraticBezierTo(
      centerX - 20 * scale, centerY - 5 * scale,
      centerX - 10 * scale, centerY - 15 * scale,
    );
    palmPath.quadraticBezierTo(
      centerX, centerY - 20 * scale,
      centerX + 10 * scale, centerY - 15 * scale,
    );
    palmPath.quadraticBezierTo(
      centerX + 20 * scale, centerY - 5 * scale,
      centerX + 15 * scale, centerY + 10 * scale,
    );
    palmPath.quadraticBezierTo(
      centerX + 10 * scale, centerY + 20 * scale,
      centerX, centerY + 15 * scale,
    );
    palmPath.quadraticBezierTo(
      centerX - 10 * scale, centerY + 20 * scale,
      centerX - 15 * scale, centerY + 10 * scale,
    );

    canvas.drawPath(palmPath, handPaint);
    canvas.drawPath(palmPath, handOutlinePaint);

    // Fingers (simplified as rounded rectangles)
    final fingerPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;

    // Thumb
    final thumbRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(centerX - 20 * scale, centerY - 5 * scale),
        width: 8 * scale,
        height: 15 * scale,
      ),
      Radius.circular(4 * scale),
    );
    canvas.drawRRect(thumbRect, fingerPaint);

    // Index finger
    final indexRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(centerX - 8 * scale, centerY - 25 * scale),
        width: 6 * scale,
        height: 18 * scale,
      ),
      Radius.circular(3 * scale),
    );
    canvas.drawRRect(indexRect, fingerPaint);

    // Middle finger
    final middleRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(centerX, centerY - 28 * scale),
        width: 6 * scale,
        height: 20 * scale,
      ),
      Radius.circular(3 * scale),
    );
    canvas.drawRRect(middleRect, fingerPaint);

    // Ring finger
    final ringRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(centerX + 8 * scale, centerY - 25 * scale),
        width: 6 * scale,
        height: 18 * scale,
      ),
      Radius.circular(3 * scale),
    );
    canvas.drawRRect(ringRect, fingerPaint);

    // Pinky finger
    final pinkyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(centerX + 15 * scale, centerY - 20 * scale),
        width: 5 * scale,
        height: 15 * scale,
      ),
      Radius.circular(2.5 * scale),
    );
    canvas.drawRRect(pinkyRect, fingerPaint);
  }

  void _drawSpeechWaves(Canvas canvas, Size size) {
    final wavePaint = Paint()
      ..color = secondaryColor.withOpacity(0.6 + 0.4 * waveProgress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final scale = size.width / 100;

    // Speech waves emanating from the hand
    final waveStartX = centerX + 25 * scale;
    final waveStartY = centerY - 10 * scale;

    // Wave 1 (closest)
    final wave1Path = Path();
    wave1Path.moveTo(waveStartX, waveStartY - 5 * scale);
    wave1Path.quadraticBezierTo(
      waveStartX + 10 * scale, waveStartY - 8 * scale,
      waveStartX + 15 * scale, waveStartY - 5 * scale,
    );
    wave1Path.quadraticBezierTo(
      waveStartX + 20 * scale, waveStartY - 2 * scale,
      waveStartX + 25 * scale, waveStartY - 5 * scale,
    );

    // Wave 2 (middle)
    final wave2Path = Path();
    wave2Path.moveTo(waveStartX + 5 * scale, waveStartY);
    wave2Path.quadraticBezierTo(
      waveStartX + 15 * scale, waveStartY - 3 * scale,
      waveStartX + 20 * scale, waveStartY,
    );
    wave2Path.quadraticBezierTo(
      waveStartX + 25 * scale, waveStartY + 3 * scale,
      waveStartX + 30 * scale, waveStartY,
    );

    // Wave 3 (farthest)
    final wave3Path = Path();
    wave3Path.moveTo(waveStartX, waveStartY + 5 * scale);
    wave3Path.quadraticBezierTo(
      waveStartX + 10 * scale, waveStartY + 8 * scale,
      waveStartX + 15 * scale, waveStartY + 5 * scale,
    );
    wave3Path.quadraticBezierTo(
      waveStartX + 20 * scale, waveStartY + 2 * scale,
      waveStartX + 25 * scale, waveStartY + 5 * scale,
    );

    // Animate wave opacity based on progress
    wavePaint.color = secondaryColor.withOpacity(0.8 * waveProgress);
    canvas.drawPath(wave1Path, wavePaint);

    wavePaint.color = secondaryColor.withOpacity(0.6 * waveProgress);
    canvas.drawPath(wave2Path, wavePaint);

    wavePaint.color = secondaryColor.withOpacity(0.4 * waveProgress);
    canvas.drawPath(wave3Path, wavePaint);
  }

  void _drawCenterAccent(Canvas canvas, Size size) {
    final accentPaint = Paint()
      ..color = secondaryColor
      ..style = PaintingStyle.fill;

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final scale = size.width / 100;

    // Small accent dot in palm center
    canvas.drawCircle(
      Offset(centerX, centerY - 2 * scale),
      2 * scale,
      accentPaint,
    );

    // Subtle highlight on fingers
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.fill;

    // Highlights on finger tips
    canvas.drawCircle(
      Offset(centerX - 8 * scale, centerY - 34 * scale),
      1.5 * scale,
      highlightPaint,
    );
    canvas.drawCircle(
      Offset(centerX, centerY - 38 * scale),
      1.5 * scale,
      highlightPaint,
    );
    canvas.drawCircle(
      Offset(centerX + 8 * scale, centerY - 34 * scale),
      1.5 * scale,
      highlightPaint,
    );
  }

  @override
  bool shouldRepaint(LogoPainter oldDelegate) {
    return oldDelegate.waveProgress != waveProgress ||
           oldDelegate.primaryColor != primaryColor ||
           oldDelegate.secondaryColor != secondaryColor;
  }
}

// Utility widget for different logo variants
class AppLogoVariant {
  static Widget splash({double size = 120}) {
    return AppLogo(
      size: size,
      animated: true,
    );
  }

  static Widget appBar({double size = 32}) {
    return AppLogo(
      size: size,
      animated: false,
    );
  }

  static Widget loading({double size = 60}) {
    return AppLogo(
      size: size,
      animated: true,
    );
  }

  static Widget icon({double size = 24}) {
    return AppLogo(
      size: size,
      animated: false,
    );
  }

  static Widget hero({double size = 200}) {
    return AppLogo(
      size: size,
      animated: true,
    );
  }
} 