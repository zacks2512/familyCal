import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/entities.dart';
import '../state/app_state.dart';
import '../services/firebase_auth_service.dart';
import '../services/firebase_repository.dart';
import '../config/app_config.dart';
import 'auth/welcome_screen.dart';
import 'log_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _authService = FirebaseAuthService();

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

          const SizedBox(height: 24),

          // ACCOUNT
          const _SectionHeader(title: 'Account'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    Icons.person_outline,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(_authService.currentUserDisplayName ?? 
                              _authService.currentUserEmail ?? 
                              'User'),
                  subtitle: Text(_authService.currentUserEmail ?? 'Logged in'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    Icons.logout,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  title: Text(
                    'Sign Out',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  onTap: () => _handleSignOut(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSignOut(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await _authService.signOut();
        
        if (context.mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const WelcomeScreen()),
            (route) => false,
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Sign out failed: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
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
                () async {
                  if (!AppConfig.useMockData) {
                    final repo = FirebaseRepository();
                    final familyId =
                        await repo.getCurrentUserFamilyId(createIfMissing: true);
                    if (familyId != null) {
                      await repo.addChild(
                        familyId: familyId,
                        name: child.displayName,
                        color: '#${child.color.value.toRadixString(16).substring(2)}',
                        birthDate: null,
                        allergies: null,
                      );
                    }
                  } else {
                    state.addChild(child);
                  }
                  if (context.mounted) {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Added ${child.displayName}')),
                    );
                  }
                }();
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

                () async {
                  if (!AppConfig.useMockData) {
                    final repo = FirebaseRepository();
                    final familyId =
                        await repo.getCurrentUserFamilyId(createIfMissing: true);
                    if (familyId != null) {
                      final newUserId = await repo.addFamilyMember(
                        familyId: familyId,
                        displayName: member.displayName,
                        email: member.email,
                        phone: member.phone,
                        invitePending: sendInvite,
                      );
                      if (sendInvite) {
                        await Clipboard.setData(
                          ClipboardData(
                            text: 'https://familycal.app/invite/$newUserId',
                          ),
                        );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Invite link copied ✅')),
                          );
                        }
                      }
                    }
                  } else {
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
                  }
                  if (context.mounted) Navigator.of(context).pop();
                }();
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
