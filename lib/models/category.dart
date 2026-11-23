import 'package:flutter/material.dart';

enum CategoryKind {
  expense, // Uscita
  income,  // Entrata
}

class TransactionCategory {
  final String id;
  final String name;
  final CategoryKind kind;
  final IconData icon;
  final Color color;

  const TransactionCategory({
    required this.id,
    required this.name,
    required this.kind,
    required this.icon,
    required this.color,
  });

  static const List<TransactionCategory> defaultCategories = [
    // --- USCITE ---
    TransactionCategory(
      id: 'cat_food',
      name: 'Alimentari & Supermercato',
      kind: CategoryKind.expense,
      icon: Icons.shopping_cart,
      color: Color(0xFFE53935),
    ),
    TransactionCategory(
      id: 'cat_restaurant',
      name: 'Ristoranti & Bar',
      kind: CategoryKind.expense,
      icon: Icons.restaurant,
      color: Color(0xFFFB8C00),
    ),
    TransactionCategory(
      id: 'cat_transport',
      name: 'Trasporti & Carburante',
      kind: CategoryKind.expense,
      icon: Icons.directions_car,
      color: Color(0xFF1E88E5),
    ),
    TransactionCategory(
      id: 'cat_home',
      name: 'Casa & Bollette',
      kind: CategoryKind.expense,
      icon: Icons.home,
      color: Color(0xFF8E24AA),
    ),
    TransactionCategory(
      id: 'cat_entertainment',
      name: 'Svago & Abbonamenti',
      kind: CategoryKind.expense,
      icon: Icons.movie,
      color: Color(0xFF00ACC1),
    ),
    TransactionCategory(
      id: 'cat_shopping',
      name: 'Shopping',
      kind: CategoryKind.expense,
      icon: Icons.shopping_bag,
      color: Color(0xFFD81B60),
    ),
    // --- ENTRATE ---
    TransactionCategory(
      id: 'cat_salary',
      name: 'Stipendio',
      kind: CategoryKind.income,
      icon: Icons.account_balance_wallet,
      color: Color(0xFF43A047),
    ),
    TransactionCategory(
      id: 'cat_other_income',
      name: 'Altre Entrate / Rimborsi',
      kind: CategoryKind.income,
      icon: Icons.trending_up,
      color: Color(0xFF00897B),
    ),
  ];
}
