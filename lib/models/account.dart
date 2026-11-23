import 'package:flutter/material.dart';

enum AccountType {
  cash,        // Contanti
  bankAccount, // Conti Bancari
  creditCard,  // Carte (Debito / Credito / Prepagate)
  savings,     // Risparmi & Investimenti
}

extension AccountTypeExtension on AccountType {
  String get label {
    switch (this) {
      case AccountType.cash:
        return 'Contanti';
      case AccountType.bankAccount:
        return 'Conti Bancari';
      case AccountType.creditCard:
        return 'Carte';
      case AccountType.savings:
        return 'Risparmi & Investimenti';
    }
  }

  IconData get icon {
    switch (this) {
      case AccountType.cash:
        return Icons.payments_outlined;
      case AccountType.bankAccount:
        return Icons.account_balance_outlined;
      case AccountType.creditCard:
        return Icons.credit_card_outlined;
      case AccountType.savings:
        return Icons.savings_outlined;
    }
  }
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
