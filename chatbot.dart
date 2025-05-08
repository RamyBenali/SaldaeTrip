import 'package:flutter/material.dart';
import 'package:flutter/animation.dart';
import 'package:google_fonts/google_fonts.dart';
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
          seedColor: Colors.blue,
          brightness: Brightness.light,
          secondary: Colors.white,
        ),
        useMaterial3: true,
        textTheme: GoogleFonts.notoSansTextTheme(Theme.of(context).textTheme),
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

class _ChatBotScreenState extends State<ChatBotScreen>
    with SingleTickerProviderStateMixin {
  final List<Message> _messages = [];
  final TextEditingController _controller = TextEditingController();
  bool _isLoading = false;
  final ScrollController _scrollController = ScrollController();
  late AnimationController _animationController;
  late Animation<double> _animation;
  DateTime _lastRequestTime = DateTime.now();

  final String _apiKey = 'sk-eb2e998ac44448afa1e902c5770ae4dd';
  final String _model = "deepseek-chat";
  final String _apiUrl = "https://api.deepseek.com/v1/chat/completions";

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
      lowerBound: 0.2,
      upperBound: 0.8,
    );
    _animation = Tween<double>(
      begin: 0.2,
      end: 0.8,
    ).animate(_animationController);
    _animationController.repeat(reverse: true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _sendAutoIntroduction();
    });
  }

  void _sendAutoIntroduction() async {
    final intro = await _getAIResponse(
      "Présentation en 20 mots strictement touristiques",
    );
    if (mounted) {
      setState(() => _messages.insert(0, Message(intro, false)));
    }
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
          'Content-Type': 'application/json; charset=utf-8',
          'Authorization': 'Bearer $_apiKey',
        },
        body: utf8.encode(
          jsonEncode({
            "model": _model,
            "messages": [
              {
                "role": "system",
                "content":
                    "Vous êtes Saldae Trip Agent, guide expert de Béjaïa. Règles :\n"
                    "- Répondez UNIQUEMENT si la question concerne Béjaïa, son tourisme ou son histoire\n"
                    "- Si la question est hors sujet, répondez: 'Je suis désolé, je ne peux répondre qu'aux questions sur Béjaïa et son tourisme.'\n"
                    "- Langage professionnel et courtois\n"
                    "- Contenu exclusivement touristique\n"
                    "- Structure claire avec emojis pertinents\n"
                    "- Maximum 100 mots\n"
                    "- Aucun caractère spécial",
              },
              {"role": "user", "content": prompt},
            ],
            "temperature": 0.7,
            "max_tokens": 1024,
          }),
        ),
      );

      return response.statusCode == 200
          ? _processResponse(
            json.decode(
              utf8.decode(response.bodyBytes),
            )['choices'][0]['message']['content'],
          )
          : "❌ Erreur ${response.statusCode}";
    } catch (e) {
      return "🔌 Problème de connexion";
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _processResponse(String response) {
    final filtered =
        response
            .replaceAllMapped(RegExp(r'&#?\w+;|A[©~®]'), (m) {
              switch (m.group(0)) {
                case 'A©':
                  return 'é';
                case 'A~a':
                  return 'ïa';
                case 'A~':
                  return 'ã';
                case 'A®':
                  return 'ê';
                default:
                  return '';
              }
            })
            .replaceAll('BA©jaA~a', 'Béjaïa')
            .replaceAll('dA©couvrir', 'découvrir')
            .replaceAll(
              RegExp(r'\b(zebi|wesh|nique|merde)\b', caseSensitive: false),
              '****',
            )
            .replaceAll(
              RegExp(r'[^\p{L}\p{M}\p{N}\p{P}\p{S}\p{Z}]', unicode: true),
              '',
            )
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();

    return filtered;
  }

  void _sendMessage() async {
    if (_controller.text.isEmpty || _isLoading) return;
    if (DateTime.now().difference(_lastRequestTime).inSeconds < 2) return;

    _lastRequestTime = DateTime.now();
    final userMessage = _controller.text;
    _controller.clear();

    if (mounted) {
      setState(() => _messages.insert(0, Message(userMessage, true)));
    }

    final aiResponse = await _getAIResponse(userMessage);

    if (mounted) {
      setState(() => _messages.insert(0, Message(aiResponse, false)));
    }
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
        title: Text("Saldae Trip Agent", style: GoogleFonts.notoSans()),
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
            builder:
                (ctx, child) => Transform.rotate(
                  angle: _animation.value * 2 * pi,
                  child: IconButton(
                    icon: const Icon(Icons.travel_explore),
                    onPressed: () {},
                  ),
                ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colors.surface.withOpacity(0.8),
              colors.surface.withOpacity(0.5),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                reverse: true,
                controller: _scrollController,
                itemCount: _messages.length,
                itemBuilder: (ctx, index) => _buildMessage(_messages[index]),
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
                          style: GoogleFonts.notoSans(color: colors.onSurface),
                          decoration: InputDecoration(
                            hintText: "Posez votre question sur Béjaïa...",
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                            ),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [colors.primary, colors.secondary],
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
                            child:
                                _isLoading
                                    ? CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: colors.onPrimary,
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

  Widget _buildMessage(Message msg) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!msg.isUser) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: colors.secondary.withOpacity(0.2),
              child: Icon(Icons.flag, size: 18, color: colors.secondary),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  msg.isUser
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
              children: [
                if (!msg.isUser)
                  Text(
                    'Saldae Trip Agent',
                    style: GoogleFonts.notoSans(
                      color: colors.secondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors:
                          msg.isUser
                              ? [
                                colors.primary,
                                colors.primary.withOpacity(0.7),
                              ]
                              : [
                                colors.surfaceVariant,
                                colors.surfaceVariant.withOpacity(0.7),
                              ],
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
                    style: GoogleFonts.notoSans(
                      fontSize: 15,
                      color: msg.isUser ? colors.onPrimary : colors.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (msg.isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: colors.primary.withOpacity(0.2),
              child: Icon(Icons.person, size: 18, color: colors.primary),
            ),
          ],
        ],
      ),
    );
  }
}

class Message {
  final String text;
  final bool isUser;

  Message(this.text, this.isUser);
}