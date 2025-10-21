import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/entities.dart';
import '../state/app_state.dart';

class EventCard extends StatelessWidget {
  EventCard({
    super.key,
    required this.state,
    required this.instance,
    required this.child,
    required this.place,
    required this.responsible,
    required this.now,
    this.onConfirm,
    this.onTap,
    this.confirmation,
    this.compact = false,
  });

  final FamilyCalState state;
  final EventInstance instance;
  final FamilyChild child;
  final FamilyPlace place;
  final FamilyMember responsible;
  final DateTime now;
  final VoidCallback? onConfirm;
  final VoidCallback? onTap;
  final ConfirmationLog? confirmation;
  final bool compact;

  final DateFormat _timeFormat = DateFormat('h:mm a');

  bool get _windowOpen => instance.windowOpenAt(now);
  bool get _windowComplete => now.isAfter(instance.windowEnd);
  bool get _isConfirmed => confirmation != null;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = child.color;
    final role = instance.event.role;
    final titleStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w600,
    );
    final timeRange =
        '${_timeFormat.format(instance.windowStart)} – ${_timeFormat.format(instance.windowEnd)}';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border(
            left: BorderSide(
              color: _isConfirmed
                  ? theme.colorScheme.secondary
                  : (_windowOpen ? role.color : color.withOpacity(0.4)),
              width: 4,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: color.withOpacity(0.2),
                  child: Text(
                    child.displayName.substring(0, 1),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${child.displayName} • ${role.label}', style: titleStyle),
                      const SizedBox(height: 4),
                      Text(
                        timeRange,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(role.icon, color: role.color),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildAssistChip(
                  context,
                  icon: Icons.place_outlined,
                  label: place.name,
                ),
                _buildAssistChip(
                  context,
                  icon: Icons.person_outline,
                  label: 'Responsible: ${responsible.displayName.split(' ').first}',
                ),
                if (instance.duration.inMinutes > 0)
                  _buildAssistChip(
                    context,
                    icon: Icons.schedule,
                    label: '${instance.duration.inMinutes} min window',
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (_isConfirmed)
              _buildConfirmationRow(theme)
            else
              Row(
                children: [
                  Expanded(child: _buildStatusText(theme)),
                  if (onConfirm != null && !_windowComplete)
                    FilledButton(
                      onPressed: onConfirm,
                      style: FilledButton.styleFrom(
                        backgroundColor: role.color,
                        foregroundColor: Colors.white,
                        padding: compact
                            ? const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              )
                            : null,
                      ),
                      child: Text(
                        role == EventRole.dropOff ? 'Dropped off' : 'Picked up',
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssistChip(
    BuildContext context, {
    required IconData icon,
    required String label,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStatusText(ThemeData theme) {
    final nowLabel = _windowOpen
        ? 'Window open • ${_countdownLabel(instance.windowEnd.difference(now))}'
        : 'Starts in ${_countdownLabel(instance.windowStart.difference(now))}';
    final text = _windowComplete ? 'Window ended' : nowLabel;
    final color = _windowOpen
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;
    return Text(
      text,
      style: theme.textTheme.bodyMedium?.copyWith(
        color: color,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _buildConfirmationRow(ThemeData theme) {
    final confirmedAt = confirmation!.confirmedAt;
    final confirmedLabel = _timeFormat.format(confirmedAt);
    final geoLabel = confirmation!.geoOk ? 'Location verified' : 'Manual confirm';
    final offlineLabel = confirmation!.offline ? 'Offline' : 'Synced';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.verified, color: theme.colorScheme.secondary),
            const SizedBox(width: 8),
            Text(
              'Confirmed • $confirmedLabel',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          children: [
            _statusChip(theme, geoLabel,
                confirmation!.geoOk ? Icons.place : Icons.warning_amber),
            _statusChip(theme, offlineLabel,
                confirmation!.offline ? Icons.cloud_off : Icons.cloud_done),
          ],
        ),
        if (confirmation!.note != null && confirmation!.note!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              confirmation!.note!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }

  Widget _statusChip(ThemeData theme, String text, IconData icon) {
    return Chip(
      visualDensity: VisualDensity.compact,
      side: BorderSide.none,
      avatar: Icon(icon, size: 16),
      label: Text(text),
    );
  }

  String _countdownLabel(Duration duration) {
    if (duration.isNegative) {
      return '0 min';
    }
    if (duration.inMinutes < 1) {
      return '${duration.inSeconds} sec';
    }
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours == 0) {
      return '$minutes min';
    }
    if (minutes == 0) {
      return '${hours}h';
    }
    return '${hours}h ${minutes}m';
  }
}
