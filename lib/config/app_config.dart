import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

enum AIProvider {
  openAI,
  anthropic,
  google,
  local,
}

extension AIProviderExtension on AIProvider {
  String get displayName {
    switch (this) {
      case AIProvider.openAI:
        return 'OpenAI';
      case AIProvider.anthropic:
        return 'Anthropic';
      case AIProvider.google:
        return 'Google Gemini';
      case AIProvider.local:
        return 'Local/Custom';
    }
  }

  String get defaultBaseUrl {
    switch (this) {
      case AIProvider.openAI:
        return 'https://api.openai.com';
      case AIProvider.anthropic:
        return 'https://api.anthropic.com';
      case AIProvider.google:
        return 'https://generativelanguage.googleapis.com';
      case AIProvider.local:
        return 'http://localhost:11434';
    }
  }

  String get defaultModel {
    switch (this) {
      case AIProvider.openAI:
        return 'gpt-4';
      case AIProvider.anthropic:
        return 'claude-3-sonnet-20240229';
      case AIProvider.google:
        return 'gemini-pro';
      case AIProvider.local:
        return 'llama2';
    }
  }
}

class ProviderConfig {
  final AIProvider provider;
  final String apiKey;
  final String baseUrl;
  final String model;
  final bool isEnabled;

  ProviderConfig({
    required this.provider,
    this.apiKey = '',
    String? baseUrl,
    String? model,
    this.isEnabled = false,
  })  : baseUrl = baseUrl ?? provider.defaultBaseUrl,
        model = model ?? provider.defaultModel;

  Map<String, dynamic> toJson() => {
        'provider': provider.name,
        'apiKey': apiKey,
        'baseUrl': baseUrl,
        'model': model,
        'isEnabled': isEnabled,
      };

  factory ProviderConfig.fromJson(Map<String, dynamic> json) {
    return ProviderConfig(
      provider: AIProvider.values.firstWhere(
        (p) => p.name == json['provider'],
        orElse: () => AIProvider.openAI,
      ),
      apiKey: json['apiKey'] ?? '',
      baseUrl: json['baseUrl'],
      model: json['model'],
      isEnabled: json['isEnabled'] ?? false,
    );
  }

  ProviderConfig copyWith({
    AIProvider? provider,
    String? apiKey,
    String? baseUrl,
    String? model,
    bool? isEnabled,
  }) {
    return ProviderConfig(
      provider: provider ?? this.provider,
      apiKey: apiKey ?? this.apiKey,
      baseUrl: baseUrl ?? this.baseUrl,
      model: model ?? this.model,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  bool get isValid => apiKey.isNotEmpty && baseUrl.isNotEmpty && model.isNotEmpty;
}

class AppConfig {
  final List<ProviderConfig> providerConfigs;
  final ProviderConfig? activeProvider;
  final String? userName;
  final bool darkMode;

  AppConfig({
    this.providerConfigs = const [],
    this.activeProvider,
    this.userName,
    this.darkMode = true,
  });

  List<ProviderConfig> get enabledProviders =>
      providerConfigs.where((p) => p.isEnabled).toList();

  Map<String, dynamic> toJson() => {
        'providerConfigs': providerConfigs.map((p) => p.toJson()).toList(),
        'activeProvider': activeProvider?.toJson(),
        'userName': userName,
        'darkMode': darkMode,
      };

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    return AppConfig(
      providerConfigs: (json['providerConfigs'] as List<dynamic>?)
              ?.map((p) => ProviderConfig.fromJson(p))
              .toList() ??
          [],
      activeProvider: json['activeProvider'] != null
          ? ProviderConfig.fromJson(json['activeProvider'])
          : null,
      userName: json['userName'],
      darkMode: json['darkMode'] ?? true,
    );
  }

  AppConfig copyWith({
    List<ProviderConfig>? providerConfigs,
    ProviderConfig? activeProvider,
    String? userName,
    bool? darkMode,
  }) {
    return AppConfig(
      providerConfigs: providerConfigs ?? this.providerConfigs,
      activeProvider: activeProvider ?? this.activeProvider,
      userName: userName ?? this.userName,
      darkMode: darkMode ?? this.darkMode,
    );
  }
}

class ConfigService {
  static const _configKey = 'app_config';
  
  static final ConfigService _instance = ConfigService._internal();
  factory ConfigService() => _instance;
  ConfigService._internal();

  SharedPreferences? _prefs;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  Future<AppConfig> loadConfig() async {
    if (_prefs == null) await initialize();
    
    final jsonString = _prefs?.getString(_configKey);
    if (jsonString != null) {
      try {
        return AppConfig.fromJson(jsonDecode(jsonString));
      } catch (e) {
        print('Error loading config: $e');
      }
    }
    
    // Return default config with all providers
    return AppConfig(
      providerConfigs: AIProvider.values
          .map((p) => ProviderConfig(provider: p))
          .toList(),
    );
  }

  Future<void> saveConfig(AppConfig config) async {
    if (_prefs == null) await initialize();
    await _prefs?.setString(_configKey, jsonEncode(config.toJson()));
  }

  Future<void> updateProviderConfig(ProviderConfig config) async {
    final currentConfig = await loadConfig();
    final updatedProviders = List<ProviderConfig>.from(currentConfig.providerConfigs);
    final index = updatedProviders.indexWhere((p) => p.provider == config.provider);
    
    if (index >= 0) {
      updatedProviders[index] = config;
    } else {
      updatedProviders.add(config);
    }
    
    final newConfig = currentConfig.copyWith(
      providerConfigs: updatedProviders,
      activeProvider: config.isEnabled ? config : currentConfig.activeProvider,
    );
    
    await saveConfig(newConfig);
  }

  Future<void> setActiveProvider(AIProvider provider) async {
    final currentConfig = await loadConfig();
    final providerConfig = currentConfig.providerConfigs
        .firstWhere((p) => p.provider == provider);
    
    if (providerConfig.isValid) {
      final newConfig = currentConfig.copyWith(activeProvider: providerConfig);
      await saveConfig(newConfig);
    }
  }

  Future<ProviderConfig?> getActiveProvider() async {
    final config = await loadConfig();
    return config.activeProvider;
  }

  Future<void> setDarkMode(bool darkMode) async {
    final currentConfig = await loadConfig();
    await saveConfig(currentConfig.copyWith(darkMode: darkMode));
  }

  Future<bool> getDarkMode() async {
    final config = await loadConfig();
    return config.darkMode;
  }
}
