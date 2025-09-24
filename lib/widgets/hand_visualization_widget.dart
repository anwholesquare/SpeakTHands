import 'package:flutter/material.dart';
import '../models/hand_sensor_data.dart';
import '../themes/app_theme.dart';

class HandVisualizationWidget extends StatefulWidget {
  final HandSensorData? sensorData;
  final double size;
  final bool showLabels;
  final VoidCallback? onTap;

  const HandVisualizationWidget({
    super.key,
    this.sensorData,
    this.size = 300.0,
    this.showLabels = true,
    this.onTap,
  });

  @override
  State<HandVisualizationWidget> createState() => _HandVisualizationWidgetState();
}

class _HandVisualizationWidgetState extends State<HandVisualizationWidget>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
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
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A1A2E),
              Color(0xFF16213E),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: CustomPaint(
            painter: HandPainter(
              sensorData: widget.sensorData,
              pulseAnimation: _pulseAnimation,
            ),
            child: widget.showLabels ? _buildLabels() : null,
          ),
        ),
      ),
    );
  }

  Widget _buildLabels() {
    return Stack(
      children: [
        // Thumb label
        Positioned(
          left: widget.size * 0.15,
          top: widget.size * 0.4,
          child: _buildKnuckleLabel('T', widget.sensorData?.thumbKnuckle ?? false),
        ),
        // Index label
        Positioned(
          left: widget.size * 0.3,
          top: widget.size * 0.15,
          child: _buildKnuckleLabel('I', widget.sensorData?.indexKnuckle ?? false),
        ),
        // Middle label
        Positioned(
          left: widget.size * 0.45,
          top: widget.size * 0.1,
          child: _buildKnuckleLabel('M', widget.sensorData?.middleKnuckle ?? false),
        ),
        // Ring label
        Positioned(
          right: widget.size * 0.3,
          top: widget.size * 0.15,
          child: _buildKnuckleLabel('R', widget.sensorData?.ringKnuckle ?? false),
        ),
        // Pinky label
        Positioned(
          right: widget.size * 0.15,
          top: widget.size * 0.25,
          child: _buildKnuckleLabel('P', widget.sensorData?.pinkyKnuckle ?? false),
        ),
      ],
    );
  }

  Widget _buildKnuckleLabel(String label, bool isActive) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: isActive ? _pulseAnimation.value : 1.0,
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: isActive ? AppTheme.primaryColor : AppTheme.surfaceColor,
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive ? Colors.white : AppTheme.textSecondary,
                width: 2,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: AppTheme.primaryColor.withOpacity(0.5),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: isActive ? Colors.white : AppTheme.textSecondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class HandPainter extends CustomPainter {
  final HandSensorData? sensorData;
  final Animation<double> pulseAnimation;

  HandPainter({
    required this.sensorData,
    required this.pulseAnimation,
  }) : super(repaint: pulseAnimation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 3;

    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = AppTheme.textSecondary;

    // Draw hand outline
    _drawHandOutline(canvas, size, strokePaint);

    // Draw knuckles
    _drawKnuckle(canvas, size, _getThumbPosition(size), sensorData?.thumbKnuckle ?? false, paint);
    _drawKnuckle(canvas, size, _getIndexPosition(size), sensorData?.indexKnuckle ?? false, paint);
    _drawKnuckle(canvas, size, _getMiddlePosition(size), sensorData?.middleKnuckle ?? false, paint);
    _drawKnuckle(canvas, size, _getRingPosition(size), sensorData?.ringKnuckle ?? false, paint);
    _drawKnuckle(canvas, size, _getPinkyPosition(size), sensorData?.pinkyKnuckle ?? false, paint);
  }

  void _drawHandOutline(Canvas canvas, Size size, Paint paint) {
    final path = Path();
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final handWidth = size.width * 0.6;
    final handHeight = size.height * 0.8;

    // Draw simplified hand shape
    path.moveTo(centerX - handWidth * 0.3, centerY + handHeight * 0.3); // Wrist left
    path.lineTo(centerX - handWidth * 0.4, centerY - handHeight * 0.1); // Palm left
    path.lineTo(centerX - handWidth * 0.3, centerY - handHeight * 0.3); // Index base
    path.lineTo(centerX - handWidth * 0.1, centerY - handHeight * 0.4); // Index tip
    path.lineTo(centerX, centerY - handHeight * 0.45); // Middle tip
    path.lineTo(centerX + handWidth * 0.1, centerY - handHeight * 0.4); // Ring tip
    path.lineTo(centerX + handWidth * 0.25, centerY - handHeight * 0.3); // Pinky tip
    path.lineTo(centerX + handWidth * 0.35, centerY - handHeight * 0.1); // Palm right
    path.lineTo(centerX + handWidth * 0.3, centerY + handHeight * 0.3); // Wrist right
    path.lineTo(centerX - handWidth * 0.3, centerY + handHeight * 0.3); // Back to start

    // Add thumb
    path.moveTo(centerX - handWidth * 0.35, centerY);
    path.lineTo(centerX - handWidth * 0.5, centerY - handHeight * 0.1);
    path.lineTo(centerX - handWidth * 0.45, centerY - handHeight * 0.25);
    path.lineTo(centerX - handWidth * 0.3, centerY - handHeight * 0.15);

    canvas.drawPath(path, paint);
  }

  void _drawKnuckle(Canvas canvas, Size size, Offset position, bool isActive, Paint paint) {
    paint.color = isActive 
        ? AppTheme.primaryColor.withOpacity(0.8)
        : AppTheme.surfaceColor.withOpacity(0.6);

    final radius = isActive ? 8.0 * pulseAnimation.value : 6.0;
    
    canvas.drawCircle(position, radius, paint);

    if (isActive) {
      // Draw glow effect
      paint.color = AppTheme.primaryColor.withOpacity(0.3);
      canvas.drawCircle(position, radius * 1.5, paint);
    }
  }

  Offset _getThumbPosition(Size size) {
    return Offset(size.width * 0.2, size.height * 0.45);
  }

  Offset _getIndexPosition(Size size) {
    return Offset(size.width * 0.35, size.height * 0.25);
  }

  Offset _getMiddlePosition(Size size) {
    return Offset(size.width * 0.5, size.height * 0.2);
  }

  Offset _getRingPosition(Size size) {
    return Offset(size.width * 0.65, size.height * 0.25);
  }

  Offset _getPinkyPosition(Size size) {
    return Offset(size.width * 0.78, size.height * 0.35);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return oldDelegate is HandPainter && 
           (oldDelegate.sensorData != sensorData ||
            oldDelegate.pulseAnimation != pulseAnimation);
  }
}