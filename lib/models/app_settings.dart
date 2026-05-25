enum AppLanguage { german, english }

enum AppTheme { light, dark }

class AppSettings {
  final AppLanguage language;
  final AppTheme theme;
  final double hourlyWage;

  AppSettings({
    this.language = AppLanguage.german,
    this.theme = AppTheme.dark,
    this.hourlyWage = 15.0,
  });

  AppSettings copyWith({
    AppLanguage? language,
    AppTheme? theme,
    double? hourlyWage,
  }) {
    return AppSettings(
      language: language ?? this.language,
      theme: theme ?? this.theme,
      hourlyWage: hourlyWage ?? this.hourlyWage,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'language': language.name,
      'theme': theme.name,
      'hourlyWage': hourlyWage,
    };
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      language: AppLanguage.values.firstWhere(
        (e) => e.name == json['language'],
        orElse: () => AppLanguage.german,
      ),
      theme: AppTheme.values.firstWhere(
        (e) => e.name == json['theme'],
        orElse: () => AppTheme.dark,
      ),
      hourlyWage: (json['hourlyWage'] as num?)?.toDouble() ?? 15.0,
    );
  }
}
