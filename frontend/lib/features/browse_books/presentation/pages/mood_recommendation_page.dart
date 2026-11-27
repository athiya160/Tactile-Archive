import '../../../../core/design_system/tokens/ds_colors.dart';
import '../../../../core/design_system/tokens/ds_radius.dart';
import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

/// Ambient reading soundscape definition
class Soundscape {
  final String id;
  final String title;
  final String subtitle;
  final String icon;
  final String assetPath;
  final String remoteUrl;

  const Soundscape({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.assetPath,
    required this.remoteUrl,
  });
}

const List<Soundscape> _kSoundscapes = [
  Soundscape(
    id: 'rain',
    title: 'Heavy Rain & Thunder',
    subtitle: 'Rainstorm & gentle ambient drops',
    icon: '🌧️',
    assetPath: 'audio/rain.mp3',
    remoteUrl: 'https://raw.githubusercontent.com/remvze/moodist/main/public/sounds/rain/heavy-rain.mp3',
  ),
  Soundscape(
    id: 'cafe',
    title: 'Cozy Coffee Shop',
    subtitle: 'Warm cafe chatter & espresso aroma',
    icon: '☕',
    assetPath: 'audio/cafe.mp3',
    remoteUrl: 'https://raw.githubusercontent.com/remvze/moodist/main/public/sounds/places/cafe.mp3',
  ),
  Soundscape(
    id: 'fireplace',
    title: 'Crackling Fireplace',
    subtitle: 'Warm hearth embers & cozy study',
    icon: '🔥',
    assetPath: 'audio/fireplace.mp3',
    remoteUrl: 'https://raw.githubusercontent.com/remvze/moodist/main/public/sounds/nature/campfire.mp3',
  ),
  Soundscape(
    id: 'library',
    title: 'Serene Classical Library',
    subtitle: 'Quiet halls & scholarly atmosphere',
    icon: '📚',
    assetPath: 'audio/library.mp3',
    remoteUrl: 'https://raw.githubusercontent.com/remvze/moodist/main/public/sounds/places/library.mp3',
  ),
];

/// Persistent in-memory session state for AI Recommendations & Mood Matcher
class MoodSessionState {
  static String? selectedAtmosphere;
  static String? primaryGoal;
  static String? selectedMood;
  static String? selectedTiming;
  static String? selectedFormat;
  static String? selectedLength;

  static bool hasDiscovered = false;
  static bool hasGeneratedPlan = false;
  static int currentRecommendationIndex = 0;
  static bool isCurrentBookAccepted = false;

  static int streakCount = 3;
  static int dailyPageTarget = 15;
  static Set<int> completedDays = {};
  static int soundscapeIndex = 0;

  static void reset() {
    selectedAtmosphere = null;
    primaryGoal = null;
    selectedMood = null;
    selectedTiming = null;
    selectedFormat = null;
    selectedLength = null;
    hasDiscovered = false;
    hasGeneratedPlan = false;
    currentRecommendationIndex = 0;
    isCurrentBookAccepted = false;
    streakCount = 3;
    dailyPageTarget = 15;
    completedDays.clear();
    soundscapeIndex = 0;
  }
}

class MoodRecommendationPage extends StatefulWidget {
  const MoodRecommendationPage({super.key});

  @override
  State<MoodRecommendationPage> createState() => _MoodRecommendationPageState();
}

class _MoodRecommendationPageState extends State<MoodRecommendationPage> {
  // Selections (Nullable: NOTHING selected by default on load)
  String? _selectedAtmosphere;
  String? _primaryGoal;
  String? _selectedMood;
  String? _selectedTiming;
  String? _selectedFormat;
  String? _selectedLength;

  // View state machine
  bool _hasDiscovered = false;      // True after clicking "Discover My Match"
  bool _hasGeneratedPlan = false;   // True after clicking "Generate Daily Reading Plan"
  int _currentRecommendationIndex = 0; // Active suggestion index (at least 3-4 suggestions per vibe)
  bool _isCurrentBookAccepted = false; // True when reader clicks right/check mark
  
  // Interactive Habit Tracker State
  int _streakCount = 3;
  int _dailyPageTarget = 15;
  final Set<int> _completedDays = {}; // Starts empty (no pre-checked days)

  // Ambient soundscape player state
  AudioPlayer? _audioPlayer;
  bool _isAudioPlaying = false;
  late Soundscape _selectedSoundscape;
  double _audioVolume = 0.7;
  int _sessionSecondsLeft = 900; // 15 minutes
  Timer? _sessionTimer;

  final List<Map<String, dynamic>> _atmosphereChips = [
    {'label': 'Rainy evening', 'icon': '🌧️'},
    {'label': 'Dark academia', 'icon': '🎓'},
    {'label': 'Cozy mystery', 'icon': '🔍'},
    {'label': 'Make me cry', 'icon': '💌'},
  ];

  final List<String> _goals = [
    'Career',
    'English',
    'AI Learning',
    'Exams',
    'Habit Building',
    'Relaxation',
  ];

  final List<String> _moods = [
    'Anxious',
    'Motivated',
    'Curious',
    'Tired',
    'Focused',
  ];

  final List<String> _timings = [
    '🌅 Morning Ritual',
    '☀️ Afternoon Focus',
    '🌙 Evening Wind-down',
    '✨ Night Owl',
  ];

  final List<String> _formats = [
    '📖 Physical Book',
    '📱 Digital / E-Book',
    '🎧 Audiobook',
    '🔄 Hybrid',
  ];

  final List<String> _lengths = [
    '⚡ Short (< 200 pgs)',
    '📖 Medium (200–350 pgs)',
    '📚 Deep / Long (350+ pgs)',
  ];

  void _restoreSessionState() {
    if (MoodSessionState.hasDiscovered ||
        MoodSessionState.selectedAtmosphere != null ||
        MoodSessionState.primaryGoal != null ||
        MoodSessionState.selectedMood != null) {
      _selectedAtmosphere = MoodSessionState.selectedAtmosphere;
      _primaryGoal = MoodSessionState.primaryGoal;
      _selectedMood = MoodSessionState.selectedMood;
      _selectedTiming = MoodSessionState.selectedTiming;
      _selectedFormat = MoodSessionState.selectedFormat;
      _selectedLength = MoodSessionState.selectedLength;
      _hasDiscovered = MoodSessionState.hasDiscovered;
      _hasGeneratedPlan = MoodSessionState.hasGeneratedPlan;
      _currentRecommendationIndex = MoodSessionState.currentRecommendationIndex;
      _isCurrentBookAccepted = MoodSessionState.isCurrentBookAccepted;
      _streakCount = MoodSessionState.streakCount;
      _dailyPageTarget = MoodSessionState.dailyPageTarget;
      _completedDays.clear();
      _completedDays.addAll(MoodSessionState.completedDays);
      _selectedSoundscape = _kSoundscapes[MoodSessionState.soundscapeIndex.clamp(0, _kSoundscapes.length - 1)];
    } else {
      _selectedSoundscape = _kSoundscapes[0]; // Rain by default
    }
  }

  void _saveSessionState() {
    MoodSessionState.selectedAtmosphere = _selectedAtmosphere;
    MoodSessionState.primaryGoal = _primaryGoal;
    MoodSessionState.selectedMood = _selectedMood;
    MoodSessionState.selectedTiming = _selectedTiming;
    MoodSessionState.selectedFormat = _selectedFormat;
    MoodSessionState.selectedLength = _selectedLength;
    MoodSessionState.hasDiscovered = _hasDiscovered;
    MoodSessionState.hasGeneratedPlan = _hasGeneratedPlan;
    MoodSessionState.currentRecommendationIndex = _currentRecommendationIndex;
    MoodSessionState.isCurrentBookAccepted = _isCurrentBookAccepted;
    MoodSessionState.streakCount = _streakCount;
    MoodSessionState.dailyPageTarget = _dailyPageTarget;
    MoodSessionState.completedDays = Set.from(_completedDays);
    final sIndex = _kSoundscapes.indexOf(_selectedSoundscape);
    MoodSessionState.soundscapeIndex = sIndex >= 0 ? sIndex : 0;
  }

  @override
  void initState() {
    super.initState();
    _restoreSessionState();
  }

  @override
  void dispose() {
    _saveSessionState();
    _sessionTimer?.cancel();
    _audioPlayer?.stop();
    _audioPlayer?.dispose();
    super.dispose();
  }

  Future<void> _playSelectedSoundscape() async {
    try {
      _audioPlayer ??= AudioPlayer();
      await _audioPlayer?.setReleaseMode(ReleaseMode.loop);
      await _audioPlayer?.setVolume(_audioVolume);

      // Try local asset first
      try {
        await _audioPlayer?.play(AssetSource(_selectedSoundscape.assetPath));
      } catch (assetErr) {
        debugPrint('Asset play fallback to URL: $assetErr');
        // Fallback to verified streaming remote URL
        await _audioPlayer?.play(UrlSource(_selectedSoundscape.remoteUrl));
      }
    } catch (e) {
      debugPrint('Audio play failed: $e');
    }
  }

  Future<void> _stopAudio() async {
    try {
      await _audioPlayer?.stop();
    } catch (e) {
      debugPrint('Audio stop error: $e');
    }
  }

  Future<void> _changeSoundscape(Soundscape soundscape) async {
    setState(() => _selectedSoundscape = soundscape);
    if (_isAudioPlaying) {
      await _stopAudio();
      await _playSelectedSoundscape();
    }
  }

  Future<void> _setVolume(double volume) async {
    setState(() => _audioVolume = volume);
    try {
      await _audioPlayer?.setVolume(volume);
    } catch (e) {
      debugPrint('Volume set error: $e');
    }
  }

  void _resetTimer() {
    _sessionTimer?.cancel();
    _stopAudio();
    setState(() {
      _isAudioPlaying = false;
      _sessionSecondsLeft = 900;
    });
  }

