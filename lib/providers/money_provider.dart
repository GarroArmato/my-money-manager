import 'package:flutter/material.dart';
import '../models/account.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../services/csv_import_service.dart';
import '../services/database_helper.dart';
import '../services/notification_reader_service.dart';

class MoneyProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final CsvImportService _csvService = CsvImportService();
  final NotificationReaderService _notificationService =
      NotificationReaderService();

  List<AccountGroup> _accountGroups = [];
  List<Account> _accounts = [];
  List<TransactionCategory> _categories = [];
  Map<String, double> _categoryBudgets = {};
  List<MoneyTransaction> _transactions = [];
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  bool _isLoading = false;

  // Colori Tema App (Default: Viola & Verde, configurabili dall'utente)
  int _primaryColorValue = DatabaseHelper.defaultPrimaryPurple;
  int _secondaryColorValue = DatabaseHelper.defaultSecondaryGreen;
  int _expenseColorValue = DatabaseHelper.defaultExpenseColor;
  ThemeMode _themeMode = ThemeMode.system;

  // Flag Impostazioni (Punto 2 e Punto 3 facoltativi)
  bool _enableCsvImport = true;
  bool _enableNotificationReader = false;

  List<AccountGroup> get accountGroups => _accountGroups;
  List<Account> get accounts => _accounts;
  List<TransactionCategory> get categories => _categories;
  List<TransactionCategory> get expenseCategories =>
      _categories.where((c) => c.kind == CategoryKind.expense).toList();
  List<TransactionCategory> get incomeCategories =>
      _categories.where((c) => c.kind == CategoryKind.income).toList();
  Map<String, double> get categoryBudgets => _categoryBudgets;
  List<MoneyTransaction> get allTransactions => _transactions;
  DateTime get selectedMonth => _selectedMonth;
  bool get isLoading => _isLoading;
  bool get enableCsvImport => _enableCsvImport;
  bool get enableNotificationReader => _enableNotificationReader;

  int get primaryColorValue => _primaryColorValue;
  int get secondaryColorValue => _secondaryColorValue;
  int get expenseColorValue => _expenseColorValue;
  Color get primaryColor => Color(_primaryColorValue);
  Color get secondaryColor => Color(_secondaryColorValue);
  Color get expenseColor => Color(_expenseColorValue);
  ThemeMode get themeMode => _themeMode;

  /// Restituisce l'elenco delle note già scritte nei movimenti (ordinate per frequenza/recentezza) per l'autocompletamento
  List<String> get suggestedNotes {
    final Map<String, int> counts = {};
    final Map<String, String> originalCase = {};

    for (final tx in _transactions) {
      final trimmed = tx.note.trim();
      if (trimmed.isEmpty) continue;
      final lower = trimmed.toLowerCase();
      counts[lower] = (counts[lower] ?? 0) + 1;
      originalCase.putIfAbsent(lower, () => trimmed);
    }

    final sortedKeys = counts.keys.toList()
      ..sort((a, b) => counts[b]!.compareTo(counts[a]!));

    return sortedKeys.map((k) => originalCase[k]!).toList();
  }

  /// Inizializza e carica gruppi di conti, conti, categorie, budget, movimenti, colori e impostazioni
  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    _accountGroups = await _db.getAllAccountGroups();
    _accounts = await _db.getAllAccounts();
    _categories = await _db.getAllCategories();
    _categoryBudgets = await _db.getCategoryBudgets();
    _transactions = await _db.getAllTransactions();
    _enableCsvImport = await _db.getEnableCsvImport();
    _enableNotificationReader = await _db.getEnableNotificationReader();
    _primaryColorValue = await _db.getPrimaryColorValue();
    _secondaryColorValue = await _db.getSecondaryColorValue();
    _expenseColorValue = await _db.getExpenseColorValue();

    final modeIndex = await _db.getThemeModeIndex();
    _themeMode = ThemeMode.values[modeIndex.clamp(0, 2)];

    _isLoading = false;
    notifyListeners();
  }

  // --- GESTIONE BUDGET MENSILI ---
  Future<void> setCategoryBudget(String categoryId, double amount) async {
    await _db.setCategoryBudget(categoryId, amount);
    _categoryBudgets = await _db.getCategoryBudgets();
    notifyListeners();
  }

  // --- GESTIONE COLORI E TEMA (DEFAULT VIOLA & VERDE) ---
  Future<void> setPrimaryColor(int colorValue) async {
    _primaryColorValue = colorValue;
    await _db.setPrimaryColorValue(colorValue);
    notifyListeners();
  }

  Future<void> setSecondaryColor(int colorValue) async {
    _secondaryColorValue = colorValue;
    await _db.setSecondaryColorValue(colorValue);
    notifyListeners();
  }

  Future<void> setExpenseColor(int colorValue) async {
    _expenseColorValue = colorValue;
    await _db.setExpenseColorValue(colorValue);
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await _db.setThemeModeIndex(mode.index);
    notifyListeners();
  }

  Future<void> resetDefaultThemeColors() async {
    _primaryColorValue = DatabaseHelper.defaultPrimaryPurple;
    _secondaryColorValue = DatabaseHelper.defaultSecondaryGreen;
    _expenseColorValue = DatabaseHelper.defaultExpenseColor;
    await _db.setPrimaryColorValue(_primaryColorValue);
    await _db.setSecondaryColorValue(_secondaryColorValue);
    await _db.setExpenseColorValue(_expenseColorValue);
    notifyListeners();
  }

  Future<void> toggleCsvImport(bool value) async {
    _enableCsvImport = value;
    await _db.setEnableCsvImport(value);
    notifyListeners();
  }

  Future<void> toggleNotificationReader(bool value) async {
    _enableNotificationReader = value;
    await _db.setEnableNotificationReader(value);
    notifyListeners();
  }

  // --- GESTIONE GRUPPI DI CONTI (ACCOUNT GROUPS) ---
  Future<void> saveAccountGroup(AccountGroup group) async {
    await _db.upsertAccountGroup(group);
    _accountGroups = await _db.getAllAccountGroups();
    notifyListeners();
  }

  Future<void> deleteAccountGroup(String groupId) async {
    await _db.deleteAccountGroup(groupId);
    _accountGroups = await _db.getAllAccountGroups();
    _accounts = await _db.getAllAccounts();
    notifyListeners();
  }

  // --- GESTIONE CONTI (ACCOUNTS) ---
  Future<void> saveAccount(Account account) async {
    await _db.upsertAccount(account);
    _accounts = await _db.getAllAccounts();
    notifyListeners();
  }

  Future<void> toggleAccountIncludeInTotal(String accountId) async {
    final acc = getAccountById(accountId);
    if (acc == null) return;
    await saveAccount(acc.copyWith(includeInTotal: !acc.includeInTotal));
  }

  Future<void> deleteAccount(String accountId) async {
    await _db.deleteAccount(accountId);
    _accounts = await _db.getAllAccounts();
    _transactions = await _db.getAllTransactions();
    notifyListeners();
  }

  // --- GESTIONE CATEGORIE (ENTRATE E USCITE) ---
  Future<void> saveCategory(TransactionCategory category) async {
    await _db.upsertCategory(category);
    _categories = await _db.getAllCategories();
    notifyListeners();
  }

  Future<void> deleteCategory(String categoryId) async {
    await _db.deleteCategory(categoryId);
    _categories = await _db.getAllCategories();
    _categoryBudgets = await _db.getCategoryBudgets();
    notifyListeners();
  }

  void changeMonth(int monthOffset) {
    _selectedMonth = DateTime(
      _selectedMonth.year,
      _selectedMonth.month + monthOffset,
    );
    notifyListeners();
  }

  /// Filtra le transazioni per il mese attualmente selezionato
  List<MoneyTransaction> get monthlyTransactions {
    return _transactions.where((tx) {
      return tx.date.year == _selectedMonth.year &&
          tx.date.month == _selectedMonth.month;
    }).toList();
  }

  /// Restituisce i movimenti del mese selezionato che appartengono a uno specifico Conto
  List<MoneyTransaction> getAccountMonthlyTransactions(String accountId) {
    return monthlyTransactions.where((tx) {
      return tx.accountId == accountId || tx.toAccountId == accountId;
    }).toList();
  }

  /// Totale Depositi / Entrate del mese per uno specifico Conto
  double getAccountMonthlyDeposits(String accountId) {
    double total = 0.0;
    for (final tx in getAccountMonthlyTransactions(accountId)) {
      if (tx.type == TransactionType.income && tx.accountId == accountId) {
        total += tx.amount;
      } else if (tx.type == TransactionType.transfer &&
          tx.toAccountId == accountId) {
        total += tx.amount;
      }
    }
    return total;
  }

  /// Totale Prelievi / Uscite del mese per uno specifico Conto
  double getAccountMonthlyWithdrawals(String accountId) {
    double total = 0.0;
    for (final tx in getAccountMonthlyTransactions(accountId)) {
      if (tx.type == TransactionType.expense && tx.accountId == accountId) {
        total += tx.amount;
      } else if (tx.type == TransactionType.transfer &&
          tx.accountId == accountId) {
        total += tx.amount;
      }
    }
    return total;
  }

  /// Totale Entrate del mese selezionato (tutti i conti)
  double get monthlyIncome {
    return monthlyTransactions
        .where((tx) => tx.type == TransactionType.income)
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }

  /// Totale Uscite del mese selezionato (tutti i conti)
  double get monthlyExpenses {
    return monthlyTransactions
        .where((tx) => tx.type == TransactionType.expense)
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }

  /// Bilancio netto del mese selezionato
  double get monthlyBalance => monthlyIncome - monthlyExpenses;

  /// Calcola il saldo attuale di un singolo conto
  double getAccountBalance(String accountId) {
    final account = _accounts.firstWhere(
      (a) => a.id == accountId,
      orElse: () => Account(
        id: accountId,
        name: '',
        groupId: 'grp_cash',
      ),
    );

    double balance = account.initialBalance;

    for (final tx in _transactions) {
      if (tx.type == TransactionType.income && tx.accountId == accountId) {
        balance += tx.amount;
      } else if (tx.type == TransactionType.expense &&
          tx.accountId == accountId) {
        balance -= tx.amount;
      } else if (tx.type == TransactionType.transfer) {
        if (tx.accountId == accountId) {
          balance -= tx.amount;
        } else if (tx.toAccountId == accountId) {
          balance += tx.amount;
        }
      }
    }
    return balance;
  }

  /// Saldo attivo (conti inclusi nel totale con saldo positivo, stile Money Manager)
  double get totalAssets {
    return _accounts.where((a) => a.includeInTotal).fold(0.0, (sum, acc) {
      final bal = getAccountBalance(acc.id);
      return bal > 0 ? sum + bal : sum;
    });
  }

  /// Saldo passivo / Debiti (conti inclusi nel totale con saldo negativo, stile Money Manager)
  double get totalLiabilities {
    return _accounts.where((a) => a.includeInTotal).fold(0.0, (sum, acc) {
      final bal = getAccountBalance(acc.id);
      return bal < 0 ? sum + bal.abs() : sum;
    });
  }

  /// Totale netto dei conti disponibili (inclusi nel totale: Saldo attivo - Saldo passivo)
  double get totalNetWorth {
    return _accounts.where((a) => a.includeInTotal).fold(
      0.0,
      (sum, acc) => sum + getAccountBalance(acc.id),
    );
  }

  /// Totale dei conti NON disponibili (esclusi dal totale, es. Parte Fissa / Risparmi accantonati)
  double get totalUnavailableBalance {
    return _accounts.where((a) => !a.includeInTotal).fold(
      0.0,
      (sum, acc) => sum + getAccountBalance(acc.id),
    );
  }

  /// Aggiunge una nuova transazione manuale
  Future<void> addTransaction(MoneyTransaction tx) async {
    await _db.insertTransaction(tx);
    _transactions = await _db.getAllTransactions();
    notifyListeners();
  }

  Future<void> deleteTransaction(String id) async {
    await _db.deleteTransaction(id);
    _transactions = await _db.getAllTransactions();
    notifyListeners();
  }

  /// Punto 2: Importa una lista di movimenti da testo CSV della banca
  Future<int> importBankCsv({
    required String csvContent,
    required String accountId,
  }) async {
    final parsedList = _csvService.parseBankCsv(
      csvContent: csvContent,
      targetAccountId: accountId,
    );

    int importedCount = 0;
    for (final tx in parsedList) {
      final inserted = await _db.insertTransaction(tx);
      if (inserted) importedCount++;
    }

    _transactions = await _db.getAllTransactions();
    notifyListeners();
    return importedCount;
  }

  /// Punto 3: Elabora una notifica push bancaria / Google Wallet e registra la spesa
  Future<MoneyTransaction?> processBankNotification({
    required String notificationText,
    required String accountId,
  }) async {
    if (!_enableNotificationReader) return null;

    final tx = _notificationService.parseNotificationText(
      notificationText: notificationText,
      targetAccountId: accountId,
    );

    if (tx != null) {
      await _db.insertTransaction(tx);
      _transactions = await _db.getAllTransactions();
      notifyListeners();
    }
    return tx;
  }

  TransactionCategory? getCategoryById(String? categoryId) {
    if (categoryId == null) return null;
    try {
      return _categories.firstWhere((c) => c.id == categoryId);
    } catch (_) {
      return null;
    }
  }

  Account? getAccountById(String accountId) {
    try {
      return _accounts.firstWhere((a) => a.id == accountId);
    } catch (_) {
      return null;
    }
  }

  AccountGroup? getAccountGroupById(String groupId) {
    try {
      return _accountGroups.firstWhere((g) => g.id == groupId);
    } catch (_) {
      return _accountGroups.isNotEmpty ? _accountGroups.first : null;
    }
  }
}
