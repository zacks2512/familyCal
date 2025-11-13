import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'config/app_config.dart';
import 'data/mock_data.dart';
import 'data/firestore_state_provider.dart';
import 'screens/calendar_screen.dart';
import 'screens/settings_screen.dart';
import 'state/app_state.dart';
import 'providers/locale_provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class FamilyCalApp extends StatelessWidget {
  const FamilyCalApp({super.key, this.showSetupWelcome = false});

  final bool showSetupWelcome;

  @override
  Widget build(BuildContext context) {
    final app = Builder(
        builder: (context) {
          final base = ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFF1A73E8),
              brightness: Brightness.light,
            ),
          );
          final colorScheme = base.colorScheme;
        final localeProvider = Provider.of<LocaleProvider>(context);
          return MaterialApp(
            title: 'FamilyCal',
            debugShowCheckedModeBanner: false,
          // Localization (mirrors main.dart)
          locale: localeProvider.locale,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('he'),
            Locale('en'),
          ],
            theme: base.copyWith(
              scaffoldBackgroundColor: Colors.white,
              appBarTheme: base.appBarTheme.copyWith(
                backgroundColor: Colors.white,
                foregroundColor: colorScheme.onSurface,
                elevation: 0,
                titleTextStyle: base.textTheme.titleLarge?.copyWith(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              navigationBarTheme: base.navigationBarTheme.copyWith(
                backgroundColor: Colors.white,
                elevation: 0,
                indicatorColor: colorScheme.primary.withOpacity(0.12),
                labelTextStyle: MaterialStateProperty.resolveWith(
                  (states) => base.textTheme.labelMedium?.copyWith(
                    fontWeight: states.contains(MaterialState.selected)
                        ? FontWeight.w600
                        : FontWeight.w500,
                  ),
                ),
                iconTheme: MaterialStateProperty.resolveWith(
                  (states) => IconThemeData(
                    color: states.contains(MaterialState.selected)
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              textTheme: base.textTheme.apply(fontFamily: 'Roboto'),
              snackBarTheme: base.snackBarTheme.copyWith(
                backgroundColor: colorScheme.primary,
                contentTextStyle: base.textTheme.bodyMedium?.copyWith(color: Colors.white),
              ),
            ),
          home: HomeShell(showSetupWelcome: showSetupWelcome),
          );
        },
    );

    if (AppConfig.useMockData) {
      return ChangeNotifierProvider<LocaleProvider>(
        create: (_) => LocaleProvider(),
        child: ChangeNotifierProvider(
          create: (_) => createMockState(),
          child: app,
        ),
      );
    } else {
      return ChangeNotifierProvider<LocaleProvider>(
        create: (_) => LocaleProvider(),
        child: FirestoreAppStateProvider(child: app),
    );
    }
  }
}

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, this.showSetupWelcome = false});

  final bool showSetupWelcome;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _selectedIndex = 0;
  final _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.showSetupWelcome) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final l10n = AppLocalizations.of(context);
        showModalBottomSheet(
          context: context,
          showDragHandle: true,
          builder: (context) {
            final theme = Theme.of(context);
            final colorScheme = theme.colorScheme;
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n?.welcomeAfterSetupTitle ?? 'Welcome to FamilyCal!',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n?.welcomeAfterSetupBody ??
                        'Invite family members in Settings to share your calendar. Then add events together.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(l10n?.gotIt ?? 'Got it'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final destinations = [
      _NavDestination(
        icon: Icons.calendar_view_day_outlined,
        selectedIcon: Icons.calendar_month,
        label: l10n?.calendar ?? 'Calendar',
        page: const CalendarScreen(),
      ),
      _NavDestination(
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings,
        label: l10n?.settings ?? 'Settings',
        page: const SettingsScreen(),
      ),
    ];

    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: destinations.map((dest) => _PageWrapper(child: dest.page)).toList(),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
          _pageController.jumpToPage(index);
        },
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: destinations
            .map(
              (dest) => NavigationDestination(
                icon: Icon(dest.icon),
                selectedIcon: Icon(dest.selectedIcon),
                label: dest.label,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _NavDestination {
  const _NavDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.page,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final Widget page;
}

class _PageWrapper extends StatelessWidget {
  const _PageWrapper({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.of(context).padding;
    return SafeArea(
      top: padding.top == 0,
      child: child,
    );
  }
}
