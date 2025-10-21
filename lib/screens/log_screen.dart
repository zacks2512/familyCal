import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/entities.dart';
import '../state/app_state.dart';

class LogScreen extends StatefulWidget {
  const LogScreen({super.key});

  @override
  State<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> {
  String? selectedChildId;
  DateTime selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  bool showOnlyGeoVerified = false;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FamilyCalState>();
    final children = state.children;
    final logs = state.logsForChildAndMonth(
      selectedChildId,
      selectedMonth,
    ).where((log) => !showOnlyGeoVerified || log.geoOk).toList();

    final monthLabel = DateFormat.yMMMM().format(selectedMonth);

    final months = _availableMonths(state)
      ..sort((a, b) => b.compareTo(a));

    final geoRate = logs.isEmpty
        ? null
        : logs.where((log) => log.geoOk).length / logs.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Activity log'),
        actions: [
          IconButton(
            tooltip: 'Export PDF',
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Generating ${monthLabel} PDF...'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
          IconButton(
            tooltip: 'Share summary',
            icon: const Icon(Icons.ios_share),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Share sheet would open on device.'),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedChildId,
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('All children'),
                      ),
                      ...children.map(
                        (child) => DropdownMenuItem(
                          value: child.id,
                          child: Text(child.displayName),
                        ),
                      ),
                    ],
                    onChanged: (value) => setState(() => selectedChildId = value),
                    decoration: const InputDecoration(
                      labelText: 'Filter by child',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<DateTime>(
                    value: months.contains(selectedMonth) ? selectedMonth : months.first,
                    items: months
                        .map(
                          (month) => DropdownMenuItem(
                            value: month,
                            child: Text(DateFormat.yMMM().format(month)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => selectedMonth = value);
                      }
                    },
                    decoration: const InputDecoration(labelText: 'Month'),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${logs.length} confirmation${logs.length == 1 ? '' : 's'} • $monthLabel',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                if (geoRate != null)
                  Chip(
                    avatar: const Icon(Icons.place, size: 16),
                    label: Text('${(geoRate * 100).round()}% geo verified'),
                  ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Geo verified only'),
                  selected: showOnlyGeoVerified,
                  onSelected: (value) => setState(() => showOnlyGeoVerified = value),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: logs.isEmpty
                ? const _EmptyState()
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: logs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      final child = state.childById(log.childId);
                      final place = state.placeById(log.placeId);
                      final member = state.memberById(log.confirmedById);
                      final timeLabel =
                          DateFormat('MMM d • h:mm a').format(log.confirmedAt);

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceVariant
                              .withOpacity(0.3),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: child.color,
                                  child: Text(
                                    child.displayName.substring(0, 1),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    '${child.displayName} • ${state.events.firstWhere((event) => event.id == log.eventId).role.label}',
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                ),
                                Icon(
                                  log.geoOk ? Icons.verified : Icons.warning_amber,
                                  color: log.geoOk
                                      ? Theme.of(context).colorScheme.secondary
                                      : Theme.of(context).colorScheme.error,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '$timeLabel • ${place.name}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'By ${member.displayName}${log.offline ? ' • synced later' : ''}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                            ),
                            if (log.note != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  log.note!,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  List<DateTime> _availableMonths(FamilyCalState state) {
    final months = <DateTime>{};
    for (final log in state.confirmations) {
      months.add(DateTime(log.windowStart.year, log.windowStart.month));
    }
    if (months.isEmpty) {
      months.add(DateTime(DateTime.now().year, DateTime.now().month));
    }
    return months.toList();
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined,
                size: 64, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              'No confirmations yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'Once you mark drop-offs or pickups, they\'ll appear here with location flags.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
