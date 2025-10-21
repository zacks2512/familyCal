import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/entities.dart';
import '../state/app_state.dart';
import '../widgets/confirm_action_sheet.dart';
import '../widgets/event_card.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FamilyCalState>();
    final selectedDay = state.selectedCalendarDay;
    final theme = Theme.of(context);
    final dateLabel = DateFormat('EEE, MMM d').format(selectedDay);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        actions: [
          IconButton(
            tooltip: 'Jump to today',
            icon: const Icon(Icons.today),
            onPressed: () => state.selectCalendarDay(DateTime.now()),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: Text(dateLabel),
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDay,
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        state.selectCalendarDay(picked);
                      }
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => state
                      .selectCalendarDay(selectedDay.subtract(const Duration(days: 1))),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () =>
                      state.selectCalendarDay(selectedDay.add(const Duration(days: 1))),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Day')),
                ButtonSegment(value: true, label: Text('Agenda')),
              ],
              selected: {state.showAgendaView},
              onSelectionChanged: (set) => state.toggleCalendarView(set.first),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: state.showAgendaView
                ? _AgendaView(selectedDay: selectedDay)
                : _DayTimeline(selectedDay: selectedDay),
          ),
        ],
      ),
    );
  }
}

class _DayTimeline extends StatelessWidget {
  const _DayTimeline({required this.selectedDay});

  final DateTime selectedDay;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FamilyCalState>();
    final instances = state.instancesForDay(selectedDay);
    final now = DateTime.now();

    if (instances.isEmpty) {
      return const _EmptyCalendarState(
        title: 'No events scheduled',
        subtitle: 'Tap the + tab to add a recurring drop-off or pickup.',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: instances.length,
      itemBuilder: (context, index) {
        final instance = instances[index];
        final child = state.childById(instance.event.childId);
        final place = state.placeById(instance.event.placeId);
        final responsible = state.memberById(instance.event.responsibleMemberId);
        final confirmation = state.findConfirmation(instance);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('h:mm a').format(instance.windowStart),
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 6),
              EventCard(
                state: state,
                instance: instance,
                child: child,
                place: place,
                responsible: responsible,
                now: now,
                confirmation: confirmation,
                onConfirm: state.instanceIsActive(instance, now) && confirmation == null
                    ? () => _confirmFromContext(context, state, instance)
                    : null,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AgendaView extends StatelessWidget {
  const _AgendaView({required this.selectedDay});

  final DateTime selectedDay;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FamilyCalState>();
    final agendaInstances = state.agendaFor(selectedDay);
    final now = DateTime.now();

    if (agendaInstances.isEmpty) {
      return const _EmptyCalendarState(
        title: 'Agenda is clear',
        subtitle: 'No events for the next two days. Add one from the + tab.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      itemCount: agendaInstances.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final instance = agendaInstances[index];
        final child = state.childById(instance.event.childId);
        final place = state.placeById(instance.event.placeId);
        final responsible = state.memberById(instance.event.responsibleMemberId);
        final confirmation = state.findConfirmation(instance);
        final dayLabel = DateFormat('EEE, MMM d').format(instance.windowStart);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (index == 0 ||
                !_isSameDay(
                  agendaInstances[index - 1].windowStart,
                  instance.windowStart,
                ))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  dayLabel,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(color: Theme.of(context).colorScheme.primary),
                ),
              ),
            EventCard(
              state: state,
              instance: instance,
              child: child,
              place: place,
              responsible: responsible,
              now: now,
              confirmation: confirmation,
              onTap: () => _showDetails(context, state, instance),
              onConfirm: confirmation == null && state.instanceIsActive(instance, now)
                  ? () => _confirmFromContext(context, state, instance)
                  : null,
              compact: true,
            ),
          ],
        );
      },
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _EmptyCalendarState extends StatelessWidget {
  const _EmptyCalendarState({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.event_available, size: 56, color: theme.colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              title,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

void _confirmFromContext(
  BuildContext context,
  FamilyCalState state,
  EventInstance instance,
) async {
  final result = await showConfirmActionSheet(
    context: context,
    instance: instance,
    member: state.currentMember,
    child: state.childById(instance.event.childId),
    place: state.placeById(instance.event.placeId),
  );
  if (result == null) {
    return;
  }
  state.confirmOccurrence(
    instance,
    confirmedById: state.currentMemberId,
    geoOk: result.geoOk,
    offline: result.offline,
    note: result.note?.trim().isEmpty ?? true ? null : result.note!.trim(),
  );
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          result.geoOk
              ? 'Confirmation saved.'
              : 'Confirmation saved with manual override.',
        ),
      ),
    );
  }
}

void _showDetails(
  BuildContext context,
  FamilyCalState state,
  EventInstance instance,
) {
  final child = state.childById(instance.event.childId);
  final place = state.placeById(instance.event.placeId);
  final responsible = state.memberById(instance.event.responsibleMemberId);
  final confirmation = state.findConfirmation(instance);
  final format = DateFormat('h:mm a');

  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: child.color,
                child: Text(child.displayName.substring(0, 1)),
              ),
              title: Text('${child.displayName} • ${instance.event.role.label}'),
              subtitle: Text('${format.format(instance.windowStart)} - '
                  '${format.format(instance.windowEnd)}'),
              trailing: Icon(instance.event.role.icon, color: instance.event.role.color),
            ),
            const Divider(),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.place_outlined),
              title: Text(place.name),
              subtitle: Text('${place.address}\nRadius ${place.radiusMeters}m'),
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.person_outline),
              title: Text(responsible.displayName),
              subtitle: const Text('Responsible adult'),
            ),
            if (instance.event.notes != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  instance.event.notes!,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            const SizedBox(height: 12),
            if (confirmation != null)
              ListTile(
                leading: Icon(
                  Icons.verified,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                title: Text(
                    'Confirmed at ${DateFormat('h:mm a').format(confirmation.confirmedAt)}'),
                subtitle: Text(
                  confirmation.geoOk
                      ? 'Location verified'
                      : 'Manual confirmation (geo flag)',
                ),
              ),
            if (confirmation == null)
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _confirmFromContext(context, state, instance);
                },
                child: Text(
                  instance.event.role == EventRole.dropOff
                      ? 'Mark dropped off'
                      : 'Mark picked up',
                ),
              ),
          ],
        ),
      );
    },
  );
}
