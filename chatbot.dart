import 'package:flutter/material.dart';
import 'package:flutter/animation.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'GlovalColors.dart';

class ChatBotScreen extends StatefulWidget {
  const ChatBotScreen({super.key});

  @override
  _ChatBotScreenState createState() => _ChatBotScreenState();
}

class Message {
  final String text;
  final bool isUser;
  Message(this.text, this.isUser);
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
      isAuto: true,
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

  /// Construit la liste des messages pour l'API 
  List<Map<String, String>> _buildApiMessages(String prompt, {bool isAuto = false}) {
    List<Map<String, String>> apiMessages = [];

    // Message système 
    apiMessages.add({
  "role": "system",
  "content": 
    "**Saldae Trip Agent Pro** - Polyglotte expert de Béjaïa (4 langues)\n\n"

    "### SYSTÈME LINGUISTIQUE\n"
    "1. **Détection automatique** :\n"
    "   - Français : 'Restaurant'/'Adresse' → FR\n"
    "   - English : 'Hotel'/'Beach' → EN\n"
    "   - Darija : 'bghit'/ⵣ → DARIJA\n"
    "   - Kabyle : 'Azul'/'Amek' → KABYLE\n\n"

    "2. **Adaptations régionales** :\n"
    "   - DARIJA : Utiliser écriture latine (ex: 'Sbeḥ lkhir') + emojis 🇩🇿\n"
    "   - KABYLE : Translittération ISO/YALA (ex: 'Taddart' ≠ 'Thaddarth')\n"
    "   - FR/EN : Conserver les noms kabyes originaux (ex: 'Aḍebbay' → non traduit)\n\n"

    "3. **Base lexicale** :\n"
    "   - FR : 'Piscine naturelle' = 'Les Aiguades'\n"
    "   - DARIJA : 'Bḥar' = Mer | 'Souq' = Marché\n"
    "   - KABYLE : 'Amane' = Eau | 'Adrar' = Montagne\n\n"

    "### EXEMPLES MULTILINGUES\n"
    "**Requête FR** : 'Meilleur café à la Casbah ?'\n"
    "```markdown\n"
    "☕ **Café Saḥel** | 📍 Rue Abderrahmane Laala, Casbah\n"
    "💬 Spécialité : Qahwa arkīk (café traditionnel torréfié au feu de bois)\n"
    "⏰ Ouvert : 7h-22h (Ramadan : 20h-1h)\n"
    "```\n\n"

    "**Requête DARIJA** : 'Fin kayn musée f Bgayet ?'\n"
    "```markdown\n"
    "🏛️ **Musée Moussa** | 📍 Rue du 1er Novembre, Casba\n"
    "💬 Haja khasra : Qadima rumaniya (stèles romaines)\n"
    "🎫 Dkhel : 100DA | ⏰ 9h-17h (fermé tlata)\n"
    "```\n\n"

    "**Requête KABYLE** : 'Anida tella tarmint n Weqbayl ?'\n"
    "```markdown\n"
    "🏫 **Tasdawit n Terga Ouzemmour** | 📍 Cḥerfa, Bgayet\n"
    "💬 Aselmad n tsenselkimt d tseddawit\n"
    "🚍 Anekcum : Bus 12A seg tɣiwant\n"
    "```\n\n"

    "### RÈGLES LINGUISTIQUES\n"
    "1. **Priorité toponymique** :\n"
    "   - Conserver les noms originaux : 'Sidi Touati' ≠ 'Saint Antoine'\n\n"
    "2. **Code-switching** :\n"
    "   - Autoriser mélanges naturels (ex: 'Yallah on y va !' → DARIJA+FR)\n\n"
    "3. **Correction proactive** :\n"
    "   - Si erreur dialectale → Reformuler poliment (ex: 'Toudja = ⵜⵓⴵⴰ en tifinagh')"
});

    // Ajoute l'historique 
    // On saute l'intro automatique pour ne pas polluer le contexte
    for (var msg in _messages.reversed) {
      if (isAuto && msg == _messages.last) continue;
      apiMessages.add({
        "role": msg.isUser ? "user" : "assistant",
        "content": msg.text,
      });
    }

    // Ajoute le message utilisateur courant 
    apiMessages.add({
      "role": "user",
      "content": prompt,
    });

    return apiMessages;
  }