  void _toggleReadingTimer() {
    if (_isAudioPlaying) {
      _sessionTimer?.cancel();
      try {
        _audioPlayer?.pause();
      } catch (e) {
        debugPrint('Audio pause error: $e');
      }
      setState(() => _isAudioPlaying = false);
    } else {
      setState(() => _isAudioPlaying = true);
      _playSelectedSoundscape();

      _sessionTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (_sessionSecondsLeft > 0) {
          setState(() => _sessionSecondsLeft--);
        } else {
          t.cancel();
          _stopAudio();
          setState(() {
            _isAudioPlaying = false;
            _sessionSecondsLeft = 900;
          });
          _handleYesClicked();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('🎉 15-Minute Focus Reading Session completed! Great job! 📖✨'),
                backgroundColor: DSColors.deepForestGreen,
              ),
            );
          }
        }
      });
    }
  }

  // Sequential Yes Click -> Completes next available day in order
  void _handleYesClicked() {
    setState(() {
      final nextDay = _completedDays.isEmpty ? 1 : (_completedDays.reduce((a, b) => a > b ? a : b) + 1);
      if (nextDay <= 7) {
        _completedDays.add(nextDay);
        _streakCount++;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🎉 Day ${_completedDays.length} Completed! Streak updated to $_streakCount Days 🔥'),
        backgroundColor: DSColors.deepForestGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Sequential Not Yet Click -> Unchecks the LAST / LATEST completed day (not the first day!)
  void _handleNotYetClicked() {
    if (_completedDays.isEmpty) return;

    final lastDay = _completedDays.reduce((a, b) => a > b ? a : b);
    setState(() {
      _completedDays.remove(lastDay);
      if (_streakCount > 0) _streakCount--;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Day $lastDay status set to "Not Yet". Keep going! 💪'),
        backgroundColor: DSColors.textLight,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Sequential Day Toggle in Checklist
  void _handleDayChecklistToggled(int dayIndex) {
    setState(() {
      if (_completedDays.contains(dayIndex)) {
        // Uncheck this day and all subsequent days
        _completedDays.removeWhere((d) => d >= dayIndex);
      } else {
        // Check this day and all prior days
        for (int i = 1; i <= dayIndex; i++) {
          _completedDays.add(i);
        }
      }
    });
  }

  // Dynamic multi-book recommendation engine (at least 3-4 suggestions per vibe)
  List<Map<String, dynamic>> get _currentRecommendations {
    if (_selectedAtmosphere == 'Dark academia') {
      return [
        {
          'title': 'The Secret History',
          'author': 'Donna Tartt',
          'cover': 'https://images-na.ssl-images-amazon.com/images/I/71u96V2y55L.jpg',
          'matchScore': '98% Match',
          'rationale': "Selected for your 'Dark Academia' atmospheric vibe. This timeless tale of classics students in New England delves into obsession, intellect, and mystery.",
          'plan': [
            {'day': 'Day 1', 'title': 'Read Prologue and Chapter 1 (The Hampden College Classics Class).'},
            {'day': 'Day 2', 'title': 'Read Chapter 2 (Julian Morrow\'s Ancient Greek Seminars).'},
            {'day': 'Day 3', 'title': 'Read Chapter 3 (The Vermont Country House Excursion).'},
            {'day': 'Day 4', 'title': 'Read Chapter 4 (Dionysian Rites & Shadows).'},
            {'day': 'Day 5', 'title': 'Read Chapter 5 (Consequences and Cover-ups).'},
            {'day': 'Day 6', 'title': 'Read Chapters 6 & 7 (The Search in the Woods).'},
            {'day': 'Day 7', 'title': 'Read Epilogue (Reflections on Youth, Guilt & Fate).'},
          ],
        },
        {
          'title': 'If We Were Villains',
          'author': 'M.L. Rio',
          'cover': 'https://images-na.ssl-images-amazon.com/images/I/81xU9d4q4JL.jpg',
          'matchScore': '96% Match',
          'rationale': "Peak dark academia. Seven Shakespearean actors at an elite arts conservatory find the line between stage drama and real-life tragedy blurring into murder.",
          'plan': [
            {'day': 'Day 1', 'title': 'Read Act I (The Dellecher Classical Conservatory & Caesar auditions).'},
            {'day': 'Day 2', 'title': 'Read Act II (The Annual Fall Masquerade by the Lake).'},
            {'day': 'Day 3', 'title': 'Read Act III (Macbeth Rehearsals & Brewing Feuds).'},
            {'day': 'Day 4', 'title': 'Read Act IV (The Tragedy on the Dock & Police Inquiries).'},
            {'day': 'Day 5', 'title': 'Read Act V (Concealing Evidence & Guilt among Friends).'},
            {'day': 'Day 6', 'title': 'Read Act VI (Oliver\'s Sacrifice & The Final Performance).'},
            {'day': 'Day 7', 'title': 'Read Epilogue (Ten Years Later: The Confession Letter).'},
          ],
        },
        {
          'title': 'Babel: An Arcane History',
          'author': 'R.F. Kuang',
          'cover': 'https://images-na.ssl-images-amazon.com/images/I/81p5H1uJbEL.jpg',
          'matchScore': '95% Match',
          'rationale': "Set in 1830s Oxford, this dark academic masterpiece explores translation, language lost in translation, silver-working magic, and the high price of scholarship.",
          'plan': [
            {'day': 'Day 1', 'title': 'Read Book I (Robin Swift\'s Early Training & Journey to England).'},
            {'day': 'Day 2', 'title': 'Read Book II (The Royal Institute of Translation at Oxford).'},
            {'day': 'Day 3', 'title': 'Read Book III (Silver-working & The Hermes Society).'},
            {'day': 'Day 4', 'title': 'Read Book IV (The France Expedition & Hidden Imperial Agendas).'},
            {'day': 'Day 5', 'title': 'Read Book V (The Common Room Tragedy & Loyalties Tested).'},
            {'day': 'Day 6', 'title': 'Read Book VI (The Babel Tower Siege & Strike).'},
            {'day': 'Day 7', 'title': 'Read Epilogue (The Enduring Echo of Words).'},
          ],
        },
        {
          'title': 'Ninth House',
          'author': 'Leigh Bardugo',
          'cover': 'https://images-na.ssl-images-amazon.com/images/I/81e5bL8e2VL.jpg',
          'matchScore': '93% Match',
          'rationale': "A gritty dark academic occult thriller set inside Yale's secretive alumni societies, where ancient magic, ghosts, and dark power intertwine.",
          'plan': [
            {'day': 'Day 1', 'title': 'Read Chapters 1–5 (Alex Stern\'s Induction into Lethe House).'},
            {'day': 'Day 2', 'title': 'Read Chapters 6–11 (Darlington\'s Lessons & Campus Portals).'},
            {'day': 'Day 3', 'title': 'Read Chapters 12–18 (The Murder at Skull & Bones).'},
            {'day': 'Day 4', 'title': 'Read Chapters 19–25 (Darlington\'s Disappearance in the Mist).'},
            {'day': 'Day 5', 'title': 'Read Chapters 26–32 (Uncovering Illicit Magic in New Haven).'},
            {'day': 'Day 6', 'title': 'Read Chapters 33–38 (The Descent into the Underworld Catacombs).'},
            {'day': 'Day 7', 'title': 'Read Chapters 39–44 (Surviving the Ninth House & Standing Tall).'},
          ],
        },
      ];
    } else if (_selectedAtmosphere == 'Rainy evening') {
      return [
        {
          'title': 'The Shadow of the Wind',
          'author': 'Carlos Ruiz Zafón',
          'cover': 'https://images-na.ssl-images-amazon.com/images/I/81+mZqMvQfL.jpg',
          'matchScore': '97% Match',
          'rationale': "Perfect for a 'Rainy Evening'. Set in post-war Barcelona's Cemetery of Forgotten Books, this gothic mystery echoes with romance, rare manuscripts, and haunting intrigue.",
          'plan': [
            {'day': 'Day 1', 'title': 'Read The Cemetery of Forgotten Books & Julian Carax introduction.'},
            {'day': 'Day 2', 'title': 'Read Chapters 2 & 3 (The Bookshop on Calle Santa Ana).'},
            {'day': 'Day 3', 'title': 'Read Chapters 4 & 5 (Penelope Aldaya\'s Secret).'},
            {'day': 'Day 4', 'title': 'Read Chapters 6 & 7 (Laain Coubert\'s Shadows).'},
            {'day': 'Day 5', 'title': 'Read Chapters 8 & 9 (Fermin\'s Wisdom & Detective Fumero).'},
            {'day': 'Day 6', 'title': 'Read Chapters 10 & 11 (Uncovering the Carax Legacy).'},
            {'day': 'Day 7', 'title': 'Read Epilogue (The City of Shadows).'},
          ],
        },
        {
          'title': 'Norwegian Wood',
          'author': 'Haruki Murakami',
          'cover': 'https://images-na.ssl-images-amazon.com/images/I/817+n7o2wZL.jpg',
          'matchScore': '95% Match',
          'rationale': "A rainy-day masterwork of student nostalgia, melancholia, and quiet rain against Tokyo apartment windows, accompanied by acoustic music and quiet reflections.",
          'plan': [
            {'day': 'Day 1', 'title': 'Read Chapters 1 & 2 (The Meadow Memory & Toru\'s Arrival in Tokyo).'},
            {'day': 'Day 2', 'title': 'Read Chapters 3 & 4 (Sunday Walks Across Tokyo in Autumn Rain).'},
            {'day': 'Day 3', 'title': 'Read Chapter 5 (The Mountain Sanatorium & Reiko\'s Guitar).'},
            {'day': 'Day 4', 'title': 'Read Chapters 6 & 7 (Meeting Midori & Campus Solitude).'},
            {'day': 'Day 5', 'title': 'Read Chapters 8 & 9 (Letters to Kyoto & Winter Solitude).'},
            {'day': 'Day 6', 'title': 'Read Chapter 10 (Grief, Solitary Wandering, and Ocean Cliffs).'},
            {'day': 'Day 7', 'title': 'Read Chapter 11 (Reiko\'s Visit & Finding the Courage to Live).'},
          ],
        },
        {
          'title': 'The Thirteenth Tale',
          'author': 'Diane Setterfield',
          'cover': 'https://images-na.ssl-images-amazon.com/images/I/91r6bL8X7SL.jpg',
          'matchScore': '94% Match',
          'rationale': "A spellbinding gothic Yorkshire mystery for stormy nights. An eccentric recluse summons a biographer to record a family's dark, twin-haunted past.",
          'plan': [
            {'day': 'Day 1', 'title': 'Read Chapters 1–4 (The Letter from Vida Winter & Arrival at Angelfield).'},
            {'day': 'Day 2', 'title': 'Read Chapters 5–9 (The Wild Twins of Angelfield Estate).'},
            {'day': 'Day 3', 'title': 'Read Chapters 10–15 (Ghostly Encounters in the Grand Library).'},
            {'day': 'Day 4', 'title': 'Read Chapters 16–21 (The Governess & Unravelling Secrets).'},
            {'day': 'Day 5', 'title': 'Read Chapters 22–26 (The Fire, The Ruins, and The Lost Child).'},
            {'day': 'Day 6', 'title': 'Read Chapters 27–31 (Piecing Together the Medical Records).'},
            {'day': 'Day 7', 'title': 'Read Chapters 32–37 (The Thirteenth Tale Revealed).'},
          ],
        },
        {
          'title': 'Kafka on the Shore',
          'author': 'Haruki Murakami',
          'cover': 'https://images-na.ssl-images-amazon.com/images/I/71u96V2y55L.jpg',
          'matchScore': '93% Match',
          'rationale': "Surreal rainy atmosphere filled with talking cats, showers of fish from storm clouds, and a peaceful sanctuary inside a quiet seaside library.",
          'plan': [
            {'day': 'Day 1', 'title': 'Read Chapters 1–6 (The Boy Named Crow & Escape from Tokyo).'},
            {'day': 'Day 2', 'title': 'Read Chapters 7–12 (Shelter in the Komura Memorial Library).'},
            {'day': 'Day 3', 'title': 'Read Chapters 13–18 (Nakata\'s Strange Calling & The Rain of Fish).'},
            {'day': 'Day 4', 'title': 'Read Chapters 19–26 (The Painting in Miss Saeki\'s Room).'},
            {'day': 'Day 5', 'title': 'Read Chapters 27–34 (The Mountain Cabin in the Deep Forest).'},
            {'day': 'Day 6', 'title': 'Read Chapters 35–42 (The Entrance Stone & Liminal Gateways).'},
            {'day': 'Day 7', 'title': 'Read Chapters 43–49 (Waking up to a Renewed Life).'},
          ],
        },
      ];
    } else if (_selectedAtmosphere == 'Cozy mystery') {
      return [
        {
          'title': 'The Thursday Murder Club',
          'author': 'Richard Osman',
          'cover': 'https://images-na.ssl-images-amazon.com/images/I/81hU2A0gECL.jpg',
          'matchScore': '96% Match',
          'rationale': "Tailored for your 'Cozy Mystery' vibe. Four clever retirees in a peaceful retirement village investigate unsolved cold cases with wit, tea, and brilliant deduction.",
          'plan': [
            {'day': 'Day 1', 'title': 'Read Chapters 1–5 (Introducing Elizabeth, Joyce, Ibrahim & Ron).'},
            {'day': 'Day 2', 'title': 'Read Chapters 6–10 (The Coopers Chase Development Dispute).'},
            {'day': 'Day 3', 'title': 'Read Chapters 11–15 (Tony Curran\'s Murder Investigation).'},
            {'day': 'Day 4', 'title': 'Read Chapters 16–20 (Inspector Donna De Freitas joins forces).'},
            {'day': 'Day 5', 'title': 'Read Chapters 21–25 (The Unmarked Grave on the Hill).'},
            {'day': 'Day 6', 'title': 'Read Chapters 26–30 (Piecing together the clues).'},
            {'day': 'Day 7', 'title': 'Read Conclusion & Afterword (Celebrating friendship & justice).'},
          ],
        },
        {
          'title': 'The Maid',
          'author': 'Nita Prose',
          'cover': 'https://images-na.ssl-images-amazon.com/images/I/81dG74vW6LL.jpg',
          'matchScore': '95% Match',
          'rationale': "Delightful and cozy. Molly the hotel maid's orderly life is upended when she discovers an eccentric guest deceased, prompting her to solve the mystery with keen observation.",
          'plan': [
            {'day': 'Day 1', 'title': 'Read Chapters 1–4 (A Grand Day at The Regency Grand Hotel).'},
            {'day': 'Day 2', 'title': 'Read Chapters 5–9 (Discovering Mr. Black in the Penthouse Suite).'},
            {'day': 'Day 3', 'title': 'Read Chapters 10–14 (Interrogations by Detective Stark).'},
            {'day': 'Day 4', 'title': 'Read Chapters 15–19 (Molly\'s Grandmother\'s Rules & Wisdom).'},
            {'day': 'Day 5', 'title': 'Read Chapters 20–25 (An Unexpected Betrayal & The Jail Cell).'},
            {'day': 'Day 6', 'title': 'Read Chapters 26–31 (Unlikely Friends Rally to Molly\'s Defense).'},
            {'day': 'Day 7', 'title': 'Read Chapters 32–36 (The True Culprit Revealed & A Clean Slate).'},
          ],
        },
        {
          'title': 'A Spoonful of Murder',
          'author': 'J.M. Hall',
          'cover': 'https://images-na.ssl-images-amazon.com/images/I/81yZ51Z9q7L.jpg',
          'matchScore': '93% Match',
          'rationale': "Charming British cozy mystery. Three retired primary school teachers meet weekly for tea and cake, only to discover a former colleague's death was far from natural.",
          'plan': [
            {'day': 'Day 1', 'title': 'Read Chapters 1–3 (Tuesday Tea & Meeting Trixie).'},
            {'day': 'Day 2', 'title': 'Read Chapters 4–8 (The Sudden Passing of their Former Colleague).'},
            {'day': 'Day 3', 'title': 'Read Chapters 9–13 (Investigating the Nursing Home Records).'},
            {'day': 'Day 4', 'title': 'Read Chapters 14–18 (Clues in the Craft Fair & Village Gossip).'},
            {'day': 'Day 5', 'title': 'Read Chapters 19–23 (A Second Suspicious Incident in Town).'},
            {'day': 'Day 6', 'title': 'Read Chapters 24–28 (Connecting the Will and the Medications).'},
            {'day': 'Day 7', 'title': 'Read Chapters 29–33 (Confronting the Villain over Fresh Scones).'},
          ],
        },
        {
          'title': 'Finlay Donovan Is Killing It',
          'author': 'Elle Cosimano',
          'cover': 'https://images-na.ssl-images-amazon.com/images/I/81h9iK1k0wL.jpg',
          'matchScore': '92% Match',
          'rationale': "Fast-paced, witty, and hilarious cozy caper. A stressed single mom and mystery author is accidentally mistaken for a contract killer in Panera Bread.",
          'plan': [
            {'day': 'Day 1', 'title': 'Read Chapters 1–4 (Panera Bread Meeting Gone Wildly Wrong).'},
            {'day': 'Day 2', 'title': 'Read Chapters 5–9 (The Enormous Cash Advance & Panic).'},
            {'day': 'Day 3', 'title': 'Read Chapters 10–14 (Vero the Nanny Becomes Partner-in-Crime).'},
            {'day': 'Day 4', 'title': 'Read Chapters 15–20 (The Mob Encounter and The Minivan).'},
            {'day': 'Day 5', 'title': 'Read Chapters 21–26 (Undercover at the Charity Gala).'},
            {'day': 'Day 6', 'title': 'Read Chapters 27–32 (Officer Nick\'s Growing Suspicions).'},
            {'day': 'Day 7', 'title': 'Read Chapters 33–38 (Saving the Day and Finishing the Manuscript).'},
          ],
        },
      ];
    } else if (_selectedAtmosphere == 'Make me cry') {
      return [
        {
          'title': 'Normal People',
          'author': 'Sally Rooney',
          'cover': 'https://images-na.ssl-images-amazon.com/images/I/71Y-aKkL9uL.jpg',
          'matchScore': '95% Match',
          'rationale': "Picked for 'Make me cry'. A deeply moving, poignant exploration of intimacy, vulnerability, and complex emotional bonds between Connell and Marianne over the years.",
          'plan': [
            {'day': 'Day 1', 'title': 'Read Years 2011 & 2012 (High School in Carricklea).'},
            {'day': 'Day 2', 'title': 'Read Year 2012 (Trinity College Dublin Days).'},
            {'day': 'Day 3', 'title': 'Read Year 2013 (Summer in Italy).'},
            {'day': 'Day 4', 'title': 'Read Year 2014 (Undergraduate Life & Misunderstandings).'},
            {'day': 'Day 5', 'title': 'Read Year 2014 (Winter in Sweden).'},
            {'day': 'Day 6', 'title': 'Read Year 2015 (Final Semester & New Horizons).'},
            {'day': 'Day 7', 'title': 'Read Epilogue (Understanding Love & Growth).'},
          ],
        },
        {
          'title': 'A Little Life',
          'author': 'Hanya Yanagihara',
          'cover': 'https://images-na.ssl-images-amazon.com/images/I/81h29QvI2WL.jpg',
          'matchScore': '96% Match',
          'rationale': "An intensely moving, emotionally devastating tour de force exploring deep friendship, trauma, and unconditional devotion across decades.",
          'plan': [
            {'day': 'Day 1', 'title': 'Read Part 1: Lispenard Street (Four College Friends in NYC).'},
            {'day': 'Day 2', 'title': 'Read Part 2: The Postman (Jude\'s Early Trials & Harold\'s Kindness).'},
            {'day': 'Day 3', 'title': 'Read Part 3: Vanities (Willem\'s Stardom & Jude\'s Vulnerability).'},
            {'day': 'Day 4', 'title': 'Read Part 4: The Axiom of Equality (Finding Family in Harold & Julia).'},
            {'day': 'Day 5', 'title': 'Read Part 5: The Happy Years (Country House Days with Willem).'},
            {'day': 'Day 6', 'title': 'Read Part 6: Dear Comrade (Facing Life\'s Deepest Sorrows).'},
            {'day': 'Day 7', 'title': 'Read Part 7: Lispenard Street (Harold\'s Reflections on Love & Memory).'},
          ],
        },
        {
          'title': 'The Kite Runner',
          'author': 'Khaled Hosseini',
          'cover': 'https://images-na.ssl-images-amazon.com/images/I/81IzbD2n4+L.jpg',
          'matchScore': '97% Match',
          'rationale': "A poignant, heart-wrenching Afghan epic of boyhood camaraderie, regret, and the timeless, tear-filled journey 'to be good again'.",
          'plan': [
            {'day': 'Day 1', 'title': 'Read Chapters 1–4 (Kabul in the 1970s: Amir and Hassan).'},
            {'day': 'Day 2', 'title': 'Read Chapters 5–7 (The Winter Kite Tournament & The Alley).'},
            {'day': 'Day 3', 'title': 'Read Chapters 8–10 (Guilt, Separation & Escape to America).'},
            {'day': 'Day 4', 'title': 'Read Chapters 11–14 (Flea Markets in Fremont & Meeting Soraya).'},
            {'day': 'Day 5', 'title': 'Read Chapters 15–18 (Rahim Khan\'s Call: A Way to Be Good Again).'},
            {'day': 'Day 6', 'title': 'Read Chapters 19–23 (Return to Kabul & Rescuing Sohrab).'},
            {'day': 'Day 7', 'title': 'Read Chapters 24–25 (Flying Kites in California: For You a Thousand Times Over).'},
          ],
        },
        {
          'title': 'When Breath Becomes Air',
          'author': 'Paul Kalanithi',
          'cover': 'https://images-na.ssl-images-amazon.com/images/I/71fx90Qp6QL.jpg',
          'matchScore': '98% Match',
          'rationale': "A deeply moving memoir of a 36-year-old neurosurgeon confronting terminal illness, exploring what makes life meaningful in the face of death.",
          'plan': [
            {'day': 'Day 1', 'title': 'Read Foreword and Prologue (From Doctor to Patient).'},
            {'day': 'Day 2', 'title': 'Read Part I: In Perfect Health I Begin (Literature & Medicine).'},
            {'day': 'Day 3', 'title': 'Read Part I: The Long Hours of Surgical Residency.'},
            {'day': 'Day 4', 'title': 'Read Part II: Cease Not till Death (The Diagnosis).'},
            {'day': 'Day 5', 'title': 'Read Part II: Welcoming Baby Cady & Legacy of Love).'},
            {'day': 'Day 6', 'title': 'Read Part II: The Final Clinical Days & Embracing Mortality.'},
            {'day': 'Day 7', 'title': 'Read Epilogue by Lucy Kalanithi (Enduring Grace & Memory).'},
          ],
        },
      ];
    } else if (_primaryGoal == 'AI Learning') {
      return [
        {
          'title': 'Life 3.0: Being Human in the Age of AI',
          'author': 'Max Tegmark',
          'cover': 'https://images-na.ssl-images-amazon.com/images/I/71QKQ9mwV7L.jpg',
          'matchScore': '98% Match',
          'rationale': "Selected for your 'AI Learning' goal. MIT physicist Max Tegmark explores artificial intelligence, future civilizations, and humanity's trajectory with superhuman intelligence.",
          'plan': [
            {'day': 'Day 1', 'title': 'Read Prelude (The Tale of the Omega Team) & Chapter 1 (Our Technology Journey).'},
            {'day': 'Day 2', 'title': 'Read Chapter 2 (Matter to Life: Hardware, Software & Evolution).'},
            {'day': 'Day 3', 'title': 'Read Chapter 3 (The Near Future: Breakthroughs, Bugs & Laws).'},
            {'day': 'Day 4', 'title': 'Read Chapter 4 (Intelligence Explosion & The Singularity).'},
            {'day': 'Day 5', 'title': 'Read Chapter 5 (Aftermath: 10,000 Years Later Scenarios).'},
            {'day': 'Day 6', 'title': 'Read Chapter 6 (Cosmic Endowment: What is Consciousness?).'},
            {'day': 'Day 7', 'title': 'Read Chapter 7 & Epilogue (Steering the Future of AGI).'},
          ],
        },
        {
          'title': 'Co-Intelligence: Living and Working with AI',
          'author': 'Ethan Mollick',
          'cover': 'https://images-na.ssl-images-amazon.com/images/I/81wgcld4wxL.jpg',
          'matchScore': '96% Match',
          'rationale': "Wharton professor Ethan Mollick's definitive guide on collaborating with LLMs in business, education, and creative problem solving.",
          'plan': [
            {'day': 'Day 1', 'title': 'Read Introduction: Aligning with the New Synthetic Mind.'},
            {'day': 'Day 2', 'title': 'Read Four Principles for Working with AI (Always Invite AI to the Table).'},
            {'day': 'Day 3', 'title': 'Read Co-Intelligence in Education & High-Velocity Learning.'},
            {'day': 'Day 4', 'title': 'Read The AI as Tutor and Coach: Accelerating Deep Understanding.'},
            {'day': 'Day 5', 'title': 'Read The AI as Creative Partner: Brainstorming & Iteration.'},
            {'day': 'Day 6', 'title': 'Read Ethical Horizons, Biases & Hallucination Guardrails.'},
            {'day': 'Day 7', 'title': 'Read The Future of Augmented Human Potential.'},
          ],
        },
        {
          'title': 'The Coming Wave',
          'author': 'Mustafa Suleyman',
          'cover': 'https://images-na.ssl-images-amazon.com/images/I/81p5H1uJbEL.jpg',
          'matchScore': '95% Match',
          'rationale': "DeepMind co-founder Mustafa Suleyman explains how AI and synthetic biology will reshape geopolitics, industry, and daily existence over the next decade.",
          'plan': [
            {'day': 'Day 1', 'title': 'Read Part 1: The Wave Arrives (The Unprecedented Accelerant).'},
            {'day': 'Day 2', 'title': 'Read Part 2: Foundations of Modern AI (Deep Learning Breakthroughs).'},
            {'day': 'Day 3', 'title': 'Read Part 2: The Next Horizon (Autonomous Agents & Reasoning).'},
            {'day': 'Day 4', 'title': 'Read Part 3: The Containment Dilemma (Governance and Safety).'},
            {'day': 'Day 5', 'title': 'Read Part 3: National Security and Open Source Ecosystems.'},
            {'day': 'Day 6', 'title': 'Read Part 4: Ten Steps to Human-Centric Technology Control.'},
            {'day': 'Day 7', 'title': 'Read Conclusion: Forging a Safe Technological Future.'},
          ],
        },
        {
          'title': 'Superintelligence: Paths, Dangers, Strategies',
          'author': 'Nick Bostrom',
          'cover': 'https://images-na.ssl-images-amazon.com/images/I/81xU9d4q4JL.jpg',
          'matchScore': '94% Match',
          'rationale': "Oxford philosopher Nick Bostrom's seminal work investigating what happens when machines surpass biological brains in general intelligence.",
          'plan': [
            {'day': 'Day 1', 'title': 'Read Chapter 1: Past Developments and Present Capabilities.'},
            {'day': 'Day 2', 'title': 'Read Chapters 2 & 3: Paths to Superintelligence & Forms of Superintelligence.'},
            {'day': 'Day 3', 'title': 'Read Chapters 4 & 5: The Kinetics of an Intelligence Explosion.'},
            {'day': 'Day 4', 'title': 'Read Chapters 7 & 8: The Superintelligent Will & Orthogonality Thesis.'},
            {'day': 'Day 5', 'title': 'Read Chapters 9 & 10: The Control Problem (Capability vs Value Loading).'},
            {'day': 'Day 6', 'title': 'Read Chapters 11 & 12: Multipolar Scenarios & Strategic Prospects.'},
            {'day': 'Day 7', 'title': 'Read Chapters 14 & 15: The Crushing of the Shallows & Way Forward.'},
          ],
        },
      ];
    } else if (_primaryGoal == 'Exams' || _primaryGoal == 'Career') {
      return [
        {
          'title': 'Deep Work',
          'author': 'Cal Newport',
          'cover': 'https://images-na.ssl-images-amazon.com/images/I/71QKQ9mwV7L.jpg',
          'matchScore': '98% Match',
          'rationale': "Essential for '${_primaryGoal ?? 'Exams'}' goals. Rules for focused success in a distracted world, helping you master complex information faster.",
          'plan': [
            {'day': 'Day 1', 'title': 'Read Deep Work is Valuable & Rare.'},
            {'day': 'Day 2', 'title': 'Read Rule #1: Work Deeply (Routines & Rituals).'},
            {'day': 'Day 3', 'title': 'Read Rule #2: Embrace Boredom (Mind Training).'},
            {'day': 'Day 4', 'title': 'Read Rule #3: Quit Social Media (Network Tools).'},
            {'day': 'Day 5', 'title': 'Read Rule #4: Drain the Shallows (Time Audits).'},
            {'day': 'Day 6', 'title': 'Read Practical Applications for Study & Work.'},
            {'day': 'Day 7', 'title': 'Read Conclusion & 30-Day Execution Roadmap.'},
          ],
        },
        {
          'title': 'Make It Stick',
          'author': 'Peter C. Brown',
          'cover': 'https://images-na.ssl-images-amazon.com/images/I/81hU2A0gECL.jpg',
          'matchScore': '96% Match',
          'rationale': "The science of successful learning. Concrete strategies like spaced retrieval and interleaving that turn study hours into long-term mastery.",
          'plan': [
            {'day': 'Day 1', 'title': 'Read Chapter 1: Learning is Misunderstood.'},
            {'day': 'Day 2', 'title': 'Read Chapter 2: To Learn, Retrieve (Testing Effect).'},
            {'day': 'Day 3', 'title': 'Read Chapter 3: Mix Up Your Practice (Interleaving).'},
            {'day': 'Day 4', 'title': 'Read Chapter 4: Embrace Difficulties (Desirable Struggles).'},
            {'day': 'Day 5', 'title': 'Read Chapter 5: Avoid Illusions of Knowing.'},
            {'day': 'Day 6', 'title': 'Read Chapter 6: Get Beyond Learning Styles.'},
            {'day': 'Day 7', 'title': 'Read Chapters 7 & 8: Make It Stick for Lifelong Study.'},
          ],
        },
        {
          'title': 'Ultralearning',
          'author': 'Scott H. Young',
          'cover': 'https://images-na.ssl-images-amazon.com/images/I/81wgcld4wxL.jpg',
          'matchScore': '95% Match',
          'rationale': "Master hard skills, outsmart the competition, and accelerate your career through self-directed, high-intensity learning projects.",
          'plan': [
            {'day': 'Day 1', 'title': 'Read Chapters 1 & 2: Can You Get an MIT Education Without Going?.'},
            {'day': 'Day 2', 'title': 'Read Principle 1: Metalearning (First Draw a Map).'},
            {'day': 'Day 3', 'title': 'Read Principle 2: Focus (Carve Out Time & Beat Procrastination).'},
            {'day': 'Day 4', 'title': 'Read Principle 3: Directness (Go Straight to the Source).'},
            {'day': 'Day 5', 'title': 'Read Principle 4 & 5: Drill and Retrieval Practice.'},
            {'day': 'Day 6', 'title': 'Read Principle 6 & 7: Feedback & Retention Systems.'},
            {'day': 'Day 7', 'title': 'Read Principles 8 & 9: Intuition, Experimentation & Your First Project.'},
          ],
        },
      ];
    } else if (_primaryGoal == 'English' || _primaryGoal == 'Relaxation') {
      return [
        {
          'title': 'To Kill a Mockingbird',
          'author': 'Harper Lee',
          'cover': 'https://images-na.ssl-images-amazon.com/images/I/71FxgtFKcQL.jpg',
          'matchScore': '97% Match',
          'rationale': "Chosen for your '${_primaryGoal ?? 'English'}' goal. A timeless literary classic examining empathy, justice, and human warmth through Scout's eyes.",
          'plan': [
            {'day': 'Day 1', 'title': 'Read Chapters 1–3 (Scout, Jem, and Dill in Maycomb).'},
            {'day': 'Day 2', 'title': 'Read Chapters 4–7 (The Boo Radley Knothole Treasures).'},
            {'day': 'Day 3', 'title': 'Read Chapters 8–11 (Atticus Finch & Mrs. Dubose).'},
            {'day': 'Day 4', 'title': 'Read Chapters 12–15 (First Purchase Church & The Jailhouse).'},
            {'day': 'Day 5', 'title': 'Read Chapters 16–20 (The Trial of Tom Robinson).'},
            {'day': 'Day 6', 'title': 'Read Chapters 21–25 (Atticus\'s Summation & Aftermath).'},
            {'day': 'Day 7', 'title': 'Read Chapters 26–31 (The Halloween Pageant & Boo\'s Reveal).'},
          ],
        },
        {
          'title': 'Pride and Prejudice',
          'author': 'Jane Austen',
          'cover': 'https://images-na.ssl-images-amazon.com/images/I/81xU9d4q4JL.jpg',
          'matchScore': '96% Match',
          'rationale': "The pinnacle of witty English prose and romantic social satire, exploring Elizabeth Bennet's spirited banter and Darcy's evolving warmth.",
          'plan': [
            {'day': 'Day 1', 'title': 'Read Chapters 1–7 (The Meryton Assembly & Netherfield Hall).'},
            {'day': 'Day 2', 'title': 'Read Chapters 8–17 (Jane\'s Illness & Mr. Collins Arrives).'},
            {'day': 'Day 3', 'title': 'Read Chapters 18–26 (The Netherfield Ball & Wickham\'s Story).'},
            {'day': 'Day 4', 'title': 'Read Chapters 27–38 (Visiting Hunsford & Darcy\'s Proposal).'},
            {'day': 'Day 5', 'title': 'Read Chapters 39–45 (Darcy\'s Explanatory Letter & Pemberley Visit).'},
            {'day': 'Day 6', 'title': 'Read Chapters 46–55 (Lydia\'s Elopement & The Hidden Benefactor).'},
            {'day': 'Day 7', 'title': 'Read Chapters 56–61 (Lady Catherine\'s Visit & Happily Ever After).'},
          ],
        },
        {
          'title': 'The Great Gatsby',
          'author': 'F. Scott Fitzgerald',
          'cover': 'https://images-na.ssl-images-amazon.com/images/I/71QKQ9mwV7L.jpg',
          'matchScore': '95% Match',
          'rationale': "Lyrical, crystalline 1920s jazz-age prose following mysterious millionaire Jay Gatsby and the green light across the Long Island bay.",
          'plan': [
            {'day': 'Day 1', 'title': 'Read Chapter 1 (Nick Carraway Arrives in West Egg).'},
            {'day': 'Day 2', 'title': 'Read Chapter 2 (The Valley of Ashes & The Eyes of Dr. Eckleburg).'},
            {'day': 'Day 3', 'title': 'Read Chapter 3 (Gatsby\'s Extravagant Midnight Party).'},
            {'day': 'Day 4', 'title': 'Read Chapters 4 & 5 (The Tea Party & Reunion with Daisy).'},
            {'day': 'Day 5', 'title': 'Read Chapter 6 (The Origins of James Gatz).'},
            {'day': 'Day 6', 'title': 'Read Chapter 7 (The Plaza Hotel Confrontation in Summer Heat).'},
            {'day': 'Day 7', 'title': 'Read Chapters 8 & 9 (The Pool, The Funeral & So We Beat On).'},
          ],
        },
      ];
    } else if (_selectedMood == 'Anxious' || _selectedMood == 'Tired') {
      return [
        {
          'title': 'The Midnight Library',
          'author': 'Matt Haig',
          'cover': 'https://images-na.ssl-images-amazon.com/images/I/81J6APjwHQL.jpg',
          'matchScore': '96% Match',
          'rationale': "Comforting pick for when you feel '${_selectedMood ?? 'Tired'}'. Somewhere out beyond the edge of the universe lies a library that offers a second chance at living.",
          'plan': [
            {'day': 'Day 1', 'title': 'Read A Conversation About Rain & The Midnight Library.'},
            {'day': 'Day 2', 'title': 'Read The Book of Regrets & The First Parallel Life.'},
            {'day': 'Day 3', 'title': 'Read The Glaciologist Life in Svalbard.'},
            {'day': 'Day 4', 'title': 'Read The Rock Star Life in South America.'},
            {'day': 'Day 5', 'title': 'Read The Country Life & Hugo\'s Wisdom.'},
            {'day': 'Day 6', 'title': 'Read The Perfect Life & The Fire in the Library.'},
            {'day': 'Day 7', 'title': 'Read The Only Way to Learn is to Live.'},
          ],
        },
        {
          'title': 'A Psalm for the Wild-Built',
          'author': 'Becky Chambers',
          'cover': 'https://images-na.ssl-images-amazon.com/images/I/81+mZqMvQfL.jpg',
          'matchScore': '97% Match',
          'rationale': "A warm, soul-soothing solarpunk comfort read. A traveling tea monk and an inquisitive wild robot wander the peaceful forests asking what humans truly need.",
          'plan': [
            {'day': 'Day 1', 'title': 'Read Chapters 1 & 2 (Dex Leaves the Monastery to Brew Tea).'},
            {'day': 'Day 2', 'title': 'Read Chapters 3 & 4 (The Village Visits & Custom Tea Blends).'},
            {'day': 'Day 3', 'title': 'Read Chapters 5 & 6 (The Call of the Wild Forest Trail).'},
            {'day': 'Day 4', 'title': 'Read Chapters 7 & 8 (Meeting Mosscap the Robot).'},
            {'day': 'Day 5', 'title': 'Read Chapters 9 & 10 (Conversations Around the Campfire).'},
            {'day': 'Day 6', 'title': 'Read Chapters 11 & 12 (Sharing Fears and Purpose).'},
            {'day': 'Day 7', 'title': 'Read Chapters 13 & 14 (Resting in the Sunlight & Inner Peace).'},
          ],
        },
        {
          'title': 'The House in the Cerulean Sea',
          'author': 'TJ Klune',
          'cover': 'https://images-na.ssl-images-amazon.com/images/I/81hU2A0gECL.jpg',
          'matchScore': '98% Match',
          'rationale': "Like being wrapped in a warm knitted blanket. A quiet caseworker travels to an eccentric coastal orphanage and discovers family in the most unexpected place.",
          'plan': [
            {'day': 'Day 1', 'title': 'Read Chapters 1–3 (Linus Baker\'s Grey Office Routine in DICOMY).'},
            {'day': 'Day 2', 'title': 'Read Chapters 4–6 (The Secret Classified Assignment).'},
            {'day': 'Day 3', 'title': 'Read Chapters 7–9 (Arrival at the Sunlit Marsyas Island).'},
            {'day': 'Day 4', 'title': 'Read Chapters 10–12 (Arthur Parnassus & The Extraordinary Youths).'},
            {'day': 'Day 5', 'title': 'Read Chapters 13–15 (Field Trip to Town & Standing Together).'},
            {'day': 'Day 6', 'title': 'Read Chapters 16–17 (The Report to Extremely Upper Management).'},
            {'day': 'Day 7', 'title': 'Read Chapters 18–19 (Choosing Happiness & Returning Home).'},
          ],
        },
      ];
    }

    // Default match for AI Learning / Habit Building / Focused
    return [
      {
        'title': 'Atomic Habits',
        'author': 'James Clear',
        'cover': 'https://images-na.ssl-images-amazon.com/images/I/81wgcld4wxL.jpg',
        'matchScore': '95% Match',
        'rationale': "Based on your preferences, this book provides actionable strategies to build good habits and break bad ones, perfect for your schedule.",
        'plan': [
          {'day': 'Day 1', 'title': 'Read the Introduction and Chapter 1 (The Surprising Power of Atomic Habits).'},
          {'day': 'Day 2', 'title': 'Read Chapters 2 and 3 (How Your Habits Shape Your Identity).'},
          {'day': 'Day 3', 'title': 'Read Chapters 4 and 5 (The 1st Law: Make It Obvious).'},
          {'day': 'Day 4', 'title': 'Read Chapters 6 and 7 (The Environment is the Invisible Hand).'},
          {'day': 'Day 5', 'title': 'Read Chapters 8 and 9 (How to Make a Habit Irresistible).'},
          {'day': 'Day 6', 'title': 'Read Chapters 10 and 11 (The Role of Family and Friends).'},
          {'day': 'Day 7', 'title': 'Read Chapters 12–14 (Advanced Tactics to Keep Going).'},
        ],
      },
      {
        'title': 'Tiny Habits',
        'author': 'BJ Fogg',
        'cover': 'https://images-na.ssl-images-amazon.com/images/I/71u96V2y55L.jpg',
        'matchScore': '94% Match',
        'rationale': "Stanford behavior scientist BJ Fogg demonstrates how tiny behavioral anchors create life-changing transformations effortlessly without willpower fatigue.",
        'plan': [
          {'day': 'Day 1', 'title': 'Read Introduction: The Anatomy of Tiny Habits.'},
          {'day': 'Day 2', 'title': 'Read Chapter 1: The Fogg Behavior Model (B=MAP).'},
          {'day': 'Day 3', 'title': 'Read Chapter 2: Motivation & Ability (Keep It Super Simple).'},
          {'day': 'Day 4', 'title': 'Read Chapter 3: Prompts & Anchors (The Matchmaker Game).'},
          {'day': 'Day 5', 'title': 'Read Chapter 4: Emotions Create Habits (The Shine Technique).'},
          {'day': 'Day 6', 'title': 'Read Chapter 5: Untangling Bad Habits.'},
          {'day': 'Day 7', 'title': 'Read Chapters 6 & 7: From Tiny to Transformative.'},
        ],
      },
      {
        'title': 'The Power of Habit',
        'author': 'Charles Duhigg',
        'cover': 'https://images-na.ssl-images-amazon.com/images/I/81xU9d4q4JL.jpg',
        'matchScore': '93% Match',
        'rationale': "Fascinating neurological exploration of the Habit Loop (Cue, Routine, Reward) and how individuals and organizations rewire automatic behaviors.",
        'plan': [
          {'day': 'Day 1', 'title': 'Read Part 1: The Habit Loop (How Habits Work in the Brain).'},
          {'day': 'Day 2', 'title': 'Read Part 1: The Craving Brain (Creating New Habits).'},
          {'day': 'Day 3', 'title': 'Read Part 1: The Golden Rule of Habit Change (Why Transformation Occurs).'},
          {'day': 'Day 4', 'title': 'Read Part 2: Keystone Habits (Paul O\'Neill and Alcoa).'},
          {'day': 'Day 5', 'title': 'Read Part 2: Starbucks and the Habit of Willpower.'},
          {'day': 'Day 6', 'title': 'Read Part 3: How Target Knows What You Want Before You Do.'},
          {'day': 'Day 7', 'title': 'Read Appendix: A Reader\'s Guide to Manipulating Habits.'},
        ],
      },
    ];
  }

  Map<String, dynamic> get _currentMatch {
    final recs = _currentRecommendations;
    if (recs.isEmpty) {
      return {
        'title': 'The Shadow of the Wind',
        'author': 'Carlos Ruiz Zafón',
        'cover': 'https://images-na.ssl-images-amazon.com/images/I/81+mZqMvQfL.jpg',
        'matchScore': '97% Match',
        'rationale': "Perfect for a 'Rainy Evening'. Set in post-war Barcelona's Cemetery of Forgotten Books.",
        'plan': [],
      };
    }
    return recs[_currentRecommendationIndex % recs.length];
  }

  // Apply smart presets to "Design Your Reading Journey" based on chosen atmosphere vibe
  void _applyAtmospherePreset(String label) {
    if (label == 'Rainy evening') {
      _primaryGoal = 'Relaxation';
      _selectedMood = 'Curious';
      _selectedTiming = '🌙 Evening Wind-down';
      _selectedFormat = '📖 Physical Book';
      _selectedLength = '📖 Medium (200–350 pgs)';
      _selectedSoundscape = _kSoundscapes[0]; // Rain & Thunder
    } else if (label == 'Dark academia') {
      _primaryGoal = 'AI Learning';
      _selectedMood = 'Focused';
      _selectedTiming = '✨ Night Owl';
      _selectedFormat = '📖 Physical Book';
      _selectedLength = '📚 Deep / Long (350+ pgs)';
      _selectedSoundscape = _kSoundscapes[2]; // Fireplace
    } else if (label == 'Cozy mystery') {
      _primaryGoal = 'English';
      _selectedMood = 'Curious';
      _selectedTiming = '☀️ Afternoon Focus';
      _selectedFormat = '📖 Physical Book';
      _selectedLength = '📖 Medium (200–350 pgs)';
      _selectedSoundscape = _kSoundscapes[1]; // Coffee Shop
    } else if (label == 'Make me cry') {
      _primaryGoal = 'Habit Building';
      _selectedMood = 'Motivated';
      _selectedTiming = '🌙 Evening Wind-down';
      _selectedFormat = '📱 Digital / E-Book';
      _selectedLength = '⚡ Short (< 200 pgs)';
      _selectedSoundscape = _kSoundscapes[3]; // Library
    }
    if (_isAudioPlaying) {
      _playSelectedSoundscape();
    }
  }

  // Pre-fill "Design Your Reading Journey" form when user selects an atmosphere chip
  void _onAtmosphereSelected(String label) {
    setState(() {
      if (_selectedAtmosphere == label) {
        _selectedAtmosphere = null;
        _primaryGoal = null;
        _selectedMood = null;
        _selectedTiming = null;
        _selectedFormat = null;
        _selectedLength = null;
      } else {
        _selectedAtmosphere = label;
        _applyAtmospherePreset(label);
      }
      _currentRecommendationIndex = 0;
      _isCurrentBookAccepted = false;
      _hasDiscovered = false; // Remains false so recommendation card only appears when user clicks "Discover My Match"!
      _hasGeneratedPlan = false;
    });
    _saveSessionState();

    if (_selectedAtmosphere != null && mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✨ "$label" applied to Your Reading Journey! Click "Discover My Match" below to see recommendations.'),
          backgroundColor: DSColors.deepForestGreen,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _launchExternal(String query, String store) async {
    final encoded = Uri.encodeComponent(query);
    String url = 'https://www.google.com/search?q=$encoded';
    if (store == 'amazon') {
      url = 'https://www.amazon.in/s?k=$encoded';
    } else if (store == 'flipkart') {
      url = 'https://www.flipkart.com/search?q=$encoded';
    } else if (store == 'openlibrary') {
      url = 'https://openlibrary.org/search?q=$encoded';
    }

    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DSColors.warmIvory,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Container(
            color: DSColors.warmIvory,
            width: double.infinity,
            child: Column(
              children: [
                // TOP HEADER BAR
                _buildTopHeader(),
                const SizedBox(height: 16),

                // MAIN BODY CONTAINER
                Center(
                  child: Container(
                    constraints: const BoxConstraints(maxWidth: 1350),
                    padding: EdgeInsets.symmetric(
                      horizontal: MediaQuery.of(context).size.width < 600 ? 12 : 24,
                      vertical: 16,
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isDesktop = constraints.maxWidth >= 950;

                        if (isDesktop) {
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // LEFT COLUMN: ARCHIVIST & JOURNEY FORM (55%)
                              Expanded(
                                flex: 11,
                                child: _buildLeftJourneyColumn(),
                              ),
                              const SizedBox(width: 32),

                              // RIGHT COLUMN: AWAITING DISCOVERY / STEP 2 / READING PLAN (45%)
                              Expanded(
                                flex: 9,
                                child: _buildRightMatchColumn(),
                              ),
                            ],
                          );
                        }

                        return Column(
                          children: [
                            _buildLeftJourneyColumn(),
                            const SizedBox(height: 32),
                            _buildRightMatchColumn(),
                          ],
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeader() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 32),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1350),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: DSColors.deepForestGreen,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: FaIcon(
                    FontAwesomeIcons.wandMagicSparkles,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'AI RECOMMENDATIONS / MOOD MATCHER',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: DSColors.deepForestGreen,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Discover books that match your mood, context & preferences',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: DSColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: DSColors.deepForestGreen),
                onPressed: () {
                  if (Navigator.of(context).canPop()) {
                    context.pop();
                  } else {
                    context.go('/');
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeftJourneyColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. MEET "THE ARCHIVIST" CARD
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: DSColors.warmIvory,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: DSColors.warmIvory),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('✨ ', style: TextStyle(fontSize: 18)),
                  Text(
                    'Meet "The Archivist"',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: DSColors.charcoal,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Your resident literary curator. Tell The Archivist your mood or pick an atmospheric vibe to discover books tailored to your soul.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: DSColors.textMuted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'QUICK ATMOSPHERE CHIPS',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.1,
                  color: DSColors.accentTerracotta,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: _atmosphereChips.map((chip) {
                  final label = chip['label'] as String;
                  final icon = chip['icon'] as String;
                  final isSelected = _selectedAtmosphere == label;

                  return ChoiceChip(
                    avatar: Text(icon, style: const TextStyle(fontSize: 12)),
                    label: Text(label),
                    selected: isSelected,
                    selectedColor: DSColors.deepForestGreen,
                    backgroundColor: Colors.white,
                    labelStyle: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? Colors.white : DSColors.textLight,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(DSRadius.pill),
                      side: BorderSide(
                        color: isSelected ? DSColors.deepForestGreen : DSColors.softBorder,
                      ),
                    ),
                    onSelected: (_) => _onAtmosphereSelected(label),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // 2. DESIGN YOUR READING JOURNEY HEADER
        Text(
          'Design Your Reading Journey',
          style: GoogleFonts.playfairDisplay(
            fontSize: 26,
            fontWeight: FontWeight.bold,
            color: DSColors.deepForestGreen,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Tell us what you want to achieve and how you feel, and The Archivist will pull the perfect volume.',
          style: GoogleFonts.inter(
            fontSize: 13,
            color: DSColors.textMuted,
          ),
        ),
        const SizedBox(height: 24),

        // 3. FORM SECTIONS (ALL INITIAL CHIPS UNSELECTED/NULL BY DEFAULT)
        _buildChipGroup(
          title: 'What is your primary goal?',
          options: _goals,
          selectedValue: _primaryGoal,
          onSelected: (val) {
            setState(() {
              _primaryGoal = (_primaryGoal == val) ? null : val;
              _selectedAtmosphere = null;
              _hasDiscovered = false;
              _hasGeneratedPlan = false;
            });
            _saveSessionState();
          },
        ),
        _buildChipGroup(
          title: 'How are you feeling right now?',
          options: _moods,
          selectedValue: _selectedMood,
          onSelected: (val) {
            setState(() {
              _selectedMood = (_selectedMood == val) ? null : val;
              _selectedAtmosphere = null;
              _hasDiscovered = false;
              _hasGeneratedPlan = false;
            });
            _saveSessionState();
          },
        ),
        _buildChipGroup(
          title: 'Preferred Reading Timing & Routine',
          options: _timings,
          selectedValue: _selectedTiming,
          onSelected: (val) {
            setState(() {
              _selectedTiming = (_selectedTiming == val) ? null : val;
              _selectedAtmosphere = null;
              _hasDiscovered = false;
              _hasGeneratedPlan = false;
            });
            _saveSessionState();
          },
        ),
        _buildChipGroup(
          title: 'Reading Medium & Format',
          options: _formats,
          selectedValue: _selectedFormat,
          onSelected: (val) {
            setState(() {
              _selectedFormat = (_selectedFormat == val) ? null : val;
              _selectedAtmosphere = null;
              _hasDiscovered = false;
              _hasGeneratedPlan = false;
            });
            _saveSessionState();
          },
        ),
        _buildChipGroup(
          title: 'Preferred Book Length & Depth',
          options: _lengths,
          selectedValue: _selectedLength,
          onSelected: (val) {
            setState(() {
              _selectedLength = (_selectedLength == val) ? null : val;
              _selectedAtmosphere = null;
              _hasDiscovered = false;
              _hasGeneratedPlan = false;
            });
            _saveSessionState();
          },
        ),

        const SizedBox(height: 12),

        // DISCOVER MY MATCH BUTTON
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _hasDiscovered = true;
                _hasGeneratedPlan = false; // Step 2 first (Image + Acquisition options)
                _currentRecommendationIndex = 0;
                _isCurrentBookAccepted = false;
              });
              _saveSessionState();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('✨ The Archivist matched you with "${_currentMatch['title']}"!'),
                  backgroundColor: DSColors.deepForestGreen,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: DSColors.accentTerracotta, // Terracotta Rust
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DSRadius.card),
              ),
            ),
            icon: const Text('✨', style: TextStyle(fontSize: 16)),
            label: Text(
              'Discover My Match',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRightMatchColumn() {
    if (!_hasDiscovered) {
      return _buildAwaitingDiscoveryPlaceholder();
    }

    if (_hasGeneratedPlan) {
      return _buildYourPerfectMatchAndPlanView();
    }

    return _buildStep2AcquisitionView();
  }

  // STATE 1: AWAITING DISCOVERY PLACEHOLDER (Right side initial state)
  Widget _buildAwaitingDiscoveryPlaceholder() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(36),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DSColors.softBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 40),
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: DSColors.warmIvory,
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Text('✨', style: TextStyle(fontSize: 36)),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'The Archivist is Ready',
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: DSColors.deepForestGreen,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Pick an atmosphere chip above or customize your reading journey goals on the left, then click "Discover My Match" to reveal your tailored volume and 7-day reading schedule.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: DSColors.textMuted,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // STATE 2: STEP 2 BOOK PREVIEW + ACQUISITION OPTIONS
  Widget _buildStep2AcquisitionView() {
    final recs = _currentRecommendations;
    final totalRecs = recs.length;
    final currentIndex = _currentRecommendationIndex % totalRecs;
    final matchData = _currentMatch;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        return Container(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: DSColors.softBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Step 2 Badge Header (Wrap prevents horizontal overflow on narrow mobile screens)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: DSColors.deepForestGreen,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Step 2: Choose How You Want to Proceed',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: DSColors.accentTerracotta.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.auto_stories, size: 13, color: DSColors.accentTerracotta),
                        const SizedBox(width: 5),
                        Text(
                          'Curated Pick ${currentIndex + 1} of $totalRecs',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: DSColors.accentTerracotta,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                'Review the curated volume below. Use the ❌ or ✅ buttons to pick your favorite suggestion, then choose how to proceed.',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: DSColors.textMuted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),

              // MATCH PREVIEW CARD WITH IMAGE & DECISION BUTTONS
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: EdgeInsets.all(isMobile ? 14 : 18),
                decoration: BoxDecoration(
                  color: _isCurrentBookAccepted
                      ? DSColors.deepForestGreen.withValues(alpha: 0.03)
                      : DSColors.warmIvory,
                  borderRadius: BorderRadius.circular(DSRadius.card),
                  border: Border.all(
                    color: _isCurrentBookAccepted
                        ? DSColors.deepForestGreen
                        : DSColors.softBorder,
                    width: _isCurrentBookAccepted ? 1.5 : 1.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(DSRadius.md),
                          child: Image.network(
                            matchData['cover'] as String,
                            width: isMobile ? 74 : 84,
                            height: isMobile ? 110 : 124,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => Container(
                              width: isMobile ? 74 : 84,
                              height: isMobile ? 110 : 124,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [DSColors.deepForestGreen, DSColors.deepForestGreen],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(DSRadius.md),
                              ),
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.auto_stories, color: Colors.white70, size: 24),
                                  const SizedBox(height: 6),
                                  Text(
                                    matchData['title'] as String,
                                    textAlign: TextAlign.center,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.playfairDisplay(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      matchData['title'] as String,
                                      style: GoogleFonts.playfairDisplay(
                                        fontSize: isMobile ? 17 : 20,
                                        fontWeight: FontWeight.bold,
                                        color: DSColors.deepForestGreen,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: DSColors.antiqueGold.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(DSRadius.pill),
                                    ),
                                    child: Text(
                                      matchData['matchScore'] as String? ?? '95% Match',
                                      style: GoogleFonts.inter(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: DSColors.accentTerracotta,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'by ${matchData['author'] as String}',
                                style: GoogleFonts.inter(fontSize: 12, color: DSColors.textMuted),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                matchData['rationale'] as String,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.inter(fontSize: 11, color: DSColors.textLight, height: 1.35),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Suggestion dots indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(totalRecs, (i) {
                        final isActive = i == currentIndex;
                        return InkWell(
                          onTap: () {
                            setState(() {
                              _currentRecommendationIndex = i;
                              _isCurrentBookAccepted = false;
                            });
                            _saveSessionState();
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: isActive ? 24 : 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: isActive ? DSColors.accentTerracotta : DSColors.softBorder,
                              borderRadius: BorderRadius.circular(DSRadius.pill),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),

                    // INTERACTIVE DECISION CONTROLS (INTO MARK ❌ & RIGHT MARK ✅)
                    Row(
                      children: [
                        // ❌ CROSS / INTO MARK: Next suggestion / Not this one
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              setState(() {
                                _currentRecommendationIndex = (currentIndex + 1) % totalRecs;
                                _isCurrentBookAccepted = false;
                              });
                              _saveSessionState();
                            },
                            icon: const Icon(Icons.close, size: 16, color: DSColors.accentTerracotta),
                            label: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                'Next Book (${(currentIndex + 1) % totalRecs + 1}/$totalRecs)',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: DSColors.accentTerracotta,
                                ),
                              ),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
                              side: const BorderSide(color: DSColors.accentTerracotta),
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DSRadius.md)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),

                        // ✅ CHECK / RIGHT MARK: I like this book / Proceed!
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              setState(() {
                                _isCurrentBookAccepted = true;
                              });
                              _saveSessionState();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('✓ Selected "${matchData['title']}"! Choose your next step below.'),
                                  backgroundColor: DSColors.deepForestGreen,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                            icon: Icon(
                              _isCurrentBookAccepted ? Icons.check_circle : Icons.check_circle_outline,
                              size: 16,
                              color: Colors.white,
                            ),
                            label: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                _isCurrentBookAccepted ? 'Selected ✓' : 'I Like This ✓',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 8),
                              backgroundColor: _isCurrentBookAccepted
                                  ? DSColors.deepForestGreen
                                  : DSColors.secondaryGreen,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DSRadius.md)),
                            ),
                          ),
                        ),
                      ],
                    ),

                    if (_isCurrentBookAccepted) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: DSColors.secondaryGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: DSColors.secondaryGreen.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.verified, size: 16, color: DSColors.secondaryGreen),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Volume selected! Choose your preferred reading route below.',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: DSColors.secondaryGreen,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // OPTION A: I ALREADY HAVE THIS BOOK
              Container(
                padding: EdgeInsets.all(isMobile ? 16 : 20),
                decoration: BoxDecoration(
                  color: DSColors.warmIvory,
                  borderRadius: BorderRadius.circular(DSRadius.card),
                  border: Border.all(color: DSColors.warmIvory),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.bookmark_added, color: DSColors.accentTerracotta, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'I Already Have This Book',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: DSColors.charcoal,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Generate customized daily schedule, page goals & habit tracking.',
                      style: GoogleFonts.inter(fontSize: 12, color: DSColors.textMuted),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          setState(() => _hasGeneratedPlan = true);
                          _saveSessionState();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DSColors.accentTerracotta,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.calendar_month, size: 18),
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Generate Daily Reading Plan',
                            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // OPTION B: I NEED TO ORDER OR RENT THIS BOOK
              Container(
                padding: EdgeInsets.all(isMobile ? 16 : 20),
                decoration: BoxDecoration(
                  color: DSColors.warmIvory,
                  borderRadius: BorderRadius.circular(DSRadius.card),
                  border: Border.all(color: DSColors.softBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.shopping_bag_outlined, color: DSColors.deepForestGreen, size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'I Need to Order or Rent This Book',
                            style: GoogleFonts.inter(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: DSColors.charcoal,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Check peer listings in The Tactile Archive or explore external booksellers.',
                      style: GoogleFonts.inter(fontSize: 12, color: DSColors.textMuted),
                    ),
                    const SizedBox(height: 16),

                    // Primary full-width CTA matching Option A
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _saveSessionState();
                          final title = matchData['title'] as String;
                          context.push('/browse?search=${Uri.encodeComponent(title)}&from=mood-match');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DSColors.deepForestGreen,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        icon: const Icon(Icons.storefront, size: 18),
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Find in Marketplace',
                            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Neat external secondary links
                    Row(
                      children: [
                        const Expanded(child: Divider(color: DSColors.softBorder)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            'OR EXPLORE EXTERNAL',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.8,
                              color: DSColors.textMuted,
                            ),
                          ),
                        ),
                        const Expanded(child: Divider(color: DSColors.softBorder)),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _launchExternal('${matchData['title']} ${matchData['author']}', 'amazon'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: DSColors.charcoal,
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            side: const BorderSide(color: DSColors.softBorder),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Text('a', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          label: const Text('Amazon', style: TextStyle(fontSize: 12)),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _launchExternal('${matchData['title']} ${matchData['author']}', 'flipkart'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: DSColors.charcoal,
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            side: const BorderSide(color: DSColors.softBorder),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Text('🛍️', style: TextStyle(fontSize: 12)),
                          label: const Text('Flipkart', style: TextStyle(fontSize: 12)),
                        ),
                        OutlinedButton.icon(
                          onPressed: () => _launchExternal('${matchData['title']} ${matchData['author']}', 'openlibrary'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: DSColors.charcoal,
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            side: const BorderSide(color: DSColors.softBorder),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          icon: const Icon(Icons.menu_book, size: 14),
                          label: const Text('Open Library', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              Center(
                child: OutlinedButton(
                  onPressed: () {
                    MoodSessionState.reset();
                    setState(() {
                      _hasDiscovered = false;
                      _hasGeneratedPlan = false;
                      _selectedAtmosphere = null;
                      _primaryGoal = null;
                      _selectedMood = null;
                      _selectedTiming = null;
                      _selectedFormat = null;
                      _selectedLength = null;
                      _currentRecommendationIndex = 0;
                      _isCurrentBookAccepted = false;
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: DSColors.textLight,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DSRadius.pill)),
                  ),
                  child: Text(
                    'Try Another Mood or Atmosphere',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // STATE 3: YOUR PERFECT MATCH & 7-DAY READING PLAN
  Widget _buildYourPerfectMatchAndPlanView() {
    final matchData = _currentMatch;
    final planList = (matchData['plan'] as List<dynamic>? ?? []).cast<Map<String, String>>();
    final double progressVal = planList.isEmpty ? 0.0 : (_completedDays.length / planList.length);
    final String minutesFormatted = '${(_sessionSecondsLeft ~/ 60).toString().padLeft(2, '0')}:${(_sessionSecondsLeft % 60).toString().padLeft(2, '0')}';
    final isCurrentDayCompleted = _completedDays.isNotEmpty && _completedDays.contains(_completedDays.length);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. YOUR PERFECT MATCH CARD
            Container(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: DSColors.softBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          'Your Perfect Match',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: isMobile ? 19 : 22,
                            fontWeight: FontWeight.bold,
                            color: DSColors.deepForestGreen,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: DSColors.antiqueGold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(DSRadius.pill),
                        ),
                        child: Text(
                          matchData['matchScore'] as String? ?? '95% Match',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: DSColors.accentTerracotta,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cover Image Container
                      ClipRRect(
                        borderRadius: BorderRadius.circular(DSRadius.md),
                        child: Image.network(
                          matchData['cover'] as String,
                          width: isMobile ? 74 : 90,
                          height: isMobile ? 110 : 135,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(
                            width: isMobile ? 74 : 90,
                            height: isMobile ? 110 : 135,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [DSColors.deepForestGreen, DSColors.deepForestGreen],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(DSRadius.md),
                            ),
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.auto_stories, color: Colors.white70, size: 24),
                                const SizedBox(height: 6),
                                Text(
                                  matchData['title'] as String,
                                  textAlign: TextAlign.center,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.playfairDisplay(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              matchData['title'] as String,
                              style: GoogleFonts.playfairDisplay(
                                fontSize: isMobile ? 18 : 22,
                                fontWeight: FontWeight.bold,
                                color: DSColors.deepForestGreen,
                              ),
                            ),
                            Text(
                              'by ${matchData['author'] as String}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: DSColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Why it's recommended:",
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: DSColors.secondaryGreen,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              matchData['rationale'] as String,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: DSColors.textLight,
                                height: 1.4,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Action Buttons: Save to Library
                            OutlinedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('🔖 "${matchData['title']}" saved to your Virtual Library Shelf!'),
                                    backgroundColor: DSColors.deepForestGreen,
                                  ),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              icon: const Icon(Icons.bookmark_border, size: 14, color: DSColors.deepForestGreen),
                              label: const Text('Save to Shelf', style: TextStyle(fontSize: 11, color: DSColors.deepForestGreen)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ENHANCED HABIT PROGRESS & STREAK CARD
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: DSColors.warmIvory,
                      borderRadius: BorderRadius.circular(DSRadius.card),
                      border: Border.all(color: DSColors.softBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                'Progress: Day ${_completedDays.length} of ${planList.length}',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: DSColors.deepForestGreen,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: DSColors.warmIvory,
                                borderRadius: BorderRadius.circular(DSRadius.pill),
                                border: Border.all(color: DSColors.warmIvory),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('🔥 ', style: TextStyle(fontSize: 11)),
                                  Text(
                                    '$_streakCount Day Streak!',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: DSColors.accentTerracotta,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        LinearProgressIndicator(
                          value: progressVal,
                          backgroundColor: DSColors.softBorder,
                          valueColor: const AlwaysStoppedAnimation<Color>(DSColors.deepForestGreen),
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(DSRadius.pill),
                        ),
                        const SizedBox(height: 14),

                        // Daily Goal Target Interactivity
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              "Did you complete today's reading target (~$_dailyPageTarget pages)?",
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: DSColors.textLight,
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ChoiceChip(
                                  avatar: isCurrentDayCompleted ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                                  label: const Text('✓ Yes'),
                                  selected: isCurrentDayCompleted,
                                  selectedColor: DSColors.deepForestGreen,
                                  labelStyle: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isCurrentDayCompleted ? Colors.white : DSColors.deepForestGreen,
                                  ),
                                  onSelected: (_) => _handleYesClicked(),
                                ),
                                const SizedBox(width: 6),
                                ChoiceChip(
                                  label: const Text('Not Yet'),
                                  selected: !isCurrentDayCompleted,
                                  backgroundColor: Colors.white,
                                  labelStyle: TextStyle(
                                    fontSize: 12,
                                    fontWeight: !isCurrentDayCompleted ? FontWeight.bold : FontWeight.normal,
                                    color: !isCurrentDayCompleted ? DSColors.deepForestGreen : DSColors.textMuted,
                                  ),
                                  onSelected: (_) => _handleNotYetClicked(),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // FOCUS READING TIMER & AMBIENT AUDIO WIDGET
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: DSColors.warmIvory,
                      borderRadius: BorderRadius.circular(DSRadius.card),
                      border: Border.all(color: DSColors.warmIvory),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('🎧 ', style: TextStyle(fontSize: 20)),
                                const SizedBox(width: 6),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          'Focus Reading Session',
                                          style: GoogleFonts.inter(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: DSColors.charcoal,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        _AudioEqualizerVisualizer(isPlaying: _isAudioPlaying),
                                      ],
                                    ),
                                    Text(
                                      _isAudioPlaying
                                          ? 'Playing: ${_selectedSoundscape.icon} ${_selectedSoundscape.title} ($minutesFormatted)'
                                          : 'Start 15-min focused session with ambient sound.',
                                      style: GoogleFonts.inter(fontSize: 11, color: DSColors.textMuted),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_sessionSecondsLeft < 900) ...[
                                  IconButton(
                                    icon: const Icon(Icons.refresh, size: 18, color: DSColors.textMuted),
                                    tooltip: 'Reset 15-min Timer',
                                    onPressed: _resetTimer,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                ElevatedButton.icon(
                                  onPressed: _toggleReadingTimer,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _isAudioPlaying ? DSColors.accentTerracotta : DSColors.deepForestGreen,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                  icon: Icon(_isAudioPlaying ? Icons.pause : Icons.play_arrow, size: 16),
                                  label: Text(_isAudioPlaying ? minutesFormatted : 'Start (15m)', style: const TextStyle(fontSize: 12)),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // SOUNDSCAPE SELECTOR CHIPS & VOLUME CONTROL
                        Row(
                          children: [
                            Expanded(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: _kSoundscapes.map((sound) {
                                    final isSelected = _selectedSoundscape.id == sound.id;
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 6),
                                      child: InkWell(
                                        onTap: () => _changeSoundscape(sound),
                                        borderRadius: BorderRadius.circular(8),
                                        child: AnimatedContainer(
                                          duration: const Duration(milliseconds: 200),
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: isSelected ? DSColors.deepForestGreen : Colors.white,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: isSelected ? DSColors.deepForestGreen : DSColors.softBorder,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(sound.icon, style: const TextStyle(fontSize: 11)),
                                              const SizedBox(width: 4),
                                              Text(
                                                sound.title,
                                                style: GoogleFonts.inter(
                                                  fontSize: 11,
                                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                                  color: isSelected ? Colors.white : DSColors.textLight,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ),
                            // Volume control button
                            PopupMenuButton<double>(
                              icon: Icon(
                                _audioVolume == 0 ? Icons.volume_off : (_audioVolume < 0.5 ? Icons.volume_down : Icons.volume_up),
                                size: 18,
                                color: DSColors.textMuted,
                              ),
                              tooltip: 'Ambient Volume (${(_audioVolume * 100).round()}%)',
                              onSelected: (val) => _setVolume(val),
                              itemBuilder: (ctx) => [
                                PopupMenuItem(
                                  value: 1.0,
                                  child: Text('🔊 High (100%)', style: GoogleFonts.inter(fontSize: 12)),
                                ),
                                PopupMenuItem(
                                  value: 0.7,
                                  child: Text('🔉 Balanced (70%)', style: GoogleFonts.inter(fontSize: 12)),
                                ),
                                PopupMenuItem(
                                  value: 0.4,
                                  child: Text('🔈 Gentle (40%)', style: GoogleFonts.inter(fontSize: 12)),
                                ),
                                PopupMenuItem(
                                  value: 0.0,
                                  child: Text('🔇 Mute', style: GoogleFonts.inter(fontSize: 12)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 2. YOUR DYNAMIC READING PLAN CARD WITH SEQUENTIAL CHECKLIST SYNC
            Container(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: DSColors.softBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Your ${planList.length}-Day Reading Plan',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: isMobile ? 18 : 22,
                                fontWeight: FontWeight.bold,
                                color: DSColors.deepForestGreen,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Tailored for "${matchData['title']}"',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: DSColors.accentTerracotta,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),

                      // Pace Selector
                      PopupMenuButton<int>(
                        initialValue: _dailyPageTarget,
                        onSelected: (val) {
                          setState(() => _dailyPageTarget = val);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Pace updated to $val pages/day!')),
                          );
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(value: 10, child: Text('⚡ 10 pages/day (10 mins)')),
                          PopupMenuItem(value: 15, child: Text('📖 15 pages/day (15 mins)')),
                          PopupMenuItem(value: 25, child: Text('📚 25 pages/day (25 mins)')),
                        ],
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: DSColors.warmIvory,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: DSColors.softBorder),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text('Pace: $_dailyPageTarget pgs/day', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold)),
                              const SizedBox(width: 2),
                              const Icon(Icons.arrow_drop_down, size: 16),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Column(
                    children: List.generate(planList.length, (idx) {
                      final dayIndex = idx + 1;
                      final isDone = _completedDays.contains(dayIndex);
                      final item = planList[idx];

                      return InkWell(
                        onTap: () => _handleDayChecklistToggled(dayIndex),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                child: Icon(
                                  isDone ? Icons.check_circle : Icons.radio_button_unchecked,
                                  size: 20,
                                  color: isDone ? DSColors.deepForestGreen : DSColors.softBorder,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  '${item['day']}: ${item['title']}',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: isDone ? DSColors.textMuted : DSColors.charcoal,
                                    decoration: isDone ? TextDecoration.lineThrough : null,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ),
        const SizedBox(height: 20),

        // Bottom option to switch view back to Step 2
        Center(
          child: TextButton.icon(
            onPressed: () => setState(() => _hasGeneratedPlan = false),
            icon: const Icon(Icons.swap_horiz, size: 16, color: DSColors.textMuted),
            label: Text(
              'Back to Acquisition Options / Marketplace Links',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: DSColors.textMuted,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ),
      ],
    );
  },
);
}

  Widget _buildChipGroup({
    required String title,
    required List<String> options,
    required String? selectedValue,
    required ValueChanged<String> onSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: DSColors.charcoal,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: options.map((option) {
            final isSelected = selectedValue == option;
            return ChoiceChip(
              label: Text(option),
              selected: isSelected,
              selectedColor: DSColors.deepForestGreen,
              backgroundColor: Colors.white,
              labelStyle: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : DSColors.textLight,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: isSelected ? DSColors.deepForestGreen : DSColors.softBorder,
                ),
              ),
              onSelected: (_) => onSelected(option),
            );
          }).toList(),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}

/// Rhythmic animated equalizer wave bars for ambient audio playback
class _AudioEqualizerVisualizer extends StatefulWidget {
  final bool isPlaying;
  const _AudioEqualizerVisualizer({required this.isPlaying});

  @override
  State<_AudioEqualizerVisualizer> createState() => _AudioEqualizerVisualizerState();
}

class _AudioEqualizerVisualizerState extends State<_AudioEqualizerVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    if (widget.isPlaying) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant _AudioEqualizerVisualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.isPlaying && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final val = _controller.value;
        final h1 = widget.isPlaying ? 4.0 + (val * 10) : 3.0;
        final h2 = widget.isPlaying ? 14.0 - (val * 9) : 6.0;
        final h3 = widget.isPlaying ? 6.0 + (val * 8) : 4.0;
        final h4 = widget.isPlaying ? 12.0 - (val * 7) : 5.0;

        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildBar(h1),
            const SizedBox(width: 2.5),
            _buildBar(h2),
            const SizedBox(width: 2.5),
            _buildBar(h3),
            const SizedBox(width: 2.5),
            _buildBar(h4),
          ],
        );
      },
    );
  }

  Widget _buildBar(double height) {
    return Container(
      width: 3,
      height: height,
      decoration: BoxDecoration(
        color: widget.isPlaying ? DSColors.accentTerracotta : DSColors.textMuted,
        borderRadius: BorderRadius.circular(DSRadius.xs),
      ),
    );
  }
}

