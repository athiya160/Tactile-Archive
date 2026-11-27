import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/theme.dart';
import '../bloc/library_bloc.dart';
import '../bloc/library_event.dart';
import '../bloc/library_state.dart';
import '../widgets/rentals_tab.dart';
import '../widgets/uploads_tab.dart';
import '../../../../core/services/api_service.dart';
import 'package:libri_flow/core/design_system/design_system.dart';

class LibraryPage extends StatefulWidget {
  final int initialTabIndex;
  const LibraryPage({super.key, this.initialTabIndex = 0});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    final tabLength = ApiService.isProvider ? 2 : 1;
    _tabController = TabController(length: tabLength, vsync: this);

    if (widget.initialTabIndex < tabLength) {
      _tabController.index = widget.initialTabIndex;
      context.read<LibraryBloc>().add(
        LibraryTabChanged(widget.initialTabIndex),
      );
    }

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        context.read<LibraryBloc>().add(
          LibraryTabChanged(_tabController.index),
        );
      }
    });
  }

  @override
  void didUpdateWidget(LibraryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialTabIndex != oldWidget.initialTabIndex) {
      final tabLength = ApiService.isProvider ? 2 : 1;
      if (widget.initialTabIndex < tabLength) {
        _tabController.animateTo(widget.initialTabIndex);
        context.read<LibraryBloc>().add(
          LibraryTabChanged(widget.initialTabIndex),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LibraryBloc, LibraryState>(
      listener: (context, state) {
        if (state is LibraryLoaded) {
          if (_tabController.index != state.activeTabIndex) {
            _tabController.animateTo(state.activeTabIndex);
          }
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Editorial Header
          Padding(
            padding: const EdgeInsets.fromLTRB(
              DSSpacing.lg,
              DSSpacing.lg,
              DSSpacing.lg,
              DSSpacing.lg,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Track your active reading rentals and manage your archive contributions.",
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: DSColors.textLight),
                ),
              ],
            ),
          ),

          // Tab System
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: DSSpacing.lg),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              dividerColor: DSColors.borderLight.withValues(alpha: 0.3),
              indicatorColor: DSColors.primary,
              indicatorSize: TabBarIndicatorSize.tab,
              indicatorWeight: 2.0,
              labelColor: DSColors.primary,
              unselectedLabelColor: DSColors.textDark.withValues(alpha: 0.5),
              labelStyle: IvoryTheme.smallCapsLabel.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 10,
                letterSpacing: 1.2,
              ),
              unselectedLabelStyle: IvoryTheme.smallCapsLabel.copyWith(
                fontWeight: FontWeight.w700,
                fontSize: 10,
                letterSpacing: 1.2,
              ),
              padding: EdgeInsets.zero,
              labelPadding: const EdgeInsets.only(
                right: DSSpacing.xl,
                bottom: DSSpacing.sm,
              ),
              tabs: [
                const Tab(text: "MY RENTALS"),
                if (ApiService.isProvider) const Tab(text: "MY UPLOADS"),
              ],
            ),
          ),

          // Content Stack
          Expanded(
            child: AnimatedBuilder(
              animation: _tabController,
              builder: (context, _) {
                return BlocBuilder<LibraryBloc, LibraryState>(
                  builder: (context, state) {
                    if (state is LibraryLoading) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: DSColors.primary,
                          ),
                        ),
                      );
                    }
                    if (state is LibraryLoaded) {
                      if (_tabController.index == 0) {
                        return RentalsTab(rentals: state.rentals);
                      } else if (ApiService.isProvider &&
                          _tabController.index == 1) {
                        return UploadsTab(uploads: state.uploads);
                      }
                    }
                    if (state is LibraryError) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: DSSpacing.xl,
                          vertical: 40,
                        ),
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: DSColors.surface,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: DSColors.borderLight.withValues(alpha: 0.5),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.wifi_off_rounded,
                                  size: 44,
                                  color: DSColors.textLight,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Unable to Sync with Archive',
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: DSColors.primary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                state.message,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: DSColors.textLight,
                                ),
                              ),
                              const SizedBox(height: 20),
                              ElevatedButton.icon(
                                onPressed: () {
                                  context.read<LibraryBloc>().add(
                                    LibraryStarted(initialTabIndex: _tabController.index),
                                  );
                                },
                                icon: const Icon(Icons.refresh, size: 16),
                                label: const Text('Try Again'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: DSColors.primary,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(DSRadius.sm),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
