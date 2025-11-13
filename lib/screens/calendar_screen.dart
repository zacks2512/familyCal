import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../models/entities.dart';
import '../config/app_config.dart';
import '../services/firebase_repository.dart';
import '../state/app_state.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final FocusNode _focusNode = FocusNode(debugLabel: 'calendar_focus');
  final TextEditingController _titleController = TextEditingController();

  DateTime? _lastSelectedDay;
  bool _showInlineQuickAdd = false;
  TimeOfDay? _quickAddStart;
  TimeOfDay? _quickAddEnd;
  EventRole? _quickAddRole;
  String? _quickAddChildId;
  String? _quickAddResponsibleId;
  bool _showSwipeHint = true;

  @override
  void initState() {
    super.initState();
    // Auto-hide swipe hint after 2 seconds on first view
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _showSwipeHint = false);
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FamilyCalState>();
    final constraints = MediaQuery.sizeOf(context);
    final isCompact = constraints.width < 600;
    final localeName = Localizations.localeOf(context).toLanguageTag();

    if (_lastSelectedDay != state.selectedCalendarDay) {
      _lastSelectedDay = state.selectedCalendarDay;
      _showInlineQuickAdd = false;
    }

    return Scaffold(
      body: SafeArea(
        child: Focus(
          focusNode: _focusNode,
          autofocus: true,
          onKey: (node, event) => _handleKey(event, state),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 600;
              return Column(
                children: [
                  _CalendarHeader(
                    isCompact: compact,
                    onNextMonth: () => state.jumpMonth(1),
                    onPreviousMonth: () => state.jumpMonth(-1),
                    onToday: () => state.jumpToToday(),
                    monthLabel:
                        DateFormat('MMMM yyyy', localeName).format(state.visibleMonth),
                    viewMode: state.calendarViewMode,
                    onViewModeChanged: (mode) =>
                        context.read<FamilyCalState>().setCalendarViewMode(mode),
                    onMonthLabelTap: () => _showMonthYearPicker(context, state),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onHorizontalDragEnd: (details) {
                        if (details.primaryVelocity != null) {
                          if (details.primaryVelocity! < -500) {
                            // Swipe left -> next month
                            state.jumpMonth(1);
                          } else if (details.primaryVelocity! > 500) {
                            // Swipe right -> previous month
                            state.jumpMonth(-1);
                          }
                        }
                      },
                    child: _buildView(
                      context: context,
                      state: state,
                      isCompact: compact,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  KeyEventResult _handleKey(RawKeyEvent event, FamilyCalState state) {
    if (event is! RawKeyDownEvent) return KeyEventResult.ignored;
    final selected = state.selectedCalendarDay;
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowRight) {
      state.selectCalendarDay(selected.add(const Duration(days: 1)));
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      state.selectCalendarDay(selected.subtract(const Duration(days: 1)));
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.pageUp) {
      state.jumpMonth(-1);
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.pageDown) {
      state.jumpMonth(1);
      return KeyEventResult.handled;
    } else if (key == LogicalKeyboardKey.keyT) {
      state.jumpToToday();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Widget _buildView({
    required BuildContext context,
    required FamilyCalState state,
    required bool isCompact,
  }) {
    switch (state.calendarViewMode) {
      case CalendarViewMode.month:
        return _MonthView(
          isCompact: isCompact,
          selectedDay: state.selectedCalendarDay,
          visibleMonth: state.visibleMonth,
          instancesForDay: state.instancesForDay,
          onSelectDay: (day) => _handleDayTap(context, state, day, isCompact),
          onOpenDetail: () =>
              _openDayDetailSheet(context, state, state.selectedCalendarDay),
          dayDrawer: _CalendarDayDrawer(
            day: state.selectedCalendarDay,
            isCompact: isCompact,
            showQuickAddInline: _showInlineQuickAdd,
            onOpenQuickAdd: () => _toggleQuickAdd(context, state, isCompact),
            onSubmitQuickAdd: (event) => _submitQuickAdd(context, state, event),
            onCloseQuickAdd: () => setState(() => _showInlineQuickAdd = false),
          ),
        );

      case CalendarViewMode.week:
        return _WeekView(
          selectedDay: state.selectedCalendarDay,
          instancesForDay: state.instancesForDay,
        onSelectDay: (day) => state.selectCalendarDay(day), // no popup on day tap
          isCompact: isCompact,
          dayDrawer: _CalendarDayDrawer(
            day: state.selectedCalendarDay,
            isCompact: isCompact,
          showQuickAddInline: false,                // ← always button-only in Week
          onOpenQuickAdd: () => _openQuickAddSheet(context, state), // ← open sheet
            onSubmitQuickAdd: (event) => _submitQuickAdd(context, state, event),
          onCloseQuickAdd: () {}, // not used in Week since no inline form
          ),
        );


      case CalendarViewMode.day:
        final events = state.instancesForDay(state.selectedCalendarDay);
        return _DayView(
          day: state.selectedCalendarDay,
          events: events,
          isCompact: isCompact,
          onSelectDay: (day) => _handleDayTap(context, state, day, isCompact),
          onOpenQuickAdd: () => _toggleQuickAdd(context, state, isCompact),
          showQuickAddInline: _showInlineQuickAdd,
          onSubmitQuickAdd: (event) => _submitQuickAdd(context, state, event),
          onCloseQuickAdd: () => setState(() => _showInlineQuickAdd = false),
        );
    }
  }

  void _handleDayTap(
    BuildContext context,
    FamilyCalState state,
    DateTime day,
    bool isCompact,
  ) {
    state.selectCalendarDay(day);
    if (isCompact && state.calendarViewMode != CalendarViewMode.week) {
      _openDayDetailSheet(context, state, day);
    }
  }

  void _openDayDetailSheet(
    BuildContext context,
    FamilyCalState state,
    DateTime day,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.50,
          builder: (context, scrollController) {
            return SingleChildScrollView(
              controller: scrollController,
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
          child: _CalendarDayDrawer(
            day: day,
            isCompact: true,
                showQuickAddInline: false,
                onOpenQuickAdd: () => _openQuickAddSheet(context, state),
            onSubmitQuickAdd: (event) =>
                _submitQuickAdd(context, state, event, closeSheet: true),
            onCloseQuickAdd: () => Navigator.of(context).maybePop(),
          ),
            );
          },
        );
      },
    );
  }

  void _toggleQuickAdd(
    BuildContext context,
    FamilyCalState state,
    bool isCompact,
  ) {
    // In WEEK view we always show the bottom sheet (button-only UI in drawer)
    if (state.calendarViewMode == CalendarViewMode.week) {
      _openQuickAddSheet(context, state);
      return;
    }

    // Day/Month behavior as you already had
    if (isCompact) {
      _openQuickAddSheet(context, state);
      return;
    }
    setState(() {
      _showInlineQuickAdd = !_showInlineQuickAdd;
      if (_showInlineQuickAdd) {
        _prepareDefaults(state);
      }
    });
  }


  void _openQuickAddSheet(BuildContext context, FamilyCalState state) {
    _prepareDefaults(state);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) {
        final mq = MediaQuery.of(context);
        final height = mq.size.height;
        final isLandscape = mq.orientation == Orientation.landscape;

        // Dynamic sizes per device/orientation
        final double initialSize =
            height < 680 ? 0.96 : (height < 820 ? 0.90 : 0.85);
        final double maxSize = isLandscape ? 0.90 : 0.98;
        const double minSize = 0.50;

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: initialSize,
          maxChildSize: maxSize,
          minChildSize: minSize,
          builder: (context, scrollController) {
            return SafeArea(
              top: false,
              child: LayoutBuilder(
                builder: (context, c) {
                  const double kMaxFormWidth = 600;
                  return SingleChildScrollView(
                    controller: scrollController,
          padding: EdgeInsets.only(
                      left: 16,
                      right: 16,
                      top: 12,
                      bottom: mq.viewInsets.bottom + 16,
          ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints:
                            const BoxConstraints(maxWidth: kMaxFormWidth),
            child: _QuickAddForm(
              titleController: _titleController,
              initialStart: _quickAddStart!,
              initialEnd: _quickAddEnd!,
              initialRole: _quickAddRole!,
                          date:
                              context.read<FamilyCalState>().selectedCalendarDay,
              childId: _quickAddChildId,
              responsibleId: _quickAddResponsibleId,
                          onSubmit: (event) => _submitQuickAdd(
                              context, state, event,
                              closeSheet: true),
                        ),
                      ),
                    ),
                  );
              },
            ),
            );
          },
        );
      },
    );
  }

  void _prepareDefaults(FamilyCalState state) {
    _titleController.clear();
    final defaultStart = TimeOfDay.fromDateTime(
      DateTime.now().isAfter(state.selectedCalendarDay)
          ? DateTime(
              state.selectedCalendarDay.year,
              state.selectedCalendarDay.month,
              state.selectedCalendarDay.day,
            ).add(const Duration(hours: 8))
          : state.selectedCalendarDay.add(const Duration(hours: 8)),
    );
    _quickAddStart = defaultStart;
    _quickAddEnd = TimeOfDay(
      hour: (defaultStart.hour + 1) % 24,
      minute: defaultStart.minute,
    );
    _quickAddRole = EventRole.dropOff;
    _quickAddChildId =
        state.children.isNotEmpty ? state.children.first.id : null;
    _quickAddResponsibleId = state.currentMemberId;
  }

  void _submitQuickAdd(
    BuildContext context,
    FamilyCalState state,
    QuickAddEvent event, {
    bool closeSheet = false,
  }) {
    final l10n = AppLocalizations.of(context)!;
    // Normalize no-repeat as a single occurrence (endDate == startDate)
    final isNoRepeat = event.repeatOption == RepeatOption.noRepeat;
    final computedWeekdays =
        event.repeatWeekdays ?? {event.date.weekday}; // fallback to selected day
    final computedEndDate =
        isNoRepeat ? DateUtils.dateOnly(event.date) : event.endDate;

    // Map repeat option to recurrence rule
    final recurrence = switch (event.repeatOption) {
      RepeatOption.noRepeat => RecurrenceRule.none,
      RepeatOption.daily => RecurrenceRule.daily,
      RepeatOption.weekly => RecurrenceRule.weekly,
      RepeatOption.monthly => RecurrenceRule.monthly,
      RepeatOption.yearly => RecurrenceRule.yearly,
    };

    // Real mode: persist to Firestore
    if (!AppConfig.useMockData) {
      final repo = FirebaseRepository();
      () async {
        final familyId = await repo.getCurrentUserFamilyId(createIfMissing: true);
        if (familyId == null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not determine family.')),
            );
          }
          return;
        }

        // Determine place name
        final placeName = event.placeName.trim().isEmpty ? 'Home' : event.placeName.trim();
        // Times as HH:mm
        String fmt(TimeOfDay t) =>
            '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

        try {
          await repo.createEvent(
            familyId: familyId,
      childId: event.childId,
            place: placeName,
      role: event.role,
            recurrence: recurrence,
            startTime: fmt(event.start),
            endTime: fmt(event.end),
            startDate: DateUtils.dateOnly(event.date),
            weekdays: computedWeekdays.toList(),
            responsibleMemberId: (event.responsibleMemberId?.isEmpty ?? true)
          ? null
          : event.responsibleMemberId,
            endDate: computedEndDate != null ? DateUtils.dateOnly(computedEndDate) : null,
            title: event.title,
            notes: null,
          );
          if (!mounted) return;
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(l10n.eventAddedMessage(event.title))));
          if (closeSheet) {
            Navigator.of(context).maybePop();
          } else {
            setState(() => _showInlineQuickAdd = false);
          }
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to add event: $e')),
          );
        }
      }();
      return;
    }

    // Handle place (optional) - create or reuse if provided
    String placeId;
    if (event.placeName.trim().isEmpty) {
      // Use default/first place if no place specified
      if (state.places.isEmpty) {
        // Create a default "Home" place if none exist
        placeId = 'place-default-${DateTime.now().millisecondsSinceEpoch}';
        state.addPlace(FamilyPlace(
          id: placeId,
          name: 'Home',
          address: '',
          radiusMeters: 150,
        ));
      } else {
        placeId = state.places.first.id;
      }
    } else {
      // Find or create place with given name
      FamilyPlace? existingPlace;
      for (final place in state.places) {
        if (place.name.toLowerCase() == event.placeName.toLowerCase()) {
          existingPlace = place;
          break;
        }
      }
      placeId = existingPlace?.id ??
          'place-${DateTime.now().millisecondsSinceEpoch}';
      if (existingPlace == null) {
        state.addPlace(FamilyPlace(
          id: placeId,
          name: event.placeName,
          address: '',
          radiusMeters: 150,
        ));
      }
    }

    final newEvent = RecurringEvent(
      id: 'event-${DateTime.now().millisecondsSinceEpoch}',
      childId: event.childId,
      placeId: placeId,
      role: event.role,
      recurrence: recurrence,
      responsibleMemberId:
          (event.responsibleMemberId?.isEmpty ?? true) ? null : event.responsibleMemberId,
      startTime: event.start,
      endTime: event.end,
      weekdays: computedWeekdays,
      startDate: DateUtils.dateOnly(event.date),
      endDate: event.endDate != null ? DateUtils.dateOnly(event.endDate!) : null,
      title: event.title,
    );
    state.addEvent(newEvent);

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l10n.eventAddedMessage(event.title))));
    if (closeSheet) {
      Navigator.of(context).maybePop();
    } else {
      setState(() => _showInlineQuickAdd = false);
    }
  }

  void _showMonthYearPicker(BuildContext context, FamilyCalState state) async {
    final currentMonth = state.visibleMonth;
    
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _MonthYearPickerSheet(
        initialDate: currentMonth,
      ),
    );
    
    if (picked != null) {
      state.setVisibleMonth(picked);
      state.selectCalendarDay(DateTime(picked.year, picked.month, 1));
    }
  }
}

