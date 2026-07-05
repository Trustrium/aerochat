import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/message.dart';

class AIService {
  Future<String> sendMessage({
    required ProviderConfig provider,
    required List<Message> messages,
  }) async {
    switch (provider.provider) {
      case AIProvider.openAI:
        return await _sendOpenAIMessage(provider, messages);
      case AIProvider.anthropic:
        return await _sendAnthropicMessage(provider, messages);
      case AIProvider.google:
        return await _sendGoogleMessage(provider, messages);
      case AIProvider.local:
        return await _sendLocalMessage(provider, messages);
    }
  }

  Future<String> _sendOpenAIMessage(
    ProviderConfig provider,
    List<Message> messages,
  ) async {
    final url = Uri.parse('${provider.baseUrl}/v1/chat/completions');
    
    final body = {
      'model': provider.model,
      'messages': messages
          .map((m) => {
                'role': m.isUser ? 'user' : 'assistant',
                'content': m.content,
              })
          .toList(),
      'temperature': 0.7,
    };

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${provider.apiKey}',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['choices'][0]['message']['content'];
    } else {
      throw Exception('OpenAI Error: ${response.body}');
    }
  }

  Future<String> _sendAnthropicMessage(
    ProviderConfig provider,
    List<Message> messages,
  ) async {
    final url = Uri.parse('${provider.baseUrl}/v1/messages');
    
    final body = {
      'model': provider.model,
      'max_tokens': 4096,
      'messages': messages
          .map((m) => {
                'role': m.isUser ? 'user' : 'assistant',
                'content': m.content,
              })
          .toList(),
    };

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'x-api-key': provider.apiKey,
        'anthropic-version': '2023-06-01',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['content'][0]['text'];
    } else {
      throw Exception('Anthropic Error: ${response.body}');
    }
  }

  Future<String> _sendGoogleMessage(
    ProviderConfig provider,
    List<Message> messages,
  ) async {
    final url = Uri.parse(
      '${provider.baseUrl}/v1beta/models/${provider.model}:generateContent?key=${provider.apiKey}',
    );
    
    final body = {
      'contents': [
        {
          'parts': messages
              .map((m) => {
                    'text': m.content,
                  })
              .toList(),
        }
      ],
    };

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['candidates'][0]['content']['parts'][0]['text'];
    } else {
      throw Exception('Google Error: ${response.body}');
    }
  }

  Future<String> _sendLocalMessage(
    ProviderConfig provider,
    List<Message> messages,
  ) async {
    // Compatible with Ollama API format
    final url = Uri.parse('${provider.baseUrl}/api/chat');
    
    final body = {
      'model': provider.model,
      'messages': messages
          .map((m) => {
                'role': m.isUser ? 'user' : 'assistant',
                'content': m.content,
              })
          .toList(),
      'stream': false,
    };

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (provider.apiKey.isNotEmpty)
          'Authorization': 'Bearer ${provider.apiKey}',
      },
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Ollama format
      if (data.containsKey('message')) {
        return data['message']['content'];
      }
      // Generic format
      return data['response'] ?? data['choices']?[0]?['message']?['content'] ?? 'No response';
    } else {
      throw Exception('Local API Error: ${response.body}');
    }
  }

  // Test connection to provider
  Future<bool> testConnection(ProviderConfig provider) async {
    try {
      switch (provider.provider) {
        case AIProvider.openAI:
          final url = Uri.parse('${provider.baseUrl}/v1/models');
          final response = await http.get(
            url,
            headers: {'Authorization': 'Bearer ${provider.apiKey}'},
          );
          return response.statusCode == 200;
        
        case AIProvider.anthropic:
          final url = Uri.parse('${provider.provider}');
          final response = await http.get(
            url,
            headers: {
              'x-api-key': provider.apiKey,
              'anthropic-version': '2023-06-01',
            },
          );
          return response.statusCode == 200;
        
        case AIProvider.google:
          final url = Uri.parse(
            '${provider.baseUrl}/v1beta/models?key=${provider.apiKey}',
          );
          final response = await http.get(url);
          return response.statusCode == 200;
        
        case AIProvider.local:
          final url = Uri.parse('${provider.baseUrl}/api/tags');
          final response = await http.get(url);
          return response.statusCode == 200;
      }
    } catch (e) {
      return false;
    }
    return false;
  }

  // Get available models for provider
  Future<List<String>> getAvailableModels(ProviderConfig provider) async {
    try {
      switch (provider.provider) {
        case AIProvider.openAI:
          final url = Uri.parse('${provider.baseUrl}/v1/models');
          final response = await http.get(
            url,
            headers: {'Authorization': 'Bearer ${provider.apiKey}'},
          );
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            return (data['data'] as List)
                .map((m) => m['id'] as String)
                .toList();
          }
          break;
        
        case AIProvider.anthropic:
          // Anthropic has a fixed model list
          return [
            'claude-3-opus-20240229',
            'claude-3-sonnet-20240229',
            'claude-3-haiku-20240307',
            'claude-3-5-sonnet-20241022',
            'claude-3-5-haiku-20241022',
          ];
        
        case AIProvider.google:
          final url = Uri.parse(
            '${provider.baseUrl}/v1beta/models?key=${provider.apiKey}',
          );
          final response = await http.get(url);
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            return (data['models'] as List)
                .map((m) => m['name'] as String)
                .toList();
          }
          break;
        
        case AIProvider.local:
          final url = Uri.parse('${provider.baseUrl}/api/tags');
          final response = await http.get(url);
          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            return (data['models'] as List? ?? [])
                .map((m) => m['name'] as String)
                .toList();
          }
          break;
      }
    } catch (e) {
      // Return default model if API call fails
    }
    
    return [provider.model];
  }
}
