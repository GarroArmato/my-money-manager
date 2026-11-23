import 'package:flutter/foundation.dart' hide Category;
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

  List<Account> _accounts = [];
  List<TransactionCategory> _categories = [];
  List<MoneyTransaction> _transactions = [];
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  bool _isLoading = false;

  // Flag Impostazioni (Punto 2 e Punto 3 facoltativi)
  bool _enableCsvImport = true;
  bool _enableNotificationReader = false;

  List<Account> get accounts => _accounts;
  List<TransactionCategory> get categories => _categories;
  List<TransactionCategory> get expenseCategories =>
      _categories.where((c) => c.kind == CategoryKind.expense).toList();
  List<TransactionCategory> get incomeCategories =>
      _categories.where((c) => c.kind == CategoryKind.income).toList();
  List<MoneyTransaction> get allTransactions => _transactions;
  DateTime get selectedMonth => _selectedMonth;
  bool get isLoading => _isLoading;
  bool get enableCsvImport => _enableCsvImport;
  bool get enableNotificationReader => _enableNotificationReader;

  /// Inizializza e carica conti, categorie, movimenti e impostazioni
  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    _accounts = await _db.getAllAccounts();
    _categories = await _db.getAllCategories();
    _transactions = await _db.getAllTransactions();
    _enableCsvImport = await _db.getEnableCsvImport();
    _enableNotificationReader = await _db.getEnableNotificationReader();

    _isLoading = false;
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

  // --- GESTIONE CONTI (ACCOUNTS) ---
  Future<void> saveAccount(Account account) async {
    await _db.upsertAccount(account);
    _accounts = await _db.getAllAccounts();
    notifyListeners();
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

  /// Totale Entrate del mese selezionato
  double get monthlyIncome {
    return monthlyTransactions
        .where((tx) => tx.type == TransactionType.income)
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }

  /// Totale Uscite del mese selezionato
  double get monthlyExpenses {
    return monthlyTransactions
        .where((tx) => tx.type == TransactionType.expense)
        .fold(0.0, (sum, tx) => sum + tx.amount);
  }

  /// Bilancio netto del mese selezionato
  double get monthlyBalance => monthlyIncome - monthlyExpenses;

  /// Calcola il saldo attuale di un singolo conto (Contanti, Banca, Carte, Risparmi)
  double getAccountBalance(String accountId) {
    final account = _accounts.firstWhere(
      (a) => a.id == accountId,
      orElse: () => Account(
        id: accountId,
        name: '',
        type: AccountType.cash,
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

  /// Totale Attività (conti con saldo positivo, stile Money Manager)
  double get totalAssets {
    return _accounts.fold(0.0, (sum, acc) {
      final bal = getAccountBalance(acc.id);
      return bal > 0 ? sum + bal : sum;
    });
  }

  /// Totale Passività / Debiti (conti con saldo negativo, stile Money Manager)
  double get totalLiabilities {
    return _accounts.fold(0.0, (sum, acc) {
      final bal = getAccountBalance(acc.id);
      return bal < 0 ? sum + bal.abs() : sum;
    });
  }

  /// Patrimonio totale netto (Attività - Passività)
  double get totalNetWorth {
    return _accounts.fold(
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
}