/* ───────────────────────── Header ───────────────────────── */

class _CalendarHeader extends StatelessWidget {
  const _CalendarHeader({
    required this.isCompact,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onToday,
    required this.monthLabel,
    required this.viewMode,
    required this.onViewModeChanged,
    required this.onMonthLabelTap,
  });

  final bool isCompact;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final VoidCallback onToday;
  final String monthLabel;
  final CalendarViewMode viewMode;
  final ValueChanged<CalendarViewMode> onViewModeChanged;
  final VoidCallback onMonthLabelTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localizedSegments = [
      ButtonSegment(value: CalendarViewMode.day, label: Text(l10n.day)),
      ButtonSegment(value: CalendarViewMode.week, label: Text(l10n.week)),
      ButtonSegment(value: CalendarViewMode.month, label: Text(l10n.month)),
    ];
    final segmentedLocalized = SegmentedButton<CalendarViewMode>(
      style: ButtonStyle(
        padding: MaterialStateProperty.all(const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
        visualDensity: VisualDensity.compact,
        textStyle: MaterialStateProperty.all(
          Theme.of(context).textTheme.bodySmall,
        ),
      ),
      segments: localizedSegments,
      selected: {viewMode},
      onSelectionChanged: (value) => onViewModeChanged(value.first),
    );

    final navigationRow = Row(
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          tooltip: 'Previous month',
          onPressed: onPreviousMonth,
        ),
        Expanded(
          child: Semantics(
            label: 'Current month $monthLabel, tap to select month and year',
            button: true,
            hint: 'Double tap to open month and year picker',
            child: InkWell(
              onTap: onMonthLabelTap,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
            child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
              child: Text(
                monthLabel,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w400,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_drop_down,
                        size: 24,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          tooltip: 'Next month',
          onPressed: onNextMonth,
          iconSize: 28,
        ),
        const SizedBox(width: 4),
        FilledButton.tonal(
          onPressed: onToday,
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            visualDensity: VisualDensity.comfortable,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.today, size: 18),
              const SizedBox(width: 6),
              Text(l10n.today),
            ],
          ),
        ),
      ],
    );

    if (isCompact) {
      return Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            // Replace with localized segmented
              navigationRow,
              const SizedBox(height: 12),
            segmentedLocalized,
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Wrap(
        alignment: WrapAlignment.spaceBetween,
        runAlignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16,
        runSpacing: 12,
        children: [
          SizedBox(width: 280, child: navigationRow),
          segmentedLocalized,
        ],
      ),
    );
  }
}

