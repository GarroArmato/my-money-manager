import '../models/account.dart';
import '../models/transaction.dart';

/// Gestisce lo storage locale multipiattaforma (Android, iOS, Web Chrome, Windows Desktop)
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  bool _enableCsvImport = true;
  bool _enableNotificationReader = false;

  final List<Account> _accounts = [
    Account(
      id: 'acc_cash',
      name: 'Contanti',
      type: AccountType.cash,
      initialBalance: 120.00,
    ),
    Account(
      id: 'acc_bank_main',
      name: 'Conto Corrente Principale',
      type: AccountType.bankAccount,
      initialBalance: 1450.00,
      iban: 'IT60X0306909606100000123456',
    ),
  ];

  final List<MoneyTransaction> _transactions = [];

  DatabaseHelper._init();

  // --- IMPOSTAZIONI (FLAG FACOLTATIVI) ---
  Future<bool> getEnableCsvImport() async => _enableCsvImport;

  Future<void> setEnableCsvImport(bool value) async {
    _enableCsvImport = value;
  }

  Future<bool> getEnableNotificationReader() async => _enableNotificationReader;

  Future<void> setEnableNotificationReader(bool value) async {
    _enableNotificationReader = value;
  }

  // --- CRUD ACCOUNTS ---
  Future<List<Account>> getAllAccounts() async {
    return List<Account>.unmodifiable(_accounts);
  }

  Future<void> insertAccount(Account account) async {
    final index = _accounts.indexWhere((a) => a.id == account.id);
    if (index >= 0) {
      _accounts[index] = account;
    } else {
      _accounts.add(account);
    }
  }

  // --- CRUD TRANSACTIONS ---
  Future<List<MoneyTransaction>> getAllTransactions() async {
    final sorted = List<MoneyTransaction>.from(_transactions)
      ..sort((a, b) => b.date.compareTo(a.date));
    return sorted;
  }

  Future<bool> insertTransaction(MoneyTransaction tx) async {
    if (tx.deduplicationKey != null) {
      final exists = _transactions
          .any((existing) => existing.deduplicationKey == tx.deduplicationKey);
      if (exists) return false;
    }
    _transactions.add(tx);
    return true;
  }

  Future<void> deleteTransaction(String id) async {
    _transactions.removeWhere((t) => t.id == id);
  }
}
