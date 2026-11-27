import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:libri_flow/core/services/api_service.dart';

class AudioSummaryPlayerWidget extends StatefulWidget {
  final int bookId;

  const AudioSummaryPlayerWidget({super.key, required this.bookId});

  @override
  State<AudioSummaryPlayerWidget> createState() => _AudioSummaryPlayerWidgetState();
}

class _AudioSummaryPlayerWidgetState extends State<AudioSummaryPlayerWidget> {
  bool _isPlaying = false;
  double _playbackSpeed = 1.0;
  double _currentProgress = 0.25;
  Map<String, dynamic>? _summaryData;

  @override
  void initState() {
    super.initState();
    _fetchAudioSummary();
  }

  Future<void> _fetchAudioSummary() async {
    try {
      final res = await ApiService.get('/ai/audio-summary/${widget.bookId}');
      if (res.statusCode == 200 && res.data != null) {
        setState(() => _summaryData = res.data);
      }
    } catch (e) {
      // Fallback display
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF0D3B2E),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 16, offset: Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFC85A32),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const FaIcon(FontAwesomeIcons.headphonesSimple, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🎙️ 5-Minute AI Audio Chapter Summary',
                      style: GoogleFonts.playfairDisplay(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                    Text(
                      _summaryData?['title'] ?? 'Selected Book Volume',
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.white70),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<double>(
                icon: Text('${_playbackSpeed}x', style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: Colors.amberAccent)),
                onSelected: (speed) => setState(() => _playbackSpeed = speed),
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 1.0, child: Text('1.0x Speed')),
                  PopupMenuItem(value: 1.25, child: Text('1.25x Speed')),
                  PopupMenuItem(value: 1.5, child: Text('1.5x Speed')),
                  PopupMenuItem(value: 2.0, child: Text('2.0x Speed')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Slider(
            value: _currentProgress,
            activeColor: const Color(0xFFC85A32),
            inactiveColor: Colors.white24,
            onChanged: (val) => setState(() => _currentProgress = val),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('1:15', style: GoogleFonts.inter(fontSize: 11, color: Colors.white70)),
              Text(_summaryData?['duration_formatted'] ?? '5:00', style: GoogleFonts.inter(fontSize: 11, color: Colors.white70)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.replay_10_rounded, color: Colors.white, size: 28),
                onPressed: () => setState(() => _currentProgress = (_currentProgress - 0.05).clamp(0.0, 1.0)),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () => setState(() => _isPlaying = !_isPlaying),
                child: CircleAvatar(
                  radius: 26,
                  backgroundColor: const Color(0xFFC85A32),
                  child: Icon(
                    _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.forward_10_rounded, color: Colors.white, size: 28),
                onPressed: () => setState(() => _currentProgress = (_currentProgress + 0.05).clamp(0.0, 1.0)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
