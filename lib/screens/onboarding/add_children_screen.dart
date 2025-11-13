import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../app.dart';
import '../../config/app_config.dart';
import '../../services/firebase_repository.dart';
import '../auth/welcome_screen.dart';
import '../../services/firebase_auth_service.dart';

/// Third step: Add children
class AddChildrenScreen extends StatefulWidget {
  const AddChildrenScreen({
    super.key,
    required this.familyName,
    required this.participants,
  });

  final String familyName;
  final List participants;

  @override
  State<AddChildrenScreen> createState() => _AddChildrenScreenState();
}

class _AddChildrenScreenState extends State<AddChildrenScreen> {
  final List<_Child> _children = [];
  final _auth = FirebaseAuthService();

  void _addChild() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddChildSheet(
        onAdd: (child) {
          setState(() => _children.add(child));
        },
      ),
    );
  }

  void _removeChild(int index) {
    setState(() => _children.removeAt(index));
  }

  Future<void> _confirmExitSetup() async {
    final l10n = AppLocalizations.of(context);
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n?.exitSetupTitle ?? 'Exit setup?'),
        content: Text(l10n?.exitSetupMessage ?? 'Your progress will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n?.continueSetup ?? 'Continue setup'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n?.signOut ?? 'Sign out'),
          ),
        ],
      ),
    );
    if (shouldExit == true && mounted) {
      await _auth.signOut();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const WelcomeScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _handleFinish() async {
    if (_children.isEmpty) {
      // Show confirmation if no children added
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(AppLocalizations.of(context)?.noChildrenAddedTitle ?? 'No Children Added'),
          content: Text(AppLocalizations.of(context)?.noChildrenAddedMessage ??
              'You haven\'t added any children yet. You can add them later from settings.\n\nContinue anyway?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(AppLocalizations.of(context)?.goBack ?? 'Go Back'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(AppLocalizations.of(context)?.continueButton ?? 'Continue'),
            ),
          ],
        ),
      );

      if (confirmed != true) return;
    }

    // Save children so they appear in the app after setup
    try {
      if (!AppConfig.useMockData) {
        final repo = FirebaseRepository();
        final familyId = await repo.getCurrentUserFamilyId(createIfMissing: true);
        if (familyId != null) {
          for (final c in _children) {
            await repo.addChild(
              familyId: familyId,
              name: c.name,
              color: '#${c.color.value.toRadixString(16).substring(2)}',
              birthDate: null,
              allergies: null,
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save children: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }

    if (!mounted) return;

    // Navigate to main app
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const FamilyCalApp(showSetupWelcome: true)),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.addChildrenAppBar ?? 'Add Children'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _confirmExitSetup,
          tooltip: l10n?.exitSetupTitle ?? 'Exit setup?',
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Progress Indicator
              _ProgressIndicator(currentStep: 3, totalSteps: 3),
              
              const SizedBox(height: 32),
              
              // Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.child_care,
                  size: 40,
                  color: colorScheme.primary,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Header
              Text(
                l10n?.addYourChildrenTitle ?? 'Add Your Children',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 8),
              
              Text(
                l10n?.addYourChildrenSubtitle ?? 'Add the kids you\'ll be coordinating schedules for',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Children List
              Expanded(
                child: _children.isEmpty
                    ? _EmptyState(onAdd: _addChild)
                    : ListView.separated(
                        itemCount: _children.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final child = _children[index];
                          return _ChildCard(
                            child: child,
                            onRemove: () => _removeChild(index),
                          );
                        },
                      ),
              ),
              
              const SizedBox(height: 16),
              
              // Add Button
              if (_children.isNotEmpty)
                OutlinedButton.icon(
                  onPressed: _addChild,
                  icon: const Icon(Icons.add),
                  label: Text(l10n?.addAnotherChild ?? 'Add Another Child'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              
              const SizedBox(height: 16),
              
              // Finish Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _handleFinish,
                  child: Text(
                    l10n?.finishSetup ?? 'Finish Setup',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Consistent Skip for Now secondary action
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _handleFinish,
                  child: Text(l10n?.skipForNow ?? 'Skip for Now'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Empty state when no children added
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.child_friendly_outlined,
            size: 64,
            color: colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            l10n?.noChildrenYetTitle ?? 'No children yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            l10n?.noChildrenYetSubtitle ?? 'Add the kids you\'ll track schedules for',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: Text(l10n?.addChild ?? 'Add Child'),
          ),
        ],
      ),
    );
  }
}

/// Child card
class _ChildCard extends StatelessWidget {
  const _ChildCard({
    required this.child,
    required this.onRemove,
  });

  final _Child child;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: child.color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: child.color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: child.color.withOpacity(0.3),
            child: Text(
              child.name[0].toUpperCase(),
              style: TextStyle(
                color: child.color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              child.name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: onRemove,
            color: colorScheme.error,
          ),
        ],
      ),
    );
  }
}

