class WorkspaceModel {
  final String id;
  final String name;
  final String description;
  final String language; // Primary language code (e.g., 'en', 'es', 'fr')
  final String? imagePath; // Optional workspace image
  final DateTime createdAt;
  final DateTime updatedAt;
  final int gestureCount;

  const WorkspaceModel({
    required this.id,
    required this.name,
    required this.description,
    required this.language,
    this.imagePath,
    required this.createdAt,
    required this.updatedAt,
    this.gestureCount = 0,
  });

  factory WorkspaceModel.fromJson(Map<String, dynamic> json) {
    return WorkspaceModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      language: json['language'] as String,
      imagePath: json['imagePath'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      gestureCount: json['gestureCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'language': language,
      'imagePath': imagePath,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'gestureCount': gestureCount,
    };
  }

  WorkspaceModel copyWith({
    String? id,
    String? name,
    String? description,
    String? language,
    String? imagePath,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? gestureCount,
  }) {
    return WorkspaceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      language: language ?? this.language,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      gestureCount: gestureCount ?? this.gestureCount,
    );
  }
}

// Supported languages for the app
enum SupportedLanguage {
  english('en', 'English', '🇺🇸'),
  spanish('es', 'Español', '🇪🇸'),
  french('fr', 'Français', '🇫🇷'),
  german('de', 'Deutsch', '🇩🇪'),
  italian('it', 'Italiano', '🇮🇹'),
  portuguese('pt', 'Português', '🇵🇹'),
  chinese('zh', '中文', '🇨🇳'),
  japanese('ja', '日本語', '🇯🇵'),
  korean('ko', '한국어', '🇰🇷'),
  arabic('ar', 'العربية', '🇸🇦');

  const SupportedLanguage(this.code, this.name, this.flag);

  final String code;
  final String name;
  final String flag;

  static SupportedLanguage fromCode(String code) {
    return SupportedLanguage.values.firstWhere(
      (lang) => lang.code == code,
      orElse: () => SupportedLanguage.english,
    );
  }
} 