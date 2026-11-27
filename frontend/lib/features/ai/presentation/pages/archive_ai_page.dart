import '../../../../core/design_system/tokens/ds_radius.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/design_system/tokens/ds_colors.dart';

class ArchiveAIPage extends StatefulWidget {
  final bool isDrawerMode;
  final VoidCallback? onClose;
  final String? currentRoute;

  const ArchiveAIPage({
    super.key,
    this.isDrawerMode = false,
    this.onClose,
    this.currentRoute,
  });

  /// Resets session chat history and past sessions (for test isolation).
  static void resetSessionForTesting() => _ArchiveAIPageState.resetSessionForTesting();

  @override
  State<ArchiveAIPage> createState() => _ArchiveAIPageState();
}

class _ArchiveAIPageState extends State<ArchiveAIPage> {
  final TextEditingController _textController = TextEditingController();
  static final List<Map<String, dynamic>> _sessionChatHistory = [];
  static final List<Map<String, dynamic>> _pastSessions = [];
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  bool _isShowingHistory = false;
  String? _currentActiveSessionTitle;

  static const _defaultPrompts = [
    {
      'icon': FontAwesomeIcons.lightbulb,
      'label': 'Recommend me a book',
      'prompt': 'Recommend me a great book to read this week.',
    },
    {
      'icon': FontAwesomeIcons.masksTheater,
      'label': 'Mood-based Recommendations',
      'prompt': 'Suggest books for a cozy, reflective rainy afternoon mood.',
    },
    {
      'icon': FontAwesomeIcons.bookBookmark,
      'label': 'Similar to Atomic Habits',
      'prompt': 'Find books similar to Atomic Habits by James Clear.',
    },
    {
      'icon': FontAwesomeIcons.calendarCheck,
      'label': 'Help with Reading Plan',
      'prompt': 'Help me build a 30-day reading plan for history & classics.',
    },
    {
      'icon': FontAwesomeIcons.graduationCap,
      'label': 'Student Study Assistant',
      'prompt': 'Help me outline a semester study plan for Computer Science.',
    },
    {
      'icon': FontAwesomeIcons.buildingColumns,
      'label': 'Discover from My Library',
      'prompt': 'Help me discover unread gems from my personal library.',
    },
  ];

  static const _bookPrompts = [
    {
      'icon': FontAwesomeIcons.lightbulb,
      'label': 'Summarize this book',
      'prompt': 'Can you provide a concise summary and key takeaways of this book?',
    },
    {
      'icon': FontAwesomeIcons.bullseye,
      'label': 'Does this suit my reading goals?',
      'prompt': 'Does this book match my current reading goals and interests?',
    },
    {
      'icon': FontAwesomeIcons.scaleBalanced,
      'label': 'Compare Buy vs Rent',
      'prompt': 'Should I buy or rent this book based on its reading length and value?',
    },
    {
      'icon': FontAwesomeIcons.bookOpen,
      'label': 'Similar Recommendations',
      'prompt': 'What are similar books to this title available in LibriFlow?',
    },
  ];

  static const _providerPrompts = [
    {
      'icon': FontAwesomeIcons.tag,
      'label': 'Suggest a rental price',
      'prompt': 'How should I price this book for rental to balance demand and revenue?',
    },
    {
      'icon': FontAwesomeIcons.penNib,
      'label': 'Describe book condition',
      'prompt': 'Help me write an accurate and appealing book condition description.',
    },
    {
      'icon': FontAwesomeIcons.chartLine,
      'label': 'Tips to increase rentals & sales',
      'prompt': 'What are best practices to increase book rentals and sales on LibriFlow?',
    },
    {
      'icon': FontAwesomeIcons.shieldHalved,
      'label': 'Condition verification guide',
      'prompt': 'What criteria define Near Mint vs Good vs Acceptable condition?',
    },
  ];

