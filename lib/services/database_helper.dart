import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/account.dart';
import '../models/transaction.dart';

/// Gestisce il salvataggio locale multipiattaforma (Android, iOS, Web Chrome, Windows Desktop)
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static const String _accountsKey = 'mm_accounts_v2';
  static const String _transactionsKey = 'mm_transactions_v2';
  static const String _enableCsvKey = 'mm_setting_enable_csv';
  static const String _enableNotificationsKey = 'mm_setting_enable_notifications';

  DatabaseHelper._init();

  // --- IMPOSTAZIONI (FLAG FACOLTATIVI) ---
  Future<bool> getEnableCsvImport() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enableCsvKey) ?? true; // Attivo di default
  }

  Future<void> setEnableCsvImport(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enableCsvKey, value);
  }

  Future<bool> getEnableNotificationReader() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enableNotificationsKey) ?? false; // Facoltativo
  }

  Future<void> setEnableNotificationReader(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enableNotificationsKey, value);
  }

  // --- CRUD ACCOUNTS ---
  Future<List<Account>> getAllAccounts() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_accountsKey);

    if (raw == null || raw.isEmpty) {
      final seedAccounts = [
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
      await _saveAccountsList(seedAccounts);
      return seedAccounts;
    }

    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((item) => Account.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> _saveAccountsList(List<Account> accounts) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(accounts.map((a) => a.toMap()).toList());
    await prefs.setString(_accountsKey, encoded);
  }

  Future<void> insertAccount(Account account) async {
    final accounts = await getAllAccounts();
    final index = accounts.indexWhere((a) => a.id == account.id);
    if (index >= 0) {
      accounts[index] = account;
    } else {
      accounts.add(account);
    }
    await _saveAccountsList(accounts);
  }

  // --- CRUD TRANSACTIONS ---
  Future<List<MoneyTransaction>> getAllTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_transactionsKey);
    if (raw == null || raw.isEmpty) return [];

    final decoded = jsonDecode(raw) as List<dynamic>;
    final list = decoded
        .map((item) => MoneyTransaction.fromMap(item as Map<String, dynamic>))
        .toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  Future<void> _saveTransactionsList(List<MoneyTransaction> transactions) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(transactions.map((t) => t.toMap()).toList());
    await prefs.setString(_transactionsKey, encoded);
  }

  Future<bool> insertTransaction(MoneyTransaction tx) async {
    final list = await getAllTransactions();

    // Se ha una deduplicationKey (es. riga CSV), controlla che non esista già
    if (tx.deduplicationKey != null) {
      final exists =
          list.any((existing) => existing.deduplicationKey == tx.deduplicationKey);
      if (exists) return false;
    }

    list.add(tx);
    list.sort((a, b) => b.date.compareTo(a.date));
    await _saveTransactionsList(list);
    return true;
  }

  Future<void> deleteTransaction(String id) async {
    final list = await getAllTransactions();
    list.removeWhere((t) => t.id == id);
    await _saveTransactionsList(list);
  }
}