/// Add child bottom sheet
class _AddChildSheet extends StatefulWidget {
  const _AddChildSheet({required this.onAdd});

  final Function(_Child) onAdd;

  @override
  State<_AddChildSheet> createState() => _AddChildSheetState();
}

class _AddChildSheetState extends State<_AddChildSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  Color _selectedColor = Colors.pink.shade300;

  // Color options are defined inside build to access localization labels

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _handleAdd() {
    if (!_formKey.currentState!.validate()) return;

    final child = _Child(
      name: _nameController.text.trim(),
      color: _selectedColor,
    );

    widget.onAdd(child);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.onSurfaceVariant.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                Text(
                  l10n?.addChild ?? 'Add Child',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Name
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: l10n?.childNameLabel ?? 'Child\'s Name',
                    hintText: l10n?.enterTheirName ?? 'Enter their name',
                    prefixIcon: const Icon(Icons.child_care),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n?.pleaseEnterAName ?? 'Please enter a name';
                    }
                    return null;
                  },
                  autofocus: true,
                ),
                
                const SizedBox(height: 24),
                
                // Color Picker
                Text(
                  l10n?.chooseAColor ?? 'Choose a color',
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
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
                    final Color color = entry['color'] as Color;
                    final String label = entry['label'] as String;
                    final bool isSelected = color == _selectedColor;
                    return Tooltip(
                      message: label,
                      child: Semantics(
                        label: label,
                        button: true,
                        selected: isSelected,
                        child: InkWell(
                      onTap: () => setState(() => _selectedColor = color),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(
                                  color: colorScheme.onSurface,
                                  width: 3,
                                )
                              : null,
                        ),
                        child: isSelected
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 20,
                              )
                            : null,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                
                const SizedBox(height: 24),
                
                // Add Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    onPressed: _handleAdd,
                    child: Text(
                      l10n?.addChild ?? 'Add Child',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Progress indicator
class _ProgressIndicator extends StatelessWidget {
  const _ProgressIndicator({
    required this.currentStep,
    required this.totalSteps,
  });

  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalizations.of(context) != null
              ? AppLocalizations.of(context)!.stepXOfY(currentStep, totalSteps)
              : 'Step $currentStep of $totalSteps',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(totalSteps, (index) {
            final isActive = index < currentStep;
            return Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsets.only(
                  right: index < totalSteps - 1 ? 8 : 0,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? colorScheme.primary
                      : colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                '1. ${l10n?.onboardingStepFamily ?? 'Family'}',
                textAlign: TextAlign.left,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: currentStep == 1
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                      fontWeight: currentStep == 1 ? FontWeight.w700 : FontWeight.w500,
                    ),
              ),
            ),
            Expanded(
              child: Text(
                '2. ${l10n?.onboardingStepMembers ?? 'Members'}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: currentStep == 2
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                      fontWeight: currentStep == 2 ? FontWeight.w700 : FontWeight.w500,
                    ),
              ),
            ),
            Expanded(
              child: Text(
                '3. ${l10n?.onboardingStepChildren ?? 'Children'}',
                textAlign: TextAlign.right,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: currentStep == 3
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                      fontWeight: currentStep == 3 ? FontWeight.w700 : FontWeight.w500,
                    ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Child model
class _Child {
  final String name;
  final Color color;

  _Child({
    required this.name,
    required this.color,
  });
}

