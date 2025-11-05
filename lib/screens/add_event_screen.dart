import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/entities.dart';
import '../state/app_state.dart';

class AddEventScreen extends StatefulWidget {
  const AddEventScreen({super.key});

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

/// Repeat options
enum _RepeatOption { none, daily, weekly, weekdays, custom }

class _AddEventScreenState extends State<AddEventScreen> {
  final formKey = GlobalKey<FormState>();

  String? selectedChildId;
  String? selectedResponsibleId;
  EventRole role = EventRole.dropOff;

  // Repeat UI state
  _RepeatOption repeat = _RepeatOption.custom; // keep your previous behavior
  final Set<int> weekdays = {DateTime.monday}; // Dart: 1=Mon..7=Sun
  DateTime startDate = DateUtils.dateOnly(DateTime.now());
  DateTime? endDate;
  bool useEndDate = false;

  // Time
  TimeOfDay startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay endTime = const TimeOfDay(hour: 8, minute: 30);

  // Reminder & notes
  int reminderMinutes = 15;
  final noteController = TextEditingController();

  // PLACE: free text (replaces dropdown)
  final TextEditingController placeController = TextEditingController();

  @override
  void dispose() {
    noteController.dispose();
    placeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FamilyCalState>();
    final children = state.children;
    final members = state.members;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create event'),
      ),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          children: [
            Text(
              'Assign a recurring drop-off or pickup.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),

            /// CHILD
            DropdownButtonFormField<String>(
              value: selectedChildId,
              onChanged: (value) => setState(() => selectedChildId = value),
              items: children
                  .map(
                    (child) => DropdownMenuItem(
                      value: child.id,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 12,
                            backgroundColor: child.color,
                            child: Text(
                              child.displayName.substring(0, 1),
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(child.displayName),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              decoration: InputDecoration(
                labelText: 'Child *',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.person_add_alt),
                  tooltip: 'Add child',
                  onPressed: () async {
                    final newChild = await _showAddChildDialog(context);
                    if (newChild != null && context.mounted) {
                      context.read<FamilyCalState>().addChild(newChild);
                      setState(() => selectedChildId = newChild.id);
                    }
                  },
                ),
              ),
              validator: (value) => value == null ? 'Select a child' : null,
            ),
            const SizedBox(height: 16),

            /// ROLE
            DropdownButtonFormField<EventRole>(
              value: role,
              items: EventRole.values
                  .map(
                    (eventRole) => DropdownMenuItem(
                      value: eventRole,
                      child: Text(eventRole.label),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() {
                if (value != null) role = value;
              }),
              decoration: const InputDecoration(
                labelText: 'Role *',
              ),
            ),
            const SizedBox(height: 16),

            /// PLACE (FREE TEXT)
            TextFormField(
              controller: placeController,
              decoration: InputDecoration(
                labelText: 'Place *',
                hintText: 'e.g., Kindergarten, Soccer field, Grandma',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.cleaning_services_outlined),
                  tooltip: 'Clear',
                  onPressed: () => placeController.clear(),
                ),
              ),
              textCapitalization: TextCapitalization.words,
              validator: (value) =>
                  (value == null || value.trim().isEmpty) ? 'Enter a place' : null,
            ),
            const SizedBox(height: 16),

            /// RESPONSIBLE
            DropdownButtonFormField<String>(
              value: selectedResponsibleId ?? state.currentMemberId,
              onChanged: (value) => setState(() => selectedResponsibleId = value),
              items: members
                  .map(
                    (member) => DropdownMenuItem(
                      value: member.id,
                      child: Text(member.displayName),
                    ),
                  )
                  .toList(),
              decoration: const InputDecoration(
                labelText: 'Responsible adult *',
              ),
              validator: (value) =>
                  value == null ? 'Select a responsible adult' : null,
            ),
            const SizedBox(height: 16),

            /// REPEAT PRESET
            DropdownButtonFormField<_RepeatOption>(
              value: repeat,
              decoration: const InputDecoration(labelText: 'Repeat'),
              items: const [
                DropdownMenuItem(
                  value: _RepeatOption.none,
                  child: Text('Does not repeat'),
                ),
                DropdownMenuItem(
                  value: _RepeatOption.daily,
                  child: Text('Every day'),
                ),
                DropdownMenuItem(
                  value: _RepeatOption.weekly,
                  child: Text('Every week'),
                ),
                DropdownMenuItem(
                  value: _RepeatOption.weekdays,
                  child: Text('Weekdays (Sun–Thu)'),
                ),
                DropdownMenuItem(
                  value: _RepeatOption.custom,
                  child: Text('Custom…'),
                ),
              ],
              onChanged: (value) => setState(() {
                repeat = value ?? _RepeatOption.custom;
                if (repeat != _RepeatOption.custom) {
                  // Auto-manage weekdays based on preset
                  weekdays
                    ..clear()
                    ..addAll(_weekdaySetForOption(repeat, startDate));
                }
                // End date toggle suggestion
                useEndDate = repeat != _RepeatOption.none ? useEndDate : false;
                if (!useEndDate) endDate = null;
              }),
            ),

            /// CUSTOM WEEKDAYS (Sunday-first letters)
            if (repeat == _RepeatOption.custom) ...[
              const SizedBox(height: 12),
              _WeekdaySelectorSundayFirst(
                selectedWeekdays: weekdays,
                onChanged: (day) => setState(() {
                  if (weekdays.contains(day)) {
                    weekdays.remove(day);
                  } else {
                    weekdays.add(day);
                  }
                }),
              ),
              if (weekdays.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Pick at least one weekday.',
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
            ],

            const SizedBox(height: 24),

            /// TIME
            Row(
              children: [
                Expanded(
                  child: _TimePickerTile(
                    label: 'Start',
                    time: startTime,
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: startTime,
                      );
                      if (picked != null) setState(() => startTime = picked);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _TimePickerTile(
                    label: 'End',
                    time: endTime,
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: endTime,
                      );
                      if (picked != null) setState(() => endTime = picked);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            /// START DATE
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Starts on'),
              subtitle: Text(DateFormat.yMMMMd().format(startDate)),
              trailing: IconButton(
                icon: const Icon(Icons.edit_calendar),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: startDate,
                    firstDate:
                        DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setState(() {
                      startDate = DateUtils.dateOnly(picked);
                      // If weekly preset, keep only anchor day
                      if (repeat == _RepeatOption.weekly) {
                        weekdays
                          ..clear()
                          ..add(startDate.weekday);
                      }
                    });
                  }
                },
              ),
            ),

            /// END DATE
            SwitchListTile(
              title: const Text('Specify end date'),
              value: useEndDate,
              onChanged: (value) => setState(() {
                useEndDate = value;
                endDate = value ? startDate.add(const Duration(days: 60)) : null;
              }),
            ),
            if (useEndDate)
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Ends on'),
                subtitle: endDate != null
                    ? Text(DateFormat.yMMMMd().format(endDate!))
                    : const Text('Select a date'),
                trailing: IconButton(
                  icon: const Icon(Icons.event),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: endDate ?? startDate,
                      firstDate: startDate,
                      lastDate: startDate.add(const Duration(days: 365 * 5)),
                    );
                    if (picked != null) {
                      setState(() => endDate = DateUtils.dateOnly(picked));
                    }
                  },
                ),
              ),

