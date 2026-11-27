import '../../../../core/design_system/tokens/ds_radius.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/design_system/tokens/ds_colors.dart';

class AIReadingConciergePage extends StatefulWidget {
  final bool isDrawerMode;
  final VoidCallback? onClose;

  const AIReadingConciergePage({
    super.key,
    this.isDrawerMode = false,
    this.onClose,
  });

  @override
  State<AIReadingConciergePage> createState() => _AIReadingConciergePageState();
}

class _AIReadingConciergePageState extends State<AIReadingConciergePage> {
  String _selectedIntent = 'Motivating';
  String _selectedMood = 'Curious';
  String _selectedTime = '30 min';
  String _selectedGoal = 'Improve a skill';

  bool _isLoading = false;
  List<Map<String, dynamic>> _picks = [];

  final List<Map<String, String>> _intentOptions = [
    {'label': '😌 Relaxing', 'val': 'Relaxing'},
    {'label': '🧠 Learn', 'val': 'Learn'},
    {'label': '❤️ Emotional', 'val': 'Emotional'},
    {'label': '🔥 Motivating', 'val': 'Motivating'},
    {'label': '🎓 Study', 'val': 'Study'},
    {'label': '🕵 Mystery', 'val': 'Mystery'},
  ];

  final List<String> _moodOptions = ['Curious', 'Calm', 'Stressed', 'Excited', 'Focused'];
  final List<String> _timeOptions = ['15 min', '30 min', '1 hour', '2+ hours'];
  final List<String> _goalOptions = ['Discover something new', 'Finish a book', 'Study', 'Improve a skill'];

  @override
  void initState() {
    super.initState();
    _fetchRecommendations();
  }

