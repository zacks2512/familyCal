import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/entities.dart';
import '../state/app_state.dart';
import 'log_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final state = context.watch<FamilyCalState>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          // CHILDREN (with color picker)
          const _SectionHeader(title: 'Children'),
          Card(
            child: Column(
              children: [
                ...state.children.map(
                  (child) => ListTile(
                    leading: CircleAvatar(
                      backgroundColor: child.color.withOpacity(0.25),
                      child: Text(
                        child.displayName.substring(0, 1),
                        style: TextStyle(
                          color: child.color.computeLuminance() > 0.5
                              ? Colors.black
                              : Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    title: Text(child.displayName),
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.add_circle_outline),
                  title: const Text('Add child'),
                  onTap: () => _showAddChildDialog(context, state),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // FAMILY MEMBERS (merged) + invite option
          const _SectionHeader(title: 'Family members'),
          Card(
            child: Column(
              children: [
                ...state.members.map(
                  (member) => ListTile(
                    leading: const Icon(Icons.person_outline),
                    title: Text(member.displayName),
                    subtitle:
                        Text(member.email ?? member.phone ?? 'No contact info'),
                    trailing: member.isOwner
                        ? const Chip(
                            label: Text('Owner'),
                            visualDensity: VisualDensity.compact,
                          )
                        : null,
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.person_add_outlined),
                  title: const Text('Add / Invite member'),
                  onTap: () => _showAddOrInviteMemberDialog(context, state),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // EXTRA
          const _SectionHeader(title: 'Extra'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.fact_check_outlined),
              title: const Text('Activity Log'),
              subtitle: const Text('Review past confirmations'),
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

  // ---------- DIALOGS ----------

  void _showAddChildDialog(BuildContext context, FamilyCalState state) {
    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    Color selectedColor = Colors.pink.shade300;

    showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add child'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    hintText: 'Enter child\'s name',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Choose color:'),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    Colors.pink.shade300,
                    Colors.orange.shade400,
                    Colors.blue.shade400,
                    Colors.green.shade400,
                    Colors.purple.shade400,
                    Colors.red.shade400,
                    Colors.teal.shade400,
                    Colors.amber.shade400,
                  ].map((color) {
                    final isSelected = color == selectedColor;
                    return InkWell(
                      onTap: () => setDialogState(() => selectedColor = color),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: Colors.black, width: 3)
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                final child = FamilyChild(
                  id: 'child-${DateTime.now().millisecondsSinceEpoch}',
                  displayName: nameController.text.trim(),
                  color: selectedColor,
                );
                state.addChild(child);
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Added ${child.displayName}')),
                );
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddOrInviteMemberDialog(BuildContext context, FamilyCalState state) {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final phoneController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool sendInvite = true;

    showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setSB) => AlertDialog(
          title: const Text('Add / Invite member'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    hintText: 'Enter member\'s name',
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Please enter a name' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email (optional)',
                    hintText: 'member@example.com',
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(
                    labelText: 'Phone (optional)',
                    hintText: '+1 555 123 4567',
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                CheckboxListTile(
                  value: sendInvite,
                  onChanged: (v) => setSB(() => sendInvite = v ?? true),
                  title: const Text('Send invite link'),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;

                final member = FamilyMember(
                  id: 'member-${DateTime.now().millisecondsSinceEpoch}',
                  displayName: nameController.text.trim(),
                  email: emailController.text.trim().isEmpty
                      ? null
                      : emailController.text.trim(),
                  phone: phoneController.text.trim().isEmpty
                      ? null
                      : phoneController.text.trim(),
                );

                state.addMember(member);

                if (sendInvite) {
                  await Clipboard.setData(
                    ClipboardData(
                      text: 'https://familycal.app/invite/${member.id}',
                    ),
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invite link copied ✅')),
                    );
                  }
                }

                if (context.mounted) Navigator.of(context).pop();
              },
              child: const Text('Add'),
            ),
          ],
        ),
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
