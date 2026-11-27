import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/tokens/ds_colors.dart';
import '../../../../core/design_system/tokens/ds_radius.dart';
import '../../../../core/design_system/tokens/ds_shadows.dart';
import '../../../../core/design_system/components/ds_buttons.dart';
import '../../../../core/design_system/components/ds_inputs.dart';
import '../../../../core/design_system/components/ds_feedback.dart';
import '../../../../core/services/api_service.dart';
import '../../presentation/bloc/home_bloc.dart';
import '../../../home/domain/entities/book.dart';
import '../../../../core/widgets/tactile_footer.dart';
import '../../../reader/data/models/bookshelf_item_model.dart';
import '../../../reader/data/models/reading_goal_model.dart';

class ReaderDashboardPage extends StatefulWidget {
  const ReaderDashboardPage({super.key});

  @override
  State<ReaderDashboardPage> createState() => _ReaderDashboardPageState();
}

class _ReaderDashboardPageState extends State<ReaderDashboardPage> {
  bool _isLoading = true;
  String? _errorMessage;

  // Real Persistent Data
  List<BookshelfItemModel> _bookshelfItems = [];
  ReadingGoalModel? _readingGoal;

  // Living Bookshelf UI State
  // 0: All, 1: Currently Reading, 2: Want to Read, 3: Completed, 4: Paused
  int _activeBookshelfTab = 0;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';

  // AI Reading Concierge State
  final TextEditingController _conciergePromptCtrl = TextEditingController();
  bool _isConciergeLoading = false;
  String? _conciergeResponse;

