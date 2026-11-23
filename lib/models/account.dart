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
  final String? iban;

  Account({
    required this.id,
    required this.name,
    required this.type,
    this.initialBalance = 0.0,
    this.currency = 'EUR',
    this.iban,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'initialBalance': initialBalance,
      'currency': currency,
      'iban': iban,
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
      iban: map['iban'] as String?,
    );
  }
}