/* ───────────────────────── Month View ───────────────────────── */
class _MonthView extends StatelessWidget {
  const _MonthView({
    required this.isCompact,
    required this.selectedDay,
    required this.visibleMonth,
    required this.instancesForDay,
    required this.onSelectDay,
    required this.onOpenDetail,
    required this.dayDrawer,
  });

  final bool isCompact;
  final DateTime selectedDay;
  final DateTime visibleMonth;
  final List<EventInstance> Function(DateTime) instancesForDay;
  final ValueChanged<DateTime> onSelectDay;
  final VoidCallback onOpenDetail;
  final Widget dayDrawer;

  @override
  Widget build(BuildContext context) {
    final days = _buildDaysSundayStart(visibleMonth);
    final state = context.read<FamilyCalState>();

    if (isCompact) {
      // Fill available height; 7x(5|6) grid
      return LayoutBuilder(
        builder: (context, c) {
          final rows = (days.length / 7).ceil();
          const cols = 7;
          const horizontalPadding = 8.0 * 2;

          final cellWidth = (c.maxWidth - horizontalPadding) / cols;
          final cellHeight = (c.maxHeight /* includes header */ - _weekdayHeaderHeight(context)) / rows;
          final aspect = cellWidth / cellHeight;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [
                _weekdayHeader(context),
                Expanded(
                  child: GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: cols,
                      childAspectRatio: aspect,
      ),
      itemCount: days.length,
      itemBuilder: (context, index) {
        final day = days[index];
        final events = instancesForDay(day);
        final isSelected = DateUtils.isSameDay(day, selectedDay);
        final inMonth = DateUtils.isSameMonth(day, visibleMonth);
        final hasWarning = events.any(
                        (event) => state.memberByIdOrNull(event.event.responsibleMemberId) == null,
        );
        return _MonthCell(
          day: day,
          isSelected: isSelected,
          inMonth: inMonth,
          events: events,
          hasWarning: hasWarning,
                        onTap: () => onSelectDay(day),
        );
      },
                  ),
                ),
            ],
          ),
          );
        },
      );
    }

    // Wide layout
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _weekdayHeader(context),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1,
              ),
              itemCount: days.length,
              itemBuilder: (context, index) {
                final day = days[index];
                final events = instancesForDay(day);
                final isSelected = DateUtils.isSameDay(day, selectedDay);
                final inMonth = DateUtils.isSameMonth(day, visibleMonth);
                final hasWarning = events.any(
                  (event) => state.memberByIdOrNull(event.event.responsibleMemberId) == null,
                );
                return _MonthCell(
                  day: day,
                  isSelected: isSelected,
                  inMonth: inMonth,
                  events: events,
                  hasWarning: hasWarning,
                  onTap: () => onSelectDay(day),
                );
              },
            ),
            const SizedBox(height: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: dayDrawer,
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  /// Sunday-start month grid builder
  List<DateTime> _buildDaysSundayStart(DateTime month) {
    final firstOfMonth = DateTime(month.year, month.month, 1);
    // Map Sunday=7 to 0, Mon=1..Sat=6 -> 1..6
    final firstIdx = firstOfMonth.weekday % 7; // 0..6 where 0 is Sunday
    final start = firstOfMonth.subtract(Duration(days: firstIdx));

    final lastOfMonth = DateTime(month.year, month.month + 1, 0);
    final lastIdx = lastOfMonth.weekday % 7; // 0..6 where 0 is Sunday
    final daysAfter = 6 - lastIdx; // fill to Saturday
    final end = lastOfMonth.add(Duration(days: daysAfter));

    final total = end.difference(start).inDays + 1;
    return List.generate(total, (i) => DateTime(start.year, start.month, start.day + i));
  }

  /// Header row: S M T W T F S
  Widget _weekdayHeader(BuildContext context) {
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final baseDate = DateTime(2023, 1, 1);
    final weekdayLetters = List.generate(
      7,
      (index) => DateFormat('EEEEE', localeName).format(
        baseDate.add(Duration(days: index)),
      ),
    );

    final style = Theme.of(context).textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          letterSpacing: 0.25,
        );
    return Padding(
      padding: const EdgeInsets.only(bottom: 6, left: 4, right: 4, top: 6),
      child: Row(
        children: List.generate(
          7,
          (i) => Expanded(
            child: Center(
              child: Text(weekdayLetters[i], style: style),
            ),
          ),
        ),
      ),
    );
  }

  double _weekdayHeaderHeight(BuildContext context) {
    final base = (Theme.of(context).textTheme.labelLarge?.fontSize ?? 14) * 1.6;
    return base + 12; // text height + padding
  }
}


class _MonthCell extends StatelessWidget {
  const _MonthCell({
    required this.day,
    required this.isSelected,
    required this.inMonth,
    required this.events,
    required this.hasWarning,
    required this.onTap,
  });

  final DateTime day;
  final bool isSelected;
  final bool inMonth;
  final List<EventInstance> events;
  final bool hasWarning;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
    final theme = Theme.of(context);
        final bgColor =
            isSelected ? theme.colorScheme.primary.withOpacity(0.08) : Colors.transparent;
    final borderColor = isSelected
        ? theme.colorScheme.primary
        : theme.dividerColor.withOpacity(0.4);
    final calendarState = context.read<FamilyCalState>();

        // Dynamically determine sizes based on available space
        final cellHeight = constraints.maxHeight;
        final cellWidth = constraints.maxWidth;
        
        // Scale based on cell height and theme text scale
        final textScale = MediaQuery.textScaleFactorOf(context);
        final baseBodySmall = (theme.textTheme.bodySmall?.fontSize ?? 12.0) * textScale;
        final baseLabelSmall = (theme.textTheme.labelSmall?.fontSize ?? 11.0) * textScale;
        
        // Scale font sizes proportionally based on cell dimensions
        final dateFontSize = (baseBodySmall * (cellHeight / 60.0)).clamp(10.0, baseBodySmall);
        final eventFontSize = (baseLabelSmall * (cellHeight / 60.0)).clamp(7.0, baseLabelSmall);
        final iconSize = (cellHeight * 0.10).clamp(6.0, 8.0);
        final padding = (cellHeight * 0.04).clamp(2.0, 4.0);
        