  static const _adminPrompts = [
    {
      'icon': FontAwesomeIcons.chartPie,
      'label': 'Marketplace health overview',
      'prompt': 'Summarize the platform marketplace health and key performance metrics.',
    },
    {
      'icon': FontAwesomeIcons.scaleUnbalanced,
      'label': 'Content moderation guidelines',
      'prompt': 'What are our moderation guidelines for book listings and dispute resolution?',
    },
    {
      'icon': FontAwesomeIcons.circleExclamation,
      'label': 'Platform policy assistance',
      'prompt': 'Explain the platform security policies for user verification and order escrow.',
    },
  ];

  List<Map<String, dynamic>> _getContextualPrompts() {
    final route = widget.currentRoute ?? '';
    if (route.contains('/book/') || route.contains('/book-detail')) {
      return _bookPrompts;
    }
    if (route.contains('/provider') || route.contains('/add-book') || route.contains('/sell')) {
      return _providerPrompts;
    }
    if (route.contains('/admin')) {
      return _adminPrompts;
    }
    return _defaultPrompts;
  }

  String _getContextualWelcomeText() {
    final route = widget.currentRoute ?? '';
    if (route.contains('/book/')) {
      return "Welcome to Archive AI! How can I assist you with this book, reading goals, or pricing options today?";
    }
    if (route.contains('/provider') || route.contains('/add-book') || route.contains('/sell')) {
      return "Welcome to Archive AI Provider Assistant! How can I assist your catalog, pricing, and book condition descriptions today?";
    }
    if (route.contains('/admin')) {
      return "Welcome to Archive AI Admin Assistant! How can I assist with platform policies and moderation guidance today?";
    }
    return "Welcome to Archive AI! Your personal AI reading companion. How can I assist your literary journey today?";
  }

  static String? _lastContextRoute;

  /// Resets session chat history and past sessions (primarily for testing and clean slate).
  static void resetSessionForTesting() {
    _sessionChatHistory.clear();
    _pastSessions.clear();
    _lastContextRoute = null;
  }

  @override
  void initState() {
    super.initState();
    _loadPastSessions();
    final hasUserMessages = _sessionChatHistory.any((m) => m['sender'] == 'user');
    if (_sessionChatHistory.isEmpty || (!hasUserMessages && widget.currentRoute != _lastContextRoute)) {
      _lastContextRoute = widget.currentRoute;
      _initInitialMessages();
    } else {
      _messages.clear();
      _messages.addAll(_sessionChatHistory);
    }
  }

  Future<void> _loadPastSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('archive_ai_past_sessions');
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(raw);
        if (mounted) {
          setState(() {
            _pastSessions.clear();
            for (final item in decoded) {
              _pastSessions.add(Map<String, dynamic>.from(item as Map));
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading past sessions: $e');
    }
  }

  static Future<void> _savePastSessions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final serializableSessions = _pastSessions.map((s) {
        final msgs = (s['messages'] as List<dynamic>? ?? []).map((m) {
          final copy = Map<String, dynamic>.from(m as Map);
          copy.remove('suggestedPrompts');
          return copy;
        }).toList();

        return {
          'id': s['id'],
          'title': s['title'],
          'date': s['date'],
          'questionCount': s['questionCount'],
          'messages': msgs,
        };
      }).toList();

      await prefs.setString('archive_ai_past_sessions', jsonEncode(serializableSessions));
    } catch (e) {
      debugPrint('Error saving past sessions: $e');
    }
  }

