// import 'package:json_annotation/json_annotation.dart';

// part 'gesture_model.g.dart';

// @JsonSerializable()
class GestureModel {
  final String id;
  final String name;
  final String workspaceId;
  final String description;
  final SensorData sensorData;
  final String sensorPattern; // New field for knuckle pattern (e.g., "10101")
  final Map<String, String> textMappings; // Language code -> text
  final String? audioPath; // Path to TTS audio file
  final DateTime createdAt;
  final DateTime updatedAt;

  const GestureModel({
    required this.id,
    required this.name,
    required this.workspaceId,
    this.description = '',
    required this.sensorData,
    required this.sensorPattern,
    required this.textMappings,
    this.audioPath,
    required this.createdAt,
    required this.updatedAt,
  });

  factory GestureModel.fromJson(Map<String, dynamic> json) {
    return GestureModel(
      id: json['id'] as String,
      name: json['name'] as String,
      workspaceId: json['workspaceId'] as String,
      description: json['description'] as String? ?? '',
      sensorData: SensorData.fromJson(json['sensorData'] as Map<String, dynamic>),
      sensorPattern: json['sensorPattern'] as String? ?? '',
      textMappings: Map<String, String>.from(json['textMappings'] as Map),
      audioPath: json['audioPath'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'workspaceId': workspaceId,
      'description': description,
      'sensorData': sensorData.toJson(),
      'sensorPattern': sensorPattern,
      'textMappings': textMappings,
      'audioPath': audioPath,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  GestureModel copyWith({
    String? id,
    String? name,
    String? workspaceId,
    String? description,
    SensorData? sensorData,
    String? sensorPattern,
    Map<String, String>? textMappings,
    String? audioPath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return GestureModel(
      id: id ?? this.id,
      name: name ?? this.name,
      workspaceId: workspaceId ?? this.workspaceId,
      description: description ?? this.description,
      sensorData: sensorData ?? this.sensorData,
      sensorPattern: sensorPattern ?? this.sensorPattern,
      textMappings: textMappings ?? this.textMappings,
      audioPath: audioPath ?? this.audioPath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Parse sensor data from string format: T{0-120}I{0-120}M{0-120}R{0-120}P{0-120}HR{-120-120}
  static SensorData parseSensorString(String sensorString) {
    final RegExp regex = RegExp(r'T\{(\d+)\}I\{(\d+)\}M\{(\d+)\}R\{(\d+)\}P\{(\d+)\}HR\{(-?\d+)\}');
    final match = regex.firstMatch(sensorString);
    
    if (match == null) {
      throw ArgumentError('Invalid sensor string format');
    }

    return SensorData(
      thumb: int.parse(match.group(1)!),
      indexFinger: int.parse(match.group(2)!),
      middle: int.parse(match.group(3)!),
      ring: int.parse(match.group(4)!),
      pinky: int.parse(match.group(5)!),
      handRotation: int.parse(match.group(6)!),
    );
  }

  String get sensorString {
    return 'T{${sensorData.thumb}}I{${sensorData.indexFinger}}M{${sensorData.middle}}R{${sensorData.ring}}P{${sensorData.pinky}}HR{${sensorData.handRotation}}';
  }
}

// @JsonSerializable()
class SensorData {
  final int thumb; // 0-120
  final int indexFinger; // 0-120
  final int middle; // 0-120
  final int ring; // 0-120
  final int pinky; // 0-120
  final int handRotation; // -120 to 120

  const SensorData({
    required this.thumb,
    required this.indexFinger,
    required this.middle,
    required this.ring,
    required this.pinky,
    required this.handRotation,
  });

  factory SensorData.fromJson(Map<String, dynamic> json) {
    return SensorData(
      thumb: json['thumb'] as int,
      indexFinger: json['indexFinger'] as int,
      middle: json['middle'] as int,
      ring: json['ring'] as int,
      pinky: json['pinky'] as int,
      handRotation: json['handRotation'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'thumb': thumb,
      'indexFinger': indexFinger,
      'middle': middle,
      'ring': ring,
      'pinky': pinky,
      'handRotation': handRotation,
    };
  }

  SensorData copyWith({
    int? thumb,
    int? indexFinger,
    int? middle,
    int? ring,
    int? pinky,
    int? handRotation,
  }) {
    return SensorData(
      thumb: thumb ?? this.thumb,
      indexFinger: indexFinger ?? this.indexFinger,
      middle: middle ?? this.middle,
      ring: ring ?? this.ring,
      pinky: pinky ?? this.pinky,
      handRotation: handRotation ?? this.handRotation,
    );
  }

  // Validate sensor values
  bool get isValid {
    return thumb >= 0 && thumb <= 120 &&
           indexFinger >= 0 && indexFinger <= 120 &&
           middle >= 0 && middle <= 120 &&
           ring >= 0 && ring <= 120 &&
           pinky >= 0 && pinky <= 120 &&
           handRotation >= -120 && handRotation <= 120;
  }
}

enum FingerType {
  thumb,
  indexFinger,
  middle,
  ring,
  pinky,
}

extension FingerTypeExtension on FingerType {
  String get displayName {
    switch (this) {
      case FingerType.thumb:
        return 'Thumb';
      case FingerType.indexFinger:
        return 'Index';
      case FingerType.middle:
        return 'Middle';
      case FingerType.ring:
        return 'Ring';
      case FingerType.pinky:
        return 'Pinky';
    }
  }

  String get shortCode {
    switch (this) {
      case FingerType.thumb:
        return 'T';
      case FingerType.indexFinger:
        return 'I';
      case FingerType.middle:
        return 'M';
      case FingerType.ring:
        return 'R';
      case FingerType.pinky:
        return 'P';
    }
  }
} 