        const maxVisible = 2;
        final visibleEvents = events.take(maxVisible).toList();
        final remainingCount =
            events.length > maxVisible ? events.length - maxVisible : 0;

        final localeName = Localizations.localeOf(context).toLanguageTag();
        final dayLabel = DateFormat('EEEE, MMMM d', localeName).format(day);

    return Semantics(
      label:
              'Day $dayLabel with ${events.length} events'
          '${hasWarning ? ' and events missing assignment' : ''}',
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: borderColor, width: 0.7),
            color: bgColor,
          ),
              padding: EdgeInsets.all(padding),
          child: Column(
                mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                  Text(
                    '${day.day}',
                    style: TextStyle(
                      fontSize: dateFontSize,
                      fontWeight: FontWeight.w600,
                      color: inMonth
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                    ),
                  ),
                  if (events.isNotEmpty)
                    Flexible(
                      child: Padding(
                        padding: EdgeInsets.only(top: padding * 0.5),
                child: Column(
                          mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                            for (final event in visibleEvents)
                              Flexible(
                                child: Padding(
                                  padding: EdgeInsets.only(bottom: padding * 0.3),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        event.event.role == EventRole.dropOff 
                                            ? Icons.arrow_downward 
                                            : Icons.arrow_upward,
                                        size: iconSize,
                                        color: calendarState.childById(event.event.childId).color,
                                      ),
                                      SizedBox(width: padding * 0.5),
                                      Flexible(
                        child: Text(
                                          event.event.title?.isNotEmpty == true
                                              ? event.event.title!
                                              : calendarState
                                                  .childById(event.event.childId)
                                                  .displayName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: eventFontSize,
                                            fontWeight: FontWeight.w500,
                                            color: calendarState.childById(event.event.childId).color,
                          ),
                        ),
                      ),
                                    ],
                                  ),
                                ),
                              ),
                            if (remainingCount > 0)
                              Text(
                                '+$remainingCount',
                                style: TextStyle(
                                  fontSize: eventFontSize,
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                    if (hasWarning)
                      Tooltip(
                                message: AppLocalizations.of(context)!.eventNeedsResponsible,
                                child: Icon(Icons.error,
                                    size: iconSize, color: theme.colorScheme.error),
                              ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/* ───────────────────────── Week View (fixed size tiles, inline details) ───────────────────────── */

double _weekStripHeight(BuildContext context) {
  // Adaptive & clamped so all tiles have the same height on any device/text scale
  final theme = Theme.of(context);
  final scale = MediaQuery.textScaleFactorOf(context);

  final weekdayFs = (theme.textTheme.bodyMedium?.fontSize ?? 14) * scale; // "S"
  final dayFs = (theme.textTheme.titleLarge?.fontSize ?? 22) * scale;      // 1..31

  const vPad = 8.0 * 2; // inner padding in card
  const gap = 4.0;

  // Reserve a small lane for up to 2 event chips text (single line).
  final content = (weekdayFs * 1.2) + (dayFs * 1.2) + gap + 18.0;
  final estimated = vPad + content;

  return estimated.clamp(112.0, 164.0);
}

class _WeekView extends StatelessWidget {
  const _WeekView({
    required this.selectedDay,
    required this.instancesForDay,
    required this.onSelectDay,
    required this.isCompact,
    required this.dayDrawer,
  });

  final DateTime selectedDay;
  final List<EventInstance> Function(DateTime) instancesForDay;
  final ValueChanged<DateTime> onSelectDay;
  final bool isCompact;
  final Widget dayDrawer;

  @override
  Widget build(BuildContext context) {
    // week starts on Sunday
    final startOfWeek =
        selectedDay.subtract(Duration(days: selectedDay.weekday % 7));
    final days = List.generate(
      7,
      (i) => DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day + i),
    );

    final stripHeight = _weekStripHeight(context);

    final dayStrip = SizedBox(
      height: stripHeight, // every tile uses this exact height
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            for (final day in days)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Builder(
                    builder: (context) {
                      final events = instancesForDay(day);
                      final isSelected = DateUtils.isSameDay(day, selectedDay);
                      final missingAssignment = events.any((e) =>
                          context
                              .read<FamilyCalState>()
                              .memberByIdOrNull(e.event.responsibleMemberId) ==
                          null);
                      return _WeekDayCard(
                        day: day,
                        events: events,
                        isSelected: isSelected,
                        hasWarning: missingAssignment,
                        onTap: () => onSelectDay(day),
                      );
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    // Always render details below (no popup in week view)
    return Column(
      children: [
        dayStrip,
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: dayDrawer,
            ),
          ),
        ),
      ],
    );
  }
}

class _WeekDayCard extends StatelessWidget {
  const _WeekDayCard({
    required this.day,
    required this.events,
    required this.isSelected,
    required this.hasWarning,
    required this.onTap,
  });

  final DateTime day;
  final List<EventInstance> events;
  final bool isSelected;
  final bool hasWarning;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final state = context.read<FamilyCalState>();
    final l10n = AppLocalizations.of(context)!;

    return Semantics(
                          label:
          '${DateFormat('EEEE', localeName).format(day)} ${events.length} events ${hasWarning ? 'includes unassigned events' : ''}',
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          // Expand to fill the SizedBox height given by _weekStripHeight
          constraints: const BoxConstraints.expand(),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.dividerColor.withOpacity(0.4),
            ),
            color: isSelected
                ? theme.colorScheme.primary.withOpacity(0.12)
                : theme.colorScheme.surface,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Single-letter weekday
              Text(
                DateFormat('EEEEE', localeName).format(day),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              Text('${day.day}', style: theme.textTheme.titleLarge),
              const SizedBox(height: 4),

              // Fixed-height events lane to prevent overflow jitter
              SizedBox(
                height: 22,
                child: events.isEmpty
                    ? Center(
                        child: Text(
                          l10n.noEventsShort,
                          style: const TextStyle(fontSize: 12),
                        ),
                      )
                    : Row(
                        children: [
                          _EventDot(color: state.childById(events.first.event.childId).color),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              events.first.event.title ??
                                  events.first.event.role.label.toLowerCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall,
                              textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),

              if (hasWarning)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(Icons.warning_amber_rounded,
                      size: 14, color: theme.colorScheme.error),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EventDot extends StatelessWidget {
  const _EventDot({required this.color});
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

/* ───────────────────────── Day Drawer / Day View ───────────────────────── */

class _CalendarDayDrawer extends StatelessWidget {
  const _CalendarDayDrawer({
    required this.day,
    required this.isCompact,
    required this.showQuickAddInline,
    required this.onOpenQuickAdd,
    required this.onSubmitQuickAdd,
    required this.onCloseQuickAdd,
  });

  final DateTime day;
  final bool isCompact;
  final bool showQuickAddInline;
  final VoidCallback onOpenQuickAdd;
  final ValueChanged<QuickAddEvent> onSubmitQuickAdd;
  final VoidCallback onCloseQuickAdd;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FamilyCalState>();
    final events = state.instancesForDay(day);
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final l10n = AppLocalizations.of(context)!;
    final dayLabel = DateFormat('EEEE, MMM d', localeName).format(day);

    return Card(
      margin: EdgeInsets.symmetric(horizontal: isCompact ? 16 : 0, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    dayLabel,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                if (!(isCompact && showQuickAddInline))
                FilledButton.icon(
                    onPressed: onOpenQuickAdd,
                  icon: const Icon(Icons.add),
                    label: Text(l10n.addEvent),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (events.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(l10n.noEventsYetMessage),
              )
            else
              Column(
                children: events
                    .map(
                      (instance) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _DayEventTile(instance: instance),
                      ),
                    )
                    .toList(),
              ),
            if (!isCompact || (isCompact && showQuickAddInline))
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 200),
                crossFadeState: showQuickAddInline
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                firstChild: const SizedBox.shrink(),
                secondChild: _QuickAddForm.inline(
                  date: day,
                  onSubmit: onSubmitQuickAdd,
                  onClose: onCloseQuickAdd,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DayEventTile extends StatelessWidget {
  const _DayEventTile({required this.instance});
  final EventInstance instance;

  @override
  Widget build(BuildContext context) {
    final state = context.read<FamilyCalState>();
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final format = DateFormat.jm(localeName);
    final start = format.format(instance.windowStart);
    final end = format.format(instance.windowEnd);
    final child = state.childById(instance.event.childId);
    final title = instance.event.title?.isNotEmpty == true
        ? instance.event.title!
        : '${child.displayName} • ${instance.event.role.label}';
    final responsible =
        state.memberByIdOrNull(instance.event.responsibleMemberId);
    final missingAssignment = responsible == null;

    return Semantics(
      label: '$title from $start to $end ${missingAssignment ? 'unassigned' : ''}',
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: missingAssignment
                ? Theme.of(context).colorScheme.error
                : child.color.withOpacity(0.5),
          ),
          color:
              Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  tooltip: AppLocalizations.of(context)!.editEvent,
                  onPressed: () => _showEditEventSheet(context, state, instance),
                  icon: const Icon(Icons.edit_outlined),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text('$start – $end'),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                Chip(
                  avatar: Icon(instance.event.role.icon,
                      size: 16, color: instance.event.role.color),
                  label: Text(instance.event.role.label),
                ),
                Chip(
                  avatar: const Icon(Icons.place_outlined, size: 16),
                  label: Text(state.placeById(instance.event.placeId).name),
                ),
                if (missingAssignment)
                  Chip(
                    backgroundColor:
                        Theme.of(context).colorScheme.error.withOpacity(0.15),
                    avatar: Icon(Icons.warning_amber_rounded,
                        size: 16, color: Theme.of(context).colorScheme.error),
                    label: Text(AppLocalizations.of(context)!.addEventAssignSegment),
                  )
                else
                  Chip(
                    avatar: const Icon(Icons.person_outline, size: 16),
                    label: Text(responsible.displayName),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static void _showEditEventSheet(
    BuildContext context,
    FamilyCalState state,
    EventInstance instance,
  ) {
    final event = instance.event;
    final place = state.placeById(event.placeId);
    final formKey = GlobalKey<_EditEventFormState>();
    
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) {
        final mq = MediaQuery.of(context);
        final height = mq.size.height;
        final isLandscape = mq.orientation == Orientation.landscape;

        final double initialSize = height < 680 ? 0.96 : (height < 820 ? 0.90 : 0.85);
        final double maxSize = isLandscape ? 0.90 : 0.98;
        const double minSize = 0.50;

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: initialSize,
          maxChildSize: maxSize,
          minChildSize: minSize,
          builder: (context, scrollController) {
            return SafeArea(
              top: false,
              child: SingleChildScrollView(
                controller: scrollController,
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 12,
                  bottom: mq.viewInsets.bottom + 16,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            children: [
                        _EditEventForm(
                          key: formKey,
                          event: event,
                          placeName: place.name,
                          date: instance.windowStart,
                          onSubmit: (updatedEvent) async {
                            if (!AppConfig.useMockData) {
                              final repo = FirebaseRepository();
                              final familyId = await repo.getCurrentUserFamilyId(createIfMissing: true);
                              if (familyId != null) {
                                String fmt(TimeOfDay t) =>
                                    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
                                await repo.updateEvent(
                                  familyId: familyId,
                                  eventId: updatedEvent.id,
                                  childId: updatedEvent.childId,
                                  place: state.placeById(updatedEvent.placeId).name,
                                  role: updatedEvent.role,
                                  recurrence: updatedEvent.recurrence,
                                  responsibleMemberId: updatedEvent.responsibleMemberId,
                                  startTime: fmt(updatedEvent.startTime),
                                  endTime: fmt(updatedEvent.endTime),
                                  startDate: updatedEvent.startDate,
                                  weekdays: updatedEvent.weekdays.toList(),
                                  endDate: updatedEvent.endDate,
                                  title: updatedEvent.title,
                                  notes: updatedEvent.notes,
                                );
                              }
                            } else {
                              state.updateEvent(updatedEvent);
                            }
                            if (context.mounted) {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    AppLocalizations.of(context)!
                                        .eventUpdatedMessage(
                                      updatedEvent.title ?? AppLocalizations.of(context)!.addEventTitleLabel,
            ),
          ),
        ),
    );
  }
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
            children: [
                            TextButton.icon(
                              onPressed: () {
                                Navigator.of(context).pop();
                                _showDeleteConfirmation(context, state, instance);
                              },
                              icon: const Icon(Icons.delete_outline),
                              label: Text(AppLocalizations.of(context)!.delete),
                              style: TextButton.styleFrom(
                                foregroundColor: Theme.of(context).colorScheme.error,
                              ),
              ),
              const Spacer(),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: Text(AppLocalizations.of(context)!.cancel),
                        ),
                            const SizedBox(width: 8),
                            FilledButton(
                              onPressed: () => formKey.currentState?.saveEvent(),
                              child: Text(AppLocalizations.of(context)!.save),
                          ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  static void _showDeleteConfirmation(
    BuildContext context,
    FamilyCalState state,
    EventInstance instance,
  ) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.deleteEventTitle),
        content: Text(
          AppLocalizations.of(context)!
              .deleteEventConfirmation(instance.event.title ?? ''),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          FilledButton(
            onPressed: () async {
              if (!AppConfig.useMockData) {
                final repo = FirebaseRepository();
                final familyId = await repo.getCurrentUserFamilyId(createIfMissing: false);
                if (familyId != null) {
                  await repo.deleteEvent(familyId, instance.event.id);
                }
              } else {
                state.deleteEvent(instance.event.id);
              }
              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text(AppLocalizations.of(context)!.eventDeletedMessage),
                  ),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(AppLocalizations.of(context)!.delete),
        ),
        ],
      ),
    );
  }
}

class _DayView extends StatelessWidget{
  const _DayView({
    required this.day,
    required this.events,
    required this.isCompact,
    required this.onSelectDay,
    required this.onOpenQuickAdd,
    required this.showQuickAddInline,
    required this.onSubmitQuickAdd,
    required this.onCloseQuickAdd,
  });

  final DateTime day;
  final List<EventInstance> events;
  final bool isCompact;
  final ValueChanged<DateTime> onSelectDay;
  final VoidCallback onOpenQuickAdd;
  final bool showQuickAddInline;
  final ValueChanged<QuickAddEvent> onSubmitQuickAdd;
  final VoidCallback onCloseQuickAdd;

  @override
  Widget build(BuildContext context) {
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final l10n = AppLocalizations.of(context)!;
    final dayLabel = DateFormat('EEEE, MMM d', localeName).format(day);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  dayLabel,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              FilledButton.icon(
                onPressed: onOpenQuickAdd,
                icon: const Icon(Icons.add),
                label: Text(l10n.addEvent),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (events.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(l10n.noEventsScheduledMessage),
            )
          else
            ...events.map(
              (event) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _DayEventTile(instance: event),
              ),
            ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 200),
            crossFadeState:
                showQuickAddInline ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: _QuickAddForm.inline(
              date: day,
              onSubmit: onSubmitQuickAdd,
              onClose: onCloseQuickAdd,
            ),
          ),
        ],
      ),
    );
  }
}

/* ───────────────────────── Quick Add (free text place + repeat options) ───────────────────────── */

class QuickAddEvent {
  QuickAddEvent({
    required this.title,
    required this.start,
    required this.end,
    required this.role,
    required this.date,
    required this.childId,
    required this.placeName,
    this.responsibleMemberId,
    this.repeatWeekdays,
    this.endDate,
    required this.repeatOption,
  });

  final String title;
  final TimeOfDay start;
  final TimeOfDay end;
  final EventRole role;
  final DateTime date;
  final String childId;
  final String placeName; // free text
  final String? responsibleMemberId;
  final Set<int>? repeatWeekdays;
  final DateTime? endDate;
  final RepeatOption repeatOption;
}

class _QuickAddForm extends StatefulWidget {
  const _QuickAddForm.inline({
    required this.date,
    required this.onSubmit,
    required this.onClose,
  })  : titleController = null,
        initialStart = null,
        initialEnd = null,
        initialRole = null,
        childId = null,
        responsibleId = null;

  const _QuickAddForm({
    required this.titleController,
    required this.initialStart,
    required this.initialEnd,
    required this.initialRole,
    required this.date,
    required this.childId,
    required this.responsibleId,
    required this.onSubmit,
  }) : onClose = null;

  final TextEditingController? titleController;
  final TimeOfDay? initialStart;
  final TimeOfDay? initialEnd;
  final EventRole? initialRole;
  final DateTime date;
  final String? childId;
  final String? responsibleId;
  final ValueChanged<QuickAddEvent> onSubmit;
  final VoidCallback? onClose;

  @override
  State<_QuickAddForm> createState() => _QuickAddFormState();
}

enum RepeatOption { noRepeat, daily, weekly, monthly, yearly }

class _QuickAddFormState extends State<_QuickAddForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _placeController;
  late TimeOfDay _start;
  late TimeOfDay _end;
  late EventRole _role;
  late String? _childId;
  late String? _responsibleId;
  RepeatOption _repeatOption = RepeatOption.noRepeat;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    final state = context.read<FamilyCalState>();
    _titleController = widget.titleController ?? TextEditingController(text: '');
    _placeController = TextEditingController();
    _start = widget.initialStart ?? const TimeOfDay(hour: 8, minute: 0);
    _end = widget.initialEnd ??
        TimeOfDay(hour: (_start.hour + 1) % 24, minute: _start.minute);
    _role = widget.initialRole ?? EventRole.dropOff;
    _childId =
        widget.childId ?? (state.children.isNotEmpty ? state.children.first.id : null);
    _responsibleId = widget.responsibleId;
  }

  @override
  void dispose() {
    if (widget.titleController == null) {
      _titleController.dispose();
    }
    _placeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final state = context.watch<FamilyCalState>();

    if (state.children.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          l10n.addEventNeedsChild,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _titleController,
            decoration: InputDecoration(labelText: l10n.addEventTitleLabel),
            validator: (value) =>
                value == null || value.trim().isEmpty ? l10n.addEventTitleRequired : null,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _TimeField(
                  label: l10n.addEventStartLabel,
                  time: _start,
                  onChanged: (value) => setState(() {
                    _start = value;
                    final startMinutes = _start.hour * 60 + _start.minute;
                    final endMinutes = _end.hour * 60 + _end.minute;
                    if (endMinutes < startMinutes) {
                      // Keep duration >= 0 by snapping end to start
                      _end = TimeOfDay(hour: _start.hour, minute: _start.minute);
                    }
                  }),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TimeField(
                  label: l10n.addEventEndLabel,
                  time: _end,
                  onChanged: (value) => setState(() => _end = value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _childId,
            decoration: InputDecoration(labelText: l10n.addEventChildLabel),
            items: state.children
                .map((child) =>
                    DropdownMenuItem(value: child.id, child: Text(child.displayName)))
                .toList(),
            onChanged: (value) => setState(() => _childId = value),
            validator: (value) => value == null ? l10n.addEventChildRequired : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _placeController,
            decoration: InputDecoration(
              labelText: l10n.addEventPlaceLabel,
              hintText: l10n.addEventPlaceHint,
                  ),
          ),
          const SizedBox(height: 12),
          SegmentedButton<EventRole>(
            segments: EventRole.values
                .map((role) {
              final roleLabels = {
                EventRole.dropOff: l10n.eventRoleDropOff,
                EventRole.pickUp: l10n.eventRolePickUp,
              };
              return ButtonSegment(value: role, label: Text(roleLabels[role]!));
            }).toList(),
            selected: {_role},
            onSelectionChanged: (value) => setState(() => _role = value.first),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
            value: _responsibleId,
            decoration: InputDecoration(labelText: l10n.addEventAssignLabel),
            items: [
              DropdownMenuItem(value: null, child: Text(l10n.addEventUnassigned)),
              ...state.members.map(
                  (m) => DropdownMenuItem(value: m.id, child: Text(m.displayName))),
            ],
            onChanged: (value) => setState(() => _responsibleId = value),
              ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          // Inline repeat dropdown
          DropdownButtonFormField<RepeatOption>(
            value: _repeatOption,
            decoration: InputDecoration(
              labelText: l10n.addEventRepeatLabel,
              prefixIcon: Icon(Icons.repeat),
            ),
            items: RepeatOption.values
                .map((option) => DropdownMenuItem(
                      value: option,
                      child: Text(repeatOptionLabel(l10n, option)),
                    ))
                .toList(),
            onChanged: (value) => setState(() => _repeatOption = value!),
          ),
          // Animated end date field (appears when repeat is enabled)
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _repeatOption != RepeatOption.noRepeat
                ? Column(
                    children: [
                      const SizedBox(height: 12),
                      ListTile(
                        leading: const Icon(Icons.event_outlined),
                        title: Text(
                          _endDate == null
                              ? l10n.addEventRepeatUntilOptional
                              : l10n.addEventRepeatUntilDate(
                                  DateFormat.yMMMd(localeName).format(_endDate!),
                                ),
                        ),
                        trailing: _endDate != null
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () => setState(() => _endDate = null),
                              )
                            : null,
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate:
                                _endDate ?? widget.date.add(const Duration(days: 90)),
                            firstDate: widget.date,
                            lastDate: widget.date.add(const Duration(days: 365 * 2)),
                          );
                          if (picked != null) {
                            setState(() => _endDate = picked);
                          }
                        },
                      ),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (widget.onClose != null)
                TextButton(onPressed: widget.onClose, child: Text(l10n.cancel)),
              const Spacer(),
              FilledButton(
                onPressed: () {
                  if (!_formKey.currentState!.validate()) return;
                  if (_end.hour * 60 + _end.minute <=
                      _start.hour * 60 + _start.minute) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n.addEventEndTimeError),
                      ),
                    );
                    return;
                  }

                  // Repeat mapping
                  Set<int>? weekdays;
                  switch (_repeatOption) {
                    case RepeatOption.noRepeat:
                      weekdays = {widget.date.weekday};
                      break;
                    case RepeatOption.daily:
                      weekdays = {1, 2, 3, 4, 5, 6, 7};
                      break;
                    case RepeatOption.weekly:
                    case RepeatOption.monthly:
                    case RepeatOption.yearly:
                      weekdays = {widget.date.weekday};
                      break;
                  }

                  widget.onSubmit(
                    QuickAddEvent(
                      title: _titleController.text.trim(),
                      start: _start,
                      end: _end,
                      role: _role,
                      date: widget.date,
                      childId: _childId!,
                      placeName: _placeController.text.trim(),
                      responsibleMemberId: _responsibleId,
                      repeatWeekdays: weekdays,
                      endDate: _endDate,
                      repeatOption: _repeatOption,
                    ),
                  );
                },
                child: Text(l10n.save),
              ),
            ],
          ),
        ],
      ),
    );
  }

}

class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.label,
    required this.time,
    required this.onChanged,
  });

  final String label;
  final TimeOfDay time;
  final ValueChanged<TimeOfDay> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final picked = await _showCustomTimePicker(context, time);
        if (picked != null) {
          onChanged(picked);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).colorScheme.outline),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text(
                '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
          ),
        ],
        ),
      ),
    );
  }

  Future<TimeOfDay?> _showCustomTimePicker(BuildContext context, TimeOfDay initialTime) {
    return showDialog<TimeOfDay>(
      context: context,
      builder: (context) => _CustomTimePicker(
        initialTime: initialTime,
        onTimeChanged: (time) {
          Navigator.of(context).pop(time);
        },
      ),
    );
  }
}

