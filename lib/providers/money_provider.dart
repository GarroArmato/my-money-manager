import 'package:flutter/foundation.dart' hide Category;
import '../models/account.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../services/database_helper.dart';
import '../services/open_banking_service.dart';

class MoneyProvider extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final OpenBankingService _openBankingService = OpenBankingService();

  List<Account> _accounts = [];
  List<MoneyTransaction> _transactions = [];
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  bool _isLoading = false;
  bool _isSyncingBank = false;

  List<Account> get accounts => _accounts;
  List<MoneyTransaction> get allTransactions => _transactions;
  List<TransactionCategory> get categories =>
      TransactionCategory.defaultCategories;
  DateTime get selectedMonth => _selectedMonth;
  bool get isLoading => _isLoading;
  bool get isSyncingBank => _isSyncingBank;

  /// Inizializza e carica i dati dal DB SQLite
  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    _accounts = await _db.getAllAccounts();
    _transactions = await _db.getAllTransactions();

    _isLoading = false;
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

  /// Calcola il saldo attuale di un singolo conto (Contanti, Banca, ecc.)
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
          balance -= tx.amount; // Uscita dal conto di origine
        } else if (tx.toAccountId == accountId) {
          balance += tx.amount; // Entrata nel conto di destinazione
        }
      }
    }
    return balance;
  }

  /// Patrimonio totale (somma di tutti i conti)
  double get totalNetWorth {
    return _accounts.fold(
      0.0,
      (sum, acc) => sum + getAccountBalance(acc.id),
    );
  }

  /// Aggiunge una nuova transazione manuale (Spesa, Entrata o Trasferimento)
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

  /// Sincronizza i movimenti dal conto bancario (Open Banking PSD2)
  Future<int> syncBankAccount(String accountId) async {
    _isSyncingBank = true;
    notifyListeners();

    try {
      final existingExternalIds = _transactions
          .where((t) => t.externalBankTransactionId != null)
          .map((t) => t.externalBankTransactionId!)
          .toSet();

      final fetched =
          await _openBankingService.fetchSandboxBankTransactions(accountId);

      int importedCount = 0;
      for (final tx in fetched) {
        if (tx.externalBankTransactionId != null &&
            !existingExternalIds.contains(tx.externalBankTransactionId)) {
          await _db.insertTransaction(tx);
          importedCount++;
        }
      }

      _transactions = await _db.getAllTransactions();
      return importedCount;
    } finally {
      _isSyncingBank = false;
      notifyListeners();
    }
  }

  TransactionCategory? getCategoryById(String? categoryId) {
    if (categoryId == null) return null;
    try {
      return categories.firstWhere((c) => c.id == categoryId);
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
