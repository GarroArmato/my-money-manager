import 'package:flutter/material.dart';
import 'providers/money_provider.dart';
import 'screens/main_navigation_screen.dart';
import 'utils/money_scope.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final provider = MoneyProvider()..loadData();

  runApp(
    MoneyScope(
      provider: provider,
      child: const MyMoneyManagerApp(),
    ),
  );
}

class MyMoneyManagerApp extends StatelessWidget {
  const MyMoneyManagerApp({super.key});

  ThemeData _buildTheme(
    Color primary,
    Color secondary,
    Brightness brightness,
  ) {
    final baseScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
    );

    final scheme = baseScheme.copyWith(
      primary: primary,
      secondary: secondary,
      secondaryContainer: secondary.withValues(
        alpha: brightness == Brightness.dark ? 0.25 : 0.16,
      ),
      onSecondaryContainer:
          brightness == Brightness.dark ? Colors.white : secondary,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.primary,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: secondary,
        foregroundColor: Colors.white,
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: secondary.withValues(alpha: 0.22),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = MoneyScope.of(context);

    return MaterialApp(
      title: 'My Money Manager',
      debugShowCheckedModeBanner: false,
      themeMode: provider.themeMode,
      theme: _buildTheme(
        provider.primaryColor,
        provider.secondaryColor,
        Brightness.light,
      ),
      darkTheme: _buildTheme(
        provider.primaryColor,
        provider.secondaryColor,
        Brightness.dark,
      ),
      home: const MainNavigationScreen(),
    );
  }
}