  void _archiveCurrentChatAndStartNew({bool showNotice = true}) {
    final userMessages = _messages.where((m) => m['sender'] == 'user').toList();

    if (userMessages.isNotEmpty) {
      final firstQuestion = userMessages.first['text'] as String? ?? 'Reading Consultation';
      String title = firstQuestion;
      if (title.length > 35) {
        title = '${title.substring(0, 32)}...';
      }

      final now = DateTime.now();
      final timeStr = DateFormat('MMM d, h:mm a').format(now);

      final newSession = {
        'id': 'session_${now.millisecondsSinceEpoch}',
        'title': title,
        'date': timeStr,
        'questionCount': userMessages.length,
        'messages': List<Map<String, dynamic>>.from(_messages),
      };

      setState(() {
        _pastSessions.insert(0, newSession);
        _currentActiveSessionTitle = null;
      });
      _savePastSessions();

      if (showNotice && mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.history_edu_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Chat saved to History! You can revisit it anytime via the 📜 History icon.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
            backgroundColor: DSColors.deepForestGreen,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'View History',
              textColor: DSColors.accentTerracotta,
              onPressed: () => setState(() => _isShowingHistory = true),
            ),
          ),
        );
      }
    }

    _initInitialMessages();
    setState(() {
      _currentActiveSessionTitle = null;
    });
  }

  void _archiveCurrentChatOnClose() {
    final userMessages = _messages.where((m) => m['sender'] == 'user').toList();
    if (userMessages.isNotEmpty) {
      final firstQuestion = userMessages.first['text'] as String? ?? 'Reading Consultation';
      String title = firstQuestion;
      if (title.length > 35) {
        title = '${title.substring(0, 32)}...';
      }

      final alreadySaved = _pastSessions.any((s) {
        final msgs = s['messages'] as List<dynamic>?;
        return msgs != null && msgs.length == _messages.length && s['title'] == title;
      });

      if (!alreadySaved) {
        final now = DateTime.now();
        final timeStr = DateFormat('MMM d, h:mm a').format(now);
        _pastSessions.insert(0, {
          'id': 'session_${now.millisecondsSinceEpoch}',
          'title': title,
          'date': timeStr,
          'questionCount': userMessages.length,
          'messages': List<Map<String, dynamic>>.from(_messages),
        });
        _savePastSessions();
      }
    }
  }

  void _restorePastSession(Map<String, dynamic> session) {
    setState(() {
      _messages.clear();
      final loaded = (session['messages'] as List<dynamic>)
          .map((m) => Map<String, dynamic>.from(m as Map))
          .toList();
      _messages.addAll(loaded);
      _sessionChatHistory.clear();
      _sessionChatHistory.addAll(loaded);
      _currentActiveSessionTitle = session['title'] as String?;
      _isShowingHistory = false;
    });

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Restored chat: "${session['title']}"'),
        backgroundColor: DSColors.deepForestGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _deletePastSession(int index) {
    final deleted = _pastSessions[index];
    setState(() {
      _pastSessions.removeAt(index);
    });
    _savePastSessions();

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Deleted "${deleted['title']}" from history.'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _confirmClearAllHistory() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Clear Chat History?', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold)),
        content: const Text('This will permanently delete all saved past conversations.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              setState(() {
                _pastSessions.clear();
              });
              _savePastSessions();
            },
            style: ElevatedButton.styleFrom(backgroundColor: DSColors.terracotta),
            child: const Text('Clear All', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _initInitialMessages() {
    _messages.clear();
    _sessionChatHistory.clear();
    final initial = {
      'sender': 'ai',
      'text': _getContextualWelcomeText(),
      'time': 'Just now',
      'suggestedPrompts': _getContextualPrompts(),
    };
    _messages.add(initial);
    _sessionChatHistory.add(initial);
  }

  void _addMessage(Map<String, dynamic> msg) {
    _messages.add(msg);
    _sessionChatHistory.add(msg);
  }

  Future<void> _handleSendMessage({String? text}) async {
    final messageText = text ?? _textController.text.trim();
    if (messageText.isEmpty) return;

    setState(() {
      _addMessage({
        'sender': 'user',
        'text': messageText,
        'time': 'Just now',
      });
      _isLoading = true;
    });

    if (text == null) {
      _textController.clear();
    }

    try {
      final route = widget.currentRoute ?? '';
      String reply;
      if (route.contains('/reader') || route.contains('/passport')) {
        reply = await ApiService.askReadingCompanion(messageText);
      } else {
        reply = await ApiService.askStudyAssistant(messageText);
      }

      if (mounted) {
        setState(() {
          _addMessage({
            'sender': 'ai',
            'text': reply,
            'time': 'Just now',
          });
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _addMessage({
            'sender': 'ai',
            'text': "Archive AI: I was unable to connect to the assistant service. Please check your connection and try again.",
            'time': 'Just now',
          });
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DSColors.warmIvory,
      appBar: AppBar(
        backgroundColor: DSColors.forestGreen,
        elevation: 0,
        leading: _isShowingHistory
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => setState(() => _isShowingHistory = false),
              )
            : (widget.isDrawerMode
                ? IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () {
                      _archiveCurrentChatOnClose();
                      if (widget.onClose != null) {
                        widget.onClose!();
                      } else {
                        Navigator.of(context).pop();
                      }
                    },
                  )
                : IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      _archiveCurrentChatOnClose();
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/');
                      }
                    },
                  )),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: DSColors.warmGold.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const FaIcon(FontAwesomeIcons.wandMagicSparkles, color: DSColors.warmGold, size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _isShowingHistory ? 'Chat History' : 'Archive AI',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _isShowingHistory
                        ? '${_pastSessions.length} saved conversation${_pastSessions.length == 1 ? '' : 's'}'
                        : 'Your personal AI reading companion',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (!_isShowingHistory) ...[
            Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.history_rounded, color: Colors.white),
                  tooltip: 'Chat History (${_pastSessions.length})',
                  onPressed: () => setState(() => _isShowingHistory = true),
                ),
                if (_pastSessions.isNotEmpty)
                  Positioned(
                    right: 6,
                    top: 6,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: DSColors.terracotta,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Center(
                        child: Text(
                          '${_pastSessions.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Colors.white),
              tooltip: 'End & Start New Chat',
              onPressed: () => _archiveCurrentChatAndStartNew(showNotice: true),
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.add_comment_outlined, color: Colors.white),
              tooltip: 'Start Fresh Chat',
              onPressed: () {
                _initInitialMessages();
                setState(() => _isShowingHistory = false);
              },
            ),
          ],
        ],
      ),
      body: SafeArea(
        child: _isShowingHistory
            ? _buildHistoryView()
            : Column(
                children: [
                  if (_currentActiveSessionTitle != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: DSColors.forestGreen.withValues(alpha: 0.08),
                        border: Border(bottom: BorderSide(color: DSColors.forestGreen.withValues(alpha: 0.15))),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.history_edu, size: 16, color: DSColors.forestGreen),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Viewing Saved Chat: "$_currentActiveSessionTitle"',
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: DSColors.forestGreen),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          InkWell(
                            onTap: () => _archiveCurrentChatAndStartNew(showNotice: false),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: DSColors.terracotta,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '+ New Chat',
                                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _messages.length,
                      itemBuilder: (context, index) => _buildMessageBubble(_messages[index]),
                    ),
                  ),

                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: DSColors.forestGreen),
                      ),
                    ),

                  // Input Bar
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(top: BorderSide(color: DSColors.borderLight)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, -2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _textController,
                            onSubmitted: (_) => _handleSendMessage(),
                            style: GoogleFonts.inter(fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Ask Archive AI anything...',
                              hintStyle: GoogleFonts.inter(fontSize: 13, color: DSColors.textMuted),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                              filled: true,
                              fillColor: DSColors.background,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(DSRadius.pill),
                                borderSide: const BorderSide(color: DSColors.border),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        InkWell(
                          onTap: () => _handleSendMessage(),
                          borderRadius: BorderRadius.circular(DSRadius.pill),
                          child: Container(
                            width: 44,
                            height: 48,
                            decoration: const BoxDecoration(
                              color: DSColors.forestGreen,
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Icon(Icons.send_rounded, color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildHistoryView() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: DSColors.borderLight)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton.icon(
                onPressed: () => setState(() => _isShowingHistory = false),
                icon: const Icon(Icons.arrow_back, size: 16, color: DSColors.forestGreen),
                label: Text(
                  'Back to Active Chat',
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: DSColors.forestGreen),
                ),
              ),
              if (_pastSessions.isNotEmpty)
                TextButton.icon(
                  onPressed: _confirmClearAllHistory,
                  icon: const Icon(Icons.delete_outline, size: 14, color: DSColors.terracotta),
                  label: Text(
                    'Clear All',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: DSColors.terracotta),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: _pastSessions.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: DSColors.forestGreen.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.history_rounded, size: 32, color: DSColors.forestGreen),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No Chat History Yet',
                          style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.bold, color: DSColors.textDark),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'When you end a chat or click "End & Start New Chat", your full conversation with book suggestions and reading plans will be saved here.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(fontSize: 13, color: DSColors.textMuted, height: 1.4),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () {
                            _initInitialMessages();
                            setState(() => _isShowingHistory = false);
                          },
                          icon: const Icon(Icons.chat_bubble_outline, size: 16),
                          label: const Text('Start a Conversation'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: DSColors.forestGreen,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DSRadius.pill)),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _pastSessions.length,
                  itemBuilder: (context, index) {
                    final session = _pastSessions[index];
                    final title = session['title'] as String? ?? 'Conversation';
                    final date = session['date'] as String? ?? '';
                    final questionCount = session['questionCount'] as int? ?? 1;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(DSRadius.card),
                        border: Border.all(color: DSColors.border),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(DSRadius.card),
                          onTap: () => _restorePastSession(session),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: DSColors.forestGreen.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.chat_bubble_outline, size: 18, color: DSColors.forestGreen),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        title,
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: DSColors.textDark,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          const Icon(Icons.access_time, size: 12, color: DSColors.textMuted),
                                          const SizedBox(width: 4),
                                          Text(
                                            date,
                                            style: GoogleFonts.inter(fontSize: 11, color: DSColors.textMuted),
                                          ),
                                          const SizedBox(width: 10),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: DSColors.softBorder,
                                              borderRadius: BorderRadius.circular(DSRadius.sm),
                                            ),
                                            child: Text(
                                              '$questionCount question${questionCount > 1 ? 's' : ''}',
                                              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: DSColors.textMuted),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, size: 18, color: DSColors.textMuted),
                                      tooltip: 'Delete',
                                      onPressed: () => _deletePastSession(index),
                                    ),
                                    const Icon(Icons.chevron_right, color: DSColors.forestGreen, size: 20),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg) {
    final isUser = msg['sender'] == 'user';
    final suggested = msg['suggestedPrompts'] as List<Map<String, dynamic>>?;
    final books = msg['books'] as List<Map<String, dynamic>>?;
    final actionChips = msg['actionChips'] as List<String>?;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isUser) ...[
                CircleAvatar(
                  radius: 18,
                  backgroundColor: DSColors.forestGreen,
                  child: const FaIcon(FontAwesomeIcons.wandMagicSparkles, size: 14, color: DSColors.warmGold),
                ),
                const SizedBox(width: 10),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isUser ? DSColors.forestGreen : Colors.white,
                    borderRadius: BorderRadius.circular(DSRadius.card).copyWith(
                      topLeft: !isUser ? Radius.zero : const Radius.circular(16),
                      topRight: isUser ? Radius.zero : const Radius.circular(16),
                    ),
                    border: isUser ? null : Border.all(color: DSColors.borderLight),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    msg['text']!,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: isUser ? Colors.white : DSColors.textDark,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Suggested Prompt Chips
          if (suggested != null && suggested.isNotEmpty) ...[
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.only(left: 46),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: suggested.map((p) {
                  return ActionChip(
                    avatar: FaIcon(p['icon'] as dynamic, size: 12, color: DSColors.forestGreen),
                    label: Text(
                      p['label'] as String,
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: DSColors.forestGreen),
                    ),
                    backgroundColor: Colors.white,
                    side: const BorderSide(color: DSColors.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DSRadius.pill)),
                    onPressed: () => _handleSendMessage(text: p['prompt'] as String),
                  );
                }).toList(),
              ),
            ),
          ],

          // Book Recommendation Cards with "Why this book?" and Action Buttons
          if (books != null && books.isNotEmpty) ...[
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.only(left: 46),
              child: Column(
                children: books.map((b) => _buildBookRecommendationCard(b)).toList(),
              ),
            ),
          ],

          // Action Chips
          if (actionChips != null && actionChips.isNotEmpty) ...[
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 46),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: actionChips.map((chipText) {
                  return ActionChip(
                    label: Text(chipText, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: DSColors.forestGreen)),
                    backgroundColor: DSColors.softMint,
                    side: BorderSide.none,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DSRadius.pill)),
                    onPressed: () => _handleSendMessage(text: chipText),
                  );
                }).toList(),
              ),
            ),
          ],

          // Interactive Conversation Controls (Continue Chat & End Chat)
          if (!isUser && msg != _messages.first) ...[
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(left: 46),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      _handleSendMessage(text: "Tell me more details about these book options.");
                    },
                    icon: const Icon(Icons.chat_bubble_outline, size: 13),
                    label: const Text('💬 Continue Chat'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: DSColors.forestGreen,
                      side: const BorderSide(color: DSColors.forestGreen),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      textStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _archiveCurrentChatAndStartNew(showNotice: true),
                    icon: const Icon(Icons.refresh_rounded, size: 13, color: DSColors.terracotta),
                    label: const Text('🔄 End & Start New Chat'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: DSColors.terracotta,
                      side: const BorderSide(color: DSColors.terracotta),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      textStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (_pastSessions.isNotEmpty)
                    OutlinedButton.icon(
                      onPressed: () => setState(() => _isShowingHistory = true),
                      icon: const Icon(Icons.history_rounded, size: 13, color: DSColors.forestGreen),
                      label: Text('📜 View Past Chats (${_pastSessions.length})'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: DSColors.forestGreen,
                        side: const BorderSide(color: DSColors.forestGreen),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        textStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBookRecommendationCard(Map<String, dynamic> b) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(DSRadius.card),
        border: Border.all(color: DSColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  b['cover'],
                  width: 56,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    width: 56,
                    height: 80,
                    color: DSColors.borderLight,
                    child: const Icon(Icons.book, color: DSColors.textMuted),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      b['title'],
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: DSColors.forestGreen,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'by ${b['author']}',
                      style: GoogleFonts.inter(fontSize: 12, color: DSColors.textLight),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      b['rating'],
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: DSColors.warmGold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      b['price'],
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: DSColors.forestGreen),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // "Why this book?" explanation pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: DSColors.softMint,
              borderRadius: BorderRadius.circular(DSRadius.md),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome, size: 12, color: DSColors.forestGreen),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    b['whyThisBook'],
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: DSColors.forestGreen),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Action Buttons: View Book, Favorite, Rent, Buy
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => context.push('/book/${b['id']}'),
                icon: const Icon(Icons.visibility_outlined, size: 14),
                label: const Text('View Book'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Added ${b['title']} to Favorites!'),
                      backgroundColor: DSColors.forestGreen,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.favorite_border, size: 14, color: DSColors.terracotta),
                label: const Text('Favorite'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
              if (b['canRent'] == true)
                ElevatedButton.icon(
                  onPressed: () => context.push('/buy-now-checkout', extra: {'mode': 'rent'}),
                  icon: const Icon(Icons.key, size: 14),
                  label: const Text('Rent'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DSColors.warmGold,
                    foregroundColor: DSColors.forestGreen,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              if (b['canBuy'] == true)
                ElevatedButton.icon(
                  onPressed: () => context.push('/buy-now-checkout', extra: {'mode': 'purchase'}),
                  icon: const Icon(Icons.shopping_bag_outlined, size: 14),
                  label: const Text('Buy'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DSColors.forestGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
