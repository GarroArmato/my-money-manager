import 'package:flutter/material.dart';

class AccountGroup {
  final String id;
  final String name;
  final String iconKey;
  final bool supportsCsvImport;

  const AccountGroup({
    required this.id,
    required this.name,
    this.iconKey = 'account_balance_wallet',
    this.supportsCsvImport = true,
  });

  IconData get icon => availableGroupIcons[iconKey] ?? Icons.folder_outlined;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'iconKey': iconKey,
      'supportsCsvImport': supportsCsvImport,
    };
  }

  factory AccountGroup.fromMap(Map<String, dynamic> map) {
    return AccountGroup(
      id: map['id'] as String,
      name: map['name'] as String,
      iconKey: map['iconKey'] as String? ?? 'account_balance_wallet',
      supportsCsvImport: map['supportsCsvImport'] as bool? ?? true,
    );
  }

  static const Map<String, IconData> availableGroupIcons = {
    'payments': Icons.payments_outlined,
    'account_balance': Icons.account_balance_outlined,
    'credit_card': Icons.credit_card_outlined,
    'savings': Icons.savings_outlined,
    'trending_up': Icons.trending_up,
    'account_balance_wallet': Icons.account_balance_wallet_outlined,
    'currency_bitcoin': Icons.currency_bitcoin,
    'real_estate_agent': Icons.home_work_outlined,
    'work': Icons.work_outline,
    'folder': Icons.folder_outlined,
  };

  static const List<AccountGroup> defaultGroups = [
    AccountGroup(
      id: 'grp_cash',
      name: 'Contanti',
      iconKey: 'payments',
      supportsCsvImport: false,
    ),
    AccountGroup(
      id: 'grp_bank',
      name: 'Conti Bancari',
      iconKey: 'account_balance',
      supportsCsvImport: true,
    ),
    AccountGroup(
      id: 'grp_card',
      name: 'Carte',
      iconKey: 'credit_card',
      supportsCsvImport: true,
    ),
    AccountGroup(
      id: 'grp_savings',
      name: 'Risparmi & Investimenti',
      iconKey: 'savings',
      supportsCsvImport: true,
    ),
  ];
}

class Account {
  final String id;
  final String name;
  final String groupId;
  final double initialBalance;
  final String currency;
  final String? iban;

  Account({
    required this.id,
    required this.name,
    required this.groupId,
    this.initialBalance = 0.0,
    this.currency = 'EUR',
    this.iban,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'groupId': groupId,
      'initialBalance': initialBalance,
      'currency': currency,
      'iban': iban,
    };
  }

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'] as String,
      name: map['name'] as String,
      groupId: map['groupId'] as String? ?? 'grp_cash',
      initialBalance: (map['initialBalance'] as num).toDouble(),
      currency: map['currency'] as String? ?? 'EUR',
      iban: map['iban'] as String?,
    );
  }
}
