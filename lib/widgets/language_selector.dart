import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../providers/locale_provider.dart';

/// Reusable language selector widget
class LanguageSelector extends StatelessWidget {
  const LanguageSelector({super.key});

  String _getLanguageText(String key, BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final defaults = {
      'language': 'Language',
      'hebrew': 'עברית',
      'english': 'English',
    };
    
    if (l10n == null) {
      return defaults[key] ?? key;
    }
    
    switch (key) {
      case 'language': return l10n.language;
      case 'hebrew': return l10n.hebrew;
      case 'english': return l10n.english;
      default: return defaults[key] ?? key;
    }
  }

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getLanguageText('language', context),
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        SegmentedButton<String>(
          segments: [
            ButtonSegment(
              value: 'he',
              label: Text(_getLanguageText('hebrew', context)),
            ),
            ButtonSegment(
              value: 'en',
              label: Text(_getLanguageText('english', context)),
            ),
          ],
          selected: {localeProvider.locale.languageCode},
          onSelectionChanged: (Set<String> selected) {
            final newLanguage = selected.first;
            localeProvider.setLocale(Locale(newLanguage));
          },
        ),
      ],
    );
  }
}

/// Language selector for settings page (list tile style)
class LanguageSettingsTile extends StatelessWidget {
  const LanguageSettingsTile({super.key});

  String _getLanguageText(String key, BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final defaults = {
      'language': 'Language',
      'hebrew': 'עברית',
      'english': 'English',
      'cancel': 'Cancel',
    };
    
    if (l10n == null) {
      return defaults[key] ?? key;
    }
    
    switch (key) {
      case 'language': return l10n.language;
      case 'hebrew': return l10n.hebrew;
      case 'english': return l10n.english;
      case 'cancel': return 'Cancel';
      default: return defaults[key] ?? key;
    }
  }

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);

    return ListTile(
      leading: const Icon(Icons.language),
      title: Text(_getLanguageText('language', context)),
      subtitle: Text(
        localeProvider.isHebrew ? _getLanguageText('hebrew', context) : _getLanguageText('english', context),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        _showLanguageDialog(context);
      },
    );
  }

  void _showLanguageDialog(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_getLanguageText('language', context)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: Text(_getLanguageText('hebrew', context)),
              value: 'he',
              groupValue: localeProvider.locale.languageCode,
              onChanged: (value) {
                if (value != null) {
                  localeProvider.setLocale(Locale(value));
                  Navigator.of(context).pop();
                }
              },
            ),
            RadioListTile<String>(
              title: Text(_getLanguageText('english', context)),
              value: 'en',
              groupValue: localeProvider.locale.languageCode,
              onChanged: (value) {
                if (value != null) {
                  localeProvider.setLocale(Locale(value));
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(_getLanguageText('cancel', context)),
          ),
        ],
      ),
    );
  }
}

