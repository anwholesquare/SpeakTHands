class HandSensorData {
  final bool thumbKnuckle;    // t
  final bool indexKnuckle;    // i1
  final bool middleKnuckle;   // m1
  final bool ringKnuckle;     // r1
  final bool pinkyKnuckle;    // p1
  final DateTime timestamp;

  const HandSensorData({
    required this.thumbKnuckle,
    required this.indexKnuckle,
    required this.middleKnuckle,
    required this.ringKnuckle,
    required this.pinkyKnuckle,
    required this.timestamp,
  });

  /// Creates HandSensorData from ESP32 BLE data string
  /// Expected format: "[t,i1,m1,r1,p1]" where 0=open, 1=closed
  factory HandSensorData.fromBleData(String data) {
    // Remove brackets and split by comma
    final cleanData = data.replaceAll(RegExp(r'[\[\]]'), '');
    final values = cleanData.split(',').map((s) => s.trim()).toList();
    
    if (values.length != 5) {
      throw ArgumentError('Invalid BLE data format. Expected 5 values, got ${values.length}');
    }

    return HandSensorData(
      thumbKnuckle: values[0] == '1',
      indexKnuckle: values[1] == '1',
      middleKnuckle: values[2] == '1',
      ringKnuckle: values[3] == '1',
      pinkyKnuckle: values[4] == '1',
      timestamp: DateTime.now(),
    );
  }

  /// Converts to a map for storage/serialization
  Map<String, dynamic> toMap() {
    return {
      'thumbKnuckle': thumbKnuckle,
      'indexKnuckle': indexKnuckle,
      'middleKnuckle': middleKnuckle,
      'ringKnuckle': ringKnuckle,
      'pinkyKnuckle': pinkyKnuckle,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  /// Creates from a map (for deserialization)
  factory HandSensorData.fromMap(Map<String, dynamic> map) {
    return HandSensorData(
      thumbKnuckle: map['thumbKnuckle'] ?? false,
      indexKnuckle: map['indexKnuckle'] ?? false,
      middleKnuckle: map['middleKnuckle'] ?? false,
      ringKnuckle: map['ringKnuckle'] ?? false,
      pinkyKnuckle: map['pinkyKnuckle'] ?? false,
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
    );
  }

  /// Gets the gesture pattern as a string (for matching)
  String get gesturePattern {
    return '${thumbKnuckle ? 1 : 0}${indexKnuckle ? 1 : 0}${middleKnuckle ? 1 : 0}${ringKnuckle ? 1 : 0}${pinkyKnuckle ? 1 : 0}';
  }

  /// Checks if this gesture matches another (with optional tolerance for timing)
  bool matches(HandSensorData other, {Duration? tolerance}) {
    if (tolerance != null) {
      final timeDiff = timestamp.difference(other.timestamp).abs();
      if (timeDiff > tolerance) return false;
    }

    return thumbKnuckle == other.thumbKnuckle &&
           indexKnuckle == other.indexKnuckle &&
           middleKnuckle == other.middleKnuckle &&
           ringKnuckle == other.ringKnuckle &&
           pinkyKnuckle == other.pinkyKnuckle;
  }

  /// Returns a list of active (closed) knuckles
  List<String> get activeKnuckles {
    final active = <String>[];
    if (thumbKnuckle) active.add('Thumb');
    if (indexKnuckle) active.add('Index');
    if (middleKnuckle) active.add('Middle');
    if (ringKnuckle) active.add('Ring');
    if (pinkyKnuckle) active.add('Pinky');
    return active;
  }

  /// Returns the number of closed knuckles
  int get closedKnuckleCount {
    int count = 0;
    if (thumbKnuckle) count++;
    if (indexKnuckle) count++;
    if (middleKnuckle) count++;
    if (ringKnuckle) count++;
    if (pinkyKnuckle) count++;
    return count;
  }

  @override
  String toString() {
    return 'HandSensorData(T:${thumbKnuckle ? 1 : 0}, I:${indexKnuckle ? 1 : 0}, M:${middleKnuckle ? 1 : 0}, R:${ringKnuckle ? 1 : 0}, P:${pinkyKnuckle ? 1 : 0}, time:${timestamp.toIso8601String()})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HandSensorData &&
           other.thumbKnuckle == thumbKnuckle &&
           other.indexKnuckle == indexKnuckle &&
           other.middleKnuckle == middleKnuckle &&
           other.ringKnuckle == ringKnuckle &&
           other.pinkyKnuckle == pinkyKnuckle;
  }

  @override
  int get hashCode {
    return thumbKnuckle.hashCode ^
           indexKnuckle.hashCode ^
           middleKnuckle.hashCode ^
           ringKnuckle.hashCode ^
           pinkyKnuckle.hashCode;
  }
}
