import 'package:flutter/material.dart';

enum CategoryKind {
  expense, // Uscita
  income,  // Entrata
}

class TransactionCategory {
  final String id;
  final String name;
  final CategoryKind kind;
  final int iconCodePoint;
  final int colorValue;

  const TransactionCategory({
    required this.id,
    required this.name,
    required this.kind,
    required this.iconCodePoint,
    required this.colorValue,
  });

  IconData get icon => IconData(iconCodePoint, fontFamily: 'MaterialIcons');
  Color get color => Color(colorValue);

  static const List<TransactionCategory> defaultCategories = [
    // --- USCITE ---
    TransactionCategory(
      id: 'cat_food',
      name: 'Alimentari & Supermercato',
      kind: CategoryKind.expense,
      iconCodePoint: 0xe59c, // shopping_cart
      colorValue: 0xFFE53935,
    ),
    TransactionCategory(
      id: 'cat_restaurant',
      name: 'Ristoranti & Bar',
      kind: CategoryKind.expense,
      iconCodePoint: 0xe532, // restaurant
      colorValue: 0xFFFB8C00,
    ),
    TransactionCategory(
      id: 'cat_transport',
      name: 'Trasporti & Carburante',
      kind: CategoryKind.expense,
      iconCodePoint: 0xe1d5, // directions_car
      colorValue: 0xFF1E88E5,
    ),
    TransactionCategory(
      id: 'cat_home',
      name: 'Casa & Bollette',
      kind: CategoryKind.expense,
      iconCodePoint: 0xe318, // home
      colorValue: 0xFF8E24AA,
    ),
    TransactionCategory(
      id: 'cat_entertainment',
      name: 'Svago & Abbonamenti',
      kind: CategoryKind.expense,
      iconCodePoint: 0xe40f, // movie
      colorValue: 0xFF00ACC1,
    ),
    TransactionCategory(
      id: 'cat_shopping',
      name: 'Shopping',
      kind: CategoryKind.expense,
      iconCodePoint: 0xe59a, // shopping_bag
      colorValue: 0xFFD81B60,
    ),
    // --- ENTRATE ---
    TransactionCategory(
      id: 'cat_salary',
      name: 'Stipendio',
      kind: CategoryKind.income,
      iconCodePoint: 0xe041, // account_balance_wallet
      colorValue: 0xFF43A047,
    ),
    TransactionCategory(
      id: 'cat_other_income',
      name: 'Altre Entrate / Rimborsi',
      kind: CategoryKind.income,
      iconCodePoint: 0xe8e5, // trending_up
      colorValue: 0xFF00897B,
    ),
  ];
}
