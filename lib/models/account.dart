enum AccountType {
  cash,        // Contanti
  bankAccount, // Conto Corrente Bancario
  creditCard,  // Carta di Credito / Debito
  savings,     // Risparmi / Salvadanaio
}

class Account {
  final String id;
  final String name;
  final AccountType type;
  final double initialBalance;
  final String currency;
  // Campi per il collegamento Open Banking (PSD2 / GoCardless)
  final String? bankInstitutionId; // es. INTESA_SANPAOLO_BCITITMM
  final String? externalAccountId; // ID conto restituito dall'aggregatore
  final String? iban;
  final DateTime? lastSyncAt;

  Account({
    required this.id,
    required this.name,
    required this.type,
    this.initialBalance = 0.0,
    this.currency = 'EUR',
    this.bankInstitutionId,
    this.externalAccountId,
    this.iban,
    this.lastSyncAt,
  });

  bool get isBankConnected =>
      externalAccountId != null && externalAccountId!.isNotEmpty;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'initialBalance': initialBalance,
      'currency': currency,
      'bankInstitutionId': bankInstitutionId,
      'externalAccountId': externalAccountId,
      'iban': iban,
      'lastSyncAt': lastSyncAt?.toIso8601String(),
    };
  }

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'] as String,
      name: map['name'] as String,
      type: AccountType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => AccountType.cash,
      ),
      initialBalance: (map['initialBalance'] as num).toDouble(),
      currency: map['currency'] as String? ?? 'EUR',
      bankInstitutionId: map['bankInstitutionId'] as String?,
      externalAccountId: map['externalAccountId'] as String?,
      iban: map['iban'] as String?,
      lastSyncAt: map['lastSyncAt'] != null
          ? DateTime.tryParse(map['lastSyncAt'] as String)
          : null,
    );
  }
}
