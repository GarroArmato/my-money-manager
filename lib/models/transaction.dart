enum TransactionType {
  expense,  // Uscita
  income,   // Entrata
  transfer, // Trasferimento tra due conti (es. Prelievo da Banca a Contanti)
}

class MoneyTransaction {
  final String id;
  final double amount;
  final DateTime date;
  final TransactionType type;
  final String accountId;
  final String? toAccountId; // Usato solo se type == TransactionType.transfer
  final String? categoryId;  // Null se è un trasferimento
  final String note;
  final String? merchantName;
  // Campi per tracciare movimenti importati tramite Open Banking (evita duplicati)
  final bool isBankSynced;
  final String? externalBankTransactionId;

  MoneyTransaction({
    required this.id,
    required this.amount,
    required this.date,
    required this.type,
    required this.accountId,
    this.toAccountId,
    this.categoryId,
    this.note = '',
    this.merchantName,
    this.isBankSynced = false,
    this.externalBankTransactionId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'date': date.toIso8601String(),
      'type': type.name,
      'accountId': accountId,
      'toAccountId': toAccountId,
      'categoryId': categoryId,
      'note': note,
      'merchantName': merchantName,
      'isBankSynced': isBankSynced ? 1 : 0,
      'externalBankTransactionId': externalBankTransactionId,
    };
  }

  factory MoneyTransaction.fromMap(Map<String, dynamic> map) {
    return MoneyTransaction(
      id: map['id'] as String,
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      type: TransactionType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => TransactionType.expense,
      ),
      accountId: map['accountId'] as String,
      toAccountId: map['toAccountId'] as String?,
      categoryId: map['categoryId'] as String?,
      note: map['note'] as String? ?? '',
      merchantName: map['merchantName'] as String?,
      isBankSynced: (map['isBankSynced'] as int? ?? 0) == 1,
      externalBankTransactionId: map['externalBankTransactionId'] as String?,
    );
  }
}
