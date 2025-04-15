import 'package:flutter/material.dart';
import 'package:flutter/animation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
          secondary: Colors.purpleAccent,
        ),
        useMaterial3: true,
      ),
      home: const ChatBotScreen(),
    );
  }
}

class ChatBotScreen extends StatefulWidget {
  const ChatBotScreen({super.key});

  @override
  _ChatBotScreenState createState() => _ChatBotScreenState();
}

class _ChatBotScreenState extends State<ChatBotScreen> with SingleTickerProviderStateMixin {
  final List<Message> _messages = [];
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();
  late AnimationController _animationController;
  late Animation<double> _animation;

  // Configuration pour DeepSeek
  final String _apiKey = 'sk-eb2e998ac44448afa1e902c5770ae4dd'; // Remplacez par votre clé API DeepSeek
  final String _model = "deepseek-chat";
  final String _apiUrl = "https://api.deepseek.com/v1/chat/completions";

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<String> _getAIResponse(String prompt) async {
    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          "model": _model,
          "messages": [
            {"role": "system", "content": "You are a helpful assistant."},
            {"role": "user", "content": prompt}
          ],
          "temperature": 0.7,
          "max_tokens": 2048, // Augmenté pour DeepSeek
          "stream": false,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        return "❌ Erreur ${response.statusCode}: ${response.body}";
      }
    } catch (e) {
      return "🔌 Erreur de connexion: ${e.toString()}";
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _sendMessage() async {
    if (_controller.text.isEmpty || _isLoading) return;

    final userMessage = _controller.text;
    _controller.clear();

    setState(() {
      _messages.insert(0, Message(userMessage, true));
    });

    final aiResponse = await _getAIResponse(userMessage);

    setState(() {
      _messages.insert(0, Message(aiResponse, false));
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text("DeepSeek Assistant"),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [colors.primary, colors.secondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        actions: [
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Transform.rotate(
                angle: _animation.value * 2 * pi,
                child: child,
              );
            },
            child: IconButton(
              icon: const Icon(Icons.auto_awesome),
              onPressed: () {},
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colors.surface.withOpacity(0.8),
              colors.surface.withOpacity(0.5),
            ],
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                reverse: true,
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                itemCount: _messages.length,
                itemBuilder: (ctx, index) => _buildMessage(_messages[index], index),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Material(
                elevation: 10,
                borderRadius: BorderRadius.circular(25),
                child: Container(
                  decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(25),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          style: TextStyle(color: colors.onSurface),
                          decoration: InputDecoration(
                            hintText: "Tapez votre message...",
                            hintStyle: TextStyle(color: colors.onSurface.withOpacity(0.5)),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              colors.primary,
                              colors.secondary,
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: colors.primary.withOpacity(0.5),
                              blurRadius: 10,
                              spreadRadius: _isLoading ? 5 : 0,
                            ),
                          ],
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(50),
                          onTap: _sendMessage,
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: _isLoading
                                ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colors.onPrimary,
                              ),
                            )
                                : Icon(Icons.send, color: colors.onPrimary),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessage(Message msg, int index) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: Container(
        key: ValueKey('${msg.text}_$index'),
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            if (!msg.isUser)
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                curve: Curves.elasticOut,
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: colors.secondary.withOpacity(0.2),
                  child: Icon(Icons.auto_awesome, size: 18, color: colors.secondary),
                ),
              ),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: msg.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (!msg.isUser)
                    Text(
                      'DeepSeek',
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.secondary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: msg.isUser
                            ? [colors.primary, colors.primary.withOpacity(0.7)]
                            : [colors.surfaceVariant, colors.surfaceVariant.withOpacity(0.7)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(12),
                        topRight: const Radius.circular(12),
                        bottomLeft: Radius.circular(msg.isUser ? 12 : 0),
                        bottomRight: Radius.circular(msg.isUser ? 0 : 12),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Text(
                      msg.text,
                      style: TextStyle(
                        fontSize: 15,
                        color: msg.isUser ? colors.onPrimary : colors.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (msg.isUser) const SizedBox(width: 8),
            if (msg.isUser)
              AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                curve: Curves.elasticOut,
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: colors.primary.withOpacity(0.2),
                  child: Icon(Icons.person, size: 18, color: colors.primary),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class Message {
  final String text;
  final bool isUser;

  Message(this.text, this.isUser);
}