class _CustomTimePicker extends StatefulWidget {
  const _CustomTimePicker({
    required this.initialTime,
    required this.onTimeChanged,
  });

  final TimeOfDay initialTime;
  final ValueChanged<TimeOfDay> onTimeChanged;

  @override
  State<_CustomTimePicker> createState() => _CustomTimePickerState();
}

class _CustomTimePickerState extends State<_CustomTimePicker> {
  late int selectedHour;
  late int selectedMinute;
  late FixedExtentScrollController hourController;
  late FixedExtentScrollController minuteController;

  @override
  void initState() {
    super.initState();
    selectedHour = widget.initialTime.hour;
    selectedMinute = widget.initialTime.minute;
    hourController = FixedExtentScrollController(initialItem: selectedHour);
    minuteController = FixedExtentScrollController(initialItem: selectedMinute);
  }

  @override
  void dispose() {
    hourController.dispose();
    minuteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.addEventSelectTimeTitle,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 24),
            // Time picker with spinners
            SizedBox(
              height: 160,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Hours
                  SizedBox(
                    width: 80,
                    child: ListWheelScrollView(
                      controller: hourController,
                      itemExtent: 60,
                      physics: const FixedExtentScrollPhysics(),
                      diameterRatio: 1.5,
                      onSelectedItemChanged: (index) {
                        setState(() => selectedHour = index);
                      },
                      children: List.generate(
                        24,
                        (i) => Center(
                          child: Text(
                            i.toString().padLeft(2, '0'),
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: selectedHour == i
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.4),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  // Separator
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      ':',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  // Minutes
                  SizedBox(
                    width: 80,
                    child: ListWheelScrollView(
                      controller: minuteController,
                      itemExtent: 60,
                      physics: const FixedExtentScrollPhysics(),
                      diameterRatio: 1.5,
                      onSelectedItemChanged: (index) {
                        setState(() => selectedMinute = index);
                      },
                      children: List.generate(
                        60,
                        (i) => Center(
                          child: Text(
                            i.toString().padLeft(2, '0'),
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: selectedMinute == i
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.4),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.cancel),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: () {
                    widget.onTimeChanged(
                      TimeOfDay(hour: selectedHour, minute: selectedMinute),
                    );
                  },
                  child: Text(l10n.ok),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EditEventForm extends StatefulWidget {
  const _EditEventForm({
    super.key,
    required this.event,
    required this.placeName,
    required this.date,
    required this.onSubmit,
  });

  final RecurringEvent event;
  final String placeName;
  final DateTime date;
  final ValueChanged<RecurringEvent> onSubmit;

  @override
  State<_EditEventForm> createState() => _EditEventFormState();
}

class _EditEventFormState extends State<_EditEventForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _placeController;
  late TimeOfDay _start;
  late TimeOfDay _end;
  late EventRole _role;
  late String? _childId;
  late String? _responsibleId;
  RepeatOption _repeatOption = RepeatOption.noRepeat;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.event.title ?? '');
    _placeController = TextEditingController(text: widget.placeName);
    _start = widget.event.startTime;
    _end = widget.event.endTime;
    _role = widget.event.role;
    _childId = widget.event.childId;
    _responsibleId = widget.event.responsibleMemberId;
    _endDate = widget.event.endDate;
    
    // Determine repeat option from event.recurrence
    switch (widget.event.recurrence) {
      case RecurrenceRule.none:
        _repeatOption = RepeatOption.noRepeat;
        break;
      case RecurrenceRule.daily:
        _repeatOption = RepeatOption.daily;
        break;
      case RecurrenceRule.weekly:
        _repeatOption = RepeatOption.weekly;
        break;
      case RecurrenceRule.monthly:
        _repeatOption = RepeatOption.monthly;
        break;
      case RecurrenceRule.yearly:
        _repeatOption = RepeatOption.yearly;
        break;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _placeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeName = Localizations.localeOf(context).toLanguageTag();
    final state = context.watch<FamilyCalState>();
    
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _titleController,
            decoration: InputDecoration(labelText: l10n.addEventTitleLabel),
            validator: (value) =>
                value == null || value.trim().isEmpty ? l10n.addEventTitleRequired : null,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _TimeField(
                  label: l10n.addEventStartLabel,
                  time: _start,
                  onChanged: (value) => setState(() {
                    _start = value;
                    final startMinutes = _start.hour * 60 + _start.minute;
                    final endMinutes = _end.hour * 60 + _end.minute;
                    if (endMinutes < startMinutes) {
                      _end = TimeOfDay(hour: _start.hour, minute: _start.minute);
                    }
                  }),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TimeField(
                  label: l10n.addEventEndLabel,
                  time: _end,
                  onChanged: (value) => setState(() => _end = value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _childId,
            decoration: InputDecoration(labelText: l10n.addEventChildLabel),
            items: state.children
                .map((child) => DropdownMenuItem(value: child.id, child: Text(child.displayName)))
                .toList(),
            onChanged: (value) => setState(() => _childId = value),
            validator: (value) => value == null ? l10n.addEventChildRequired : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _placeController,
            decoration: InputDecoration(
              labelText: l10n.addEventPlaceLabel,
              hintText: l10n.addEventPlaceHint,
            ),
          ),
          const SizedBox(height: 12),
          SegmentedButton<EventRole>(
            segments: EventRole.values
                .map((role) {
              final roleLabels = {
                EventRole.dropOff: l10n.eventRoleDropOff,
                EventRole.pickUp: l10n.eventRolePickUp,
              };
              return ButtonSegment(value: role, label: Text(roleLabels[role]!));
            }).toList(),
            selected: {_role},
            onSelectionChanged: (value) => setState(() => _role = value.first),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
            value: _responsibleId?.isEmpty ?? true ? null : _responsibleId,
            decoration: InputDecoration(labelText: l10n.addEventAssignLabel),
            items: [
              const DropdownMenuItem(value: null, child: Text('Unassigned')),
              ...state.members.map((m) => DropdownMenuItem(value: m.id, child: Text(m.displayName))),
            ],
            onChanged: (value) => setState(() => _responsibleId = value),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.repeat),
            title: Text(l10n.addEventRepeatLabel),
            subtitle: Text(_getRepeatText(l10n)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showRepeatDialog(context, l10n),
          ),
          if (_repeatOption != RepeatOption.noRepeat) ...[
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.event_outlined),
              title: Text(_endDate == null
                  ? l10n.addEventRepeatUntilOptional
                  : l10n.addEventRepeatUntilDate(
                      DateFormat.yMMMd(localeName).format(_endDate!),
                    )),
              trailing: _endDate != null
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _endDate = null),
                    )
                  : null,
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _endDate ?? widget.date.add(const Duration(days: 90)),
                  firstDate: widget.date,
                  lastDate: widget.date.add(const Duration(days: 365 * 2)),
                );
                if (picked != null) {
                  setState(() => _endDate = picked);
                }
              },
            ),
          ],
        ],
      ),
    );
  }

