import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../models/entities.dart';
import '../state/app_state.dart';
import '../services/firebase_auth_service.dart';
import '../services/firebase_repository.dart';
import '../config/app_config.dart';
import '../widgets/language_selector.dart';
import '../providers/locale_provider.dart';
import 'auth/welcome_screen.dart';
import 'log_screen.dart';
import 'invite_member_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _authService = FirebaseAuthService();

  // Helper to get localized strings with fallback
  String _getString(String key, BuildContext context) {
    final l10n = AppLocalizations.of(context);
    
    final fallbackStrings = {
      'settingsTitle': 'Settings',
      'children': 'Children',
      'addChild': 'Add Child',
      'familyMembers': 'Family Members',
      'addMember': 'Add Member',
      'activityLog': 'Activity Log',
      'viewActivityLog': 'View Activity Log',
      'account': 'Account',
      'signOut': 'Sign Out',
    };
    
    if (l10n == null) {
      return fallbackStrings[key] ?? key;
    }
    
    switch (key) {
      case 'settingsTitle': return l10n.settingsTitle;
      case 'children': return l10n.children;
      case 'addChild': return l10n.addChild;
      case 'familyMembers': return l10n.familyMembers;
      case 'addMember': return l10n.addMember;
      case 'activityLog': return l10n.activityLog;
      case 'viewActivityLog': return l10n.viewActivityLog;
      case 'account': return l10n.account;
      case 'signOut': return l10n.signOut;
      default: return fallbackStrings[key] ?? key;
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<FamilyCalState>();
    // Listen to locale changes to rebuild when language switches
    context.watch<LocaleProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(_getString('settingsTitle', context))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          // CHILDREN (with color picker)
          _SectionHeader(
            title: '${_getString('children', context)} (${state.children.length})',
          ),
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
                  title: Text(_getString('addChild', context)),
                  onTap: () => _showAddChildDialog(context, state),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // FAMILY MEMBERS (merged) + invite option
          _SectionHeader(title: _getString('familyMembers', context)),
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
                  title: Text(_getString('addMember', context)),
                  onTap: () => _showAddOrInviteMemberDialog(context, state),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // EXTRA
          _SectionHeader(title: _getString('activityLog', context)),
          Card(
            child: ListTile(
              leading: const Icon(Icons.fact_check_outlined),
              title: Text(_getString('activityLog', context)),
              subtitle: Text(_getString('viewActivityLog', context)),
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
          _SectionHeader(title: _getString('account', context)),
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
                // Language Selector
                const LanguageSettingsTile(),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    Icons.logout,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  title: Text(
                    _getString('signOut', context),
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
    final l10n = AppLocalizations.of(context);

    showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(l10n?.addChild ?? 'Add child'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: l10n?.fullName ?? 'Name',
                    hintText: l10n?.enterTheirName ?? 'Enter child\'s name',
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n?.pleaseEnterAName ?? 'Please enter a name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('${l10n?.chooseAColor ?? 'Choose a color'}:'),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    {'label': l10n?.colorPink ?? 'Pink', 'color': Colors.pink.shade300},
                    {'label': l10n?.colorOrange ?? 'Orange', 'color': Colors.orange.shade400},
                    {'label': l10n?.colorBlue ?? 'Blue', 'color': Colors.blue.shade400},
                    {'label': l10n?.colorGreen ?? 'Green', 'color': Colors.green.shade400},
                    {'label': l10n?.colorPurple ?? 'Purple', 'color': Colors.purple.shade400},
                    {'label': l10n?.colorRed ?? 'Red', 'color': Colors.red.shade400},
                    {'label': l10n?.colorTeal ?? 'Teal', 'color': Colors.teal.shade400},
                    {'label': l10n?.colorAmber ?? 'Amber', 'color': Colors.amber.shade400},
                  ].map((entry) {
                    final color = entry['color'] as Color;
                    final label = entry['label'] as String;
                    final isSelected = color == selectedColor;
                    return Tooltip(
                      message: label,
                      child: Semantics(
                        label: label,
                        button: true,
                        selected: isSelected,
                        child: InkWell(
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
                        ),
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
              child: Text(l10n?.cancel ?? 'Cancel'),
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
              child: Text(l10n?.addChild ?? 'Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddOrInviteMemberDialog(BuildContext context, FamilyCalState state) {
    // Navigate to the new clean invite screen
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
        builder: (_) => const InviteMemberScreen(),
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
