import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/entities.dart';
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
  String? _quickAddPlaceId;
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
                    onViewModeChanged: (mode) {
                      context.read<FamilyCalState>().setCalendarViewMode(mode);
                    },
                  ),
                  Expanded(
                    child: _buildView(
                      context: context,
                      state: state,
                      isCompact: compact,
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
    if (event is! RawKeyDownEvent) {
      return KeyEventResult.ignored;
    }
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
          onSelectDay: (day) => _handleDayTap(context, state, day, isCompact),
          isCompact: isCompact,
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
    if (isCompact) {
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
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.8,
          child: _CalendarDayDrawer(
            day: day,
            isCompact: true,
            showQuickAddInline: true,
            onOpenQuickAdd: () {},
            onSubmitQuickAdd: (event) =>
                _submitQuickAdd(context, state, event, closeSheet: true),
            onCloseQuickAdd: () => Navigator.of(context).maybePop(),
          ),
        );
      },
    );
  }

  void _toggleQuickAdd(
    BuildContext context,
    FamilyCalState state,
    bool isCompact,
  ) {
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
      showDragHandle: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SafeArea(
            top: false,
            child: _QuickAddForm(
              titleController: _titleController,
              initialStart: _quickAddStart!,
              initialEnd: _quickAddEnd!,
              initialRole: _quickAddRole!,
              date: context.read<FamilyCalState>().selectedCalendarDay,
              childId: _quickAddChildId,
              placeId: _quickAddPlaceId,
              responsibleId: _quickAddResponsibleId,
              onSubmit: (event) {
                _submitQuickAdd(context, state, event, closeSheet: true);
              },
            ),
          ),
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
    _quickAddPlaceId =
        state.places.isNotEmpty ? state.places.first.id : null;
    _quickAddResponsibleId = state.currentMemberId;
  }

  void _submitQuickAdd(
    BuildContext context,
    FamilyCalState state,
    QuickAddEvent event, {
    bool closeSheet = false,
  }) {
    final newEvent = RecurringEvent(
      id: 'event-${DateTime.now().millisecondsSinceEpoch}',
      childId: event.childId,
      placeId: event.placeId,
      role: event.role,
      responsibleMemberId: event.responsibleMemberId?.isEmpty ?? true
          ? null
          : event.responsibleMemberId,
      startTime: event.start,
      endTime: event.end,
      weekdays: {event.date.weekday},
      startDate: DateUtils.dateOnly(event.date),
      endDate: DateUtils.dateOnly(event.date),
      title: event.title,
    );
    state.addEvent(newEvent);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Added ${event.title} on ${DateFormat.yMMMd().format(event.date)}'),
      ),
    );
    if (closeSheet) {
      Navigator.of(context).maybePop();
    } else {
      setState(() {
        _showInlineQuickAdd = false;
      });
    }
  }
}

class _CalendarHeader extends StatelessWidget {
  const _CalendarHeader({
    required this.isCompact,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onToday,
    required this.monthLabel,
    required this.viewMode,
    required this.onViewModeChanged,
  });

  final bool isCompact;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final VoidCallback onToday;
  final String monthLabel;
  final CalendarViewMode viewMode;
  final ValueChanged<CalendarViewMode> onViewModeChanged;

  @override
  Widget build(BuildContext context) {
    final segmented = SegmentedButton<CalendarViewMode>(
      style: ButtonStyle(
        padding:
            MaterialStateProperty.all(const EdgeInsets.symmetric(horizontal: 12)),
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
            label: 'Current month $monthLabel',
            child: Center(
              child: Text(
                monthLabel,
                style: Theme.of(context).textTheme.titleLarge,
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
          SizedBox(
            width: 280,
            child: navigationRow,
          ),
          segmented,
        ],
      ),
    );
  }
}

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
    final days = _buildDays(visibleMonth);
    final state = context.read<FamilyCalState>();