  String _getRepeatText(AppLocalizations l10n) {
    return repeatOptionLabel(l10n, _repeatOption);
  }

  void _showRepeatDialog(BuildContext context, AppLocalizations l10n) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.addEventRepeatDialogTitle),
        contentPadding: const EdgeInsets.symmetric(vertical: 8),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final opt in RepeatOption.values)
              RadioListTile<RepeatOption>(
                value: opt,
                groupValue: _repeatOption,
                onChanged: (value) {
                  setState(() => _repeatOption = value!);
                  Navigator.of(context).pop();
                },
                title: Text(repeatOptionLabel(l10n, opt)),
              ),
          ],
        ),
      ),
    );
  }

  void saveEvent() {
    if (!_formKey.currentState!.validate()) return;
    
    if (_end.hour * 60 + _end.minute <= _start.hour * 60 + _start.minute) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context)!.addEventEndTimeError)),
      );
      return;
    }

    final state = context.read<FamilyCalState>();
    
    // Handle place (optional)
    String placeId;
    if (_placeController.text.trim().isEmpty) {
      // Keep existing place if no new place specified
      placeId = widget.event.placeId;
    } else {
      // Find or create place
      FamilyPlace? existingPlace;
      for (final place in state.places) {
        if (place.name.toLowerCase() == _placeController.text.trim().toLowerCase()) {
          existingPlace = place;
          break;
        }
      }
      
      placeId = existingPlace?.id ?? 'place-${DateTime.now().millisecondsSinceEpoch}';
      
      // Create place if it doesn't exist
      if (existingPlace == null) {
        final newPlace = FamilyPlace(
          id: placeId,
          name: _placeController.text.trim(),
          address: '',
          radiusMeters: 150,
        );
        state.addPlace(newPlace);
      }
    }

    // Calculate weekdays based on repeat option
    Set<int> weekdays;
    switch (_repeatOption) {
      case RepeatOption.noRepeat:
        weekdays = {widget.date.weekday};
        break;
      case RepeatOption.daily:
        weekdays = {1, 2, 3, 4, 5, 6, 7};
        break;
      case RepeatOption.weekly:
        weekdays = {widget.date.weekday};
        break;
      case RepeatOption.monthly:
      case RepeatOption.yearly:
        weekdays = {widget.date.weekday};
        break;
    }

    // Normalize no-repeat to single occurrence by setting endDate == date
    final normalizedEndDate =
        _repeatOption == RepeatOption.noRepeat ? DateUtils.dateOnly(widget.date) : _endDate;

    // Map repeat option to recurrence rule
    final updatedRecurrence = switch (_repeatOption) {
      RepeatOption.noRepeat => RecurrenceRule.none,
      RepeatOption.daily => RecurrenceRule.daily,
      RepeatOption.weekly => RecurrenceRule.weekly,
      RepeatOption.monthly => RecurrenceRule.monthly,
      RepeatOption.yearly => RecurrenceRule.yearly,
    };

    final updatedEvent = RecurringEvent(
      id: widget.event.id,
      childId: _childId!,
      placeId: placeId,
      role: _role,
      recurrence: updatedRecurrence,
      responsibleMemberId: _responsibleId?.isEmpty ?? true ? null : _responsibleId,
      startTime: _start,
      endTime: _end,
      weekdays: weekdays,
      startDate: widget.event.startDate,
      endDate: normalizedEndDate,
      title: _titleController.text.trim(),
      notes: widget.event.notes,
    );

    widget.onSubmit(updatedEvent);
  }
}