            /// REMINDER
            DropdownButtonFormField<int>(
              value: reminderMinutes,
              onChanged: (value) => setState(() {
                if (value != null) reminderMinutes = value;
              }),
              decoration: const InputDecoration(labelText: 'Reminder lead time'),
              items: const [
                DropdownMenuItem(value: 5, child: Text('5 minutes before')),
                DropdownMenuItem(value: 10, child: Text('10 minutes before')),
                DropdownMenuItem(value: 15, child: Text('15 minutes before')),
                DropdownMenuItem(value: 30, child: Text('30 minutes before')),
              ],
            ),
            const SizedBox(height: 16),

            /// NOTES
            TextFormField(
              controller: noteController,
              decoration: const InputDecoration(
                labelText: 'Notes for partner (optional)',
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        color: Theme.of(context).colorScheme.surface,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: FilledButton.icon(
          icon: const Icon(Icons.save),
          label: const Text('Save event'),
          onPressed: () {
            final isValid = formKey.currentState?.validate() ?? false;

            if (!isValid) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fill required fields to continue.')),
              );
              return;
            }
            if (repeat == _RepeatOption.custom && weekdays.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Pick at least one weekday.')),
              );
              return;
            }
            if (!_isChronological(startTime, endTime)) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('End time must be after start time.')),
              );
              return;
            }

            final state = context.read<FamilyCalState>();

            // Resolve or create place by free text
            final placeId = _ensurePlaceIdFromText(state, placeController.text);

            // Compute weekdays for presets
            final Set<int> chosenWeekdays = (repeat == _RepeatOption.custom)
                ? Set.of(weekdays)
                : _weekdaySetForOption(repeat, startDate);

            // If does not repeat -> endDate equals startDate
            final DateTime? finalEndDate =
                (repeat == _RepeatOption.none) ? startDate : (useEndDate ? endDate : null);

            final event = RecurringEvent(
              id: 'event-${DateTime.now().millisecondsSinceEpoch}',
              childId: selectedChildId!,
              placeId: placeId,
              role: role,
              responsibleMemberId:
                  selectedResponsibleId ?? state.currentMemberId,
              startTime: startTime,
              endTime: endTime,
              weekdays: chosenWeekdays,
              startDate: startDate,
              endDate: finalEndDate,
              notes: noteController.text.trim().isEmpty
                  ? null
                  : noteController.text.trim(),
              reminderMinutes: [reminderMinutes],
            );

            state.addEvent(event);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    '${role.label} for ${state.childById(event.childId).displayName} saved.'),
              ),
            );
            _resetForm();
          },
        ),
      ),
    );
  }

  /// Map repeat option to weekday set (Dart: 1=Mon..7=Sun)
  Set<int> _weekdaySetForOption(_RepeatOption opt, DateTime anchor) {
    switch (opt) {
      case _RepeatOption.none:
        return {anchor.weekday};
      case _RepeatOption.daily:
        return {1, 2, 3, 4, 5, 6, 7};
      case _RepeatOption.weekly:
        return {anchor.weekday};
      case _RepeatOption.weekdays:
        // Israel-style weekdays: Sun–Thu (Sun is 7 in Dart)
        return {7, 1, 2, 3, 4};
      case _RepeatOption.custom:
        return weekdays.isEmpty ? {anchor.weekday} : Set.of(weekdays);
    }
  }

  /// Create or reuse a FamilyPlace by name; returns its id.
  String _ensurePlaceIdFromText(FamilyCalState state, String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      // Fallback default place
      final fallback = FamilyPlace(
        id: 'place-${DateTime.now().millisecondsSinceEpoch}',
        name: 'General',
        address: '',
        radiusMeters: 150,
      );
      state.addPlace(fallback);
      return fallback.id;
    }
    // Try to reuse existing (case-insensitive match on name)
    for (final p in state.places) {
      if (p.name.toLowerCase() == trimmed.toLowerCase()) {
        return p.id;
      }
    }
    // Create new place
    final created = FamilyPlace(
      id: 'place-${DateTime.now().millisecondsSinceEpoch}',
      name: trimmed,
      address: '',
      radiusMeters: 150,
    );
    state.addPlace(created);
    return created.id;
  }

  void _resetForm() {
    setState(() {
      selectedChildId = null;
      selectedResponsibleId = null;
      role = EventRole.dropOff;

      repeat = _RepeatOption.custom;
      weekdays
        ..clear()
        ..add(DateTime.monday);
      startDate = DateUtils.dateOnly(DateTime.now());
      endDate = null;
      useEndDate = false;

      startTime = const TimeOfDay(hour: 8, minute: 0);
      endTime = const TimeOfDay(hour: 8, minute: 30);

      reminderMinutes = 15;
      noteController.clear();
      placeController.clear();
    });
  }

  bool _isChronological(TimeOfDay start, TimeOfDay end) {
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;
    return endMinutes > startMinutes;
  }

  Future<FamilyChild?> _showAddChildDialog(BuildContext context) async {
    final nameController = TextEditingController();
    return showDialog<FamilyChild>(
      context: context,
      builder: (dialogContext) {
        Color selectedColor = Colors.blueAccent;
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Add child'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final color in _palette)
                        ChoiceChip(
                          label: const SizedBox(width: 18, height: 18),
                          selected: selectedColor == color,
                          onSelected: (_) =>
                              setStateDialog(() => selectedColor = color),
                          selectedColor: color,
                          backgroundColor: color.withOpacity(0.3),
                        ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    if (nameController.text.trim().isEmpty) return;
                    Navigator.of(dialogContext).pop(
                      FamilyChild(
                        id: 'child-${DateTime.now().millisecondsSinceEpoch}',
                        displayName: nameController.text.trim(),
                        color: selectedColor,
                      ),
                    );
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// Sunday-first weekday selector with single letters: S M T W T F S
class _WeekdaySelectorSundayFirst extends StatelessWidget {
  const _WeekdaySelectorSundayFirst({
    required this.selectedWeekdays,
    required this.onChanged,
  });

  final Set<int> selectedWeekdays; // Dart 1=Mon..7=Sun
  final ValueChanged<int> onChanged;

  static const _labels = ['S', 'M', 'T', 'W', 'T', 'F', 'S']; // Sun..Sat

  @override
  Widget build(BuildContext context) {
    // Map Sunday-first to Dart weekdays: Sun=7, Mon=1, Tue=2, ..., Sat=6
    final dartWeekdays = const [7, 1, 2, 3, 4, 5, 6];

    return Wrap(
      spacing: 8,
      children: List.generate(7, (i) {
        final day = dartWeekdays[i];
        final selected = selectedWeekdays.contains(day);
        return ChoiceChip(
          label: Text(_labels[i]),
          selected: selected,
          onSelected: (_) => onChanged(day),
        );
      }),
    );
  }
}

class _TimePickerTile extends StatelessWidget {
  const _TimePickerTile({
    required this.label,
    required this.time,
    required this.onTap,
  });

  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      tileColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
      title: Text(label),
      subtitle: Text(time.format(context)),
      trailing: const Icon(Icons.schedule),
    );
  }
}

const _palette = [
  Colors.pinkAccent,
  Colors.orangeAccent,
  Colors.lightBlueAccent,
  Colors.greenAccent,
  Colors.purpleAccent,
  Colors.tealAccent,
  Colors.indigoAccent,
];
