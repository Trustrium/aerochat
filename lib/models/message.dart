class Message {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final List<MessageAttachment>? attachments;

  Message({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.attachments,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'content': content,
        'isUser': isUser,
        'timestamp': timestamp.toIso8601String(),
        'attachments': attachments?.map((a) => a.toJson()).toList(),
      };

  factory Message.fromJson(Map<String, dynamic> json) => Message(
        id: json['id'],
        content: json['content'],
        isUser: json['isUser'],
        timestamp: DateTime.parse(json['timestamp']),
        attachments: (json['attachments'] as List<dynamic>?)
            ?.map((a) => MessageAttachment.fromJson(a))
            .toList(),
      );

  Message copyWith({
    String? id,
    String? content,
    bool? isUser,
    DateTime? timestamp,
    List<MessageAttachment>? attachments,
  }) {
    return Message(
      id: id ?? this.id,
      content: content ?? this.content,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      attachments: attachments ?? this.attachments,
    );
  }
}

class MessageAttachment {
  final String type;
  final String url;
  final String? name;
  final int? size;

  MessageAttachment({
    required this.type,
    required this.url,
    this.name,
    this.size,
  });

  Map<String, dynamic> toJson() => {
        'type': type,
        'url': url,
        'name': name,
        'size': size,
      };

  factory MessageAttachment.fromJson(Map<String, dynamic> json) =>
      MessageAttachment(
        type: json['type'],
        url: json['url'],
        name: json['name'],
        size: json['size'],
      );
}

class ChatSession {
  final String id;
  final String title;
  final List<Message> messages;
  final DateTime createdAt;
  final DateTime updatedAt;
  final ProviderConfig? provider;

  ChatSession({
    required this.id,
    required this.title,
    required this.messages,
    required this.createdAt,
    required this.updatedAt,
    this.provider,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'messages': messages.map((m) => m.toJson()).toList(),
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'provider': provider?.toJson(),
      };

  factory ChatSession.fromJson(Map<String, dynamic> json) => ChatSession(
        id: json['id'],
        title: json['title'],
        messages: (json['messages'] as List<dynamic>)
            .map((m) => Message.fromJson(m))
            .toList(),
        createdAt: DateTime.parse(json['createdAt']),
        updatedAt: DateTime.parse(json['updatedAt']),
        provider: json['provider'] != null
            ? ProviderConfig.fromJson(json['provider'])
            : null,
      );

  ChatSession copyWith({
    String? id,
    String? title,
    List<Message>? messages,
    DateTime? createdAt,
    DateTime? updatedAt,
    ProviderConfig? provider,
  }) {
    return ChatSession(
      id: id ?? this.id,
      title: title ?? this.title,
      messages: messages ?? this.messages,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      provider: provider ?? this.provider,
    );
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
