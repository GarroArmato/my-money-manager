import 'package:flutter/material.dart';

enum CategoryKind {
  expense, // Uscita
  income,  // Entrata
}

class TransactionCategory {
  final String id;
  final String name;
  final CategoryKind kind;
  final String iconKey;
  final int colorValue;
  final List<String> subcategories;

  const TransactionCategory({
    required this.id,
    required this.name,
    required this.kind,
    required this.iconKey,
    required this.colorValue,
    this.subcategories = const [],
  });

  IconData get icon => availableIcons[iconKey] ?? Icons.category;
  Color get color => Color(colorValue);

  TransactionCategory copyWith({
    String? id,
    String? name,
    CategoryKind? kind,
    String? iconKey,
    int? colorValue,
    List<String>? subcategories,
  }) {
    return TransactionCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      kind: kind ?? this.kind,
      iconKey: iconKey ?? this.iconKey,
      colorValue: colorValue ?? this.colorValue,
      subcategories: subcategories ?? this.subcategories,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'kind': kind.name,
      'iconKey': iconKey,
      'colorValue': colorValue,
      'subcategories': subcategories,
    };
  }

  factory TransactionCategory.fromMap(Map<String, dynamic> map) {
    return TransactionCategory(
      id: map['id'] as String,
      name: map['name'] as String,
      kind: CategoryKind.values.firstWhere(
        (e) => e.name == map['kind'],
        orElse: () => CategoryKind.expense,
      ),
      iconKey: map['iconKey'] as String? ?? 'category',
      colorValue: map['colorValue'] as int? ?? 0xFF00796B,
      subcategories: (map['subcategories'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  /// Catalogo di icone selezionabili dall'utente quando crea una nuova categoria
  static const Map<String, IconData> availableIcons = {
    'shopping_cart': Icons.shopping_cart,
    'restaurant': Icons.restaurant,
    'local_cafe': Icons.local_cafe,
    'directions_car': Icons.directions_car,
    'directions_bus': Icons.directions_bus,
    'flight': Icons.flight,
    'home': Icons.home,
    'bolt': Icons.bolt,
    'movie': Icons.movie,
    'shopping_bag': Icons.shopping_bag,
    'fitness_center': Icons.fitness_center,
    'medical_services': Icons.medical_services,
    'pets': Icons.pets,
    'school': Icons.school,
    'card_giftcard': Icons.card_giftcard,
    'sports_esports': Icons.sports_esports,
    'phone_android': Icons.phone_android,
    'build': Icons.build,
    'account_balance_wallet': Icons.account_balance_wallet,
    'trending_up': Icons.trending_up,
    'savings': Icons.savings,
    'work': Icons.work,
    'euro': Icons.euro,
    'category': Icons.category,
  };

  /// Tavolozza di colori selezionabili dall'utente per le categorie
  static const List<int> availableColors = [
    0xFFE53935, // Rosso
    0xFFD81B60, // Rosa scuro
    0xFF8E24AA, // Viola
    0xFF5E35B1, // Indaco
    0xFF1E88E5, // Blu
    0xFF039BE5, // Azzurro
    0xFF00ACC1, // Ciano
    0xFF00897B, // Verde acqua (Teal)
    0xFF43A047, // Verde
    0xFF7CB342, // Verde chiaro
    0xFFFB8C00, // Arancione
    0xFF6D4C41, // Marrone
    0xFF546E7A, // Grigio blu
  ];

  static const List<TransactionCategory> defaultCategories = [
    // --- USCITE PREDEFINITE (con Sottocategorie stile Money Manager) ---
    TransactionCategory(
      id: 'cat_food',
      name: 'Alimentari',
      kind: CategoryKind.expense,
      iconKey: 'shopping_cart',
      colorValue: 0xFFE53935,
      subcategories: [
        'Supermercato',
        'Frutta & Verdura',
        'Forno & Pane',
        'macelleria',
        'Altro',
      ],
    ),
    TransactionCategory(
      id: 'cat_restaurant',
      name: 'Ristoranti & Bar',
      kind: CategoryKind.expense,
      iconKey: 'restaurant',
      colorValue: 0xFFFB8C00,
      subcategories: [
        'Ristorante / Pizzeria',
        'Colazione & Bar',
        'Delivery (Glovo/Deliveroo)',
        'Aperitivo',
        'Altro',
      ],
    ),
    TransactionCategory(
      id: 'cat_transport',
      name: 'Macchina & Trasporti',
      kind: CategoryKind.expense,
      iconKey: 'directions_car',
      colorValue: 0xFF1E88E5,
      subcategories: [
        'Carburante',
        'Assicurazione',
        'Multa',
        'Parcheggio',
        'Rate',
        'Bollo',
        'Revisione',
        'Mezzi Pubblici',
        'Altro',
      ],
    ),
    TransactionCategory(
      id: 'cat_home',
      name: 'Casa & Utenze',
      kind: CategoryKind.expense,
      iconKey: 'home',
      colorValue: 0xFF8E24AA,
      subcategories: [
        'Affitto / Mutuo',
        'Luce & Gas',
        'Internet & Telefono',
        'Condominio',
        'Manutenzione',
        'Altro',
      ],
    ),
    TransactionCategory(
      id: 'cat_entertainment',
      name: 'Svago & Cultura',
      kind: CategoryKind.expense,
      iconKey: 'movie',
      colorValue: 0xFF00ACC1,
      subcategories: [
        'Abbonamenti (Netflix/Spotify)',
        'Cinema & Concerti',
        'Viaggi & Vacanze',
        'Hobby & Giochi',
        'Altro',
      ],
    ),
    TransactionCategory(
      id: 'cat_shopping',
      name: 'Shopping & Vestiti',
      kind: CategoryKind.expense,
      iconKey: 'shopping_bag',
      colorValue: 0xFFD81B60,
      subcategories: [
        'Abbigliamento',
        'Scarpe & Accessori',
        'Elettronica',
        'Regali',
        'Altro',
      ],
    ),
    TransactionCategory(
      id: 'cat_health',
      name: 'Salute & Cura',
      kind: CategoryKind.expense,
      iconKey: 'medical_services',
      colorValue: 0xFF00897B,
      subcategories: [
        'Farmacia',
        'Visite Mediche',
        'Palestra & Sport',
        'Cura Persona',
        'Altro',
      ],
    ),
    // --- ENTRATE PREDEFINITE ---
    TransactionCategory(
      id: 'cat_salary',
      name: 'Stipendio',
      kind: CategoryKind.income,
      iconKey: 'account_balance_wallet',
      colorValue: 0xFF43A047,
      subcategories: [
        'Stipendio Base',
        'Straordinari',
        'Tredicesima / Quattordicesima',
        'Altro',
      ],
    ),
    TransactionCategory(
      id: 'cat_bonus',
      name: 'Bonus & Regali',
      kind: CategoryKind.income,
      iconKey: 'card_giftcard',
      colorValue: 0xFF039BE5,
      subcategories: [
        'Bonus Aziendale',
        'Regalo',
        'Rimborso',
        'Altro',
      ],
    ),
    TransactionCategory(
      id: 'cat_other_income',
      name: 'Altre Entrate',
      kind: CategoryKind.income,
      iconKey: 'trending_up',
      colorValue: 0xFF00897B,
      subcategories: [
        'Vendite Usato',
        'Interessi & Dividendi',
        'Freelance',
        'Altro',
      ],
    ),
  ];
}
