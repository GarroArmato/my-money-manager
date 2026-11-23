import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'providers/money_provider.dart';
import 'screens/main_navigation_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('it_IT', null);

  runApp(
    ChangeNotifierProvider(
      create: (_) => MoneyProvider()..loadData(),
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
