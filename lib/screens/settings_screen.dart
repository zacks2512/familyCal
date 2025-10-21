import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/app_state.dart';
import 'log_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool remindersEnabled = true;
  bool partnerAlertsEnabled = true;
  bool quietHours = false;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FamilyCalState>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _SectionHeader(title: 'Family'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.home_outlined),
                  title: Text(state.currentMember.displayName),
                  subtitle: Text(state.currentMember.isOwner
                      ? 'Family owner'
                      : 'Member'),
                  trailing: Chip(
                    label: Text('${state.members.length} adults'),
                    avatar: const Icon(Icons.group),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.mail_outline),
                  title: const Text('Invite partner'),
                  subtitle: const Text('Send magic link via SMS or email'),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invite link copied to clipboard.')),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _SectionHeader(title: 'Places & geofence'),
          ...state.places.map(
            (place) => Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      place.name,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      place.address.isEmpty ? 'No address on file' : place.address,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.radar_outlined, size: 20),
                        const SizedBox(width: 8),
                        Text('${place.radiusMeters} m radius'),
                      ],
                    ),
                    Slider(
                      value: place.radiusMeters.toDouble(),
                      min: 80,
                      max: 250,
                      divisions: 17,
                      label: '${place.radiusMeters} m',
                      onChanged: (value) {
                        final updated =
                            place.copyWith(radiusMeters: value.round());
                        context.read<FamilyCalState>().updatePlace(updated);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _SectionHeader(title: 'Notifications'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  value: remindersEnabled,
                  onChanged: (value) => setState(() => remindersEnabled = value),
                  title: const Text('Reminders'),
                  subtitle:
                      const Text('T−15 and window start pushes to responsible adult'),
                ),
                SwitchListTile(
                  value: partnerAlertsEnabled,
                  onChanged: (value) => setState(() => partnerAlertsEnabled = value),
                  title: const Text('Partner updates'),
                  subtitle:
                      const Text('Send “Done ✅” push once confirmation is marked'),
                ),
                SwitchListTile(
                  value: quietHours,
                  onChanged: (value) => setState(() => quietHours = value),
                  title: const Text('Quiet hours (22:00 – 06:00)'),
                  subtitle: const Text('Late nudges will be suppressed overnight'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _SectionHeader(title: 'Privacy'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text('Location retention'),
              subtitle: const Text(
                'Raw GPS kept for 14 days for troubleshooting. Only geo ✅ flag stored in history.',
              ),
              trailing: TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Privacy preferences saved.'),
                    ),
                  );
                },
                child: const Text('Review policy'),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _SectionHeader(title: 'Diagnostics'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.analytics_outlined),
                  title: const Text('Analytics event log'),
                  subtitle: const Text('View local analytics queue before upload'),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Analytics debug view opening...'),
                      ),
                    );
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.bug_report_outlined),
                  title: const Text('Send feedback'),
                  subtitle: const Text('Sends console log & device info to FamilyCal'),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Feedback composer would open here.'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _SectionHeader(title: 'Extra info'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.fact_check_outlined),
              title: const Text('Activity log'),
              subtitle: const Text('Review past confirmations and export history'),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const LogScreen(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              letterSpacing: 0.3,
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
