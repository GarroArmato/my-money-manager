import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/account.dart';
import '../models/transaction.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('money_manager.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE accounts (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        initialBalance REAL NOT NULL,
        currency TEXT NOT NULL,
        bankInstitutionId TEXT,
        externalAccountId TEXT,
        iban TEXT,
        lastSyncAt TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        amount REAL NOT NULL,
        date TEXT NOT NULL,
        type TEXT NOT NULL,
        accountId TEXT NOT NULL,
        toAccountId TEXT,
        categoryId TEXT,
        note TEXT NOT NULL,
        merchantName TEXT,
        isBankSynced INTEGER NOT NULL DEFAULT 0,
        externalBankTransactionId TEXT UNIQUE,
        FOREIGN KEY (accountId) REFERENCES accounts (id)
      )
    ''');

    // Inseriamo i conti predefiniti in stile Money Manager
    await db.insert('accounts', Account(
      id: 'acc_cash',
      name: 'Contanti',
      type: AccountType.cash,
      initialBalance: 120.00,
    ).toMap());

    await db.insert('accounts', Account(
      id: 'acc_bank_main',
      name: 'Conto Corrente Principale',
      type: AccountType.bankAccount,
      initialBalance: 1450.00,
      bankInstitutionId: 'INTESA_SANPAOLO_BCITITMM',
      iban: 'IT60X0306909606100000123456',
    ).toMap());
  }

  // --- CRUD ACCOUNTS ---
  Future<List<Account>> getAllAccounts() async {
    final db = await instance.database;
    final result = await db.query('accounts');
    return result.map((json) => Account.fromMap(json)).toList();
  }

  Future<void> insertAccount(Account account) async {
    final db = await instance.database;
    await db.insert(
      'accounts',
      account.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // --- CRUD TRANSACTIONS ---
  Future<List<MoneyTransaction>> getAllTransactions() async {
    final db = await instance.database;
    final result = await db.query('transactions', orderBy: 'date DESC');
    return result.map((json) => MoneyTransaction.fromMap(json)).toList();
  }

  Future<void> insertTransaction(MoneyTransaction tx) async {
    final db = await instance.database;
    await db.insert(
      'transactions',
      tx.toMap(),
      conflictAlgorithm: ConflictAlgorithm.ignore, // Ignora duplicati bancari
    );
  }

  Future<void> deleteTransaction(String id) async {
    final db = await instance.database;
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }
}
