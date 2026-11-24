import 'package:flutter/material.dart';
import '../models/category.dart';
import '../utils/formatters.dart';
import '../utils/money_scope.dart';
import '../widgets/app_top_bar.dart';

/// Mostra il dialog modale per Creare o Modificare una Categoria (e le sue Sottocategorie)
Future<TransactionCategory?> showCategoryEditorDialog(
  BuildContext context, {
  CategoryKind initialKind = CategoryKind.expense,
  TransactionCategory? existingCategory,
}) async {
  final nameController = TextEditingController(
    text: existingCategory?.name ?? '',
  );
  final subController = TextEditingController();
  CategoryKind selectedKind = existingCategory?.kind ?? initialKind;
  String selectedIconKey =
      existingCategory?.iconKey ?? TransactionCategory.availableIcons.keys.first;
  int selectedColorValue = existingCategory?.colorValue ??
      (selectedKind == CategoryKind.income ? 0xFF43A047 : 0xFFE53935);
  final List<String> subcategories = List<String>.from(
    existingCategory?.subcategories ?? ['Altro'],
  );

  return showDialog<TransactionCategory>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: Text(
              existingCategory == null
                  ? 'Nuova Categoria'
                  : 'Modifica Categoria',
            ),
            content: SizedBox(
              width: 450,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Tipo: Uscita o Entrata
                    SegmentedButton<CategoryKind>(
                      segments: const [
                        ButtonSegment(
                          value: CategoryKind.expense,
                          label: Text('Categoria Uscita'),
                          icon: Icon(Icons.arrow_upward),
                        ),
                        ButtonSegment(
                          value: CategoryKind.income,
                          label: Text('Categoria Entrata'),
                          icon: Icon(Icons.arrow_downward),
                        ),
                      ],
                      selected: {selectedKind},
                      onSelectionChanged: (sel) {
                        setDialogState(() {
                          selectedKind = sel.first;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Nome Categoria
                    TextField(
                      controller: nameController,
                      autofocus: existingCategory == null,
                      decoration: InputDecoration(
                        labelText: 'Nome Categoria (es. Macchina, Cibo...)',
                        border: const OutlineInputBorder(),
                        prefixIcon: Icon(
                          TransactionCategory.availableIcons[selectedIconKey] ??
                              Icons.category,
                          color: Color(selectedColorValue),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Sottocategorie (es. Assicurazione, Multa, Parcheggio, Bollo...)
                    const Text(
                      'Sottocategorie (visibili nel dettaglio statistiche)',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: subcategories.map((sub) {
                        return InputChip(
                          label: Text(sub),
                          onDeleted: subcategories.length > 1
                              ? () {
                                  setDialogState(() {
                                    subcategories.remove(sub);
                                  });
                                }
                              : null,
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: subController,
                            decoration: const InputDecoration(
                              isDense: true,
                              labelText:
                                  'Aggiungi sottocategoria (es. Assicurazione)',
                              border: OutlineInputBorder(),
                            ),
                            onSubmitted: (val) {
                              final t = val.trim();
                              if (t.isNotEmpty && !subcategories.contains(t)) {
                                setDialogState(() {
                                  subcategories.add(t);
                                  subController.clear();
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          onPressed: () {
                            final t = subController.text.trim();
                            if (t.isNotEmpty && !subcategories.contains(t)) {
                              setDialogState(() {
                                subcategories.add(t);
                                subController.clear();
                              });
                            }
                          },
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Scelta Colore
                    const Text(
                      'Colore',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: TransactionCategory.availableColors.map((col) {
                        final isSelected = col == selectedColorValue;
                        return InkWell(
                          onTap: () {
                            setDialogState(() {
                              selectedColorValue = col;
                            });
                          },
                          borderRadius: BorderRadius.circular(20),
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: Color(col),
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? Border.all(
                                      color: Theme.of(ctx).colorScheme.onSurface,
                                      width: 3,
                                    )
                                  : null,
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check,
                                    size: 18,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),

                    // Scelta Icona
                    const Text(
                      'Icona',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          TransactionCategory.availableIcons.entries.map((e) {
                        final isSelected = e.key == selectedIconKey;
                        return InkWell(
                          onTap: () {
                            setDialogState(() {
                              selectedIconKey = e.key;
                            });
                          },
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Color(selectedColorValue)
                                      .withValues(alpha: 0.2)
                                  : Theme.of(ctx)
                                      .colorScheme
                                      .surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(10),
                              border: isSelected
                                  ? Border.all(
                                      color: Color(selectedColorValue),
                                      width: 2,
                                    )
                                  : null,
                            ),
                            child: Icon(
                              e.value,
                              color: isSelected
                                  ? Color(selectedColorValue)
                                  : Theme.of(ctx).colorScheme.onSurfaceVariant,
                              size: 22,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Annulla'),
              ),
              FilledButton.icon(
                onPressed: () async {
                  final name = nameController.text.trim();
                  if (name.isEmpty) return;

                  final newCat = TransactionCategory(
                    id: existingCategory?.id ??
                        AppFormatters.generateId('cat'),
                    name: name,
                    kind: selectedKind,
                    iconKey: selectedIconKey,
                    colorValue: selectedColorValue,
                    subcategories: subcategories,
                  );

                  await MoneyScope.read(context).saveCategory(newCat);
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop(newCat);
                  }
                },
                icon: const Icon(Icons.check),
                label: const Text('Salva Categoria'),
              ),
            ],
          );
        },
      );
    },
  );
}

class CategoriesScreen extends StatefulWidget {
  final CategoryKind initialKind;

  const CategoriesScreen({
    super.key,
    this.initialKind = CategoryKind.expense,
  });

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  late CategoryKind _activeKind;

  @override
  void initState() {
    super.initState();
    _activeKind = widget.initialKind;
  }

  @override
  Widget build(BuildContext context) {
    final provider = MoneyScope.of(context);
    final list = _activeKind == CategoryKind.expense
        ? provider.expenseCategories
        : provider.incomeCategories;

    return Scaffold(
      appBar: const AppTopBar(
        title: 'Categorie Entrate & Uscite',
        icon: Icons.category_outlined,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showCategoryEditorDialog(
            context,
            initialKind: _activeKind,
          );
        },
        icon: const Icon(Icons.add),
        label: Text(
          _activeKind == CategoryKind.expense
              ? 'Nuova Cat. Uscita'
              : 'Nuova Cat. Entrata',
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<CategoryKind>(
                segments: [
                  ButtonSegment(
                    value: CategoryKind.expense,
                    label: Text(
                        'Categorie Uscite (${provider.expenseCategories.length})'),
                    icon: const Icon(Icons.arrow_upward),
                  ),
                  ButtonSegment(
                    value: CategoryKind.income,
                    label: Text(
                        'Categorie Entrate (${provider.incomeCategories.length})'),
                    icon: const Icon(Icons.arrow_downward),
                  ),
                ],
                selected: {_activeKind},
                onSelectionChanged: (sel) {
                  setState(() {
                    _activeKind = sel.first;
                  });
                },
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
              itemCount: list.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final cat = list[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: cat.color.withValues(alpha: 0.15),
                    child: Icon(cat.icon, color: cat.color),
                  ),
                  title: Text(
                    cat.name,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: cat.subcategories.isNotEmpty
                      ? Text(
                          cat.subcategories.join(', '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12),
                        )
                      : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Modifica categoria e sottocategorie',
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () {
                          showCategoryEditorDialog(
                            context,
                            existingCategory: cat,
                          );
                        },
                      ),
                      if (list.length > 1)
                        IconButton(
                          tooltip: 'Elimina categoria',
                          icon: Icon(
                            Icons.delete_outline,
                            color: Colors.red.shade600,
                          ),
                          onPressed: () => provider.deleteCategory(cat.id),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