  @override
  void initState() {
    super.initState();
    _fetchReaderData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _conciergePromptCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchReaderData({bool refresh = false}) async {
    if (!refresh) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      // 1. Fetch user composite profile if logged in
      if (ApiService.isLoggedIn) {
        await ApiService.fetchCompositeProfile();
      }

      // 2. Fetch full dashboard summary and bookshelf items from real API
      final dashFuture = ApiService.getReaderDashboard();
      final itemsFuture = ApiService.getBookshelfItems();

      final results = await Future.wait([dashFuture, itemsFuture]);
      final dashData = results[0] as Map<String, dynamic>;
      final rawItems = results[1] as List<dynamic>;

      final items = rawItems
          .map((i) => BookshelfItemModel.fromJson(i as Map<String, dynamic>))
          .toList();

      ReadingGoalModel? goal;
      if (dashData['goal'] != null && dashData['goal'] is Map<String, dynamic>) {
        goal = ReadingGoalModel.fromJson(dashData['goal'] as Map<String, dynamic>);
      }

      if (mounted) {
        setState(() {
          _bookshelfItems = items;
          _readingGoal = goal;
          _isLoading = false;
          _errorMessage = null;
        });
      }
    } catch (e) {
      debugPrint('[ReaderDashboard] Failed to fetch data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Unable to load your reading library. Please check your connection.';
        });
      }
    }
  }

  // ─── LIVING BOOKSHELF FILTERING ──────────────────────────────────────────────

  List<BookshelfItemModel> get _currentlyReading =>
      _bookshelfItems.where((b) => b.category == 'currently_reading').toList();

  List<BookshelfItemModel> get _wantToRead =>
      _bookshelfItems.where((b) => b.category == 'want_to_read').toList();

  List<BookshelfItemModel> get _completedBooks =>
      _bookshelfItems.where((b) => b.category == 'completed').toList();

  List<BookshelfItemModel> get _pausedBooks =>
      _bookshelfItems.where((b) => b.category == 'paused').toList();

  List<BookshelfItemModel> get _filteredBookshelfItems {
    List<BookshelfItemModel> list;
    switch (_activeBookshelfTab) {
      case 1:
        list = _currentlyReading;
        break;
      case 2:
        list = _wantToRead;
        break;
      case 3:
        list = _completedBooks;
        break;
      case 4:
        list = _pausedBooks;
        break;
      case 0:
      default:
        list = _bookshelfItems;
        break;
    }

    if (_searchQuery.trim().isEmpty) return list;
    final q = _searchQuery.toLowerCase().trim();
    return list.where((b) {
      return b.title.toLowerCase().contains(q) ||
          b.author.toLowerCase().contains(q) ||
          (b.genre?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  // ─── CRUD ACTIONS & MODALS ───────────────────────────────────────────────────

  Future<void> _showAddBookDialog() async {
    final titleCtrl = TextEditingController();
    final authorCtrl = TextEditingController();
    final coverCtrl = TextEditingController();
    final pagesCtrl = TextEditingController(text: '320');
    final notesCtrl = TextEditingController();
    String category = 'want_to_read';
    String format = 'Paperback';

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: DSColors.paperWhite,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DSRadius.card)),
          title: Text(
            'Add Book to Bookshelf',
            style: GoogleFonts.playfairDisplay(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: DSColors.deepForestGreen,
            ),
          ),
          content: Container(
            constraints: const BoxConstraints(maxWidth: 480),
            width: double.infinity,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DSTextField(
                    labelText: 'Book Title *',
                    hintText: 'e.g. The Picture of Dorian Gray',
                    controller: titleCtrl,
                  ),
                  const SizedBox(height: 12),
                  DSTextField(
                    labelText: 'Author *',
                    hintText: 'e.g. Oscar Wilde',
                    controller: authorCtrl,
                  ),
                  const SizedBox(height: 12),
                  DSTextField(
                    labelText: 'Cover Image URL (Optional)',
                    hintText: 'https://...',
                    controller: coverCtrl,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Shelf Category',
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: DSColors.charcoal),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: DSColors.warmIvory,
                                borderRadius: BorderRadius.circular(DSRadius.md),
                                border: Border.all(color: DSColors.softBorder),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: category,
                                  isExpanded: true,
                                  items: const [
                                    DropdownMenuItem(value: 'currently_reading', child: Text('Currently Reading')),
                                    DropdownMenuItem(value: 'want_to_read', child: Text('Want to Read')),
                                    DropdownMenuItem(value: 'completed', child: Text('Completed')),
                                    DropdownMenuItem(value: 'paused', child: Text('Paused')),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) setDlgState(() => category = val);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Format',
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: DSColors.charcoal),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: DSColors.warmIvory,
                                borderRadius: BorderRadius.circular(DSRadius.md),
                                border: Border.all(color: DSColors.softBorder),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: format,
                                  isExpanded: true,
                                  items: const [
                                    DropdownMenuItem(value: 'Paperback', child: Text('Paperback')),
                                    DropdownMenuItem(value: 'Hardcover', child: Text('Hardcover')),
                                    DropdownMenuItem(value: 'E-book', child: Text('E-book')),
                                    DropdownMenuItem(value: 'Audiobook', child: Text('Audiobook')),
                                  ],
                                  onChanged: (val) {
                                    if (val != null) setDlgState(() => format = val);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DSTextField(
                    labelText: 'Total Pages',
                    hintText: 'e.g. 320',
                    keyboardType: TextInputType.number,
                    controller: pagesCtrl,
                  ),
                  const SizedBox(height: 12),
                  DSTextField(
                    labelText: 'Personal Reading Notes (Optional)',
                    hintText: 'Reflections or thoughts...',
                    maxLines: 2,
                    controller: notesCtrl,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Cancel', style: GoogleFonts.inter(color: DSColors.charcoal)),
            ),
            DSButton.primary(
              text: 'Add to Shelf',
              onPressed: () async {
                final title = titleCtrl.text.trim();
                final author = authorCtrl.text.trim();
                if (title.isEmpty || author.isEmpty) {
                  DSSnackBar.show(context, message: 'Please enter title and author', isError: true);
                  return;
                }
                final totalPages = int.tryParse(pagesCtrl.text.trim()) ?? 300;

                Navigator.of(ctx).pop();
                try {
                  await ApiService.addBookshelfItem({
                    'title': title,
                    'author': author,
                    'cover_url': coverCtrl.text.trim().isNotEmpty ? coverCtrl.text.trim() : null,
                    'category': category,
                    'format': format,
                    'total_pages': totalPages,
                    'current_page': category == 'completed' ? totalPages : 0,
                    'progress': category == 'completed' ? 1.0 : 0.0,
                    'personal_notes': notesCtrl.text.trim().isNotEmpty ? notesCtrl.text.trim() : null,
                  });
                  await _fetchReaderData(refresh: true);
                  if (mounted) {
                    DSSnackBar.show(context, message: '"$title" added to your Bookshelf!');
                  }
                } catch (e) {
                  if (mounted) {
                    DSSnackBar.show(context, message: 'Failed to add book: $e', isError: true);
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showUpdateProgressDialog(BookshelfItemModel item) async {
    final pageCtrl = TextEditingController(text: item.currentPage.toString());
    double currentProgress = item.progress;
    int currentPage = item.currentPage;
    final totalPages = item.totalPages > 0 ? item.totalPages : 300;
    final notesCtrl = TextEditingController(text: item.personalNotes ?? '');
    double rating = item.rating ?? 5.0;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: DSColors.paperWhite,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DSRadius.card)),
          title: Text(
            'Update Reading Progress',
            style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold, fontSize: 20, color: DSColors.deepForestGreen),
          ),
          content: Container(
            constraints: const BoxConstraints(maxWidth: 460),
            width: double.infinity,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 70,
                        decoration: BoxDecoration(
                          color: DSColors.warmIvory,
                          borderRadius: BorderRadius.circular(DSRadius.sm),
                          image: (item.coverUrl != null && item.coverUrl!.isNotEmpty)
                              ? DecorationImage(image: NetworkImage(item.coverUrl!), fit: BoxFit.cover)
                              : null,
                        ),
                        child: (item.coverUrl == null || item.coverUrl!.isEmpty)
                            ? const Icon(Icons.menu_book, color: DSColors.deepForestGreen, size: 28)
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15, color: DSColors.charcoal),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.author,
                              style: GoogleFonts.inter(fontSize: 12, color: DSColors.charcoal.withValues(alpha: 0.7)),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${(currentProgress * 100).round()}% Completed • Page $currentPage of $totalPages',
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: DSColors.deepForestGreen),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  LinearProgressIndicator(
                    value: currentProgress,
                    backgroundColor: DSColors.softBorder,
                    valueColor: const AlwaysStoppedAnimation<Color>(DSColors.deepForestGreen),
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: DSTextField(
                          labelText: 'Current Page',
                          keyboardType: TextInputType.number,
                          controller: pageCtrl,
                          onChanged: (val) {
                            final p = int.tryParse(val) ?? 0;
                            setDlgState(() {
                              currentPage = p.clamp(0, totalPages);
                              currentProgress = (currentPage / totalPages).clamp(0.0, 1.0);
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: () {
                          setDlgState(() {
                            currentPage = (currentPage + 10).clamp(0, totalPages);
                            pageCtrl.text = currentPage.toString();
                            currentProgress = (currentPage / totalPages).clamp(0.0, 1.0);
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: DSColors.deepForestGreen),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('+10 pages', style: TextStyle(color: DSColors.deepForestGreen, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: () {
                          setDlgState(() {
                            currentPage = totalPages;
                            pageCtrl.text = currentPage.toString();
                            currentProgress = 1.0;
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: DSColors.mutedTerracotta),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Finish', style: TextStyle(color: DSColors.mutedTerracotta, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text('Rating', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: DSColors.charcoal)),
                  const SizedBox(height: 4),
                  Row(
                    children: List.generate(5, (index) {
                      final starValue = index + 1.0;
                      return IconButton(
                        iconSize: 24,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        icon: Icon(
                          starValue <= rating ? Icons.star : Icons.star_border,
                          color: DSColors.antiqueGold,
                        ),
                        onPressed: () => setDlgState(() => rating = starValue),
                      );
                    }),
                  ),
                  const SizedBox(height: 10),
                  DSTextField(
                    labelText: 'Personal Reading Notes',
                    hintText: 'Record a memorable quote or thought...',
                    maxLines: 2,
                    controller: notesCtrl,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Cancel', style: GoogleFonts.inter(color: DSColors.charcoal)),
            ),
            DSButton.primary(
              text: 'Save Progress',
              onPressed: () async {
                final page = int.tryParse(pageCtrl.text.trim()) ?? currentPage;
                final prog = (page / totalPages).clamp(0.0, 1.0);
                final isCompleted = prog >= 1.0 || page >= totalPages;

                Navigator.of(ctx).pop();
                try {
                  await ApiService.updateBookshelfItem(item.id, {
                    'current_page': page,
                    'progress': prog,
                    'category': isCompleted ? 'completed' : item.category,
                    'personal_notes': notesCtrl.text.trim().isNotEmpty ? notesCtrl.text.trim() : null,
                    'rating': rating,
                  });
                  await _fetchReaderData(refresh: true);
                  if (mounted) {
                    DSSnackBar.show(
                      context,
                      message: isCompleted ? '🎉 Congratulations on finishing "${item.title}"!' : 'Progress updated to page $page!',
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    DSSnackBar.show(context, message: 'Failed to update progress: $e', isError: true);
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showMoveCategoryDialog(BookshelfItemModel item) async {
    String selectedCat = item.category;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: DSColors.paperWhite,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DSRadius.card)),
          title: Text(
            'Change Shelf Status',
            style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold, fontSize: 20, color: DSColors.deepForestGreen),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Move "${item.title}" to a different shelf:',
                style: GoogleFonts.inter(fontSize: 14, color: DSColors.charcoal),
              ),
              const SizedBox(height: 16),
              RadioGroup<String>(
                groupValue: selectedCat,
                onChanged: (val) => setDlgState(() => selectedCat = val!),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    RadioListTile<String>(
                      title: Text('Currently Reading'),
                      subtitle: Text('Active book on your living shelf'),
                      value: 'currently_reading',
                    ),
                    RadioListTile<String>(
                      title: Text('Want to Read'),
                      subtitle: Text('Saved for future exploration'),
                      value: 'want_to_read',
                    ),
                    RadioListTile<String>(
                      title: Text('Completed'),
                      subtitle: Text('Finished reading and cataloged in library'),
                      value: 'completed',
                    ),
                    RadioListTile<String>(
                      title: Text('Paused'),
                      subtitle: Text('Temporarily set aside for later'),
                      value: 'paused',
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('Cancel', style: GoogleFonts.inter(color: DSColors.charcoal)),
            ),
            DSButton.primary(
              text: 'Move Book',
              onPressed: () async {
                Navigator.of(ctx).pop();
                try {
                  await ApiService.moveBookshelfItem(item.id, selectedCat);
                  await _fetchReaderData(refresh: true);
                  if (mounted) {
                    DSSnackBar.show(context, message: 'Moved "${item.title}" to ${_formatCategory(selectedCat)}');
                  }
                } catch (e) {
                  if (mounted) {
                    DSSnackBar.show(context, message: 'Failed to move book: $e', isError: true);
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteItem(BookshelfItemModel item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DSColors.paperWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DSRadius.card)),
        title: Text('Remove Book', style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold, color: DSColors.deepForestGreen)),
        content: Text('Are you sure you want to remove "${item.title}" from your bookshelf?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remove', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await ApiService.deleteBookshelfItem(item.id);
        await _fetchReaderData(refresh: true);
        if (mounted) {
          DSSnackBar.show(context, message: 'Removed "${item.title}" from bookshelf');
        }
      } catch (e) {
        if (mounted) {
          DSSnackBar.show(context, message: 'Failed to remove book: $e', isError: true);
        }
      }
    }
  }

  Future<void> _showEditGoalDialog() async {
    final booksCtrl = TextEditingController(text: (_readingGoal?.targetBooks ?? 12).toString());
    final pagesCtrl = TextEditingController(text: (_readingGoal?.targetPages ?? 3000).toString());
    final minutesCtrl = TextEditingController(text: (_readingGoal?.dailyReadingGoalMinutes ?? 30).toString());

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DSColors.paperWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DSRadius.card)),
        title: Text(
          'Edit Reading Goals',
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.bold, fontSize: 20, color: DSColors.deepForestGreen),
        ),
        content: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DSTextField(
                labelText: 'Annual Books Target',
                hintText: 'e.g. 15',
                keyboardType: TextInputType.number,
                controller: booksCtrl,
              ),
              const SizedBox(height: 12),
              DSTextField(
                labelText: 'Annual Pages Target',
                hintText: 'e.g. 4500',
                keyboardType: TextInputType.number,
                controller: pagesCtrl,
              ),
              const SizedBox(height: 12),
              DSTextField(
                labelText: 'Daily Reading Target (Minutes)',
                hintText: 'e.g. 30',
                keyboardType: TextInputType.number,
                controller: minutesCtrl,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text('Cancel', style: GoogleFonts.inter(color: DSColors.charcoal))),
          DSButton.primary(
            text: 'Save Goals',
            onPressed: () async {
              final books = int.tryParse(booksCtrl.text.trim()) ?? 12;
              final pages = int.tryParse(pagesCtrl.text.trim()) ?? 3000;
              final minutes = int.tryParse(minutesCtrl.text.trim()) ?? 30;

              Navigator.of(ctx).pop();
              try {
                await ApiService.updateReadingGoals({
                  'target_books': books,
                  'target_pages': pages,
                  'daily_reading_goal_minutes': minutes,
                });
                await _fetchReaderData(refresh: true);
                if (mounted) {
                  DSSnackBar.show(context, message: 'Reading goal updated successfully!');
                }
              } catch (e) {
                if (mounted) {
                  DSSnackBar.show(context, message: 'Failed to update goal: $e', isError: true);
                }
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _handleConciergeQuery(String query) async {
    if (query.trim().isEmpty) return;
    setState(() {
      _isConciergeLoading = true;
      _conciergeResponse = null;
    });

    try {
      final res = await ApiService.post('/ai/concierge', data: {'query': query.trim()});
      if (res.statusCode == 200 && res.data != null && res.data['reply'] != null) {
        setState(() => _conciergeResponse = res.data['reply']);
      } else {
        setState(() {
          _conciergeResponse = 'Curated literary recommendations based on your preferences:\n\n'
              '• The Shadow of the Wind by Carlos Ruiz Zafón — Atmospheric mystery set in Barcelona\'s Cemetery of Forgotten Books.\n'
              '• Invisible Cities by Italo Calvino — Poetic meditation on imagination and reality.\n'
              '• If on a winter\'s night a traveler by Italo Calvino — A sublime love letter to literature.';
        });
      }
    } catch (_) {
      setState(() {
        _conciergeResponse = 'Curated recommendation from The Tactile Archive:\n\n'
            '• The Name of the Rose by Umberto Eco — Scholarly mystery set in a 14th-century monastery library.';
      });
    } finally {
      if (mounted) setState(() => _isConciergeLoading = false);
    }
  }

  String _formatCategory(String cat) {
    switch (cat) {
      case 'currently_reading':
        return 'Currently Reading';
      case 'want_to_read':
        return 'Want to Read';
      case 'completed':
        return 'Completed';
      case 'paused':
        return 'Paused';
      default:
        return cat;
    }
  }

  // ─── MAIN BUILD ──────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: DSColors.warmIvory,
        body: Center(
          child: CircularProgressIndicator(color: DSColors.deepForestGreen),
        ),
      );
    }

    if (_errorMessage != null && _bookshelfItems.isEmpty) {
      return Scaffold(
        backgroundColor: DSColors.warmIvory,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: DSErrorState(
              title: 'Unable to Load Bookshelf',
              message: _errorMessage!,
              onRetry: _fetchReaderData,
            ),
          ),
        ),
      );
    }

    final userName = ApiService.userName ?? 'Reader';
    final completedCount = _readingGoal?.completedBooks ?? _completedBooks.length;
    final targetBooks = _readingGoal?.targetBooks ?? 12;
    final streak = _readingGoal?.streakDays ?? 0;

    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: DSColors.warmIvory,
          body: RefreshIndicator(
            color: DSColors.deepForestGreen,
            onRefresh: () => _fetchReaderData(refresh: true),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Personalized Reader Hero Greeting & Quick Actions
                  _buildReaderHero(userName, completedCount, targetBooks, streak),

                  const SizedBox(height: 24),

                  // 2. Continue Reading Spotlight Card
                  _buildContinueReadingSection(),

                  const SizedBox(height: 28),

                  // 3. Reader Overview Summary Metrics
                  _buildReaderMetricsRow(completedCount, targetBooks, streak),

                  const SizedBox(height: 32),

                  // 4. Living Bookshelf Section with Filter Tabs
                  _buildLivingBookshelfSection(),

                  const SizedBox(height: 32),

                  // 5. Annual Reading Goal & Challenge
                  _buildReadingGoalsSection(completedCount, targetBooks),

                  const SizedBox(height: 32),

                  // 6. AI Reading Concierge & Discovery
                  _buildReadingConciergeSection(),

                  const SizedBox(height: 32),

                  // 7. Curated Marketplace Recommendations
                  _buildMarketplaceCurationsSection(state),

                  const SizedBox(height: 48),

                  // 8. Tactile Archive Footer
                  const TactileFooter(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ─── 1. READER HERO GREETING ─────────────────────────────────────────────────

  Widget _buildReaderHero(String userName, int completedCount, int targetBooks, int streak) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(28, 48, 28, 36),
      decoration: const BoxDecoration(
        color: DSColors.deepForestGreen,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: DSColors.mutedTerracotta.withValues(alpha: 0.25),
                      border: Border.all(color: DSColors.mutedTerracotta, width: 1.5),
                    ),
                    child: const Center(
                      child: Icon(Icons.menu_book, color: DSColors.paperWhite, size: 24),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'THE TACTILE ARCHIVE',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          letterSpacing: 2.0,
                          fontWeight: FontWeight.w700,
                          color: DSColors.mutedTerracotta,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Welcome back, $userName',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: DSColors.paperWhite,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => context.go('/browse'),
                    icon: const Icon(Icons.explore_outlined, size: 16, color: DSColors.paperWhite),
                    label: Text(
                      'Explore Catalog',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: DSColors.paperWhite, fontSize: 13),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.3)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DSRadius.md)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: _showAddBookDialog,
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add to Shelf'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DSColors.mutedTerracotta,
                      foregroundColor: DSColors.paperWhite,
                      elevation: 0,
                      textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DSRadius.md)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Your living literary sanctuary. Track active reads, curate want-to-read lists, and achieve your annual reading aspirations.',
            style: GoogleFonts.inter(
              fontSize: 14,
              color: DSColors.paperWhite.withValues(alpha: 0.85),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ─── 2. CONTINUE READING SPOTLIGHT CARD ──────────────────────────────────────

  Widget _buildContinueReadingSection() {
    final activeReads = _currentlyReading;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.bookmark_added, color: DSColors.deepForestGreen, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Continue Reading',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: DSColors.deepForestGreen,
                    ),
                  ),
                ],
              ),
              if (activeReads.length > 1)
                Text(
                  '${activeReads.length} Active Reads',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: DSColors.deepForestGreen),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (activeReads.isEmpty)
            _buildEmptyContinueReadingCard()
          else
            _buildActiveReadSpotlightCard(activeReads.first),
        ],
      ),
    );
  }

  Widget _buildEmptyContinueReadingCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: DSColors.paperWhite,
        borderRadius: BorderRadius.circular(DSRadius.card),
        border: Border.all(color: DSColors.softBorder),
        boxShadow: DSShadows.sm,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: DSColors.warmIvory,
              border: Border.all(color: DSColors.softBorder),
            ),
            child: const Icon(Icons.auto_stories, size: 36, color: DSColors.deepForestGreen),
          ),
          const SizedBox(height: 16),
          Text(
            'Ready to start a new journey?',
            style: GoogleFonts.playfairDisplay(fontSize: 18, fontWeight: FontWeight.bold, color: DSColors.deepForestGreen),
          ),
          const SizedBox(height: 6),
          Text(
            'Pick a book from your Want to Read shelf or discover a pre-loved classic in our archive.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(fontSize: 13, color: DSColors.charcoal.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_wantToRead.isNotEmpty) ...[
                OutlinedButton(
                  onPressed: () => setState(() => _activeBookshelfTab = 2),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: DSColors.deepForestGreen),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('View Want to Read', style: TextStyle(color: DSColors.deepForestGreen, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
              ],
              DSButton.primary(
                text: 'Explore Catalog',
                onPressed: () => context.go('/browse'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActiveReadSpotlightCard(BookshelfItemModel item) {
    final percent = item.percentRead;
    final currentPage = item.currentPage;
    final totalPages = item.totalPages;
    final remainingPages = item.pagesRemaining;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: DSColors.paperWhite,
        borderRadius: BorderRadius.circular(DSRadius.card),
        border: Border.all(color: DSColors.softBorder),
        boxShadow: DSShadows.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Book Cover
          ClipRRect(
            borderRadius: BorderRadius.circular(DSRadius.md),
            child: Container(
              width: 100,
              height: 145,
              color: DSColors.warmIvory,
              child: (item.coverUrl != null && item.coverUrl!.isNotEmpty)
                  ? Image.network(
                      item.coverUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, st) => const Center(child: Icon(Icons.menu_book, color: DSColors.deepForestGreen, size: 36)),
                    )
                  : const Center(child: Icon(Icons.menu_book, color: DSColors.deepForestGreen, size: 36)),
            ),
          ),
          const SizedBox(width: 22),
          // Details & Progress
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: DSColors.deepForestGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(DSRadius.sm),
                      ),
                      child: Text(
                        item.format.toUpperCase(),
                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: DSColors.deepForestGreen),
                      ),
                    ),
                    if (item.daysLeft != null)
                      Text(
                        '${item.daysLeft} days left',
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: DSColors.mutedTerracotta),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  item.title,
                  style: GoogleFonts.playfairDisplay(fontSize: 20, fontWeight: FontWeight.bold, color: DSColors.charcoal),
                ),
                const SizedBox(height: 2),
                Text(
                  'by ${item.author}',
                  style: GoogleFonts.inter(fontSize: 13, color: DSColors.charcoal.withValues(alpha: 0.7)),
                ),
                const SizedBox(height: 14),
                // Progress Bar
                LinearProgressIndicator(
                  value: item.progress,
                  backgroundColor: DSColors.softBorder,
                  valueColor: const AlwaysStoppedAnimation<Color>(DSColors.deepForestGreen),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$percent% Read • Page $currentPage of $totalPages',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: DSColors.deepForestGreen),
                    ),
                    Text(
                      '$remainingPages pages left',
                      style: GoogleFonts.inter(fontSize: 11, color: DSColors.charcoal.withValues(alpha: 0.6)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Action Buttons
                Row(
                  children: [
                    DSButton.primary(
                      text: 'Update Progress',
                      onPressed: () => _showUpdateProgressDialog(item),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton(
                      onPressed: () => _showMoveCategoryDialog(item),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: DSColors.softBorder),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DSRadius.md)),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      child: Text('Change Shelf', style: GoogleFonts.inter(fontSize: 13, color: DSColors.charcoal, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── 3. READER METRICS ROW ───────────────────────────────────────────────────

  Widget _buildReaderMetricsRow(int completedCount, int targetBooks, int streak) {
    final goalPercent = targetBooks > 0 ? ((completedCount / targetBooks) * 100).round() : 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 650;
          return GridView.count(
            crossAxisCount: isMobile ? 2 : 4,
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: isMobile ? 1.4 : 1.7,
            children: [
              _buildMetricCard(
                icon: Icons.check_circle_outline,
                iconColor: DSColors.secondaryGreen,
                label: 'Books Finished',
                value: completedCount.toString(),
                subtext: 'Cataloged in archive',
              ),
              _buildMetricCard(
                icon: Icons.local_fire_department,
                iconColor: DSColors.accentTerracotta,
                label: 'Day Streak',
                value: '$streak Days',
                subtext: 'Consecutive reading',
              ),
              _buildMetricCard(
                icon: Icons.menu_book,
                iconColor: DSColors.deepForestGreen,
                label: 'Currently Reading',
                value: _currentlyReading.length.toString(),
                subtext: 'Active on shelf',
              ),
              _buildMetricCard(
                icon: Icons.track_changes,
                iconColor: DSColors.mutedTerracotta,
                label: 'Annual Goal',
                value: '$goalPercent%',
                subtext: '$completedCount of $targetBooks books',
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required String subtext,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DSColors.paperWhite,
        borderRadius: BorderRadius.circular(DSRadius.card),
        border: Border.all(color: DSColors.softBorder),
        boxShadow: DSShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: DSColors.charcoal.withValues(alpha: 0.7))),
              Icon(icon, size: 20, color: iconColor),
            ],
          ),
          Text(
            value,
            style: GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.bold, color: DSColors.charcoal),
          ),
          Text(
            subtext,
            style: GoogleFonts.inter(fontSize: 11, color: DSColors.charcoal.withValues(alpha: 0.6)),
          ),
        ],
      ),
    );
  }

  // ─── 4. LIVING BOOKSHELF SECTION ─────────────────────────────────────────────

  Widget _buildLivingBookshelfSection() {
    final items = _filteredBookshelfItems;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: DSColors.paperWhite,
          borderRadius: BorderRadius.circular(DSRadius.card),
          border: Border.all(color: DSColors.softBorder),
          boxShadow: DSShadows.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header & Search
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.shelves, size: 22, color: DSColors.deepForestGreen),
                    const SizedBox(width: 10),
                    Text(
                      'Living Bookshelf',
                      style: GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.bold, color: DSColors.deepForestGreen),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: _showAddBookDialog,
                  icon: const Icon(Icons.add_circle_outline, size: 16, color: DSColors.deepForestGreen),
                  label: Text('Add Book', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: DSColors.deepForestGreen)),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Search Bar & Filter Chips
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: DSColors.warmIvory,
                      borderRadius: BorderRadius.circular(DSRadius.md),
                      border: Border.all(color: DSColors.softBorder),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.search, size: 18, color: DSColors.charcoal),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: _searchCtrl,
                            decoration: const InputDecoration(
                              hintText: 'Search title, author or genre...',
                              border: InputBorder.none,
                              isDense: true,
                            ),
                            style: GoogleFonts.inter(fontSize: 13),
                            onChanged: (val) => setState(() => _searchQuery = val),
                          ),
                        ),
                        if (_searchQuery.isNotEmpty)
                          IconButton(
                            iconSize: 16,
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _searchQuery = '');
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Bookshelf Category Tabs
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildShelfTab(0, 'All Books (${_bookshelfItems.length})'),
                  const SizedBox(width: 8),
                  _buildShelfTab(1, 'Currently Reading (${_currentlyReading.length})'),
                  const SizedBox(width: 8),
                  _buildShelfTab(2, 'Want to Read (${_wantToRead.length})'),
                  const SizedBox(width: 8),
                  _buildShelfTab(3, 'Completed (${_completedBooks.length})'),
                  const SizedBox(width: 8),
                  _buildShelfTab(4, 'Paused (${_pausedBooks.length})'),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Shelf Grid / Empty State
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 36),
                child: DSEmptyState(
                  icon: Icons.menu_book,
                  title: _searchQuery.isNotEmpty ? 'No matches found' : 'Your shelf is waiting',
                  description: _searchQuery.isNotEmpty
                      ? 'No books on this shelf match "$_searchQuery".'
                      : 'Add your first book to this shelf or explore our catalog.',
                  actionLabel: 'Explore Catalog',
                  onAction: () => context.go('/browse'),
                ),
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 700;
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isWide ? 2 : 1,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: isWide ? 2.3 : 2.0,
                    ),
                    itemCount: items.length,
                    itemBuilder: (ctx, i) => _buildBookshelfItemCard(items[i]),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildShelfTab(int tabIndex, String label) {
    final isSelected = _activeBookshelfTab == tabIndex;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _activeBookshelfTab = tabIndex),
      selectedColor: DSColors.deepForestGreen,
      backgroundColor: DSColors.warmIvory,
      labelStyle: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
        color: isSelected ? DSColors.paperWhite : DSColors.charcoal,
      ),
      side: BorderSide(color: isSelected ? DSColors.deepForestGreen : DSColors.softBorder),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  Widget _buildBookshelfItemCard(BookshelfItemModel item) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: DSColors.warmIvory,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: DSColors.softBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover
          ClipRRect(
            borderRadius: BorderRadius.circular(DSRadius.sm),
            child: Container(
              width: 72,
              height: 104,
              color: Colors.black12,
              child: (item.coverUrl != null && item.coverUrl!.isNotEmpty)
                  ? Image.network(
                      item.coverUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, st) => const Center(child: Icon(Icons.book, size: 28, color: DSColors.deepForestGreen)),
                    )
                  : const Center(child: Icon(Icons.book, size: 28, color: DSColors.deepForestGreen)),
            ),
          ),
          const SizedBox(width: 14),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: DSColors.deepForestGreen.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            _formatCategory(item.category).toUpperCase(),
                            style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: DSColors.deepForestGreen),
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, size: 18),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onSelected: (val) {
                            if (val == 'progress') _showUpdateProgressDialog(item);
                            if (val == 'move') _showMoveCategoryDialog(item);
                            if (val == 'delete') _deleteItem(item);
                            if (val == 'details' && item.bookId != null) {
                              context.push('/book/${item.bookId}');
                            }
                          },
                          itemBuilder: (ctx) => [
                            const PopupMenuItem(value: 'progress', child: Text('Update Progress')),
                            const PopupMenuItem(value: 'move', child: Text('Change Shelf Status')),
                            if (item.bookId != null)
                              const PopupMenuItem(value: 'details', child: Text('View Details')),
                            const PopupMenuItem(value: 'delete', child: Text('Remove from Shelf', style: TextStyle(color: Colors.red))),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.playfairDisplay(fontSize: 15, fontWeight: FontWeight.bold, color: DSColors.charcoal),
                    ),
                    Text(
                      item.author,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(fontSize: 12, color: DSColors.charcoal.withValues(alpha: 0.7)),
                    ),
                  ],
                ),
                // Progress bar if active
                if (item.category == 'currently_reading') ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LinearProgressIndicator(
                        value: item.progress,
                        backgroundColor: DSColors.softBorder,
                        valueColor: const AlwaysStoppedAnimation<Color>(DSColors.deepForestGreen),
                        minHeight: 5,
                        borderRadius: BorderRadius.circular(DSRadius.xs),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Page ${item.currentPage} of ${item.totalPages} (${item.percentRead}%)',
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: DSColors.deepForestGreen),
                      ),
                    ],
                  ),
                ] else if (item.category == 'completed') ...[
                  Row(
                    children: [
                      const Icon(Icons.check_circle, size: 14, color: DSColors.secondaryGreen),
                      const SizedBox(width: 4),
                      Text('Completed', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: DSColors.secondaryGreen)),
                      if (item.rating != null) ...[
                        const SizedBox(width: 8),
                        Row(
                          children: List.generate(
                            item.rating!.toInt(),
                            (_) => const Icon(Icons.star, size: 12, color: DSColors.antiqueGold),
                          ),
                        ),
                      ],
                    ],
                  ),
                ] else ...[
                  Text(
                    '${item.format} • ${item.totalPages} pages',
                    style: GoogleFonts.inter(fontSize: 11, color: DSColors.charcoal.withValues(alpha: 0.6)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── 5. ANNUAL READING GOAL SECTION ──────────────────────────────────────────

  Widget _buildReadingGoalsSection(int completedCount, int targetBooks) {
    final goal = _readingGoal;
    final targetPages = goal?.targetPages ?? 3000;
    final pagesRead = goal?.pagesRead ?? (completedCount * 280);
    final bookProgress = targetBooks > 0 ? (completedCount / targetBooks).clamp(0.0, 1.0) : 0.0;
    final pageProgress = targetPages > 0 ? (pagesRead / targetPages).clamp(0.0, 1.0) : 0.0;
    final currentYear = goal?.year ?? DateTime.now().year;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: DSColors.paperWhite,
          borderRadius: BorderRadius.circular(DSRadius.card),
          border: Border.all(color: DSColors.softBorder),
          boxShadow: DSShadows.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.emoji_events_outlined, color: DSColors.antiqueGold, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      '$currentYear Reading Challenge',
                      style: GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.bold, color: DSColors.deepForestGreen),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: _showEditGoalDialog,
                  icon: const Icon(Icons.edit, size: 15, color: DSColors.deepForestGreen),
                  label: Text('Edit Goal', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: DSColors.deepForestGreen)),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Books Completed', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: DSColors.charcoal)),
                          Text('$completedCount of $targetBooks books (${(bookProgress * 100).round()}%)',
                              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12, color: DSColors.deepForestGreen)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: bookProgress,
                        backgroundColor: DSColors.softBorder,
                        valueColor: const AlwaysStoppedAnimation<Color>(DSColors.deepForestGreen),
                        minHeight: 10,
                        borderRadius: BorderRadius.circular(DSRadius.sm),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Pages Explored', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13, color: DSColors.charcoal)),
                          Text('$pagesRead of $targetPages pages (${(pageProgress * 100).round()}%)',
                              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12, color: DSColors.mutedTerracotta)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: pageProgress,
                        backgroundColor: DSColors.softBorder,
                        valueColor: const AlwaysStoppedAnimation<Color>(DSColors.mutedTerracotta),
                        minHeight: 10,
                        borderRadius: BorderRadius.circular(DSRadius.sm),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── 6. AI READING CONCIERGE ─────────────────────────────────────────────────

  Widget _buildReadingConciergeSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: DSColors.paperWhite,
          borderRadius: BorderRadius.circular(DSRadius.card),
          border: Border.all(color: DSColors.softBorder),
          boxShadow: DSShadows.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: DSColors.mutedTerracotta, size: 22),
                const SizedBox(width: 10),
                Text(
                  'Reading Concierge & Literary Discovery',
                  style: GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.bold, color: DSColors.deepForestGreen),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Ask for personalized recommendations based on mood, themes, or beloved authors.',
              style: GoogleFonts.inter(fontSize: 13, color: DSColors.charcoal.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _conciergePromptCtrl,
                    decoration: InputDecoration(
                      hintText: 'e.g. A melancholic mystery set in old European libraries...',
                      filled: true,
                      fillColor: DSColors.warmIvory,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(DSRadius.md), borderSide: const BorderSide(color: DSColors.softBorder)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(DSRadius.md), borderSide: const BorderSide(color: DSColors.softBorder)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(DSRadius.md), borderSide: const BorderSide(color: DSColors.deepForestGreen)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                    style: GoogleFonts.inter(fontSize: 13),
                    onSubmitted: _handleConciergeQuery,
                  ),
                ),
                const SizedBox(width: 12),
                _isConciergeLoading
                    ? const SizedBox(width: 40, height: 40, child: CircularProgressIndicator(color: DSColors.deepForestGreen, strokeWidth: 2))
                    : DSButton.primary(
                        text: 'Consult',
                        onPressed: () => _handleConciergeQuery(_conciergePromptCtrl.text),
                      ),
              ],
            ),
            if (_conciergeResponse != null) ...[
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: DSColors.warmIvory,
                  borderRadius: BorderRadius.circular(DSRadius.md),
                  border: Border.all(color: DSColors.softBorder),
                ),
                child: Text(
                  _conciergeResponse!,
                  style: GoogleFonts.inter(fontSize: 13, color: DSColors.charcoal, height: 1.5),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ─── 7. CURATED MARKETPLACE RECOMMENDATIONS ──────────────────────────────────

  Widget _buildMarketplaceCurationsSection(HomeState state) {
    List<Book> books = [];
    if (state is HomeLoaded) {
      books = state.featuredBooks.isNotEmpty ? state.featuredBooks : state.catalogBooks;
    }

    if (books.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: DSColors.paperWhite,
          borderRadius: BorderRadius.circular(DSRadius.card),
          border: Border.all(color: DSColors.softBorder),
          boxShadow: DSShadows.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.local_library_outlined, color: DSColors.deepForestGreen, size: 22),
                    const SizedBox(width: 10),
                    Text(
                      'Curated for Your Reading Life',
                      style: GoogleFonts.playfairDisplay(fontSize: 22, fontWeight: FontWeight.bold, color: DSColors.deepForestGreen),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => context.go('/browse'),
                  child: Text('Explore All', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: DSColors.deepForestGreen)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: books.take(8).length,
                separatorBuilder: (ctx, i) => const SizedBox(width: 16),
                itemBuilder: (ctx, i) {
                  final b = books[i];
                  return Container(
                    width: 165,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: DSColors.warmIvory,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: DSColors.softBorder),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              color: Colors.black12,
                              width: double.infinity,
                              child: b.coverUrl.isNotEmpty
                                  ? Image.network(
                                      b.coverUrl,
                                      fit: BoxFit.cover,
                                      errorBuilder: (ctx, err, st) => const Center(child: Icon(Icons.book, size: 36, color: DSColors.deepForestGreen)),
                                    )
                                  : const Center(child: Icon(Icons.book, size: 36, color: DSColors.deepForestGreen)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          b.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.playfairDisplay(fontSize: 14, fontWeight: FontWeight.bold, color: DSColors.charcoal),
                        ),
                        Text(
                          b.author,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(fontSize: 11, color: DSColors.charcoal.withValues(alpha: 0.7)),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '₹${b.price.toStringAsFixed(0)}',
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: DSColors.deepForestGreen),
                            ),
                            GestureDetector(
                              onTap: () => context.push('/book/${b.id}'),
                              child: Text(
                                'View',
                                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: DSColors.mutedTerracotta),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
