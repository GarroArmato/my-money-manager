import '../models/account.dart';
import '../models/category.dart';
import '../models/transaction.dart';

/// Gestisce lo storage locale multipiattaforma per Conti, Categorie, Movimenti e Impostazioni
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  bool _enableCsvImport = true;
  bool _enableNotificationReader = false;

  final List<Account> _accounts = [
    Account(
      id: 'acc_cash',
      name: 'Portafoglio Contanti',
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
    Account(
      id: 'acc_card_revolut',
      name: 'Carta Revolut / Prepagata',
      type: AccountType.creditCard,
      initialBalance: 250.00,
    ),
    Account(
      id: 'acc_savings',
      name: 'Salvadanaio Risparmi',
      type: AccountType.savings,
      initialBalance: 3000.00,
    ),
  ];

  final List<TransactionCategory> _categories = List<TransactionCategory>.from(
    TransactionCategory.defaultCategories,
  );

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

  // --- CRUD ACCOUNTS (CONTI) ---
  Future<List<Account>> getAllAccounts() async {
    return List<Account>.unmodifiable(_accounts);
  }

  Future<void> upsertAccount(Account account) async {
    final index = _accounts.indexWhere((a) => a.id == account.id);
    if (index >= 0) {
      _accounts[index] = account;
    } else {
      _accounts.add(account);
    }
  }

  Future<void> deleteAccount(String accountId) async {
    if (_accounts.length <= 1) return; // Mantiene almeno un conto attivo
    _accounts.removeWhere((a) => a.id == accountId);
    _transactions.removeWhere(
      (t) => t.accountId == accountId || t.toAccountId == accountId,
    );
  }

  // --- CRUD CATEGORIES (CATEGORIE ENTRATA E USCITA) ---
  Future<List<TransactionCategory>> getAllCategories() async {
    return List<TransactionCategory>.unmodifiable(_categories);
  }

  Future<void> upsertCategory(TransactionCategory category) async {
    final index = _categories.indexWhere((c) => c.id == category.id);
    if (index >= 0) {
      _categories[index] = category;
    } else {
      _categories.add(category);
    }
  }

  Future<void> deleteCategory(String categoryId) async {
    _categories.removeWhere((c) => c.id == categoryId);
  }

  // --- CRUD TRANSACTIONS (MOVIMENTI) ---
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
