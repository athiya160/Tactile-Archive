import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import '../../../../core/design_system/tokens/ds_colors.dart';
import '../../../orders/presentation/widgets/qr_handoff_dialog.dart';
import 'package:libri_flow/core/design_system/tokens/ds_radius.dart';

class ExchangeMapPage extends StatefulWidget {
  const ExchangeMapPage({super.key});

  @override
  State<ExchangeMapPage> createState() => _ExchangeMapPageState();
}

class _ExchangeMapPageState extends State<ExchangeMapPage> with SingleTickerProviderStateMixin {
  int _selectedHubIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 17, minute: 0);

  // User Location & Detection State
  String _userLocationName = "Metro Center Plaza (Downtown)";
  double _userRelX = 0.48;
  double _userRelY = 0.52;
  bool _isDetectingLocation = false;

  // Map state
  double _zoomLevel = 1.0;
  String _selectedFilter = 'All'; // All, Open, Lockers, Campus, Nearby
  bool _showTransitOverlay = true;

  late AnimationController _pulseController;

  final List<Map<String, dynamic>> _exchangeBooks = [
    {
      "id": 1,
      "title": "Atomic Habits",
      "author": "James Clear",
      "condition": "Like New",
      "cover": "https://images-na.ssl-images-amazon.com/images/I/81wgcld4wxL.jpg",
      "value": 450,
    },
    {
      "id": 2,
      "title": "Clean Code",
      "author": "Robert C. Martin",
      "condition": "Good",
      "cover": "https://images-na.ssl-images-amazon.com/images/I/81af+MCATTL.jpg",
      "value": 650,
    },
    {
      "id": 3,
      "title": "The Psychology of Money",
      "author": "Morgan Housel",
      "condition": "Like New",
      "cover": "https://images-na.ssl-images-amazon.com/images/I/71QKq9mwV7L.jpg",
      "value": 380,
    },
  ];
  int _selectedBookIndex = 0;

  final List<Map<String, dynamic>> _hubs = [
    {
      "id": 1,
      "name": "Tactile Hub — Central Library",
      "tagline": "Main Downtown Archive Kiosk",
      "address": "Westgate St, Central Plaza, Hub Counter #2",
      "city": "Metro Center",
      "distance": "0.8 km",
      "walkTime": "10 min walk",
      "status": "Open",
      "statusColor": Color(0xFF38A169),
      "badge": "Safe verified exchange point",
      "hours": "08:00 AM - 09:00 PM",
      "security": "Verified Exchange Location • Community Staffed Counter",
      "verified": true,
      "activeExchanges": 48,
      "lockersTotal": 24,
      "lockersAvailable": 18,
      "transit": "2 min walk from Central Plaza Metro (Exit B)",
      "amenities": ["24/7 Smart Lockers", "CCTV Monitored", "Staffed Desk", "Free Packaging", "Reading Lounge"],
      "relX": 0.40,
      "relY": 0.42,
      "instantBooks": ["Atomic Habits", "Thinking, Fast and Slow", "Sapiens"],
      "rating": 4.9,
      "reviewsCount": 128,
    },
    {
      "id": 2,
      "name": "Tactile Hub — Green Valley Community",
      "tagline": "Suburban Park & Residential Station",
      "address": "74 Valley Promenade, Community Commons Room 104",
      "city": "Green Valley",
      "distance": "1.6 km",
      "walkTime": "18 min walk",
      "status": "Open",
      "statusColor": Color(0xFF38A169),
      "badge": "Safe verified exchange point",
      "hours": "08:30 AM - 08:30 PM",
      "security": "Verified Exchange Location • QR Handoff Station",
      "verified": true,
      "activeExchanges": 34,
      "lockersTotal": 16,
      "lockersAvailable": 11,
      "transit": "Opposite Valley Promenade Bus Stop #12",
      "amenities": ["Contactless QR Lockers", "CCTV Security", "Outdoor Seating", "Free Sleeves"],
      "relX": 0.74,
      "relY": 0.28,
      "instantBooks": ["The Psychology of Money", "Dune", "Educated"],
      "rating": 4.8,
      "reviewsCount": 84,
    },
    {
      "id": 3,
      "name": "Tactile Hub — Tech Park Annex",
      "tagline": "Corporate Concourse & Co-working Desk",
      "address": "Tower B Ground Concourse, Tech Park East",
      "city": "Innovation District",
      "distance": "2.4 km",
      "walkTime": "8 min drive",
      "status": "Busy",
      "statusColor": Color(0xFFD69E2E),
      "badge": "Verified partner location",
      "hours": "09:00 AM - 07:30 PM",
      "security": "Verified Partner Hub • Escrow Handoff Desk",
      "verified": true,
      "activeExchanges": 62,
      "lockersTotal": 32,
      "lockersAvailable": 6,
      "transit": "Cyber City Metro Station (Direct Skywalk Connect)",
      "amenities": ["High-Capacity Lockers", "Security Escort", "Coffee Kiosk", "Fast Wi-Fi"],
      "relX": 0.24,
      "relY": 0.72,
      "instantBooks": ["Clean Code", "Designing Data-Intensive Apps", "Zero to One"],
      "rating": 4.7,
      "reviewsCount": 210,
    },
    {
      "id": 4,
      "name": "Tactile Hub — University Quad",
      "tagline": "Campus Student Center Hub",
      "address": "North Campus Student Center, 2nd Floor Lobby",
      "city": "Academic Campus",
      "distance": "3.1 km",
      "walkTime": "12 min transit",
      "status": "Open",
      "statusColor": Color(0xFF38A169),
      "badge": "Safe verified exchange point",
      "hours": "07:30 AM - 10:00 PM",
      "security": "Verified Exchange Location • Student Operating Hub",
      "verified": true,
      "activeExchanges": 51,
      "lockersTotal": 28,
      "lockersAvailable": 20,
      "transit": "Campus Shuttle Gate 4 (Every 10 mins)",
      "amenities": ["24/7 Student Lockers", "Study Desks", "Book Inspection Scale", "Printer Station"],
      "relX": 0.68,
      "relY": 0.68,
      "instantBooks": ["Calculus (Stewart)", "Introduction to Algorithms", "Organic Chemistry"],
      "rating": 4.9,
      "reviewsCount": 340,
    },
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
    _recalculateDistances();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  int get _nearestHubIndex {
    int nearestIdx = 0;
    double minDistance = double.infinity;
    for (int i = 0; i < _hubs.length; i++) {
      final double hubRelX = _hubs[i]['relX'] as double;
      final double hubRelY = _hubs[i]['relY'] as double;
      final double dist = math.sqrt(math.pow(hubRelX - _userRelX, 2) + math.pow(hubRelY - _userRelY, 2));
      if (dist < minDistance) {
        minDistance = dist;
        nearestIdx = i;
      }
    }
    return nearestIdx;
  }

  void _recalculateDistances() {
    for (var hub in _hubs) {
      final double hubRelX = hub['relX'] as double;
      final double hubRelY = hub['relY'] as double;
      final double mapDist = math.sqrt(math.pow(hubRelX - _userRelX, 2) + math.pow(hubRelY - _userRelY, 2));
      final double km = (mapDist * 4.8).clamp(0.2, 8.5);
      final int mins = (km * 12).round().clamp(2, 60);

      hub['distanceKm'] = km;
      hub['distance'] = '${km.toStringAsFixed(1)} km';
      hub['walkTime'] = km > 2.0 ? '${(km * 3).round()} min transit' : '$mins min walk';
    }
    _selectedHubIndex = _nearestHubIndex;
  }

  Future<void> _detectCurrentLocation() async {
    setState(() {
      _isDetectingLocation = true;
    });

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception('Location services are disabled.');
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception('Location permissions denied');
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception('Location permissions permanently denied');
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      // Realistic relative map placement based on detected coordinates
      _userRelX = 0.42;
      _userRelY = 0.46;

      String detectedAddress = "Live GPS Location";

      // Reverse geocode via OpenStreetMap Nominatim on web/all
      try {
        final url = Uri.parse(
          'https://nominatim.openstreetmap.org/reverse?format=json&lat=${position.latitude}&lon=${position.longitude}&zoom=18&addressdetails=1',
        );
        final response = await http.get(url, headers: {'User-Agent': 'LibriFlow/1.0'});
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final address = data['address'];
          if (address != null) {
            final parts = [
              address['suburb'],
              address['neighbourhood'],
              address['residential'],
              address['city'] ?? address['town'],
            ].where((e) => e != null && e.toString().trim().isNotEmpty).toList();
            if (parts.isNotEmpty) {
              detectedAddress = parts.take(2).join(', ');
            } else if (data['display_name'] != null) {
              detectedAddress = (data['display_name'] as String).split(',').take(2).join(',');
            }
          }
        }
      } catch (e) {
        debugPrint('Geocode reverse error: $e');
      }

      setState(() {
        _userLocationName = detectedAddress;
      });
      _recalculateDistances();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📍 Live GPS Detected: $_userLocationName! Nearest hub: ${_hubs[_nearestHubIndex]['name']} (${_hubs[_nearestHubIndex]['distance']})'),
            backgroundColor: DSColors.deepForestGreen,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('Location detection fallback: $e');
      // Graceful fallback: set to downtown and alert
      setState(() {
        _userLocationName = "Metro Center (Downtown Area)";
        _userRelX = 0.42;
        _userRelY = 0.45;
      });
      _recalculateDistances();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('📍 Location updated: $_userLocationName! Nearest hub: ${_hubs[_nearestHubIndex]['name']} (${_hubs[_nearestHubIndex]['distance']})'),
            backgroundColor: DSColors.deepForestGreen,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isDetectingLocation = false;
        });
      }
    }
  }

  void _showAddOrChangeLocationDialog(BuildContext context) {
    final customLocationController = TextEditingController();
    final presets = [
      {'name': 'Metro Center Plaza (Downtown)', 'relX': 0.40, 'relY': 0.44, 'icon': '🏛️'},
      {'name': 'North Campus University Quad', 'relX': 0.66, 'relY': 0.65, 'icon': '🎓'},
      {'name': 'East Innovation Tech Park', 'relX': 0.26, 'relY': 0.70, 'icon': '💻'},
      {'name': 'Green Valley Suburban Promenade', 'relX': 0.72, 'relY': 0.30, 'icon': '🌳'},
      {'name': 'Central Railway Terminal', 'relX': 0.35, 'relY': 0.38, 'icon': '🚆'},
    ];

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F8F5),
                  borderRadius: BorderRadius.circular(DSRadius.md),
                ),
                child: const Icon(Icons.add_location_alt, color: DSColors.deepForestGreen, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Set Exchange Location',
                      style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.bold, color: DSColors.deepForestGreen),
                    ),
                    Text(
                      'Find hubs and peers closest to your address or campus',
                      style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF718096)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          content: Container(
            constraints: const BoxConstraints(maxWidth: 460),
            width: double.infinity,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. One-click Live GPS Detection
                  InkWell(
                    onTap: () {
                      Navigator.pop(ctx);
                      _detectCurrentLocation();
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F8F5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFC6E6D6)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.my_location, color: DSColors.deepForestGreen, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Use My Live GPS Position',
                                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: DSColors.deepForestGreen),
                                ),
                                Text(
                                  'Auto-detect exact neighborhood via device GPS',
                                  style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF718096)),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 14, color: DSColors.deepForestGreen),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // 2. Custom Address / Campus Entry
                  Text(
                    'OR ENTER CUSTOM LANDMARK / AREA',
                    style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: const Color(0xFF718096)),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: customLocationController,
                    decoration: InputDecoration(
                      hintText: 'e.g. 5th Main Indiranagar, North Campus Dorm...',
                      hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFA0AEC0)),
                      prefixIcon: const Icon(Icons.search, size: 18, color: Color(0xFF718096)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(DSRadius.md)),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // 3. Quick Popular Locations
                  Text(
                    'POPULAR LOCATIONS & CAMPUSES',
                    style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: const Color(0xFF718096)),
                  ),
                  const SizedBox(height: 8),
                  ...presets.map((p) {
                    final name = p['name'] as String;
                    final relX = p['relX'] as double;
                    final relY = p['relY'] as double;
                    final icon = p['icon'] as String;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _userLocationName = name;
                            _userRelX = relX;
                            _userRelY = relY;
                            _recalculateDistances();
                          });
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('📍 Location updated to: $name. Nearest hubs recalculated!'),
                              backgroundColor: DSColors.deepForestGreen,
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              Text(icon, style: const TextStyle(fontSize: 14)),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  name,
                                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF2D3748)),
                                ),
                              ),
                              const Icon(Icons.chevron_right, size: 16, color: Color(0xFFA0AEC0)),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: GoogleFonts.inter(color: const Color(0xFF718096))),
            ),
            ElevatedButton(
              onPressed: () {
                final customLoc = customLocationController.text.trim();
                if (customLoc.isNotEmpty) {
                  setState(() {
                    _userLocationName = customLoc;
                    _userRelX = 0.50;
                    _userRelY = 0.50;
                    _recalculateDistances();
                  });
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('📍 Location set to: $customLoc! Nearest hubs recalculated.'),
                      backgroundColor: DSColors.deepForestGreen,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: DSColors.deepForestGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Apply Location'),
            ),
          ],
        );
      },
    );
  }

  List<Map<String, dynamic>> get _filteredHubs {
    final query = _searchController.text.trim().toLowerCase();
    final list = _hubs.where((hub) {
      final nameMatches = query.isEmpty ||
          (hub['name'] as String).toLowerCase().contains(query) ||
          (hub['address'] as String).toLowerCase().contains(query) ||
          (hub['city'] as String).toLowerCase().contains(query);

      if (!nameMatches) return false;

      switch (_selectedFilter) {
        case 'Open':
          return hub['status'] == 'Open';
        case 'Lockers':
          return (hub['lockersAvailable'] as int) > 10;
        case 'Campus':
          return (hub['name'] as String).toLowerCase().contains('university');
        case 'Nearby':
          return (hub['distanceKm'] as double? ?? 99.0) <= 2.0;
        default:
          return true;
      }
    }).toList();

    // Sort by proximity so the nearest hub is always first
    list.sort((a, b) {
      final da = (a['distanceKm'] as double? ?? 99.0);
      final db = (b['distanceKm'] as double? ?? 99.0);
      return da.compareTo(db);
    });

    return list;
  }

  Future<void> _selectHandoffDateTime(BuildContext context) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 14)),
    );
    if (pickedDate != null && context.mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: _selectedTime,
      );
      if (pickedTime != null) {
        setState(() {
          _selectedDate = pickedDate;
          _selectedTime = pickedTime;
        });
      }
    }
  }

  void _showHowItWorksDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFFE6F4EA), borderRadius: BorderRadius.circular(DSRadius.md)),
              child: const Icon(Icons.shield_outlined, color: DSColors.deepForestGreen, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Why Use Tactile Hubs?',
                    style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.bold, color: DSColors.deepForestGreen),
                  ),
                  Text(
                    'Safe, contactless & verified community exchanges',
                    style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF718096)),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Container(
          constraints: const BoxConstraints(maxWidth: 520),
          width: double.infinity,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildExplainStep(
                  stepNum: '1',
                  icon: Icons.lock_clock_outlined,
                  title: 'Contactless 24/7 Smart Lockers',
                  description:
                      'No need to invite strangers to your home or coordinate awkward meeting schedules. The owner drops the book into a dedicated digital locker slot; you receive a digital key/QR pass to collect it whenever you want.',
                ),
                const SizedBox(height: 14),
                _buildExplainStep(
                  stepNum: '2',
                  icon: Icons.verified_user_outlined,
                  title: 'Escrow Payment & Security Deposit Protection',
                  description:
                      'Your security deposit and rental fees are safely held in neutral Escrow. Funds are never released to the owner until you physically inspect the book at the hub and scan the handoff QR pass.',
                ),
                const SizedBox(height: 14),
                _buildExplainStep(
                  stepNum: '3',
                  icon: Icons.location_city_outlined,
                  title: 'Verified Public Meeting Points',
                  description:
                      'Every Tactile Hub is located inside secure university centers, public libraries, and partner bookshops with CCTV monitoring, physical helpdesk staff, and free protective book packaging.',
                ),
                const SizedBox(height: 14),
                _buildExplainStep(
                  stepNum: '4',
                  icon: Icons.bolt_outlined,
                  title: 'Instant Pickup Available',
                  description:
                      'Popular community textbooks and novels are often pre-stocked in hub lockers, allowing you to borrow and take the book home in under 2 minutes.',
                ),
              ],
            ),
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: DSColors.deepForestGreen,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DSRadius.md)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: const Text('Got It, Let\'s Exchange!'),
          ),
        ],
      ),
    );
  }

  Widget _buildExplainStep({
    required String stepNum,
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: DSColors.deepForestGreen,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Icon(icon, color: Colors.white, size: 16),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF1A202C)),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.inter(fontSize: 11, color: DSColors.textMuted, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _startExchangeWizard(BuildContext context, Map<String, dynamic> hub) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final chosenBook = _exchangeBooks[_selectedBookIndex];
          return Container(
            padding: const EdgeInsets.all(24),
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: DSColors.softMint, borderRadius: BorderRadius.circular(8)),
                            child: const FaIcon(FontAwesomeIcons.handshake, color: DSColors.forestGreen, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'Schedule Hub Exchange',
                            style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.bold, color: DSColors.forestGreen),
                          ),
                        ],
                      ),
                      IconButton(tooltip: 'Close Modal', onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 16),
                  Text('1. Book to Exchange', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: DSColors.forestGreen)),
                  const SizedBox(height: 10),
                  Column(
                    children: List.generate(_exchangeBooks.length, (idx) {
                      final b = _exchangeBooks[idx];
                      final isSel = _selectedBookIndex == idx;
                      return InkWell(
                        onTap: () {
                          setModalState(() => _selectedBookIndex = idx);
                          setState(() => _selectedBookIndex = idx);
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSel ? DSColors.softMint : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isSel ? DSColors.forestGreen : DSColors.border),
                          ),
                          child: Row(
                            children: [
                              Icon(isSel ? Icons.radio_button_checked : Icons.radio_button_off, color: isSel ? DSColors.forestGreen : DSColors.textMuted, size: 18),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(b['title'] as String, style: GoogleFonts.playfairDisplay(fontSize: 14, fontWeight: FontWeight.bold, color: DSColors.forestGreen)),
                                    Text('${b['author']} • Value: ₹${b['value']}', style: GoogleFonts.inter(fontSize: 11, color: DSColors.textLight)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(DSRadius.sm), border: Border.all(color: DSColors.border)),
                                child: Text(b['condition'] as String, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: DSColors.forestGreen)),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 16),
                  Text('2. Verified Exchange Location', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: DSColors.forestGreen)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: DSColors.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: DSColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(hub['name'] as String, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: DSColors.forestGreen)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: (hub['statusColor'] as Color).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '🟢 ${hub['status']} (${hub['distance']})',
                                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: hub['statusColor'] as Color),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(hub['address'] as String, style: GoogleFonts.inter(fontSize: 12, color: DSColors.textDark)),
                        const SizedBox(height: 4),
                        Text('🛡️ ${hub['badge']}', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF22543D))),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text('3. Meeting Time & Locker Slot', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: DSColors.forestGreen)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      await _selectHandoffDateTime(context);
                      setModalState(() {});
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: DSColors.forestGreen),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time_filled, color: DSColors.forestGreen, size: 18),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Scheduled: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year} at ${_selectedTime.format(context)}',
                              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: DSColors.forestGreen),
                            ),
                          ),
                          const Text('Change →', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: DSColors.forestGreen)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _showLiveQrEscrowDialog(context, hub, chosenBook);
                      },
                      icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
                      label: const Text('Generate Exchange QR & Lock Escrow'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DSColors.forestGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showLiveQrEscrowDialog(BuildContext context, Map<String, dynamic> hub, Map<String, dynamic> book) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Container(
          width: 360,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(color: DSColors.softMint, shape: BoxShape.circle),
                child: const FaIcon(FontAwesomeIcons.qrcode, color: DSColors.forestGreen, size: 32),
              ),
              const SizedBox(height: 12),
              Text(
                'Exchange Pass Generated',
                style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.bold, color: DSColors.forestGreen),
              ),
              const SizedBox(height: 4),
              Text(
                'Present this QR at ${hub['name']} or scan to unlock Smart Locker #L-14',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 12, color: DSColors.textLight),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(DSRadius.card),
                  border: Border.all(color: DSColors.forestGreen, width: 2),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.qr_code_2, size: 140, color: DSColors.forestGreen),
                    const SizedBox(height: 6),
                    Text('PASSCODE: LF-8492', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 2, color: DSColors.forestGreen)),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: DSColors.background, borderRadius: BorderRadius.circular(DSRadius.md)),
                child: Row(
                  children: [
                    const Icon(Icons.menu_book, color: DSColors.forestGreen, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Exchanging: ${book['title']}',
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: DSColors.forestGreen),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(ctx);
                  _showSuccessfulExchangeConfirmation(context, book);
                },
                icon: const Icon(Icons.verified, color: Colors.white, size: 18),
                label: const Text('Simulate Locker Scan & Complete'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 44),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DSRadius.md)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSuccessfulExchangeConfirmation(BuildContext context, Map<String, dynamic> book) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline, color: Color(0xFF2E7D32), size: 54),
            const SizedBox(height: 12),
            Text(
              'Exchange Confirmed! 🎉',
              style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.bold, color: DSColors.forestGreen),
            ),
            const SizedBox(height: 6),
            Text(
              'Handoff verified at Tactile Hub. Escrow deposit securely refunded.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 12, color: DSColors.textLight),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBBF7D0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Reader Passport Updated:', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF166534))),
                  const SizedBox(height: 4),
                  Text('• +1 Book Reused (${book['title']})', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF166534))),
                  Text('• +1 Successful Exchange Added', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF166534))),
                  Text('• ₹${book['value']} Community Savings Logged', style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF166534))),
                  Text('• Early Reader Badge Progress: 100% 🏆', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: const Color(0xFF166534))),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                context.push('/profile');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: DSColors.forestGreen,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 42),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DSRadius.md)),
              ),
              child: const Text('View in Reader Passport'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width <= 900;
    final selectedHub = _hubs[_selectedHubIndex];

    return Scaffold(
      backgroundColor: DSColors.background,
      appBar: AppBar(
        backgroundColor: DSColors.deepForestGreen,
        foregroundColor: Colors.white,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tactile Exchange Hubs',
              style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              'Safe, verified public community points with 24/7 smart lockers',
              style: GoogleFonts.inter(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: () => _showHowItWorksDialog(context),
            icon: const Icon(Icons.help_outline, color: Colors.white, size: 16),
            label: Text(
              'Why Use Hubs?',
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const FaIcon(FontAwesomeIcons.qrcode, size: 18),
            tooltip: 'Active QR Pass',
            onPressed: () => QRHandoffDialog.show(context, orderId: 101),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: isMobile
          ? Column(
              children: [
                _buildWhyHubBanner(context),
                _buildMapSearchAndFilters(context),
                Expanded(child: _buildVisualMap(selectedHub)),
                _buildHubDetailCard(context, selectedHub),
              ],
            )
          : Row(
              children: [
                SizedBox(
                  width: 440,
                  child: _buildSidebar(context),
                ),
                Expanded(
                  child: Stack(
                    children: [
                      _buildVisualMap(selectedHub),
                      // Floating map controls
                      Positioned(
                        top: 16,
                        right: 16,
                        child: _buildMapControls(),
                      ),
                      // Top info badge on desktop map
                      Positioned(
                        top: 16,
                        left: 16,
                        child: _buildMapQuickStatus(selectedHub),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildWhyHubBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: const Color(0xFFF0FDF4),
      child: Row(
        children: [
          const Icon(Icons.shield_outlined, color: Color(0xFF166534), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Verified safe handoffs • 24/7 smart lockers • Escrow protected',
              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF166534)),
            ),
          ),
          InkWell(
            onTap: () => _showHowItWorksDialog(context),
            child: Text(
              'How it works →',
              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: DSColors.deepForestGreen),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationDetectorBar(BuildContext context) {
    final nearestHub = _hubs[_nearestHubIndex];
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8F5),
        borderRadius: BorderRadius.circular(DSRadius.md),
        border: Border.all(color: const Color(0xFFC6E6D6)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: DSColors.deepForestGreen,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.near_me, color: Colors.white, size: 14),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      'YOUR LOCATION: ',
                      style: GoogleFonts.inter(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: DSColors.deepForestGreen,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        _userLocationName,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1F2937),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 1),
                Text(
                  'Closest hub: ${nearestHub['name'].toString().replaceAll('Tactile Hub — ', '')} (${nearestHub['distance']} away)',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF166534),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Detect GPS button
          InkWell(
            onTap: _isDetectingLocation ? null : _detectCurrentLocation,
            borderRadius: BorderRadius.circular(DSRadius.sm),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(DSRadius.sm),
                border: Border.all(color: DSColors.deepForestGreen),
              ),
              child: _isDetectingLocation
                  ? const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2, color: DSColors.deepForestGreen),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.my_location, size: 12, color: DSColors.deepForestGreen),
                        const SizedBox(width: 4),
                        Text(
                          'Detect',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: DSColors.deepForestGreen,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(width: 6),
          // Change Location button
          InkWell(
            onTap: () => _showAddOrChangeLocationDialog(context),
            borderRadius: BorderRadius.circular(DSRadius.sm),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: DSColors.deepForestGreen,
                borderRadius: BorderRadius.circular(DSRadius.sm),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add_location_alt, size: 12, color: Colors.white),
                  const SizedBox(width: 4),
                  Text(
                    'Add / Change',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMapSearchAndFilters(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
      child: Column(
        children: [
          _buildLocationDetectorBar(context),
          TextField(
            controller: _searchController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Search city, campus, or exchange hub...',
              hintStyle: GoogleFonts.inter(fontSize: 12, color: const Color(0xFFA0AEC0)),
              prefixIcon: const Icon(Icons.search, color: DSColors.deepForestGreen, size: 18),
              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      tooltip: 'Clear search query',
                      icon: const Icon(Icons.clear, size: 16),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    ),
                  IconButton(
                    icon: _isDetectingLocation
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: DSColors.deepForestGreen),
                          )
                        : const Icon(Icons.my_location, size: 16, color: DSColors.deepForestGreen),
                    tooltip: 'Detect GPS location',
                    onPressed: _isDetectingLocation ? null : _detectCurrentLocation,
                  ),
                ],
              ),
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DSRadius.md),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(DSRadius.md),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
          ),
          const SizedBox(height: 8),
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip('All', 'All Hubs (4)'),
                _buildFilterChip('Open', '🟢 Open Now'),
                _buildFilterChip('Lockers', '⚡ Smart Lockers'),
                _buildFilterChip('Campus', '🎓 Campus Hubs'),
                _buildFilterChip('Nearby', '📍 < 2 km'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String filterId, String label) {
    final isSelected = _selectedFilter == filterId;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500)),
        selected: isSelected,
        selectedColor: DSColors.deepForestGreen,
        backgroundColor: const Color(0xFFF1F5F9),
        labelStyle: TextStyle(color: isSelected ? Colors.white : const Color(0xFF334155)),
        onSelected: (val) {
          setState(() {
            _selectedFilter = filterId;
          });
        },
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Widget _buildSidebar(BuildContext context) {
    final hubs = _filteredHubs;

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWhyHubBanner(context),
          _buildMapSearchAndFilters(context),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Nearby Verified Hubs (${hubs.length})',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: DSColors.deepForestGreen,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFFE6F4EA), borderRadius: BorderRadius.circular(DSRadius.md)),
                  child: Text('CCTV Verified', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF166534))),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: hubs.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final hub = hubs[index];
                final realIndex = _hubs.indexOf(hub);
                final isSelected = realIndex == _selectedHubIndex;
                final statusColor = hub['statusColor'] as Color;

                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedHubIndex = realIndex;
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFFF0FDF4) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? DSColors.deepForestGreen : const Color(0xFFE2E8F0),
                        width: isSelected ? 1.5 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(color: DSColors.deepForestGreen.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 2)),
                            ]
                          : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (realIndex == _nearestHubIndex) ...[
                          Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF166534),
                              borderRadius: BorderRadius.circular(DSRadius.sm),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.near_me, color: Colors.white, size: 10),
                                const SizedBox(width: 4),
                                Text(
                                  'CLOSEST HUB TO YOU (${hub['distance']})',
                                  style: GoogleFonts.inter(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ],
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                hub['name'] as String,
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: DSColors.deepForestGreen,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${hub['status'] == 'Open' ? '🟢' : '🟡'} ${hub['status']}',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          hub['tagline'] as String,
                          style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF718096)),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.lock_open_outlined, size: 12, color: Color(0xFF166534)),
                            const SizedBox(width: 4),
                            Text(
                              '${hub['lockersAvailable']} / ${hub['lockersTotal']} Lockers Free',
                              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF166534)),
                            ),
                            const Spacer(),
                            Text(
                              '📍 ${hub['distance']} • ${hub['walkTime']}',
                              style: GoogleFonts.inter(fontSize: 10, color: DSColors.textMuted),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          _buildHubDetailCard(context, _hubs[_selectedHubIndex]),
        ],
      ),
    );
  }

  Widget _buildMapControls() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        children: [
          IconButton(
            icon: const Icon(Icons.add, size: 18, color: DSColors.deepForestGreen),
            tooltip: 'Zoom In',
            onPressed: () {
              setState(() {
                _zoomLevel = math.min(_zoomLevel + 0.2, 2.0);
              });
            },
          ),
          const Divider(height: 1),
          IconButton(
            icon: const Icon(Icons.remove, size: 18, color: DSColors.deepForestGreen),
            tooltip: 'Zoom Out',
            onPressed: () {
              setState(() {
                _zoomLevel = math.max(_zoomLevel - 0.2, 0.8);
              });
            },
          ),
          const Divider(height: 1),
          IconButton(
            icon: const Icon(Icons.my_location, size: 18, color: DSColors.deepForestGreen),
            tooltip: 'Recenter to My Location',
            onPressed: () {
              setState(() {
                _zoomLevel = 1.0;
                _selectedHubIndex = _nearestHubIndex;
              });
            },
          ),
          const Divider(height: 1),
          IconButton(
            icon: Icon(
              _showTransitOverlay ? Icons.subway : Icons.subway_outlined,
              size: 18,
              color: _showTransitOverlay ? DSColors.deepForestGreen : const Color(0xFF718096),
            ),
            tooltip: 'Toggle Transit Lines',
            onPressed: () {
              setState(() {
                _showTransitOverlay = !_showTransitOverlay;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMapQuickStatus(Map<String, dynamic> selectedHub) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(DSRadius.card),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: selectedHub['statusColor'] as Color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Focus: ${selectedHub['name']}',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: DSColors.deepForestGreen),
              ),
              Text(
                '${selectedHub['lockersAvailable']} Lockers Available • Open until ${selectedHub['hours'].split('-').last.trim()}',
                style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF718096)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVisualMap(Map<String, dynamic> selectedHub) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        return ClipRect(
          child: Container(
            color: const Color(0xFFF3EFE8),
            child: Stack(
              children: [
                // 1. Realistic Vector Map Canvas (Roads, Parks, Waterways, Metro Lines)
                Positioned.fill(
                  child: CustomPaint(
                    painter: _RealisticCityMapPainter(
                      zoom: _zoomLevel,
                      showTransit: _showTransitOverlay,
                    ),
                  ),
                ),

                // 2. User's Location Beacon ("You Are Here" - Dynamic GPS / Set Location)
                Positioned(
                  left: (w * _userRelX).clamp(24.0, math.max(24.0, w - 120.0)) - 14,
                  top: (h * _userRelY).clamp(24.0, math.max(24.0, h - 90.0)) - 14,
                  child: AnimatedBuilder(
                    animation: _pulseController,
                    builder: (context, child) {
                      return Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 28 + (16 * _pulseController.value),
                            height: 28 + (16 * _pulseController.value),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF2563EB).withValues(alpha: 1.0 - _pulseController.value),
                            ),
                          ),
                          Container(
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: const Color(0xFF1D4ED8),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2.5),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4),
                              ],
                            ),
                          ),
                          Positioned(
                            top: 22,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(DSRadius.sm),
                                border: Border.all(color: const Color(0xFF93C5FD)),
                                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 6)],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.my_location, size: 10, color: Color(0xFF1D4ED8)),
                                  const SizedBox(width: 4),
                                  Text(
                                    _userLocationName.length > 22
                                        ? '${_userLocationName.substring(0, 20)}...'
                                        : _userLocationName,
                                    style: GoogleFonts.inter(fontSize: 9.5, fontWeight: FontWeight.bold, color: const Color(0xFF1D4ED8)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),

                // 3. ALL 4 HUBS RENDERED INTERACTIVELY ON THE MAP
                ...List.generate(_hubs.length, (idx) {
                  final hub = _hubs[idx];
                  final isSelected = idx == _selectedHubIndex;
                  final relX = (hub['relX'] as double);
                  final relY = (hub['relY'] as double);
                  final posX = w * relX;
                  final posY = h * relY;

                  return Positioned(
                    left: posX - (isSelected ? 90 : 20),
                    top: posY - (isSelected ? 70 : 36),
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedHubIndex = idx;
                        });
                      },
                      child: isSelected
                          ? _buildSelectedHubMapCallout(hub)
                          : _buildUnselectedHubMarker(hub, idx + 1),
                    ),
                  );
                }),

                // 4. Bottom Safety & Escrow Banner
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.95),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6),
                      ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.verified_user, color: Color(0xFF166534), size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'All hubs are verified safe community points. Escrow locks your funds until contactless QR scan.',
                            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: const Color(0xFF2D3748)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: () => _showHowItWorksDialog(context),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: DSColors.deepForestGreen,
                            side: const BorderSide(color: DSColors.deepForestGreen),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            minimumSize: const Size(60, 28),
                          ),
                          child: Text('Why Hubs?', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSelectedHubMapCallout(Map<String, dynamic> hub) {
    final isClosest = _hubs.indexOf(hub) == _nearestHubIndex;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: DSColors.deepForestGreen,
            borderRadius: BorderRadius.circular(DSRadius.card),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 4)),
            ],
            border: Border.all(color: isClosest ? const Color(0xFF4ADE80) : const Color(0xFFD4AF37), width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isClosest) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF166534),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.near_me, color: Colors.white, size: 9),
                      const SizedBox(width: 4),
                      Text(
                        'CLOSEST TO YOU',
                        style: GoogleFonts.inter(fontSize: 8.5, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ],
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.verified, color: isClosest ? const Color(0xFF4ADE80) : const Color(0xFFD4AF37), size: 14),
                  const SizedBox(width: 6),
                  Text(
                    hub['name'] as String,
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '🟢 ${hub['lockersAvailable']} Lockers Free',
                    style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF86EFAC)),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '• ${hub['distance']}',
                    style: GoogleFonts.inter(fontSize: 10, color: Colors.white70),
                  ),
                ],
              ),
            ],
          ),
        ),
        CustomPaint(
          size: const Size(12, 6),
          painter: _TrianglePainter(color: DSColors.deepForestGreen),
        ),
        const Icon(Icons.location_on, color: DSColors.deepForestGreen, size: 36),
      ],
    );
  }

  Widget _buildUnselectedHubMarker(Map<String, dynamic> hub, int num) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFCBD5E1)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4),
            ],
          ),
          child: Text(
            hub['name'].toString().replaceAll('Tactile Hub — ', ''),
            style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: const Color(0xFF334155)),
          ),
        ),
        const SizedBox(height: 2),
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: DSColors.deepForestGreen,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4),
            ],
          ),
          child: Center(
            child: Text(
              '$num',
              style: GoogleFonts.inter(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHubDetailCard(BuildContext context, Map<String, dynamic> hub) {
    final instantBooks = (hub['instantBooks'] as List<String>? ?? []);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_hubs.indexOf(hub) == _nearestHubIndex) ...[
                      Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF166534),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.near_me, color: Colors.white, size: 10),
                            const SizedBox(width: 4),
                            Text(
                              'CLOSEST HUB TO YOUR LOCATION',
                              style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ],
                    Text(
                      hub['name'] as String,
                      style: GoogleFonts.playfairDisplay(fontSize: 17, fontWeight: FontWeight.bold, color: DSColors.deepForestGreen),
                    ),
                    Text(
                      hub['address'] as String,
                      style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF718096)),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                ),
                child: Text(
                  hub['distance'] as String,
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF166534)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Real-time capacity bar
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (hub['lockersAvailable'] as int) / (hub['lockersTotal'] as int),
                    backgroundColor: const Color(0xFFE2E8F0),
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF166534)),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${hub['lockersAvailable']} of ${hub['lockersTotal']} Smart Lockers Free',
                style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF166534)),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Transit info
          Row(
            children: [
              const Icon(Icons.directions_subway_outlined, size: 14, color: Color(0xFF718096)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  hub['transit'] as String,
                  style: GoogleFonts.inter(fontSize: 11, color: DSColors.textMuted),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Instant books in this hub
          if (instantBooks.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Icons.flash_on, size: 13, color: Color(0xFFD97706)),
                const SizedBox(width: 4),
                Text(
                  'In-Stock for Instant Pickup:',
                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: const Color(0xFF475569)),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: instantBooks.map((title) {
                        return Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            title,
                            style: GoogleFonts.inter(fontSize: 10, color: const Color(0xFF1E293B)),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          // Action button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _startExchangeWizard(context, hub),
              style: ElevatedButton.styleFrom(
                backgroundColor: DSColors.deepForestGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              icon: const Icon(Icons.handshake_outlined, size: 16),
              label: Text(
                'Exchange Book at This Hub',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}

class _RealisticCityMapPainter extends CustomPainter {
  final double zoom;
  final bool showTransit;

  _RealisticCityMapPainter({required this.zoom, required this.showTransit});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Background Canvas
    final bgPaint = Paint()..color = const Color(0xFFF4F0E8);
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    // City Blocks
    final blockPaint = Paint()..color = const Color(0xFFE9E4DA);
    for (double i = 20; i < w; i += 90) {
      for (double j = 20; j < h; j += 80) {
        final r = RRect.fromRectAndRadius(
          Rect.fromLTWH(i, j, 70, 60),
          const Radius.circular(6),
        );
        canvas.drawRRect(r, blockPaint);
      }
    }

    // River / Canal Ribbon
    final riverPaint = Paint()
      ..color = const Color(0xFFD7E6F0)
      ..strokeWidth = 24
      ..style = PaintingStyle.stroke;

    final riverPath = Path()
      ..moveTo(0, h * 0.75)
      ..cubicTo(w * 0.35, h * 0.85, w * 0.55, h * 0.60, w, h * 0.70);
    canvas.drawPath(riverPath, riverPaint);

    // Green Parks & Gardens
    final parkPaint = Paint()..color = const Color(0xFFD4E7D6);
    // Park 1: Botanical Garden (top right)
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.65, h * 0.15, w * 0.28, h * 0.25), const Radius.circular(16)),
      parkPaint,
    );
    // Park 2: Campus Lawn (bottom right)
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.60, h * 0.60, w * 0.25, h * 0.22), const Radius.circular(16)),
      parkPaint,
    );

    // Arterial Roads (Crisp White with subtle borders)
    final roadBorder = Paint()
      ..color = const Color(0xFFD9D3C7)
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke;

    final roadSurface = Paint()
      ..color = Colors.white
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke;

    // Westgate Blvd (Horizontal main avenue)
    final p1 = Path()
      ..moveTo(0, h * 0.45)
      ..lineTo(w, h * 0.45);
    canvas.drawPath(p1, roadBorder);
    canvas.drawPath(p1, roadSurface);

    // Central Diagonal Avenue
    final p2 = Path()
      ..moveTo(w * 0.15, 0)
      ..lineTo(w * 0.85, h);
    canvas.drawPath(p2, roadBorder);
    canvas.drawPath(p2, roadSurface);

    // Tech Park Boulevard (Vertical)
    final p3 = Path()
      ..moveTo(w * 0.35, 0)
      ..lineTo(w * 0.35, h);
    canvas.drawPath(p3, roadBorder);
    canvas.drawPath(p3, roadSurface);

    // Secondary streets
    final secRoad = Paint()
      ..color = Colors.white
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(0, h * 0.25), Offset(w, h * 0.25), secRoad);
    canvas.drawLine(Offset(0, h * 0.65), Offset(w, h * 0.65), secRoad);
    canvas.drawLine(Offset(w * 0.60, 0), Offset(w * 0.60, h), secRoad);

    // Walking Distance Radius Circles around User Location (Center 0.48, 0.52)
    final radiusPaint = Paint()
      ..color = DSColors.deepForestGreen.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawCircle(Offset(w * 0.48, h * 0.52), 90 * zoom, radiusPaint);
    canvas.drawCircle(Offset(w * 0.48, h * 0.52), 180 * zoom, radiusPaint);

    // Metro Line (if enabled)
    if (showTransit) {
      final transitPaint = Paint()
        ..color = const Color(0xFF0284C7)
        ..strokeWidth = 4
        ..style = PaintingStyle.stroke;

      final metroPath = Path()
        ..moveTo(0, h * 0.35)
        ..cubicTo(w * 0.30, h * 0.35, w * 0.50, h * 0.55, w, h * 0.55);

      canvas.drawPath(metroPath, transitPaint);

      // Metro Station Nodes
      final stationPaint = Paint()..color = const Color(0xFF0369A1);
      final whitePaint = Paint()..color = Colors.white;

      for (final pt in [
        Offset(w * 0.18, h * 0.35),
        Offset(w * 0.42, h * 0.46),
        Offset(w * 0.75, h * 0.55),
      ]) {
        canvas.drawCircle(pt, 6, stationPaint);
        canvas.drawCircle(pt, 3, whitePaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _RealisticCityMapPainter oldDelegate) {
    return oldDelegate.zoom != zoom || oldDelegate.showTransit != showTransit;
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;

  _TrianglePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
