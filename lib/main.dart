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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Money Manager',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF00796B),
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF00796B),
        brightness: Brightness.dark,
      ),
      home: const MainNavigationScreen(),
    );
  }
}
