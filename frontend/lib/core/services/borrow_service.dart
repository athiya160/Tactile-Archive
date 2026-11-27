import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum BorrowStage {
  compose, // Step 1: Compose note (address hidden)
  pending, // Step 2: Request sent, awaiting owner approval (address locked)
  accepted, // Step 3: Owner accepted! Address bar unlocked
  confirmed, // Handover finalized & address shared
}

class BorrowRequestRecord {
  final String requestId;
  final String bookId;
  final String bookTitle;
  final String bookAuthor;
  final String bookCoverUrl;
  final String ownerName;
  final int durationDays;
  final String message;
  final DateTime createdAt;
  BorrowStage stage;
  String? deliveryMethod;
  String? deliveryAddress;
  String? recipientName;
  String? recipientPhone;
  DateTime? acceptedAt;
  DateTime? confirmedAt;

  BorrowRequestRecord({
    required this.requestId,
    required this.bookId,
    required this.bookTitle,
    required this.bookAuthor,
    required this.bookCoverUrl,
    required this.ownerName,
    required this.durationDays,
    required this.message,
    required this.createdAt,
    this.stage = BorrowStage.pending,
    this.deliveryMethod,
    this.deliveryAddress,
    this.recipientName,
    this.recipientPhone,
    this.acceptedAt,
    this.confirmedAt,
  });

  Map<String, dynamic> toJson() => {
    'requestId': requestId,
    'bookId': bookId,
    'bookTitle': bookTitle,
    'bookAuthor': bookAuthor,
    'bookCoverUrl': bookCoverUrl,
    'ownerName': ownerName,
    'durationDays': durationDays,
    'message': message,
    'createdAt': createdAt.toIso8601String(),
    'stage': stage.name,
    'deliveryMethod': deliveryMethod,
    'deliveryAddress': deliveryAddress,
    'recipientName': recipientName,
    'recipientPhone': recipientPhone,
    'acceptedAt': acceptedAt?.toIso8601String(),
    'confirmedAt': confirmedAt?.toIso8601String(),
  };

  factory BorrowRequestRecord.fromJson(Map<String, dynamic> json) {
    BorrowStage parseStage(String? val) {
      switch (val) {
        case 'pending':
          return BorrowStage.pending;
        case 'accepted':
          return BorrowStage.accepted;
        case 'confirmed':
          return BorrowStage.confirmed;
        default:
          return BorrowStage.compose;
      }
    }

    return BorrowRequestRecord(
      requestId: json['requestId'] as String? ?? 'REQ-2026-8941',
      bookId: json['bookId'] as String? ?? '',
      bookTitle: json['bookTitle'] as String? ?? '',
      bookAuthor: json['bookAuthor'] as String? ?? '',
      bookCoverUrl: json['bookCoverUrl'] as String? ?? '',
      ownerName: json['ownerName'] as String? ?? 'Rahul Sharma',
      durationDays: (json['durationDays'] as num?)?.toInt() ?? 14,
      message: json['message'] as String? ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      stage: parseStage(json['stage'] as String?),
      deliveryMethod: json['deliveryMethod'] as String?,
      deliveryAddress: json['deliveryAddress'] as String?,
      recipientName: json['recipientName'] as String?,
      recipientPhone: json['recipientPhone'] as String?,
      acceptedAt: json['acceptedAt'] != null ? DateTime.tryParse(json['acceptedAt'] as String) : null,
      confirmedAt: json['confirmedAt'] != null ? DateTime.tryParse(json['confirmedAt'] as String) : null,
    );
  }
}

class BorrowService {
  static const String _storageKey = 'tactile_borrow_requests_v3';
  static final Map<String, BorrowRequestRecord> _requests = {};
  static bool _initialized = false;
  static final ValueNotifier<int> changeNotifier = ValueNotifier<int>(0);

  static String _normalizeKey(String? bookId, String? bookTitle) {
    if (bookId != null && bookId.trim().isNotEmpty) {
      return bookId.trim().toLowerCase();
    }
    return (bookTitle ?? '').trim().toLowerCase();
  }

  static Future<void> init() async {
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> list = jsonDecode(raw);
        _requests.clear();
        for (final item in list) {
          if (item is Map<String, dynamic>) {
            final rec = BorrowRequestRecord.fromJson(item);
            final key = _normalizeKey(rec.bookId, rec.bookTitle);
            if (key.isNotEmpty) {
              _requests[key] = rec;
            }
          }
        }
      }

