import '../../domain/entities/aprendiz_progress_entity.dart';

class AprendizProgressModel extends AprendizProgressEntity {
  const AprendizProgressModel({
    required super.level,
    required super.xp,
    required super.xpForNextLevel,
    required super.streakDays,
  });

  factory AprendizProgressModel.fromJson(Map<String, dynamic> json) {
    return AprendizProgressModel(
      level: json['level'] as int,
      xp: json['xp'] as int,
      xpForNextLevel: json['xpForNextLevel'] as int,
      streakDays: json['streakDays'] as int,
    );
  }

  Map<String, dynamic> toJson() => {
        'level': level,
        'xp': xp,
        'xpForNextLevel': xpForNextLevel,
        'streakDays': streakDays,
      };
}
