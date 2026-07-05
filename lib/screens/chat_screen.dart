import 'package:flutter/material.dart';
import 'dart:math';
import '../config/app_config.dart';
import '../services/ai_service.dart';
import '../services/database_service.dart';
import '../models/message.dart';

class ChatScreen extends StatefulWidget {
  final String? sessionId;
  const ChatScreen({super.key, this.sessionId});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<Message> _messages = [];
  final List<FloatingBubble> _bubbles = [];
  final ChatHistoryService _historyService = ChatHistoryService();
  bool _isTyping = false;
  bool _sessionCreated = false;
  late AnimationController _bubbleController;
  late AIService _aiService;
  ProviderConfig? _activeProvider;

  @override
  void initState() {
    super.initState();
    _bubbleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    _aiService = AIService();
    _initializeBubbles();
    _initSession();
  }

  Future<void> _initSession() async {
    await _loadConfig();
    
    if (widget.sessionId != null) {
      // Load existing session
      final session = await _historyService._db.getSession(widget.sessionId!);
      if (session != null) {
        setState(() {
          _messages.addAll(session.messages);
          _sessionCreated = true;
        });
      }
    }
  }

  void _initializeBubbles() {
    final random = Random();
    for (int i = 0; i < 15; i++) {
      _bubbles.add(FloatingBubble(
        x: random.nextDouble() * 400,
        y: random.nextDouble() * 800,
        size: random.nextDouble() * 60 + 20,
        speed: random.nextDouble() * 30 + 20,
        color: [
          Colors.purple.shade400,
          Colors.blue.shade400,
          Colors.teal.shade400,
          Colors.indigo.shade400,
          Colors.deepPurple.shade400,
        ][random.nextInt(5)],
      ));
    }
  }

  Future<void> _loadConfig() async {
    final configService = ConfigService();
    final config = await configService.loadConfig();
    setState(() {
      _activeProvider = config.activeProvider;
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _bubbleController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _activeProvider == null) return;

    // Create session if not exists
    if (!_sessionCreated) {
      final session = await _historyService.createNewSession(
        provider: _activeProvider,
      );
      setState(() => _sessionCreated = true);
      // Update title with first message
      if (_messages.isEmpty) {
        await _historyService.updateSessionTitle(
          text.length > 30 ? '${text.substring(0, 30)}...' : text,
        );
      }
    }

    final userMessage = Message(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _messageController.clear();
      _isTyping = true;
    });

    // Save user message to history
    await _historyService.addMessage(userMessage);

    _scrollToBottom();

    try {
      final response = await _aiService.sendMessage(
        provider: _activeProvider!,
        messages: _messages,
      );

      final aiMessage = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: response,
        isUser: false,
        timestamp: DateTime.now(),
      );

      setState(() {
        _isTyping = false;
        _messages.add(aiMessage);
      });

      // Save AI response to history
      await _historyService.addMessage(aiMessage);

      // Update session timestamp
      final currentSession = await _historyService.getCurrentSession();
      if (currentSession != null) {
        await _historyService._db.updateSession(currentSession);
      }
    } catch (e) {
      setState(() {
        _isTyping = false;
        _messages.add(Message(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: 'Error: $e',
          isUser: false,
          timestamp: DateTime.now(),
        ));
      });
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.deepPurple.shade900,
                  Colors.indigo.shade900,
                  Colors.purple.shade900,
                ],
              ),
            ),
          ),

          // Floating bubbles
          ..._bubbles.map((bubble) => _buildFloatingBubble(bubble)),

          // Main content
          Column(
            children: [
              _buildAppBar(),
              Expanded(
                child: _messages.isEmpty
                    ? _buildEmptyState()
                    : _buildMessageList(),
              ),
              if (_isTyping) _buildTypingIndicator(),
              _buildInputArea(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.deepPurple.shade800.withOpacity(0.8),
            Colors.deepPurple.shade900.withOpacity(0.6),
          ],
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.purple.shade400,
                  Colors.blue.shade400,
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.shade400.withOpacity(0.5),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.bubble_chart,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Antigravity AI',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  _activeProvider?.provider.displayName ?? 'No provider selected',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.more_vert, color: Colors.white70),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingBubble(FloatingBubble bubble) {
    return AnimatedBuilder(
      animation: _bubbleController,
      builder: (context, child) {
        final progress =
            (_bubbleController.value * bubble.speed + bubble.y) % 1000;
        final yOffset = 1000 - progress;

        return Positioned(
          left: bubble.x,
          top: yOffset,
          child: Opacity(
            opacity: 0.15,
            child: Container(
              width: bubble.size,
              height: bubble.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    bubble.color,
                    bubble.color.withOpacity(0.5),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: bubble.color.withOpacity(0.3),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.purple.shade400,
                  Colors.blue.shade400,
                ],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.purple.shade400.withOpacity(0.5),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: const Icon(
              Icons.bubble_chart,
              size: 60,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Start a conversation',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Ask me anything or just say hello!',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.6),
            ),
          ),
          if (_activeProvider == null) ...[
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/settings');
              },
              icon: const Icon(Icons.settings),
              label: const Text('Configure AI Provider'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple.shade600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length,
      itemBuilder: (context, index) {
        final message = _messages[index];
        return _buildMessageBubble(message);
      },
    );
  }

  Widget _buildMessageBubble(Message message) {
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 12,
          left: isUser ? 64 : 0,
          right: isUser ? 0 : 64,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: isUser
              ? LinearGradient(
                  colors: [
                    Colors.purple.shade600,
                    Colors.blue.shade600,
                  ],
                )
              : null,
          color: isUser ? null : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 20),
          ),
          boxShadow: isUser
              ? [
                  BoxShadow(
                    color: Colors.purple.shade600.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          message.content,
          style: TextStyle(
            fontSize: 16,
            color: Colors.white.withOpacity(isUser ? 1 : 0.9),
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.only(left: 16, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildDot(0),
          const SizedBox(width: 4),
          _buildDot(1),
          const SizedBox(width: 4),
          _buildDot(2),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.6),
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
        top: 16,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.deepPurple.shade900.withOpacity(0),
            Colors.deepPurple.shade900.withOpacity(0.95),
          ],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(
                  color: Colors.white.withOpacity(0.2),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: Icon(
                      Icons.add_circle_outline,
                      color: Colors.white.withOpacity(0.6),
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        hintStyle: TextStyle(
                          color: Colors.white.withOpacity(0.4),
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                      enabled: _activeProvider != null,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _activeProvider != null ? _sendMessage : null,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: _activeProvider != null
                    ? LinearGradient(
                        colors: [
                          Colors.purple.shade400,
                          Colors.blue.shade400,
                        ],
                      )
                    : LinearGradient(
                        colors: [
                          Colors.grey.shade600,
                          Colors.grey.shade700,
                        ],
                      ),
                shape: BoxShape.circle,
                boxShadow: _activeProvider != null
                    ? [
                        BoxShadow(
                          color: Colors.purple.shade400.withOpacity(0.4),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: const Icon(
                Icons.send,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FloatingBubble {
  double x;
  double y;
  double size;
  double speed;
  Color color;

  FloatingBubble({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.color,
  });
}