  Future<String> _getAIResponse(String prompt, {bool isAuto = false}) async {
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
            "messages": _buildApiMessages(prompt, isAuto: isAuto),
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
      return "🔌 Problème de connexion ";
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
    final colors = Theme.of(context).colorScheme;
    final bleuTurquoise = GlobalColors.bleuTurquoise;
    final primaryColor = GlobalColors.primaryColor;
    final secondaryColor = GlobalColors.secondaryColor;
    final isDarkMode = GlobalColors.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Saldae Trip Agent",
          style: GoogleFonts.robotoSlab(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [GlobalColors.bleuTurquoise, GlobalColors.bleuTurquoise],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          AnimatedBuilder(
            animation: _animation,
            builder: (ctx, child) => Transform.rotate(
              angle: _animation.value * 2 * pi,
              child: IconButton(
                icon: Icon(Icons.travel_explore, color: Colors.white),
                onPressed: () {},
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? GlobalColors.darkCard : colors.surface,
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
            Container(
              decoration: BoxDecoration(
                color: isDarkMode
                    ? GlobalColors.darkCard
                    : colors.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: Offset(0, -3),
                  )
                ],
              ),
              padding: const EdgeInsets.all(12.0),
              child: Material(
                elevation: 0,
                borderRadius: BorderRadius.circular(25),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDarkMode
                        ? GlobalColors.darkCard.withOpacity(0.8)
                        : colors.surface,
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                      color: bleuTurquoise.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          style: TextStyle(
                            color: isDarkMode ? Colors.white : colors.onSurface,
                            fontFamily: 'Poppins',
                          ),
                          decoration: InputDecoration(
                            hintText: "Posez votre question sur Béjaïa...",
                            hintStyle: TextStyle(
                              color: isDarkMode
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600,
                              fontFamily: 'Poppins',
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [bleuTurquoise, bleuTurquoise],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: bleuTurquoise.withOpacity(0.4),
                              blurRadius: _isLoading ? 15 : 5,
                              spreadRadius: _isLoading ? 2 : 0,
                            ),
                          ],
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(50),
                          onTap: _sendMessage,
                          child: Padding(
                            padding: const EdgeInsets.all(14.0),
                            child: _isLoading
                                ? SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : Icon(Icons.send, color: Colors.white, size: 22),
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
    final isDarkMode = GlobalColors.isDarkMode;
    final bleuTurquoise = GlobalColors.bleuTurquoise;
    final primaryColor = GlobalColors.primaryColor;
    final secondaryColor = GlobalColors.secondaryColor;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            msg.isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!msg.isUser) ...[
            Container(
              margin: EdgeInsets.only(top: 8),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: bleuTurquoise.withOpacity(0.2),
                child: Icon(
                  Icons.assistant_rounded,
                  size: 20,
                  color: bleuTurquoise,
                ),
              ),
            ),
            const SizedBox(width: 10),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  msg.isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!msg.isUser)
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 4),
                    child: Text(
                      'Saldae Trip Agent',
                      style: TextStyle(
                        color: bleuTurquoise,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: msg.isUser
                          ? [bleuTurquoise, bleuTurquoise]
                          : [bleuTurquoise.withOpacity(0.8), bleuTurquoise.withOpacity(0.7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                      bottomLeft: Radius.circular(msg.isUser ? 20 : 4),
                      bottomRight: Radius.circular(msg.isUser ? 4 : 20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 5,
                        offset: Offset(0, 2),
                      )
                    ],
                  ),
                  child: MarkdownBody(
                    data: msg.text,
                    styleSheet: MarkdownStyleSheet(
                      p: TextStyle(
                        color: msg.isUser
                            ? Colors.white
                            : isDarkMode
                                ? Colors.white
                                : primaryColor,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