    if (isCompact) {
      // Fill the available height with a 7x(5|6) grid.
      return LayoutBuilder(
        builder: (context, c) {
          final rows = (days.length / 7).ceil(); // 5 or 6 depending on month
          const cols = 7;

          // Match the horizontal padding you already use.
          const horizontalPadding = 8.0 * 2;

          final cellWidth = (c.maxWidth - horizontalPadding) / cols;
          final cellHeight = c.maxHeight / rows;
          final aspect = cellWidth / cellHeight;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
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
                  (event) => state
                          .memberByIdOrNull(event.event.responsibleMemberId) ==
                      null,
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
          );
        },
      );
    }

    // Wide layout: keep existing behavior with a square grid and drawer below.
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                  (event) => state
                          .memberByIdOrNull(event.event.responsibleMemberId) ==
                      null,
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

  List<DateTime> _buildDays(DateTime month) {
    final firstOfMonth = DateTime(month.year, month.month, 1);
    final firstWeekday = firstOfMonth.weekday;
    final daysBefore = (firstWeekday + 6) % 7;
    final start = firstOfMonth.subtract(Duration(days: daysBefore));

    final lastOfMonth = DateTime(month.year, month.month + 1, 0);
    final daysAfter = (7 - lastOfMonth.weekday) % 7;
    final end = lastOfMonth.add(Duration(days: daysAfter));

    final total = end.difference(start).inDays + 1;
    return List.generate(
      total,
      (index) => DateTime(start.year, start.month, start.day + index),
    );
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
    final bgColor = isSelected
        ? theme.colorScheme.primary.withOpacity(0.08)
        : Colors.transparent;
    final borderColor = isSelected
        ? theme.colorScheme.primary
        : theme.dividerColor.withOpacity(0.4);

    final calendarState = context.read<FamilyCalState>();
    const maxVisible = 1;
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
                        if (visibleEvents.isNotEmpty)
                          for (final event in visibleEvents)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 2),
                              child: Row(
                                children: [
                                  Container(
                                    width: 4,
                                    height: 4,
                                    margin: const EdgeInsets.only(right: 4),
                                    decoration: BoxDecoration(
                                      color: event.event.role.color,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      event.event.title?.isNotEmpty == true
                                          ? event.event.title!
                                          : calendarState
                                              .childById(event.event.childId)
                                              .displayName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.labelSmall
                                          ?.copyWith(
                                        fontWeight: FontWeight.w500,
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
                          Icon(
                            Icons.error,
                            size: 12,
                            color: theme.colorScheme.error,
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
  }
}

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
    final title = instance.event.title?.isNotEmpty == true
        ? instance.event.title!
        : '${state.childById(instance.event.childId).displayName} '
            '• ${instance.event.role.label}';
    final responsible =
        state.memberByIdOrNull(instance.event.responsibleMemberId);
    final missingAssignment = responsible == null;

    return Semantics(
      label:
          '$title from $start to $end ${missingAssignment ? 'unassigned' : ''}',
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: missingAssignment
                ? Theme.of(context).colorScheme.error
                : instance.event.role.color.withOpacity(0.5),
          ),
          color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
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
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Edit flow coming soon.'),
                      ),
                    );
                  },
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
                  avatar: Icon(
                    instance.event.role.icon,
                    size: 16,
                    color: instance.event.role.color,
                  ),
                  label: Text(instance.event.role.label),
                ),
                Chip(
                  avatar: const Icon(Icons.place_outlined, size: 16),
                  label: Text(
                    state.placeById(instance.event.placeId).name,
                  ),
                ),
                if (missingAssignment)
                  Chip(
                    backgroundColor:
                        Theme.of(context).colorScheme.error.withOpacity(0.15),
                    avatar: Icon(
                      Icons.warning_amber_rounded,
                      size: 16,
                      color: Theme.of(context).colorScheme.error,
                    ),
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
}

class _WeekView extends StatelessWidget {
  const _WeekView({
    required this.selectedDay,
    required this.instancesForDay,
    required this.onSelectDay,
    required this.isCompact,
    required this.onOpenDetail,
    required this.dayDrawer,
  });

  final DateTime selectedDay;
  final List<EventInstance> Function(DateTime) instancesForDay;
  final ValueChanged<DateTime> onSelectDay;
  final bool isCompact;
  final VoidCallback onOpenDetail;
  final Widget dayDrawer;

  @override
  Widget build(BuildContext context) {
    final startOfWeek = selectedDay.subtract(
      Duration(days: selectedDay.weekday - DateTime.monday),
    );
    final days = List.generate(
      7,
      (index) => DateTime(
        startOfWeek.year,
        startOfWeek.month,
        startOfWeek.day + index,
      ),
    );

    final dayStrip = SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: days.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final day = days[index];
          final events = instancesForDay(day);
          final isSelected = DateUtils.isSameDay(day, selectedDay);
          final missingAssignment = events.any(
            (event) =>
                context
                    .read<FamilyCalState>()
                    .memberByIdOrNull(event.event.responsibleMemberId) ==
                null,
          );
          return _WeekDayCard(
            day: day,
            events: events,
            isSelected: isSelected,
            hasWarning: missingAssignment,
            onTap: () {
              onSelectDay(day);
              if (isCompact) {
                onOpenDetail();
              }
            },
          );
        },
      ),
    );

    if (isCompact) {
      return SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 96),
          child: Column(
            children: [
              dayStrip,
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: dayDrawer,
              ),
            ],
          ),
        ),
      );
    }
    return Column(
      children: [
        dayStrip,
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
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
    return Semantics(
      label:
          '${DateFormat('EEEE').format(day)} ${events.length} events ${hasWarning ? 'includes unassigned events' : ''}',
      button: true,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: 120,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.dividerColor.withOpacity(0.2),
            ),
            color: isSelected
                ? theme.colorScheme.primary.withOpacity(0.1)
                : theme.colorScheme.surface,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                DateFormat('EEE').format(day),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${day.day}',
                style: theme.textTheme.headlineSmall,
              ),
              const Spacer(),
              if (events.isEmpty)
                const Text('No events', style: TextStyle(fontSize: 12))
              else
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: events
                        .take(3)
                        .map(
                          (event) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: event.event.role.color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    event.event.title ??
                                        event.event.role.label.toLowerCase(),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              if (hasWarning)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Icon(Icons.warning_amber_rounded,
                      size: 16, color: theme.colorScheme.error),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DayView extends StatelessWidget {
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
    );
  }
}

