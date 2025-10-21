import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/entities.dart';
import '../state/app_state.dart';
import '../widgets/confirm_action_sheet.dart';
import '../widgets/event_card.dart';

class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = context.watch<FamilyCalState>();
    final now = DateTime.now();
    final upcoming = state.nowAndNextInstances(now);
    final active = upcoming.where((instance) => state.instanceIsActive(instance, now)).toList();
    final future = upcoming.where((instance) => instance.isUpcoming(now)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Today'),
        actions: [
          _UserSwitcher(current: state.currentMemberId, members: state.members),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Placeholder for future sync hook.
          await Future<void>.delayed(const Duration(milliseconds: 350));
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          children: [
            Text(
              'Now & Next',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (active.isEmpty)
              _EmptyState(
                icon: Icons.celebration,
                title: 'No open windows',
                subtitle: 'You are all caught up. Enjoy a calm moment!',
              )
            else
              ...active.map((instance) => _EventCardWrapper(
                    state: state,
                    instance: instance,
                    now: now,
                    onConfirm: () => _showConfirmSheet(context, state, instance),
                  )),
            const SizedBox(height: 24),
            Text(
              'Up next',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            if (future.isEmpty)
              _EmptyState(
                icon: Icons.free_breakfast,
                title: 'Nothing else today',
                subtitle: 'Add events from the + tab or invite your partner to assign.',
              )
            else
              ...future.map((instance) => _EventCardWrapper(
                    state: state,
                    instance: instance,
                    now: now,
                    compact: true,
                    onConfirm: () => _showConfirmSheet(context, state, instance),
                  )),
            const SizedBox(height: 32),
            _ReminderPanel(now: now, state: state),
          ],
        ),
      ),
    );
  }

  Future<void> _showConfirmSheet(
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
                ? 'Marked as complete — location verified.'
                : 'Marked as complete — geofence override saved.',
          ),
        ),
      );
    }
  }
}

class _EventCardWrapper extends StatelessWidget {
  const _EventCardWrapper({
    required this.state,
    required this.instance,
    required this.now,
    this.onConfirm,
    this.compact = false,
  });

  final FamilyCalState state;
  final EventInstance instance;
  final DateTime now;
  final VoidCallback? onConfirm;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final child = state.childById(instance.event.childId);
    final place = state.placeById(instance.event.placeId);
    final responsible = state.memberById(instance.event.responsibleMemberId);
    final confirmation = state.findConfirmation(instance);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: EventCard(
        state: state,
        instance: instance,
        child: child,
        place: place,
        responsible: responsible,
        now: now,
        onConfirm: onConfirm,
        confirmation: confirmation,
        compact: compact,
      ),
    );
  }
}

class _UserSwitcher extends StatelessWidget {
  const _UserSwitcher({required this.current, required this.members});

  final String current;
  final List<FamilyMember> members;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      initialValue: current,
      onSelected: (value) =>
          context.read<FamilyCalState>().switchCurrentMember(value),
      itemBuilder: (context) => members
          .map(
            (member) => PopupMenuItem(
              value: member.id,
              child: Row(
                children: [
                  Icon(
                    member.id == current
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(member.displayName),
                ],
              ),
            ),
          )
          .toList(),
      child: CircleAvatar(
        child: Text(
          members
              .firstWhere((m) => m.id == current)
              .displayName
              .substring(0, 1),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.colorScheme.surfaceVariant.withOpacity(0.4),
      ),
      child: Column(
        children: [
          Icon(icon, size: 36, color: theme.colorScheme.primary),
          const SizedBox(height: 12),
          Text(
            title,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ReminderPanel extends StatelessWidget {
  const _ReminderPanel({required this.now, required this.state});

  final DateTime now;
  final FamilyCalState state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final instances = state.instancesForDay(now);
    final reminders = instances
        .where((instance) => instance.isUpcoming(now))
        .map((instance) {
          final reminderLeadMinutes = instance.event.reminderMinutes.isEmpty
              ? 15
              : instance.event.reminderMinutes.first;
          final reminderTime =
              instance.windowStart.subtract(Duration(minutes: reminderLeadMinutes));
          return (instance, reminderTime);
        })
        .take(3)
        .toList();
    if (reminders.isEmpty) {
      return const SizedBox.shrink();
    }
    return Card(
      elevation: 0,
      color: theme.colorScheme.primaryContainer.withOpacity(0.3),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Next reminders',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            for (final entry in reminders)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(Icons.notifications_active,
                        size: 18, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${state.childById(entry.$1.event.childId).displayName} • ${entry.$1.event.role.label} reminder at '
                        '${TimeOfDay.fromDateTime(entry.$2).format(context)}',
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