      // Pre-seed "Thinking, Fast and Slow" as pending so the user's previously sent message is immediately recognized
      const tfsKey = 'thinking, fast and slow';
      if (!_requests.containsKey(tfsKey)) {
        final preseedRecord = BorrowRequestRecord(
          requestId: 'REQ-2026-8941',
          bookId: 'tfs-1',
          bookTitle: 'Thinking, Fast and Slow',
          bookAuthor: 'Daniel Kahneman',
          bookCoverUrl: 'https://images-na.ssl-images-amazon.com/images/I/61fdrEuPJwL.jpg',
          ownerName: 'Rahul Sharma',
          durationDays: 14,
          message:
              'Hi Rahul! I\'m preparing for my exams and would love to borrow your copy of "Thinking, Fast and Slow" for 14 days. I promise to take great care of it and return it on time!',
          createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
          stage: BorrowStage.pending,
        );
        _requests[tfsKey] = preseedRecord;
        _requests['tfs-1'] = preseedRecord;
      }
    } catch (_) {}
    _initialized = true;
  }

  static BorrowRequestRecord? getRequestForBook(String? bookId, String? bookTitle) {
    final key1 = _normalizeKey(bookId, null);
    if (key1.isNotEmpty && _requests.containsKey(key1)) {
      return _requests[key1];
    }
    final key2 = _normalizeKey(null, bookTitle);
    if (key2.isNotEmpty && _requests.containsKey(key2)) {
      return _requests[key2];
    }
    return null;
  }

  static bool hasActiveRequest(String? bookId, String? bookTitle) {
    final req = getRequestForBook(bookId, bookTitle);
    return req != null && req.stage != BorrowStage.compose;
  }

  static Future<BorrowRequestRecord> saveRequest({
    required String bookId,
    required String bookTitle,
    required String bookAuthor,
    required String bookCoverUrl,
    required String ownerName,
    required int durationDays,
    required String message,
    BorrowStage stage = BorrowStage.pending,
  }) async {
    await init();
    final existing = getRequestForBook(bookId, bookTitle);
    final reqId = existing?.requestId ?? 'REQ-2026-${(1000 + _requests.length * 137) % 9000}';
    final record = BorrowRequestRecord(
      requestId: reqId,
      bookId: bookId,
      bookTitle: bookTitle,
      bookAuthor: bookAuthor,
      bookCoverUrl: bookCoverUrl,
      ownerName: ownerName,
      durationDays: durationDays,
      message: message,
      createdAt: existing?.createdAt ?? DateTime.now(),
      stage: stage,
      deliveryMethod: existing?.deliveryMethod,
      deliveryAddress: existing?.deliveryAddress,
      recipientName: existing?.recipientName,
      recipientPhone: existing?.recipientPhone,
      acceptedAt: existing?.acceptedAt,
      confirmedAt: existing?.confirmedAt,
    );

    final key1 = _normalizeKey(bookId, null);
    if (key1.isNotEmpty) _requests[key1] = record;
    final key2 = _normalizeKey(null, bookTitle);
    if (key2.isNotEmpty) _requests[key2] = record;

    await _persist();
    changeNotifier.value++;
    return record;
  }

  static Future<void> updateStage(
    String? bookId,
    String? bookTitle,
    BorrowStage stage, {
    String? deliveryMethod,
    String? deliveryAddress,
    String? recipientName,
    String? recipientPhone,
  }) async {
    await init();
    final req = getRequestForBook(bookId, bookTitle);
    if (req != null) {
      req.stage = stage;
      if (stage == BorrowStage.accepted && req.acceptedAt == null) {
        req.acceptedAt = DateTime.now();
      }
      if (stage == BorrowStage.confirmed) {
        req.confirmedAt = DateTime.now();
        if (deliveryMethod != null) req.deliveryMethod = deliveryMethod;
        if (deliveryAddress != null) req.deliveryAddress = deliveryAddress;
        if (recipientName != null) req.recipientName = recipientName;
        if (recipientPhone != null) req.recipientPhone = recipientPhone;
      }
      await _persist();
      changeNotifier.value++;
    }
  }

  static Future<void> cancelRequest(String? bookId, String? bookTitle) async {
    await init();
    final key1 = _normalizeKey(bookId, null);
    final key2 = _normalizeKey(null, bookTitle);
    _requests.remove(key1);
    _requests.remove(key2);
    await _persist();
    changeNotifier.value++;
  }

  static List<BorrowRequestRecord> getAllRequests() {
    return _requests.values.toSet().toList();
  }

  static Future<void> _persist() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _requests.values.toSet().map((r) => r.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(list));
    } catch (_) {}
  }
}