class QuickAddEvent {
  QuickAddEvent({
    required this.title,
    required this.start,
    required this.end,
    required this.role,
    required this.date,
    required this.childId,
    required this.placeId,
    this.responsibleMemberId,
  });

  final String title;
  final TimeOfDay start;
  final TimeOfDay end;
  final EventRole role;
  final DateTime date;
  final String childId;
  final String placeId;
  final String? responsibleMemberId;
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
        placeId = null,
        responsibleId = null;

  const _QuickAddForm({
    required this.titleController,
    required this.initialStart,
    required this.initialEnd,
    required this.initialRole,
    required this.date,
    required this.childId,
    required this.placeId,
    required this.responsibleId,
    required this.onSubmit,
  }) : onClose = null;

  final TextEditingController? titleController;
  final TimeOfDay? initialStart;
  final TimeOfDay? initialEnd;
  final EventRole? initialRole;
  final DateTime date;
  final String? childId;
  final String? placeId;
  final String? responsibleId;
  final ValueChanged<QuickAddEvent> onSubmit;
  final VoidCallback? onClose;

  @override
  State<_QuickAddForm> createState() => _QuickAddFormState();
}

class _QuickAddFormState extends State<_QuickAddForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TimeOfDay _start;
  late TimeOfDay _end;
  late EventRole _role;
  late String? _childId;
  late String? _placeId;
  late String? _responsibleId;

  @override
  void initState() {
    super.initState();
    final state = context.read<FamilyCalState>();
    _titleController =
        widget.titleController ?? TextEditingController(text: '');
    _start = widget.initialStart ?? const TimeOfDay(hour: 8, minute: 0);
    _end = widget.initialEnd ??
        TimeOfDay(hour: (_start.hour + 1) % 24, minute: _start.minute);
    _role = widget.initialRole ?? EventRole.dropOff;
    _childId = widget.childId ??
        (state.children.isNotEmpty ? state.children.first.id : null);
    _placeId = widget.placeId ??
        (state.places.isNotEmpty ? state.places.first.id : null);
    _responsibleId = widget.responsibleId ?? state.currentMemberId;
  }

  @override
  void dispose() {
    if (widget.titleController == null) {
      _titleController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FamilyCalState>();
    if (state.children.isEmpty || state.places.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Text(
          'Add at least one child and place before scheduling events.',
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
                .map(
                  (child) => DropdownMenuItem(
                    value: child.id,
                    child: Text(child.displayName),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _childId = value),
            validator: (value) => value == null ? 'Select a child' : null,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _placeId,
            decoration: const InputDecoration(labelText: 'Place'),
            items: state.places
                .map(
                  (place) => DropdownMenuItem(
                    value: place.id,
                    child: Text(place.name),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => _placeId = value),
            validator: (value) => value == null ? 'Select a place' : null,
          ),
          const SizedBox(height: 12),
          SegmentedButton<EventRole>(
            segments: EventRole.values
                .map(
                  (role) => ButtonSegment(
                    value: role,
                    label: Text(role.label),
                  ),
                )
                .toList(),
            selected: {_role},
            onSelectionChanged: (value) => setState(() => _role = value.first),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _responsibleId,
            decoration: const InputDecoration(labelText: 'Assign to'),
            items: const [
              DropdownMenuItem(
                value: '',
                child: Text('Unassigned'),
              ),
            ]..addAll(
                state.members.map(
                  (member) => DropdownMenuItem(
                    value: member.id,
                    child: Text(member.displayName),
                  ),
                ),
              ),
            onChanged: (value) => setState(() => _responsibleId = value),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (widget.onClose != null)
                TextButton(
                  onPressed: widget.onClose,
                  child: const Text('Cancel'),
                ),
              const Spacer(),
              FilledButton(
                onPressed: () {
                  if (!_formKey.currentState!.validate()) {
                    return;
                  }
                  if (_end.hour * 60 + _end.minute <=
                      _start.hour * 60 + _start.minute) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content:
                            Text('End time must be after the start time.'),
                      ),
                    );
                    return;
                  }
                  widget.onSubmit(
                    QuickAddEvent(
                      title: _titleController.text.trim(),
                      start: _start,
                      end: _end,
                      role: _role,
                      date: widget.date,
                      childId: _childId!,
                      placeId: _placeId!,
                      responsibleMemberId: _responsibleId,
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
        if (picked != null) {
          onChanged(picked);
        }
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
