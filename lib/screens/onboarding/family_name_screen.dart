import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'add_participants_screen.dart';

/// First step: Create family and set name
class FamilyNameScreen extends StatefulWidget {
  const FamilyNameScreen({super.key});

  @override
  State<FamilyNameScreen> createState() => _FamilyNameScreenState();
}

class _FamilyNameScreenState extends State<FamilyNameScreen> {
  final _formKey = GlobalKey<FormState>();
  final _familyNameController = TextEditingController();

  @override
  void dispose() {
    _familyNameController.dispose();
    super.dispose();
  }

  void _handleContinue() {
    if (!_formKey.currentState!.validate()) return;

    // TODO: Save family name to state/database
    final familyName = _familyNameController.text.trim();
    
    // Navigate to add participants
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddParticipantsScreen(familyName: familyName),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Progress Indicator
                _ProgressIndicator(currentStep: 1, totalSteps: 3),
                
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
                    Icons.family_restroom,
                    size: 40,
                    color: colorScheme.primary,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Header
                Text(
                  l10n?.familySetupCreateTitle ?? 'Create Your Family',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                Text(
                  l10n?.familySetupCreateSubtitle ?? 'Let\'s start by giving your family a name',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                
                const SizedBox(height: 32),
                
                // Family Name Input
                TextFormField(
                  controller: _familyNameController,
                  decoration: InputDecoration(
                    labelText: l10n?.familyNameLabel ?? 'Family Name',
                    hintText: l10n?.familyNameHint ?? 'e.g., The Smiths, Johnson Family',
                    prefixIcon: const Icon(Icons.home_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n?.pleaseEnterFamilyName ?? 'Please enter a family name';
                    }
                    return null;
                  },
                  autofocus: true,
                ),
                
                const SizedBox(height: 16),
                
                // Helper text
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          l10n?.familyNameHelper ?? 'You can change this later in settings',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const Spacer(),
                
                // Continue Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    onPressed: _handleContinue,
                    child: Text(
                      l10n?.continueButton ?? 'Continue',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Progress indicator widget
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
      ],
    );
  }
}

