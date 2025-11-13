import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../config/app_config.dart';
import '../services/firebase_repository.dart';
import '../state/app_state.dart';

/// Clean invite-by-link screen for adding family members
class InviteMemberScreen extends StatefulWidget {
  const InviteMemberScreen({super.key});

  @override
  State<InviteMemberScreen> createState() => _InviteMemberScreenState();
}

class _InviteMemberScreenState extends State<InviteMemberScreen> {
  String? _inviteLink;
  bool _isGenerating = false;
  bool _isCopying = false;

  @override
  void initState() {
    super.initState();
    _generateInviteLink();
  }

  Future<void> _generateInviteLink() async {
    setState(() => _isGenerating = true);

    try {
      if (!AppConfig.useMockData) {
        final repo = FirebaseRepository();
        final familyId = await repo.getCurrentUserFamilyId(createIfMissing: true);
        if (familyId != null) {
          // TODO: Implement actual invite link generation from backend
          // For now, create a placeholder link
          _inviteLink = 'https://familycal.app/invite/$familyId?token=${DateTime.now().millisecondsSinceEpoch}';
        }
      } else {
        // Mock mode
        await Future.delayed(const Duration(milliseconds: 500));
        _inviteLink = 'https://familycal.app/invite/demo-family-${DateTime.now().millisecondsSinceEpoch}';
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.failedToGenerateLink(e.toString())),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _copyToClipboard() async {
    if (_inviteLink == null) return;

    setState(() => _isCopying = true);

    try {
      await Clipboard.setData(ClipboardData(text: _inviteLink!));
      
      if (!mounted) return;

      final l10n = AppLocalizations.of(context)!;
      
      // Show success feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(l10n.inviteLinkCopiedSuccess),
              ),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: l10n.share,
            textColor: Colors.white,
            onPressed: () {
              // TODO: Open native share sheet
              // Share.share(_inviteLink!);
            },
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.failedToCopy(e.toString())),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCopying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(l10n.addMembersTitle),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: l10n.close,
        ),
        backgroundColor: colorScheme.surface,
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Explanatory text
              Text(
                l10n.inviteMembersRecommendation,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 32),

              // Tab-like header (just visual, single tab)
              Container(
                padding: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: colorScheme.primary,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  l10n.inviteByLink,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Description with help link
              RichText(
                text: TextSpan(
                  text: l10n.inviteLinkDescription,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                    height: 1.5,
                  ),
                  children: [
                    // TODO: Make this a tappable link
                    TextSpan(
                      text: l10n.visitHelpArticle,
                      style: TextStyle(
                        color: colorScheme.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    TextSpan(
                      text: l10n.inviteLinkDescriptionSuffix,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Invite link field
              if (_isGenerating)
                Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colorScheme.outline.withOpacity(0.5),
                    ),
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              else if (_inviteLink != null)
                Row(
                  children: [
                    // Link display (read-only)
                    Expanded(
                      child: Container(
                        height: 56,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceVariant.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: colorScheme.outline.withOpacity(0.5),
                          ),
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SelectableText(
                              _inviteLink!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),

                    // Copy button
                    SizedBox(
                      height: 56,
                      child: FilledButton(
                        onPressed: _isCopying ? null : _copyToClipboard,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isCopying
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                l10n.copy,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 24),

              // Generate new link button
              TextButton.icon(
                onPressed: _isGenerating ? null : _generateInviteLink,
                icon: _isGenerating
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh, size: 20),
                label: Text(l10n.generateNewLink),
                style: TextButton.styleFrom(
                  foregroundColor: colorScheme.primary,
                ),
              ),

              const SizedBox(height: 32),

              // Info card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: colorScheme.primary.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        l10n.inviteLinkSecurityInfo,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

