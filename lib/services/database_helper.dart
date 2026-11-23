import '../models/account.dart';
import '../models/category.dart';
import '../models/transaction.dart';

/// Gestisce lo storage locale multipiattaforma per Gruppi di Conti, Conti, Categorie, Movimenti, Colori e Impostazioni
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static const int defaultPrimaryPurple = 0xFF6A1B9A;   // Viola di default
  static const int defaultSecondaryGreen = 0xFF2E7D32;  // Verde di default
  static const int defaultExpenseColor = 0xFFD32F2F;    // Rosso uscite di default

  bool _enableCsvImport = true;
  bool _enableNotificationReader = false;

  int _primaryColorValue = defaultPrimaryPurple;
  int _secondaryColorValue = defaultSecondaryGreen;
  int _expenseColorValue = defaultExpenseColor;
  int _themeModeIndex = 0; // 0 = System, 1 = Light, 2 = Dark

  final List<AccountGroup> _accountGroups = List<AccountGroup>.from(
    AccountGroup.defaultGroups,
  );

  final List<Account> _accounts = [
    Account(
      id: 'acc_cash',
      name: 'Portafoglio Contanti',
      groupId: 'grp_cash',
      initialBalance: 120.00,
    ),
    Account(
      id: 'acc_bank_main',
      name: 'Conto Corrente Principale',
      groupId: 'grp_bank',
      initialBalance: 1450.00,
      iban: 'IT60X0306909606100000123456',
    ),
    Account(
      id: 'acc_card_revolut',
      name: 'Carta Revolut / Prepagata',
      groupId: 'grp_card',
      initialBalance: 250.00,
    ),
    Account(
      id: 'acc_savings',
      name: 'Salvadanaio Risparmi',
      groupId: 'grp_savings',
      initialBalance: 3000.00,
    ),
  ];

  final List<TransactionCategory> _categories = List<TransactionCategory>.from(
    TransactionCategory.defaultCategories,
  );

  final List<MoneyTransaction> _transactions = [];

  DatabaseHelper._init();

  // --- COLORI E TEMA DELL'APP (DEFAULT: VIOLA & VERDE) ---
  Future<int> getPrimaryColorValue() async => _primaryColorValue;
  Future<void> setPrimaryColorValue(int val) async => _primaryColorValue = val;

  Future<int> getSecondaryColorValue() async => _secondaryColorValue;
  Future<void> setSecondaryColorValue(int val) async =>
      _secondaryColorValue = val;

  Future<int> getExpenseColorValue() async => _expenseColorValue;
  Future<void> setExpenseColorValue(int val) async => _expenseColorValue = val;

  Future<int> getThemeModeIndex() async => _themeModeIndex;
  Future<void> setThemeModeIndex(int val) async => _themeModeIndex = val;

  // --- IMPOSTAZIONI (FLAG FACOLTATIVI) ---
  Future<bool> getEnableCsvImport() async => _enableCsvImport;

  Future<void> setEnableCsvImport(bool value) async {
    _enableCsvImport = value;
  }

  Future<bool> getEnableNotificationReader() async => _enableNotificationReader;

  Future<void> setEnableNotificationReader(bool value) async {
    _enableNotificationReader = value;
  }

  // --- CRUD ACCOUNT GROUPS (GRUPPI DI CONTI) ---
  Future<List<AccountGroup>> getAllAccountGroups() async {
    return List<AccountGroup>.unmodifiable(_accountGroups);
  }

  Future<void> upsertAccountGroup(AccountGroup group) async {
    final index = _accountGroups.indexWhere((g) => g.id == group.id);
    if (index >= 0) {
      _accountGroups[index] = group;
    } else {
      _accountGroups.add(group);
    }
  }

  Future<void> deleteAccountGroup(String groupId) async {
    if (_accountGroups.length <= 1) return;
    _accountGroups.removeWhere((g) => g.id == groupId);
    final fallbackGroupId = _accountGroups.first.id;
    for (int i = 0; i < _accounts.length; i++) {
      if (_accounts[i].groupId == groupId) {
        final old = _accounts[i];
        _accounts[i] = Account(
          id: old.id,
          name: old.name,
          groupId: fallbackGroupId,
          initialBalance: old.initialBalance,
          currency: old.currency,
          iban: old.iban,
        );
      }
    }
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
    if (_accounts.length <= 1) return;
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