class _MonthYearPickerSheet extends StatefulWidget {
  const _MonthYearPickerSheet({required this.initialDate});

  final DateTime initialDate;

  @override
  State<_MonthYearPickerSheet> createState() => _MonthYearPickerSheetState();
}

class _MonthYearPickerSheetState extends State<_MonthYearPickerSheet> {
  late int _selectedYear;
  late int _selectedMonth;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialDate.year;
    _selectedMonth = widget.initialDate.month;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final localeName = Localizations.localeOf(context).toLanguageTag();
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Year selector
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => setState(() => _selectedYear--),
              ),
              const SizedBox(width: 16),
              InkWell(
                onTap: () {
                  // Allow direct year input or show year picker
                },
                child: Text(
                  '$_selectedYear',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_drop_down,
                color: theme.colorScheme.onSurface,
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => setState(() => _selectedYear++),
              ),
            ],
          ),
          const SizedBox(height: 32),
          // Month grid
          GridView.count(
            shrinkWrap: true,
            crossAxisCount: 4,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.2,
            children: List.generate(12, (index) {
              final month = index + 1;
              final monthName = DateFormat('MMM', localeName).format(DateTime(_selectedYear, month));
              final isSelected = month == _selectedMonth && _selectedYear == widget.initialDate.year;
              final isCurrentMonth = month == now.month && _selectedYear == now.year;
              
              return InkWell(
                onTap: () {
                  Navigator.of(context).pop(DateTime(_selectedYear, month));
                },
                borderRadius: BorderRadius.circular(50),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected
                        ? theme.colorScheme.primary
                        : Colors.transparent,
                    border: isCurrentMonth && !isSelected
                        ? Border.all(
                            color: theme.colorScheme.primary,
                            width: 2,
                          )
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      monthName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: isSelected
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurface,
                        fontWeight: isSelected || isCurrentMonth
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

/// Swipe hint overlay - shows pulsing arrows on left/right edges
class _SwipeHintOverlay extends StatefulWidget {
  const _SwipeHintOverlay();

  @override
  State<_SwipeHintOverlay> createState() => _SwipeHintOverlayState();
}

class _SwipeHintOverlayState extends State<_SwipeHintOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0.3, end: 0.8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return IgnorePointer(
      child: Container(
        color: Colors.transparent,
        child: Stack(
          children: [
            // Left arrow hint
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 16),
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: primaryColor.withOpacity(0.1),
                      ),
                      child: Icon(
                        Icons.chevron_left,
                        size: 32,
                        color: primaryColor,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Right arrow hint
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: primaryColor.withOpacity(0.1),
                      ),
                      child: Icon(
                        Icons.chevron_right,
                        size: 32,
                        color: primaryColor,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String repeatOptionLabel(AppLocalizations l10n, RepeatOption option) {
  switch (option) {
    case RepeatOption.noRepeat:
      return l10n.addEventRepeatNone;
    case RepeatOption.daily:
      return l10n.addEventRepeatDaily;
    case RepeatOption.weekly:
      return l10n.addEventRepeatWeekly;
    case RepeatOption.monthly:
      return l10n.addEventRepeatMonthly;
    case RepeatOption.yearly:
      return l10n.addEventRepeatYearly;
  }
}
