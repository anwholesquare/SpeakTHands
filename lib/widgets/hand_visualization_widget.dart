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
    this.size = 300,
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
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
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
        padding: const EdgeInsets.all(16),
        child: CustomPaint(
          painter: HandPainter(
            sensorData: widget.sensorData,
            showLabels: widget.showLabels,
            pulseAnimation: _pulseAnimation,
          ),
          child: Container(),
        ),
      ),
    );
  }
}

class HandPainter extends CustomPainter {
  final HandSensorData? sensorData;
  final bool showLabels;
  final Animation<double> pulseAnimation;

  HandPainter({
    required this.sensorData,
    required this.showLabels,
    required this.pulseAnimation,
  }) : super(repaint: pulseAnimation);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..strokeWidth = 2;

    final outlinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = AppTheme.primaryColor.withOpacity(0.3);

    // Hand dimensions
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final handWidth = size.width * 0.6;
    final handHeight = size.height * 0.8;

    // Draw palm
    final palmRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(centerX, centerY + handHeight * 0.1),
        width: handWidth * 0.8,
        height: handHeight * 0.5,
      ),
      const Radius.circular(20),
    );

    paint.color = AppTheme.surfaceColor;
    canvas.drawRRect(palmRect, paint);
    canvas.drawRRect(palmRect, outlinePaint);

    // Finger positions and dimensions
    final fingers = [
      // Thumb (t)
      {
        'name': 'Thumb',
        'position': Offset(centerX - handWidth * 0.35, centerY + handHeight * 0.05),
        'width': handWidth * 0.12,
        'height': handHeight * 0.25,
        'active': sensorData?.thumbKnuckle ?? false,
        'label': 'T',
      },
      // Index (i1)
      {
        'name': 'Index',
        'position': Offset(centerX - handWidth * 0.2, centerY - handHeight * 0.25),
        'width': handWidth * 0.1,
        'height': handHeight * 0.35,
        'active': sensorData?.indexKnuckle ?? false,
        'label': 'I',
      },
      // Middle (m1)
      {
        'name': 'Middle',
        'position': Offset(centerX, centerY - handHeight * 0.3),
        'width': handWidth * 0.1,
        'height': handHeight * 0.4,
        'active': sensorData?.middleKnuckle ?? false,
        'label': 'M',
      },
      // Ring (r1)
      {
        'name': 'Ring',
        'position': Offset(centerX + handWidth * 0.2, centerY - handHeight * 0.25),
        'width': handWidth * 0.1,
        'height': handHeight * 0.35,
        'active': sensorData?.ringKnuckle ?? false,
        'label': 'R',
      },
      // Pinky (p1)
      {
        'name': 'Pinky',
        'position': Offset(centerX + handWidth * 0.35, centerY - handHeight * 0.15),
        'width': handWidth * 0.08,
        'height': handHeight * 0.25,
        'active': sensorData?.pinkyKnuckle ?? false,
        'label': 'P',
      },
    ];

    // Draw fingers
    for (final finger in fingers) {
      final position = finger['position'] as Offset;
      final width = finger['width'] as double;
      final height = finger['height'] as double;
      final isActive = finger['active'] as bool;
      final label = finger['label'] as String;

      // Apply pulse animation to active fingers
      final scale = isActive ? pulseAnimation.value : 1.0;
      final scaledWidth = width * scale;
      final scaledHeight = height * scale;

      // Finger color based on state
      paint.color = isActive 
          ? AppTheme.primaryColor.withOpacity(0.8)
          : AppTheme.surfaceColor.withOpacity(0.6);

      // Draw finger
      final fingerRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: position,
          width: scaledWidth,
          height: scaledHeight,
        ),
        Radius.circular(scaledWidth / 2),
      );

      canvas.drawRRect(fingerRect, paint);

      // Draw finger outline
      outlinePaint.color = isActive 
          ? AppTheme.primaryColor
          : AppTheme.primaryColor.withOpacity(0.3);
      canvas.drawRRect(fingerRect, outlinePaint);

      // Draw knuckle indicator (small circle)
      final knuckleCenter = Offset(
        position.dx,
        position.dy + scaledHeight * 0.3,
      );

      paint.color = isActive 
          ? AppTheme.accentColor
          : AppTheme.textSecondary.withOpacity(0.5);

      canvas.drawCircle(knuckleCenter, scaledWidth * 0.15, paint);

      // Draw labels if enabled
      if (showLabels) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: label,
            style: TextStyle(
              color: isActive ? AppTheme.accentColor : AppTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: TextDirection.ltr,
        );

        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(
            position.dx - textPainter.width / 2,
            position.dy - scaledHeight / 2 - 20,
          ),
        );
      }
    }

    // Draw connection status indicator
    if (sensorData != null) {
      paint.color = AppTheme.successColor;
      canvas.drawCircle(
        Offset(size.width - 20, 20),
        6,
        paint,
      );
    } else {
      paint.color = AppTheme.errorColor;
      canvas.drawCircle(
        Offset(size.width - 20, 20),
        6,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return oldDelegate is! HandPainter ||
           oldDelegate.sensorData != sensorData ||
           oldDelegate.showLabels != showLabels;
  }
}

class HandGestureCard extends StatelessWidget {
  final HandSensorData? sensorData;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool isSelected;

  const HandGestureCard({
    super.key,
    required this.title,
    this.sensorData,
    this.subtitle,
    this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isSelected ? 8 : 2,
      color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : AppTheme.surfaceColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          width: 2,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isSelected ? AppTheme.primaryColor : null,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  HandVisualizationWidget(
                    sensorData: sensorData,
                    size: 80,
                    showLabels: false,
                  ),
                ],
              ),
              if (sensorData != null) ...[
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: sensorData!.activeKnuckles.map((knuckle) {
                    return Chip(
                      label: Text(
                        knuckle,
                        style: const TextStyle(fontSize: 10),
                      ),
                      backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                      labelStyle: TextStyle(color: AppTheme.primaryColor),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
