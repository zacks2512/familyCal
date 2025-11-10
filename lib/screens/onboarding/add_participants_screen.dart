import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'add_children_screen.dart';

/// Second step: Invite family participants via link
class AddParticipantsScreen extends StatefulWidget {
  const AddParticipantsScreen({
    super.key,
    required this.familyName,
  });

  final String familyName;

  @override
  State<AddParticipantsScreen> createState() => _AddParticipantsScreenState();
}

class _AddParticipantsScreenState extends State<AddParticipantsScreen> {
  final List<_InviteSent> _invitesSent = [];

  void _sendInvite() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SendInviteSheet(
        familyName: widget.familyName,
        onSent: (invite) {
          setState(() => _invitesSent.add(invite));
        },
      ),
    );
  }

  void _removeInvite(int index) {
    setState(() => _invitesSent.removeAt(index));
  }

  void _handleContinue() {
    // Can continue even with no invites sent
    // TODO: Save invite records to state/database
    
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddChildrenScreen(
          familyName: widget.familyName,
          participants: _invitesSent.map((i) => i.contact).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Family Members'),
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
              _ProgressIndicator(currentStep: 2, totalSteps: 3),
              
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
                  Icons.people_outline,
                  size: 40,
                  color: colorScheme.primary,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Header
              Text(
                'Invite Family Members',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 8),
              
              Text(
                'Send invite links to your partner, grandparents, or anyone who helps',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Invites List
              Expanded(
                child: _invitesSent.isEmpty
                    ? _EmptyState(onSend: _sendInvite)
                    : ListView.separated(
                        itemCount: _invitesSent.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final invite = _invitesSent[index];
                          return _InviteCard(
                            invite: invite,
                            onRemove: () => _removeInvite(index),
                          );
                        },
                      ),
              ),
              
              const SizedBox(height: 16),
              
              // Send Another Button
              if (_invitesSent.isNotEmpty)
                OutlinedButton.icon(
                  onPressed: _sendInvite,
                  icon: const Icon(Icons.send),
                  label: const Text('Send Another Invite'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 48),
                  ),
                ),
              
              const SizedBox(height: 16),
              
              // Continue Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _handleContinue,
                  child: Text(
                    _invitesSent.isEmpty ? 'Skip for Now' : 'Continue',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Empty state when no invites sent
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onSend});

  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.share_outlined,
            size: 64,
            color: colorScheme.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No invites sent yet',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Send links to people who will help\ncoordinate your family schedules',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onSend,
            icon: const Icon(Icons.send),
            label: const Text('Send Invite'),
          ),
        ],
      ),
    );
  }
}

/// Invite card showing sent invite
class _InviteCard extends StatelessWidget {
  const _InviteCard({
    required this.invite,
    required this.onRemove,
  });

  final _InviteSent invite;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: colorScheme.primary.withOpacity(0.2),
            child: Icon(
              Icons.mail_outline,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  invite.contact,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Invite sent ✓',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary,
                  ),
                ),
              ],
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

/// Send invite bottom sheet
class _SendInviteSheet extends StatefulWidget {
  const _SendInviteSheet({
    required this.familyName,
    required this.onSent,
  });

  final String familyName;
  final Function(_InviteSent) onSent;

  @override
  State<_SendInviteSheet> createState() => _SendInviteSheetState();
}

class _SendInviteSheetState extends State<_SendInviteSheet> {
  final _formKey = GlobalKey<FormState>();
  final _contactController = TextEditingController();
  bool _isEmail = true;

  @override
  void dispose() {
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _handleSend() async {
    if (!_formKey.currentState!.validate()) return;

    final contact = _contactController.text.trim();
    
    // Generate invite link
    // TODO: Use real invite link from backend
    final inviteLink = 'https://familycal.app/invite/family_${DateTime.now().millisecondsSinceEpoch}';
    
    // Copy to clipboard
    await Clipboard.setData(ClipboardData(text: inviteLink));

    if (!mounted) return;

    final invite = _InviteSent(
      contact: contact,
      inviteLink: inviteLink,
      sentAt: DateTime.now(),
    );

    widget.onSent(invite);
    
    Navigator.of(context).pop();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Invite link copied! Share it with $contact'),
        action: SnackBarAction(
          label: 'Share',
          onPressed: () {
            // TODO: Open share dialog
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
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
                  'Send Invite to Join ${widget.familyName}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Contact Input
                TextFormField(
                  controller: _contactController,
                  decoration: InputDecoration(
                    labelText: 'Email or Phone',
                    hintText: _isEmail ? 'their@email.com' : '+1 (555) 123-4567',
                    prefixIcon: Icon(_isEmail ? Icons.email_outlined : Icons.phone_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(_isEmail ? Icons.phone_outlined : Icons.email_outlined),
                      onPressed: () {
                        setState(() => _isEmail = !_isEmail);
                      },
                      tooltip: _isEmail ? 'Switch to phone' : 'Switch to email',
                    ),
                  ),
                  keyboardType: _isEmail 
                      ? TextInputType.emailAddress 
                      : TextInputType.phone,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter ${_isEmail ? "an email" : "a phone number"}';
                    }
                    return null;
                  },
                  autofocus: true,
                ),
                
                const SizedBox(height: 16),
                
                // Info box
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
                          'We\'ll create an invite link you can share',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Send Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton.icon(
                    onPressed: _handleSend,
                    icon: const Icon(Icons.send),
                    label: const Text(
                      'Create & Copy Link',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
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

/// Progress indicator (same as family name screen)
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
          'Step $currentStep of $totalSteps',
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

/// Invite sent model
class _InviteSent {
  final String contact;
  final String inviteLink;
  final DateTime sentAt;

  _InviteSent({
    required this.contact,
    required this.inviteLink,
    required this.sentAt,
  });
}

