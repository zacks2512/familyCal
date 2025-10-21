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

class _AddEventScreenState extends State<AddEventScreen> {
  final formKey = GlobalKey<FormState>();

  String? selectedChildId;
  String? selectedPlaceId;
  String? selectedResponsibleId;
  EventRole role = EventRole.dropOff;
  final Set<int> weekdays = {DateTime.monday};
  DateTime startDate = DateUtils.dateOnly(DateTime.now());
  DateTime? endDate;
  TimeOfDay startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay endTime = const TimeOfDay(hour: 8, minute: 30);
  bool useEndDate = false;
  int reminderMinutes = 15;
  final noteController = TextEditingController();

  @override
  void dispose() {
    noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FamilyCalState>();
    final children = state.children;
    final places = state.places;
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
                  onPressed: () async {
                    final newChild = await _showAddChildDialog(context);
                    if (newChild != null) {
                      if (context.mounted) {
                        context.read<FamilyCalState>().addChild(newChild);
                        setState(() => selectedChildId = newChild.id);
                      }
                    }
                  },
                ),
              ),
              validator: (value) => value == null ? 'Select a child' : null,
            ),
            const SizedBox(height: 16),
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
                if (value != null) {
                  role = value;
                }
              }),
              decoration: const InputDecoration(
                labelText: 'Role *',
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: selectedPlaceId,
              onChanged: (value) => setState(() => selectedPlaceId = value),
              items: places
                  .map(
                    (place) => DropdownMenuItem(
                      value: place.id,
                      child: Text('${place.name} (${place.radiusMeters}m)'),
                    ),
                  )
                  .toList(),
              decoration: InputDecoration(
                labelText: 'Place *',
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add_location_alt_outlined),
                  onPressed: () async {
                    final place = await _showAddPlaceDialog(context);
                    if (place != null) {
                      if (context.mounted) {
                        context.read<FamilyCalState>().addPlace(place);
                        setState(() => selectedPlaceId = place.id);
                      }
                    }
                  },
                ),
              ),
              validator: (value) => value == null ? 'Select a place' : null,
            ),
            const SizedBox(height: 16),
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
              validator: (value) => value == null ? 'Select a responsible adult' : null,
            ),
            const SizedBox(height: 16),
            _WeekdaySelector(
              selectedWeekdays: weekdays,
              onChanged: (value) => setState(() {
                if (weekdays.contains(value)) {
                  weekdays.remove(value);
                } else {
                  weekdays.add(value);
                }
              }),
            ),
            if (weekdays.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Pick at least one weekday.',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            const SizedBox(height: 24),
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
                      if (picked != null) {
                        setState(() => startTime = picked);
                      }
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
                      if (picked != null) {
                        setState(() => endTime = picked);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
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
                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    setState(() => startDate = picked);
                  }
                },
              ),
            ),
            SwitchListTile(
              title: const Text('Specify end date'),
              value: useEndDate,
              onChanged: (value) => setState(() {
                useEndDate = value;
                if (!useEndDate) {
                  endDate = null;
                } else {
                  endDate = startDate.add(const Duration(days: 60));
                }
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
                      lastDate: startDate.add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() => endDate = picked);
                    }
                  },
                ),
              ),
            DropdownButtonFormField<int>(
              value: reminderMinutes,
              onChanged: (value) => setState(() {
                if (value != null) {
                  reminderMinutes = value;
                }
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
          onPressed: () {
            final isValid = formKey.currentState?.validate() ?? false;
            if (!isValid || weekdays.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Fill required fields to continue.')),
              );
              return;
            }
            if (!_isChronological(startTime, endTime)) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('End time must be after start time.')),
              );
              return;
            }
            final event = RecurringEvent(
              id: 'event-${DateTime.now().millisecondsSinceEpoch}',
              childId: selectedChildId!,
              placeId: selectedPlaceId!,
              role: role,
              responsibleMemberId: selectedResponsibleId ?? state.currentMemberId,
              startTime: startTime,
              endTime: endTime,
              weekdays: Set.of(weekdays),
              startDate: startDate,
              endDate: useEndDate ? endDate : null,
              notes: noteController.text.trim().isEmpty ? null : noteController.text.trim(),
              reminderMinutes: [reminderMinutes],
            );
            context.read<FamilyCalState>().addEvent(event);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    '${role.label} for ${state.childById(event.childId).displayName} saved.'),
              ),
            );
            _resetForm();
          },
          label: const Text('Save event'),
        ),
      ),
    );
  }

  void _resetForm() {
    setState(() {
      selectedChildId = null;
      selectedPlaceId = null;
      selectedResponsibleId = null;
      role = EventRole.dropOff;
      weekdays.clear();
      weekdays.add(DateTime.monday);
      startDate = DateUtils.dateOnly(DateTime.now());
      endDate = null;
      useEndDate = false;
      startTime = const TimeOfDay(hour: 8, minute: 0);
      endTime = const TimeOfDay(hour: 8, minute: 30);
      reminderMinutes = 15;
      noteController.clear();
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
                    if (nameController.text.trim().isEmpty) {
                      return;
                    }
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

  Future<FamilyPlace?> _showAddPlaceDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    return showDialog<FamilyPlace>(
      context: context,
      builder: (dialogContext) {
        int radius = 150;
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Add place'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                  ),
                  TextField(
                    controller: addressController,
                    decoration: const InputDecoration(labelText: 'Address'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Radius'),
                      Expanded(
                        child: Slider(
                          value: radius.toDouble(),
                          min: 50,
                          max: 250,
                          divisions: 8,
                          label: '$radius m',
                          onChanged: (value) =>
                              setStateDialog(() => radius = value.round()),
                        ),
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
                    if (nameController.text.trim().isEmpty) {
                      return;
                    }
                    Navigator.of(dialogContext).pop(
                      FamilyPlace(
                        id: 'place-${DateTime.now().millisecondsSinceEpoch}',
                        name: nameController.text.trim(),
                        address: addressController.text.trim(),
                        radiusMeters: radius,
                      ),
                    );
                  },
                  child: const Text('Add place'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _WeekdaySelector extends StatelessWidget {
  const _WeekdaySelector({
    required this.selectedWeekdays,
    required this.onChanged,
  });

  final Set<int> selectedWeekdays;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const days = [
      DateTime.monday,
      DateTime.tuesday,
      DateTime.wednesday,
      DateTime.thursday,
      DateTime.friday,
      DateTime.saturday,
      DateTime.sunday,
    ];

    return Wrap(
      spacing: 8,
      children: [
        for (final day in days)
          ChoiceChip(
            label: Text(DateFormat('EEE').format(DateTime(2024, 1, day))),
            selected: selectedWeekdays.contains(day),
            onSelected: (_) => onChanged(day),
          ),
      ],
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
