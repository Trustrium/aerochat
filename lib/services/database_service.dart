import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/message.dart';

class DatabaseService {
  static Database? _database;
  static final DatabaseService instance = DatabaseService._init();

  DatabaseService._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('antigravity_chat.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE chat_sessions (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        provider TEXT,
        provider_api_key TEXT,
        provider_base_url TEXT,
        provider_model TEXT,
        provider_is_enabled INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE messages (
        id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        content TEXT NOT NULL,
        is_user INTEGER NOT NULL,
        timestamp TEXT NOT NULL,
        FOREIGN KEY (session_id) REFERENCES chat_sessions (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE message_attachments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        message_id TEXT NOT NULL,
        type TEXT NOT NULL,
        url TEXT NOT NULL,
        name TEXT,
        size INTEGER,
        FOREIGN KEY (message_id) REFERENCES messages (id) ON DELETE CASCADE
      )
    ''');
  }

  // Chat Session Operations
  Future<ChatSession> createSession(ProviderConfig? provider) async {
    final db = await database;
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final now = DateTime.now();

    final session = ChatSession(
      id: id,
      title: 'New Chat',
      messages: [],
      createdAt: now,
      updatedAt: now,
      provider: provider,
    );

    await db.insert('chat_sessions', _sessionToMap(session));
    return session;
  }

  Future<List<ChatSession>> getSessions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'chat_sessions',
      orderBy: 'updated_at DESC',
    );

    return List.generate(maps.length, (i) => _mapToSession(maps[i]));
  }

  Future<ChatSession?> getSession(String id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'chat_sessions',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;

    final session = _mapToSession(maps.first);
    final messages = await getMessagesForSession(id);
    return session.copyWith(messages: messages);
  }

  Future<void> updateSession(ChatSession session) async {
    final db = await database;
    await db.update(
      'chat_sessions',
      _sessionToMap(session.copyWith(updatedAt: DateTime.now())),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  Future<void> updateSessionTitle(String id, String title) async {
    final db = await database;
    await db.update(
      'chat_sessions',
      {'title': title, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteSession(String id) async {
    final db = await database;
    await db.delete(
      'chat_sessions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Message Operations
  Future<Message> insertMessage(String sessionId, Message message) async {
    final db = await database;
    
    await db.insert('messages', {
      'id': message.id,
      'session_id': sessionId,
      'content': message.content,
      'is_user': message.isUser ? 1 : 0,
      'timestamp': message.timestamp.toIso8601String(),
    });

    if (message.attachments != null) {
      for (final attachment in message.attachments!) {
        await db.insert('message_attachments', {
          'message_id': message.id,
          'type': attachment.type,
          'url': attachment.url,
          'name': attachment.name,
          'size': attachment.size,
        });
      }
    }

    // Update session timestamp
    await db.update(
      'chat_sessions',
      {'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [sessionId],
    );

    return message;
  }

  Future<List<Message>> getMessagesForSession(String sessionId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'messages',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'timestamp ASC',
    );

    return List.generate(maps.length, (i) => _mapToMessage(maps[i]));
  }

  Future<void> deleteMessage(String id) async {
    final db = await database;
    await db.delete(
      'messages',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> clearMessagesForSession(String sessionId) async {
    final db = await database;
    await db.delete(
      'messages',
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );
  }

  // Utility Methods
  Map<String, dynamic> _sessionToMap(ChatSession session) {
    return {
      'id': session.id,
      'title': session.title,
      'created_at': session.createdAt.toIso8601String(),
      'updated_at': session.updatedAt.toIso8601String(),
      'provider': session.provider?.provider.name,
      'provider_api_key': session.provider?.apiKey,
      'provider_base_url': session.provider?.baseUrl,
      'provider_model': session.provider?.model,
      'provider_is_enabled': session.provider?.isEnabled ?? false ? 1 : 0,
    };
  }

  ChatSession _mapToSession(Map<String, dynamic> map) {
    ProviderConfig? provider;
    if (map['provider'] != null) {
      provider = ProviderConfig(
        provider: AIProvider.values.firstWhere(
          (p) => p.name == map['provider'],
          orElse: () => AIProvider.openAI,
        ),
        apiKey: map['provider_api_key'] ?? '',
        baseUrl: map['provider_base_url'],
        model: map['provider_model'],
        isEnabled: map['provider_is_enabled'] == 1,
      );
    }

    return ChatSession(
      id: map['id'],
      title: map['title'],
      messages: [],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      provider: provider,
    );
  }

  Message _mapToMessage(Map<String, dynamic> map) {
    return Message(
      id: map['id'],
      content: map['content'],
      isUser: map['is_user'] == 1,
      timestamp: DateTime.parse(map['timestamp']),
    );
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}

// Default session manager wrapper with SharedPreferences fallback
class ChatHistoryService {
  final DatabaseService _db = DatabaseService.instance;
  String? _currentSessionId;

  Future<ChatSession> createNewSession({ProviderConfig? provider}) async {
    final session = await _db.createSession(provider);
    _currentSessionId = session.id;
    return session;
  }

  Future<List<ChatSession>> getRecentSessions({int limit = 50}) async {
    return await _db.getSessions();
  }

  Future<ChatSession?> getCurrentSession() async {
    if (_currentSessionId == null) return null;
    return await _db.getSession(_currentSessionId!);
  }

  Future<void> setCurrentSession(String sessionId) async {
    _currentSessionId = sessionId;
  }

  Future<Message> addMessage(Message message) async {
    if (_currentSessionId == null) {
      await createNewSession();
    }
    return await _db.insertMessage(_currentSessionId!, message);
  }

  Future<List<Message>> getCurrentSessionMessages() async {
    if (_currentSessionId == null) return [];
    return await _db.getMessagesForSession(_currentSessionId!);
  }

  Future<void> updateSessionTitle(String title) async {
    if (_currentSessionId != null) {
      await _db.updateSessionTitle(_currentSessionId!, title);
    }
  }

  Future<void> deleteCurrentSession() async {
    if (_currentSessionId != null) {
      await _db.deleteSession(_currentSessionId!);
      _currentSessionId = null;
    }
  }

  Future<void> clearCurrentSession() async {
    if (_currentSessionId != null) {
      await _db.clearMessagesForSession(_currentSessionId!);
    }
  }
}
