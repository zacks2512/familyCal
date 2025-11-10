import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
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
                        DateFormat('MMMM yyyy').format(state.visibleMonth),
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
            startTime: fmt(event.start),
            endTime: fmt(event.end),
            startDate: DateUtils.dateOnly(event.date),
            weekdays: (event.repeatWeekdays ?? {event.date.weekday}).toList(),
            responsibleMemberId: (event.responsibleMemberId?.isEmpty ?? true)
                ? null
                : event.responsibleMemberId,
            endDate: event.endDate != null ? DateUtils.dateOnly(event.endDate!) : null,
            title: event.title,
            notes: null,
          );
          if (!mounted) return;
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Added ${event.title}')));
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
      responsibleMemberId:
          (event.responsibleMemberId?.isEmpty ?? true) ? null : event.responsibleMemberId,
      startTime: event.start,
      endTime: event.end,
      weekdays: event.repeatWeekdays ?? {event.date.weekday},
      startDate: DateUtils.dateOnly(event.date),
      endDate: event.endDate != null ? DateUtils.dateOnly(event.endDate!) : null,
      title: event.title,
    );
    state.addEvent(newEvent);

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Added ${event.title}')));
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
    final segmented = SegmentedButton<CalendarViewMode>(
      style: ButtonStyle(
        padding: MaterialStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 12),
        ),
        visualDensity: VisualDensity.comfortable,
      ),
      segments: const [
        ButtonSegment(value: CalendarViewMode.day, label: Text('Day')),
        ButtonSegment(value: CalendarViewMode.week, label: Text('Week')),
        ButtonSegment(value: CalendarViewMode.month, label: Text('Month')),
      ],
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
            child: InkWell(
              onTap: onMonthLabelTap,
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        monthLabel,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.arrow_drop_down,
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
        ),
        TextButton(
          onPressed: onToday,
          child: const Text('Today'),
        ),
      ],
    );

    if (isCompact) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            navigationRow,
            const SizedBox(height: 12),
            segmented,
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
          segmented,
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

  static const _weekdayLetters = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

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
              child: Text(_weekdayLetters[i], style: style),
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
    final theme = Theme.of(context);
    final bgColor =
        isSelected ? theme.colorScheme.primary.withOpacity(0.08) : Colors.transparent;
    final borderColor = isSelected
        ? theme.colorScheme.primary
        : theme.dividerColor.withOpacity(0.4);

    final calendarState = context.read<FamilyCalState>();
    const maxVisible = 2;
    final visibleEvents = events.take(maxVisible).toList();
    final remainingCount =
        events.length > maxVisible ? events.length - maxVisible : 0;

    return Semantics(
      label:
          'Day ${DateFormat('EEEE, MMMM d').format(day)} with ${events.length} events'
          '${hasWarning ? ' and events missing assignment' : ''}',
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: borderColor, width: 0.7),
            color: bgColor,
          ),
          padding: const EdgeInsets.all(4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${day.day}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: inMonth
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                ),
              ),
              if (events.isNotEmpty)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final event in visibleEvents)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 2),
                            child: Row(
                              children: [
                                Icon(
                                  event.event.role == EventRole.dropOff 
                                      ? Icons.arrow_downward 
                                      : Icons.arrow_upward,
                                  size: 8,
                                  color: calendarState.childById(event.event.childId).color,
                                ),
                                const SizedBox(width: 2),
                                Expanded(
                                  child: Text(
                                    event.event.title?.isNotEmpty == true
                                        ? event.event.title!
                                        : calendarState
                                            .childById(event.event.childId)
                                            .displayName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      fontWeight: FontWeight.w500,
                                      color: calendarState.childById(event.event.childId).color,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (remainingCount > 0)
                          Text(
                            '+$remainingCount',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        const Spacer(),
                        if (hasWarning)
                          Icon(Icons.error,
                              size: 12, color: theme.colorScheme.error),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/* ───────────────────────── Week View (fixed size tiles, inline details) ───────────────────────── */

double _weekStripHeight(BuildContext context) {
  // Adaptive & clamped so all tiles have the same height on any device/text scale
  final theme = Theme.of(context);
  final scale = MediaQuery.textScaleFactorOf(context);

  final weekdayFs = (theme.textTheme.bodyMedium?.fontSize ?? 14) * scale; // “S”
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
    final state = context.read<FamilyCalState>();

    return Semantics(
      label:
          '${DateFormat('EEEE').format(day)} ${events.length} events ${hasWarning ? 'includes unassigned events' : ''}',
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
                DateFormat('EEEEE').format(day),
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
                    ? const Center(
                        child: Text('No events',
                            style: TextStyle(fontSize: 12)))
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
    final dayLabel = DateFormat('EEEE, MMM d').format(day);

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
                    label: const Text('Add Event'),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (events.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text('No events yet. Add one to get started.'),
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
    final format = DateFormat('h:mm a');
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
                  tooltip: 'Edit event',
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
                    label: const Text('Assign pickup/drop-off'),
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
                                SnackBar(content: Text('Updated ${updatedEvent.title}')),
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
                              label: const Text('Delete'),
                              style: TextButton.styleFrom(
                                foregroundColor: Theme.of(context).colorScheme.error,
                              ),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Cancel'),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              onPressed: () => formKey.currentState?.saveEvent(),
                              child: const Text('Save'),
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
        title: const Text('Delete event?'),
        content: Text('Are you sure you want to delete "${instance.event.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
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
                  const SnackBar(content: Text('Event deleted')),
                );
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete'),
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
    final dayLabel = DateFormat('EEEE, MMM d').format(day);
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
                label: const Text('Add Event'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (events.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text('No events scheduled for this day.'),
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
    final state = context.watch<FamilyCalState>();
    if (state.children.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'Add at least one child before scheduling events.',
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
            decoration: const InputDecoration(labelText: 'Title'),
            validator: (value) =>
                value == null || value.trim().isEmpty ? 'Enter a title' : null,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _TimeField(
                  label: 'Start',
                  time: _start,
                  onChanged: (value) => setState(() => _start = value),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TimeField(
                  label: 'End',
                  time: _end,
                  onChanged: (value) => setState(() => _end = value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _childId,
            decoration: const InputDecoration(labelText: 'Child'),
            items: state.children
                .map((child) =>
                    DropdownMenuItem(value: child.id, child: Text(child.displayName)))
                .toList(),
            onChanged: (value) => setState(() => _childId = value),
            validator: (value) => value == null ? 'Select a child' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _placeController,
            decoration: const InputDecoration(
              labelText: 'Place (optional)',
              hintText: 'School, gym, home, etc.',
            ),
          ),
          const SizedBox(height: 12),
          SegmentedButton<EventRole>(
            segments: EventRole.values
                .map((role) => ButtonSegment(value: role, label: Text(role.label)))
                .toList(),
            selected: {_role},
            onSelectionChanged: (value) => setState(() => _role = value.first),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
            value: _responsibleId,
            decoration: const InputDecoration(labelText: 'Assign to'),
            items: [
              const DropdownMenuItem(value: null, child: Text('Unassigned')),
              ...state.members.map(
                  (m) => DropdownMenuItem(value: m.id, child: Text(m.displayName))),
            ],
            onChanged: (value) => setState(() => _responsibleId = value),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.repeat),
            title: const Text('Repeat'),
            subtitle: Text(_getRepeatText()),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showRepeatDialog(context),
          ),
          if (_repeatOption != RepeatOption.noRepeat) ...[
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.event_outlined),
              title: Text(_endDate == null
                  ? 'Repeat until... (optional)'
                  : 'Until: ${DateFormat.yMMMd().format(_endDate!)}'),
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
          const SizedBox(height: 16),
          Row(
            children: [
              if (widget.onClose != null)
                TextButton(onPressed: widget.onClose, child: const Text('Cancel')),
              const Spacer(),
              FilledButton(
                onPressed: () {
                  if (!_formKey.currentState!.validate()) return;
                  if (_end.hour * 60 + _end.minute <=
                      _start.hour * 60 + _start.minute) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('End time must be after the start time.'),
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
                    ),
                  );
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _getRepeatText() {
    switch (_repeatOption) {
      case RepeatOption.noRepeat:
        return "Don't repeat";
      case RepeatOption.daily:
        return 'Every 1 day';
      case RepeatOption.weekly:
        return 'Every 1 week';
      case RepeatOption.monthly:
        return 'Every 1 month';
      case RepeatOption.yearly:
        return 'Every 1 year';
    }
  }

  void _showRepeatDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Repeat'),
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
                title: Text({
                      RepeatOption.noRepeat: "Don't repeat",
                      RepeatOption.daily: 'Every 1 day',
                      RepeatOption.weekly: 'Every 1 week',
                      RepeatOption.monthly: 'Every 1 month',
                      RepeatOption.yearly: 'Every 1 year',
                    }[opt]!),
              ),
          ],
        ),
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
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
      onPressed: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: time,
        );
        if (picked != null) onChanged(picked);
      },
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            time.format(context),
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
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
    
    // Determine repeat option from weekdays
    if (widget.event.weekdays.length == 7) {
      _repeatOption = RepeatOption.daily;
    } else if (widget.event.weekdays.length == 1) {
      _repeatOption = RepeatOption.noRepeat;
    } else {
      _repeatOption = RepeatOption.weekly;
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
    final state = context.watch<FamilyCalState>();
    
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: 'Title'),
            validator: (value) => value == null || value.trim().isEmpty ? 'Enter a title' : null,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _TimeField(
                  label: 'Start',
                  time: _start,
                  onChanged: (value) => setState(() => _start = value),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TimeField(
                  label: 'End',
                  time: _end,
                  onChanged: (value) => setState(() => _end = value),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _childId,
            decoration: const InputDecoration(labelText: 'Child'),
            items: state.children
                .map((child) => DropdownMenuItem(value: child.id, child: Text(child.displayName)))
                .toList(),
            onChanged: (value) => setState(() => _childId = value),
            validator: (value) => value == null ? 'Select a child' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _placeController,
            decoration: const InputDecoration(
              labelText: 'Place (optional)',
              hintText: 'School, gym, home, etc.',
            ),
          ),
          const SizedBox(height: 12),
          SegmentedButton<EventRole>(
            segments: EventRole.values.map((role) => ButtonSegment(value: role, label: Text(role.label))).toList(),
            selected: {_role},
            onSelectionChanged: (value) => setState(() => _role = value.first),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
            value: _responsibleId?.isEmpty ?? true ? null : _responsibleId,
            decoration: const InputDecoration(labelText: 'Assign to'),
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
            title: const Text('Repeat'),
            subtitle: Text(_getRepeatText()),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showRepeatDialog(context),
          ),
          if (_repeatOption != RepeatOption.noRepeat) ...[
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.event_outlined),
              title: Text(_endDate == null
                  ? 'Repeat until... (optional)'
                  : 'Until: ${DateFormat.yMMMd().format(_endDate!)}'),
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

  String _getRepeatText() {
    switch (_repeatOption) {
      case RepeatOption.noRepeat:
        return "Don't repeat";
      case RepeatOption.daily:
        return 'Every 1 day';
      case RepeatOption.weekly:
        return 'Every 1 week';
      case RepeatOption.monthly:
        return 'Every 1 month';
      case RepeatOption.yearly:
        return 'Every 1 year';
    }
  }

  void _showRepeatDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Repeat'),
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
                title: Text({
                      RepeatOption.noRepeat: "Don't repeat",
                      RepeatOption.daily: 'Every 1 day',
                      RepeatOption.weekly: 'Every 1 week',
                      RepeatOption.monthly: 'Every 1 month',
                      RepeatOption.yearly: 'Every 1 year',
                    }[opt]!),
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
        const SnackBar(content: Text('End time must be after the start time.')),
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

    final updatedEvent = RecurringEvent(
      id: widget.event.id,
      childId: _childId!,
      placeId: placeId,
      role: _role,
      responsibleMemberId: _responsibleId?.isEmpty ?? true ? null : _responsibleId,
      startTime: _start,
      endTime: _end,
      weekdays: weekdays,
      startDate: widget.event.startDate,
      endDate: _endDate,
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
              final monthName = DateFormat('MMM').format(DateTime(_selectedYear, month));
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