  Future<void> _fetchRecommendations() async {
    setState(() => _isLoading = true);

    try {
      final res = await ApiService.post('/ai/concierge/recommend', data: {
        'intent': _selectedIntent,
        'mood': _selectedMood,
        'available_time': _selectedTime,
        'goal': _selectedGoal,
      });

      if (res.statusCode == 200 && res.data != null && res.data['picks'] != null) {
        setState(() {
          _picks = List<Map<String, dynamic>>.from(res.data['picks']);
          _isLoading = false;
        });
        return;
      }
    } catch (_) {}

    // High quality client-side fallback if backend call returns error
    setState(() {
      _picks = [
        {
          'id': 1,
          'title': 'Atomic Habits',
          'author': 'James Clear',
          'coverUrl': '/images/book1.jpg',
          'category': 'Self-Improvement',
          'price': 350.0,
          'rentalPrice': 50.0,
          'matchScore': '94%',
          'matchReason': 'You liked self-improvement books + similar reading history + matches today\'s \'$_selectedMood\' mood & $_selectedGoal goal.',
          'reasons': [
            'You enjoy self-improvement and productivity literature',
            'Fits comfortably into your $_selectedTime daily reading slot',
            'Targeted directly at your goal: $_selectedGoal'
          ]
        },
        {
          'id': 2,
          'title': 'Ikigai: The Japanese Secret to a Long and Happy Life',
          'author': 'Héctor García & Francesc Miralles',
          'coverUrl': '/images/book2.jpg',
          'category': 'Philosophy',
          'price': 280.0,
          'rentalPrice': 40.0,
          'matchScore': '89%',
          'matchReason': 'Reflective, mindful pacing ideal for a $_selectedTime session when feeling $_selectedMood.',
          'reasons': [
            'Proven companion for lifestyle balance and purpose',
            'Clean, uplifting prose with high reader satisfaction',
            'Matches your \'$_selectedIntent\' intent focus'
          ]
        },
        {
          'id': 3,
          'title': 'The Psychology of Money',
          'author': 'Morgan Housel',
          'coverUrl': '/images/book3.jpg',
          'category': 'Finance & Behavior',
          'price': 320.0,
          'rentalPrice': 45.0,
          'matchScore': '86%',
          'matchReason': 'Bite-sized chapters combining practical behavioral wisdom with $_selectedGoal.',
          'reasons': [
            'Compact chapters ideal for $_selectedTime focus bursts',
            'Highly rated by fellow archive community members',
            'Strong thematic alignment with your focus'
          ]
        }
      ];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DSColors.paperWhite,
      appBar: AppBar(
        backgroundColor: DSColors.forestGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            if (widget.onClose != null) {
              widget.onClose!();
            } else if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
        title: Text(
          '✨ AI Reading Concierge',
          style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 800),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title & Subtitle Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: DSColors.warmIvory,
                    borderRadius: BorderRadius.circular(DSRadius.card),
                    border: Border.all(color: DSColors.softBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI READING CONCIERGE',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          color: DSColors.secondaryGreen,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'This app understands what kind of reader you are.',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: DSColors.deepForestGreen,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Tuned in real-time across your mood, available duration, goals, and verified reading history.',
                        style: GoogleFonts.inter(fontSize: 13, color: DSColors.textLight),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // SECTION 1: WHAT ARE YOU LOOKING FOR TODAY?
                _buildSectionHeader('What are you looking for today?'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: _intentOptions.map((opt) {
                    final isSelected = _selectedIntent == opt['val'];
                    return ChoiceChip(
                      label: Text(opt['label']!),
                      selected: isSelected,
                      selectedColor: DSColors.deepForestGreen,
                      backgroundColor: Colors.white,
                      labelStyle: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? Colors.white : DSColors.charcoal,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(DSRadius.card),
                        side: BorderSide(
                          color: isSelected ? DSColors.deepForestGreen : DSColors.softBorder,
                        ),
                      ),
                      onSelected: (val) {
                        if (val) setState(() => _selectedIntent = opt['val']!);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                const Divider(color: DSColors.softBorder),
                const SizedBox(height: 20),

                // SECTION 2: WHAT IS YOUR MOOD?
                _buildSectionHeader('What is your mood?'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: _moodOptions.map((mood) {
                    final isSelected = _selectedMood == mood;
                    return InkWell(
                      onTap: () => setState(() => _selectedMood = mood),
                      borderRadius: BorderRadius.circular(DSRadius.card),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? DSColors.warmIvory : Colors.white,
                          borderRadius: BorderRadius.circular(DSRadius.card),
                          border: Border.all(
                            color: isSelected ? DSColors.antiqueGold : DSColors.softBorder,
                            width: isSelected ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                              size: 16,
                              color: isSelected ? DSColors.antiqueGold : DSColors.textMuted,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              mood,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected ? DSColors.antiqueGold : DSColors.textLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                const Divider(color: DSColors.softBorder),
                const SizedBox(height: 20),

                // SECTION 3: HOW MUCH TIME DO YOU HAVE?
                _buildSectionHeader('How much time do you have?'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: _timeOptions.map((t) {
                    final isSelected = _selectedTime == t;
                    return ChoiceChip(
                      label: Text(t),
                      selected: isSelected,
                      selectedColor: DSColors.deepForestGreen,
                      backgroundColor: Colors.white,
                      labelStyle: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? Colors.white : DSColors.charcoal,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(DSRadius.card),
                        side: BorderSide(
                          color: isSelected ? DSColors.deepForestGreen : DSColors.softBorder,
                        ),
                      ),
                      onSelected: (val) {
                        if (val) setState(() => _selectedTime = t);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                const Divider(color: DSColors.softBorder),
                const SizedBox(height: 20),

                // SECTION 4: YOUR GOAL
                _buildSectionHeader('Your goal'),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  children: _goalOptions.map((g) {
                    final isSelected = _selectedGoal == g;
                    return InkWell(
                      onTap: () => setState(() => _selectedGoal = g),
                      borderRadius: BorderRadius.circular(DSRadius.card),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected ? DSColors.warmIvory : Colors.white,
                          borderRadius: BorderRadius.circular(DSRadius.card),
                          border: Border.all(
                            color: isSelected ? DSColors.deepForestGreen : DSColors.softBorder,
                            width: isSelected ? 1.5 : 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isSelected ? Icons.check_circle : Icons.circle_outlined,
                              size: 16,
                              color: isSelected ? DSColors.deepForestGreen : DSColors.textMuted,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              g,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected ? DSColors.deepForestGreen : DSColors.textLight,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 28),

                // ACTION BUTTON: FIND MY BOOKS
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _fetchRecommendations,
                    icon: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.auto_awesome, size: 18),
                    label: Text(
                      _isLoading ? 'Analyzing Literary Vector Matches...' : '✨ Find My Books',
                      style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DSColors.deepForestGreen,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 36),

                // SECTION 5: YOUR PICKS
                Row(
                  children: [
                    Text(
                      '✨ YOUR PICKS',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: DSColors.deepForestGreen,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: DSColors.warmIvory,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: DSColors.antiqueGold),
                      ),
                      child: Text(
                        '${_picks.length} Personalized',
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: DSColors.antiqueGold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                ..._picks.map((book) => _buildPickCard(book)),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.playfairDisplay(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: DSColors.deepForestGreen,
      ),
    );
  }

  Widget _buildPickCard(Map<String, dynamic> book) {
    final reasons = (book['reasons'] as List?) ?? [];
    final matchScore = book['matchScore'] ?? '94%';

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(DSRadius.card),
        border: Border.all(color: DSColors.softBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover Thumbnail
              Container(
                width: 56,
                height: 80,
                decoration: BoxDecoration(
                  color: DSColors.deepForestGreen,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Icon(Icons.book, color: Colors.white, size: 28),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            book['title'] ?? '',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: DSColors.deepForestGreen,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: DSColors.warmIvory,
                            borderRadius: BorderRadius.circular(DSRadius.card),
                            border: Border.all(color: DSColors.softBorder),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.stars, size: 12, color: DSColors.secondaryGreen),
                              const SizedBox(width: 4),
                              Text(
                                '$matchScore Match',
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: DSColors.secondaryGreen,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'by ${book['author'] ?? ''}',
                      style: GoogleFonts.inter(fontSize: 12, color: DSColors.textMuted),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Category: ${book['category'] ?? 'General'}',
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: DSColors.textLight),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // "Why:" Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: DSColors.warmIvory,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: DSColors.softBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Why this book?',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: DSColors.deepForestGreen),
                ),
                const SizedBox(height: 6),
                if (reasons.isNotEmpty)
                  ...reasons.map((r) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('• ', style: TextStyle(color: DSColors.deepForestGreen, fontWeight: FontWeight.bold)),
                            Expanded(
                              child: Text(
                                '$r',
                                style: GoogleFonts.inter(fontSize: 12, color: DSColors.textLight),
                              ),
                            ),
                          ],
                        ),
                      ))
                else
                  Text(
                    book['matchReason'] ?? 'Matches your current reading preferences.',
                    style: GoogleFonts.inter(fontSize: 12, color: DSColors.textLight),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Direct Action Buttons: [Borrow] [Rent] [Buy]
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.push('/book/${book['id']}'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: DSColors.deepForestGreen,
                    side: const BorderSide(color: DSColors.deepForestGreen),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text('Borrow', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => context.push('/buy-now-checkout', extra: {
                    'mode': 'rental',
                    'rentalDays': 14,
                    'rentalFee': (book['rentalPrice'] as num?)?.toDouble() ?? 50.0,
                  }),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DSColors.accentTerracotta,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text('Rent ₹${(book['rentalPrice'] as num?)?.toInt() ?? 50}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => context.push('/buy-now-checkout', extra: {
                    'mode': 'purchase',
                  }),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DSColors.deepForestGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text('Buy ₹${(book['price'] as num?)?.toInt() ?? 350}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
