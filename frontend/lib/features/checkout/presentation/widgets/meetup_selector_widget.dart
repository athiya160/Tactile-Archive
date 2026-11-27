import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MeetupSelectorWidget extends StatefulWidget {
  final ValueChanged<Map<String, dynamic>>? onLocationSelected;
  const MeetupSelectorWidget({super.key, this.onLocationSelected});

  @override
  State<MeetupSelectorWidget> createState() => _MeetupSelectorWidgetState();
}

class _MeetupSelectorWidgetState extends State<MeetupSelectorWidget> {
  int _selectedId = 1;
  String _selectedTime = 'Tomorrow at 04:00 PM';

  final List<Map<String, dynamic>> _safeZones = [
    {
      'id': 1,
      'name': 'Central Campus Library — Ground Exchange Desk',
      'address': 'Building A, 1st Floor Lobby, Main Quad',
      'operating_hours': '08:00 AM - 10:00 PM',
      'badge': 'Verified Campus Hub',
    },
    {
      'id': 2,
      'name': 'Student Union Lounge & Cafe',
      'address': 'North Wing, Student Activity Center',
      'operating_hours': '09:00 AM - 08:00 PM',
      'badge': 'High Security Lounge',
    },
    {
      'id': 3,
      'name': 'SciTech Innovation Hub',
      'address': 'Science Block 3 Entrance',
      'operating_hours': '08:30 AM - 07:00 PM',
      'badge': 'Smart Drop Box',
    },
  ];

  final List<String> _timeSlots = [
    'Today at 05:30 PM',
    'Tomorrow at 10:00 AM',
    'Tomorrow at 04:00 PM',
    'Saturday at 02:00 PM'
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF0FDF4), // Light green tint for safety
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBBF7D0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_outlined, color: Color(0xFF166534), size: 22),
              const SizedBox(width: 10),
              Text(
                '🤝 Rental Safe Exchange Point',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF166534),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Select a CCTV-monitored campus drop-off hub for safe peer-to-peer rental handoffs.',
            style: GoogleFonts.inter(fontSize: 13, color: const Color(0xFF15803D)),
          ),
          const SizedBox(height: 16),

          // Safe zones list
          ..._safeZones.map((zone) {
            final isSelected = zone['id'] == _selectedId;
            return InkWell(
              onTap: () {
                setState(() {
                  _selectedId = zone['id'];
                });
                if (widget.onLocationSelected != null) {
                  widget.onLocationSelected!({
                    'zone': zone,
                    'time': _selectedTime,
                  });
                }
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF166534) : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Radio<int>(
                      value: zone['id'],
                      groupValue: _selectedId,
                      activeColor: const Color(0xFF166534),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedId = val);
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  zone['name'],
                                  style: GoogleFonts.inter(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: const Color(0xFF1E3A2B),
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  zone['badge'],
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF15803D),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            zone['address'],
                            style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 12),
          Text(
            'Preferred Pickup Time Slot:',
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF1E3A2B)),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _timeSlots.map((slot) {
              final isSelected = slot == _selectedTime;
              return ChoiceChip(
                label: Text(slot, style: GoogleFonts.inter(fontSize: 12)),
                selected: isSelected,
                selectedColor: const Color(0xFF166534),
                labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
                onSelected: (_) => setState(() => _selectedTime = slot),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
