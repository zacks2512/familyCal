import 'package:flutter/material.dart';

import '../models/entities.dart';

class ConfirmActionResult {
  const ConfirmActionResult({
    required this.geoOk,
    required this.offline,
    this.note,
  });

  final bool geoOk;
  final bool offline;
  final String? note;
}

Future<ConfirmActionResult?> showConfirmActionSheet({
  required BuildContext context,
  required EventInstance instance,
  required FamilyMember member,
  required FamilyChild child,
  required FamilyPlace place,
}) {
  return showModalBottomSheet<ConfirmActionResult>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) {
      return _ConfirmSheet(
        instance: instance,
        member: member,
        child: child,
        place: place,
      );
    },
  );
}

class _ConfirmSheet extends StatefulWidget {
  const _ConfirmSheet({
    required this.instance,
    required this.member,
    required this.child,
    required this.place,
  });

  final EventInstance instance;
  final FamilyMember member;
  final FamilyChild child;
  final FamilyPlace place;

  @override
  State<_ConfirmSheet> createState() => _ConfirmSheetState();
}

class _ConfirmSheetState extends State<_ConfirmSheet> {
  bool geoOk = true;
  bool offline = false;
  final noteController = TextEditingController();

  @override
  void dispose() {
    noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final confirmLabel =
        widget.instance.event.role == EventRole.dropOff ? 'Dropped off' : 'Picked up';
    return Padding(
      padding: EdgeInsets.only(
        bottom: bottom,
        left: 20,
        right: 20,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(widget.instance.event.role.icon,
                  color: widget.instance.event.role.color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '$confirmLabel ${widget.child.displayName}',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${widget.place.name} • ${widget.member.displayName}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Text(
            'Confirmation options',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          SwitchListTile(
            value: geoOk,
            onChanged: (value) => setState(() => geoOk = value),
            title: const Text('Inside geofence'),
            subtitle: Text(geoOk
                ? 'Will mark as location verified.'
                : 'Marks as manual confirmation (partner will see a flag).'),
          ),
          SwitchListTile(
            value: offline,
            onChanged: (value) => setState(() => offline = value),
            title: const Text('Queue offline'),
            subtitle: const Text('Use when reception is poor; app will sync later.'),
          ),
          TextField(
            controller: noteController,
            decoration: const InputDecoration(
              labelText: 'Optional note',
              hintText: 'Add context for your partner (e.g., running late).',
            ),
            minLines: 1,
            maxLines: 2,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: () {
              Navigator.of(context).pop(
                ConfirmActionResult(
                  geoOk: geoOk,
                  offline: offline,
                  note: noteController.text,
                ),
              );
            },
            icon: const Icon(Icons.check_circle_outline),
            label: Text(confirmLabel),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
