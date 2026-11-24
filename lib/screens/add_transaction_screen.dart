import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../providers/money_provider.dart';
import '../utils/formatters.dart';
import '../utils/money_scope.dart';
import 'accounts_screen.dart';
import 'categories_screen.dart';

class AddTransactionScreen extends StatefulWidget {
  final String? initialAccountId;

  const AddTransactionScreen({
    super.key,
    this.initialAccountId,
  });

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _descriptionController = TextEditingController();

  TransactionType _selectedType = TransactionType.expense;
  DateTime _selectedDate = DateTime.now();
  String? _selectedAccountId;
  String? _selectedToAccountId;
  String? _selectedCategoryId;
  String? _selectedSubcategory;
  String? _selectedTag;
  bool _isRepeatEnabled = false;
  String _currentNoteQuery = '';
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _noteController.addListener(() {
      if (mounted) {
        setState(() {
          _currentNoteQuery = _noteController.text.trim();
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      final provider = MoneyScope.read(context);
      if (provider.accounts.isNotEmpty) {
        if (widget.initialAccountId != null &&
            provider.accounts.any((a) => a.id == widget.initialAccountId)) {
          _selectedAccountId = widget.initialAccountId;
        } else {
          _selectedAccountId = provider.accounts.first.id;
        }
        if (provider.accounts.length > 1) {
          final other = provider.accounts.firstWhere(
            (a) => a.id != _selectedAccountId,
            orElse: () => provider.accounts.first,
          );
          _selectedToAccountId = other.id;
        }
      }
      _resetCategorySelection(provider);
      _initialized = true;
    }
  }

  void _resetCategorySelection(MoneyProvider provider) {
    final matching = _selectedType == TransactionType.income
        ? provider.incomeCategories
        : provider.expenseCategories;

    if (matching.isNotEmpty) {
      if (_selectedCategoryId == null ||
          !matching.any((c) => c.id == _selectedCategoryId)) {
        _selectedCategoryId = matching.first.id;
      }
      final cat = provider.getCategoryById(_selectedCategoryId);
      _selectedSubcategory =
          (cat != null && cat.subcategories.isNotEmpty)
              ? cat.subcategories.first
              : null;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedDate.hour,
          _selectedDate.minute,
        );
      });
    }
  }

  Future<void> _promptNewSubcategory(TransactionCategory category) async {
    final controller = TextEditingController();
    final created = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Nuova Sottocategoria in ${category.name}'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Nome Sottocategoria (es. Assicurazione, Bollo...)',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Annulla'),
            ),
            FilledButton.icon(
              onPressed: () {
                final text = controller.text.trim();
                if (text.isEmpty) return;
                Navigator.of(dialogContext).pop(text);
              },
              icon: const Icon(Icons.add),
              label: const Text('Aggiungi'),
            ),
          ],
        );
      },
    );

    if (created != null && mounted) {
      final provider = MoneyScope.read(context);
      if (!category.subcategories.contains(created)) {
        await provider.saveCategory(
          category.copyWith(
            subcategories: [...category.subcategories, created],
          ),
        );
      }
      setState(() {
        _selectedSubcategory = created;
      });
    }
  }

  /// Pannello dal basso per scegliere Categoria e Sottocategoria (come in Money Manager)
  Future<void> _showCategoryPickerSheet() async {
    final currentKind = _selectedType == TransactionType.income
        ? CategoryKind.income
        : CategoryKind.expense;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final provider = MoneyScope.of(ctx);
            final categories = currentKind == CategoryKind.income
                ? provider.incomeCategories
                : provider.expenseCategories;
            final activeCat = provider.getCategoryById(_selectedCategoryId);

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          currentKind == CategoryKind.income
                              ? 'Seleziona Categoria Entrata'
                              : 'Seleziona Categoria Spesa',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            TextButton.icon(
                              onPressed: () async {
                                final created = await showCategoryEditorDialog(
                                  context,
                                  initialKind: currentKind,
                                );
                                if (created != null) {
                                  setState(() {
                                    _selectedCategoryId = created.id;
                                    _selectedSubcategory =
                                        created.subcategories.isNotEmpty
                                            ? created.subcategories.first
                                            : null;
                                  });
                                  setSheetState(() {});
                                }
                              },
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Nuova'),
                            ),
                            IconButton(
                              tooltip: 'Gestisci categorie',
                              icon: const Icon(Icons.settings_outlined, size: 20),
                              onPressed: () {
                                Navigator.of(sheetContext).pop();
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => CategoriesScreen(
                                      initialKind: currentKind,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: categories.map((cat) {
                        final isSelected = cat.id == _selectedCategoryId;
                        return ChoiceChip(
                          avatar: Icon(
                            cat.icon,
                            size: 18,
                            color: isSelected ? Colors.white : cat.color,
                          ),
                          label: Text(cat.name),
                          selected: isSelected,
                          selectedColor: cat.color,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : null,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          showCheckmark: false,
                          onSelected: (_) {
                            setState(() {
                              _selectedCategoryId = cat.id;
                              _selectedSubcategory =
                                  cat.subcategories.isNotEmpty
                                      ? cat.subcategories.first
                                      : null;
                            });
                            setSheetState(() {});
                          },
                        );
                      }).toList(),
                    ),
                    if (activeCat != null) ...[
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Sottocategoria (${activeCat.name})',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () async {
                              await _promptNewSubcategory(activeCat);
                              setSheetState(() {});
                            },
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('+ Sottocategoria'),
                          ),
                        ],
                      ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: activeCat.subcategories.map((sub) {
                          final isSubSelected = sub == _selectedSubcategory;
                          return ChoiceChip(
                            label: Text(sub),
                            selected: isSubSelected,
                            onSelected: (_) {
                              setState(() {
                                _selectedSubcategory = sub;
                              });
                              Navigator.of(sheetContext).pop();
                            },
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () => Navigator.of(sheetContext).pop(),
                        child: const Text('Conferma'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Pannello dal basso per scegliere il Conto (o crearne uno nuovo)
  Future<void> _showAccountPickerSheet({required bool isDestination}) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        final provider = MoneyScope.of(sheetContext);
        final currentId =
            isDestination ? _selectedToAccountId : _selectedAccountId;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isDestination
                          ? 'Seleziona Conto Destinazione'
                          : 'Seleziona Conto',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        final created = await showAccountEditorDialog(context);
                        if (created != null) {
                          setState(() {
                            if (isDestination) {
                              _selectedToAccountId = created.id;
                            } else {
                              _selectedAccountId = created.id;
                            }
                          });
                          if (sheetContext.mounted) {
                            Navigator.of(sheetContext).pop();
                          }
                        }
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Nuovo Conto'),
                    ),
                  ],
                ),
                const Divider(),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: provider.accounts.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, idx) {
                      final acc = provider.accounts[idx];
                      final grp = provider.getAccountGroupById(acc.groupId);
                      final isSelected = acc.id == currentId;

                      return ListTile(
                        leading: Icon(grp?.icon ?? Icons.account_balance_wallet),
                        title: Text(
                          acc.name,
                          style: TextStyle(
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        subtitle: grp != null ? Text(grp.name) : null,
                        trailing: isSelected
                            ? Icon(
                                Icons.check,
                                color: provider.secondaryColor,
                              )
                            : Text(
                                AppFormatters.formatCurrency(
                                  provider.getAccountBalance(acc.id),
                                ),
                                style: const TextStyle(fontSize: 13),
                              ),
                        onTap: () {
                          setState(() {
                            if (isDestination) {
                              _selectedToAccountId = acc.id;
                            } else {
                              _selectedAccountId = acc.id;
                            }
                          });
                          Navigator.of(sheetContext).pop();
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _promptTagDialog() async {
    final controller = TextEditingController(text: _selectedTag ?? '');
    final tag = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Aggiungi Etichetta'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Etichetta (es. Vacanza, Lavoro, Rimborsabile)',
              prefixText: '#',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            if (_selectedTag != null)
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(''),
                child: const Text('Rimuovi'),
              ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Annulla'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.of(dialogContext).pop(controller.text.trim()),
              child: const Text('Conferma'),
            ),
          ],
        );
      },
    );

    if (tag != null && mounted) {
      setState(() {
        _selectedTag = tag.isEmpty ? null : tag;
      });
    }
  }

  Future<void> _saveTransaction({required bool closeOnSave}) async {
    final rawAmount = _amountController.text.trim().replaceAll(',', '.');
    final amount = double.tryParse(rawAmount);

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inserisci un importo valido maggiore di zero.'),
        ),
      );
      return;
    }
    if (_selectedAccountId == null) return;

    // Combina nota, eventuale etichetta ed eventuale descrizione extra
    final parts = <String>[];
    if (_noteController.text.trim().isNotEmpty) {
      parts.add(_noteController.text.trim());
    }
    if (_descriptionController.text.trim().isNotEmpty) {
      parts.add(_descriptionController.text.trim());
    }
    if (_selectedTag != null && _selectedTag!.isNotEmpty) {
      parts.add('#$_selectedTag');
    }

    final tx = MoneyTransaction(
      id: AppFormatters.generateId('tx'),
      amount: amount,
      date: _selectedDate,
      type: _selectedType,
      accountId: _selectedAccountId!,
      toAccountId: _selectedType == TransactionType.transfer
          ? _selectedToAccountId
          : null,
      categoryId: _selectedType == TransactionType.transfer
          ? null
          : _selectedCategoryId,
      subcategory: _selectedType == TransactionType.transfer
          ? null
          : _selectedSubcategory,
      note: parts.join(' - '),
    );

    await MoneyScope.read(context).addTransaction(tx);
    if (!mounted) return;

    if (closeOnSave) {
      Navigator.of(context).pop();
    } else {
      // Modalità "Continua": pulisce importo e nota per inserire subito il movimento successivo
      setState(() {
        _amountController.clear();
        _noteController.clear();
        _descriptionController.clear();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Movimento salvato! Puoi inserirne un altro.'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = MoneyScope.of(context);
    final currentKind = _selectedType == TransactionType.income
        ? CategoryKind.income
        : CategoryKind.expense;
    final availableCategories = currentKind == CategoryKind.income
        ? provider.incomeCategories
        : provider.expenseCategories;

    if (availableCategories.isNotEmpty &&
        !availableCategories.any((c) => c.id == _selectedCategoryId)) {
      _selectedCategoryId = availableCategories.first.id;
    }

    final selectedCategory = provider.getCategoryById(_selectedCategoryId);
    final selectedAccount = _selectedAccountId != null
        ? provider.getAccountById(_selectedAccountId!)
        : null;
    final selectedToAccount = _selectedToAccountId != null
        ? provider.getAccountById(_selectedToAccountId!)
        : null;

    // Colore attivo e titolo della schermata in base al tab (In | Spesa | Trasferimento)
    final Color activeTabColor;
    final String screenTitle;
    switch (_selectedType) {
      case TransactionType.income:
        activeTabColor = provider.secondaryColor;
        screenTitle = 'In';
        break;
      case TransactionType.expense:
        activeTabColor = const Color(0xFFFF6B6B);
        screenTitle = 'Spesa';
        break;
      case TransactionType.transfer:
        activeTabColor = Colors.white;
        screenTitle = 'Trasferimento';
        break;
    }

    // Filtra i suggerimenti di note già scritte in precedenza
    final allSavedNotes = provider.suggestedNotes;
    final matchingNotes = allSavedNotes.where((n) {
      if (_currentNoteQuery.isEmpty) return true;
      final lowerN = n.toLowerCase();
      final lowerQ = _currentNoteQuery.toLowerCase();
      return lowerN.contains(lowerQ) && lowerN != lowerQ;
    }).take(6).toList();

    final categoryDisplay = selectedCategory != null
        ? (_selectedSubcategory != null && _selectedSubcategory!.isNotEmpty
            ? '${selectedCategory.name} / $_selectedSubcategory'
            : selectedCategory.name)
        : 'Seleziona categoria';

    final dayString =
        '${AppFormatters.formatShortWeekday(_selectedDate).toLowerCase()} ${AppFormatters.formatDate(_selectedDate)}';

    final subtleLineColor = Colors.grey.withValues(alpha: 0.25);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        leadingWidth: 135,
        leading: TextButton.icon(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(
            Icons.chevron_left,
            size: 26,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          label: Text(
            'Transazioni',
            style: TextStyle(
              fontSize: 15,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        title: Text(
          screenTitle,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Preferiti / Modelli',
            icon: Icon(
              Icons.star_border,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            onPressed: () {
              if (allSavedNotes.isNotEmpty) {
                setState(() {
                  _noteController.text = allSavedNotes.first;
                });
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // 1. I 3 Pulsanti rettangolari separati: [ In ]  [ Spesa ]  [ Trasferimento ]
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                _TypeTabButton(
                  label: 'In',
                  isSelected: _selectedType == TransactionType.income,
                  activeColor: provider.secondaryColor,
                  onTap: () {
                    setState(() {
                      _selectedType = TransactionType.income;
                      _resetCategorySelection(provider);
                    });
                  },
                ),
                const SizedBox(width: 10),
                _TypeTabButton(
                  label: 'Spesa',
                  isSelected: _selectedType == TransactionType.expense,
                  activeColor: const Color(0xFFFF6B6B),
                  onTap: () {
                    setState(() {
                      _selectedType = TransactionType.expense;
                      _resetCategorySelection(provider);
                    });
                  },
                ),
                const SizedBox(width: 10),
                _TypeTabButton(
                  label: 'Trasferimento',
                  isSelected: _selectedType == TransactionType.transfer,
                  activeColor: Theme.of(context).colorScheme.onSurface,
                  onTap: () {
                    setState(() {
                      _selectedType = TransactionType.transfer;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // 2. Blocco righe form in stile Money Manager (Etichetta a sinistra + Campo sottolineato a destra)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                // RIGA 1: Giorno
                _MoneyManagerFormRow(
                  label: 'Giorno',
                  lineColor: subtleLineColor,
                  child: Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: _pickDate,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              dayString,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () {
                          setState(() {
                            _isRepeatEnabled = !_isRepeatEnabled;
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 4,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.sync,
                                size: 18,
                                color: _isRepeatEnabled
                                    ? activeTabColor
                                    : Colors.grey,
                              ),
                              Text(
                                'Ripeti',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: _isRepeatEnabled
                                      ? activeTabColor
                                      : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // RIGA 2: Importo
                _MoneyManagerFormRow(
                  label: 'Importo',
                  lineColor: subtleLineColor,
                  child: TextField(
                    controller: _amountController,
                    autofocus: true,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 12),
                      suffixText: '€',
                    ),
                  ),
                ),

                // RIGA 3: Categoria (oppure "Da" se è un Trasferimento)
                if (_selectedType == TransactionType.transfer)
                  _MoneyManagerFormRow(
                    label: 'Da',
                    lineColor: subtleLineColor,
                    child: InkWell(
                      onTap: () =>
                          _showAccountPickerSheet(isDestination: false),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              selectedAccount?.name ?? 'Seleziona conto',
                              style: const TextStyle(fontSize: 15),
                            ),
                            const Icon(
                              Icons.keyboard_arrow_down,
                              size: 18,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  _MoneyManagerFormRow(
                    label: 'Categoria',
                    lineColor: subtleLineColor,
                    child: InkWell(
                      onTap: _showCategoryPickerSheet,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        child: Row(
                          children: [
                            if (selectedCategory != null) ...[
                              Icon(
                                selectedCategory.icon,
                                size: 18,
                                color: selectedCategory.color,
                              ),
                              const SizedBox(width: 8),
                            ],
                            Expanded(
                              child: Text(
                                categoryDisplay,
                                style: const TextStyle(fontSize: 15),
                              ),
                            ),
                            const Icon(
                              Icons.keyboard_arrow_down,
                              size: 18,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // RIGA 4: Conto (oppure "A" se è un Trasferimento)
                _MoneyManagerFormRow(
                  label:
                      _selectedType == TransactionType.transfer ? 'A' : 'Conto',
                  lineColor: subtleLineColor,
                  child: InkWell(
                    onTap: () => _showAccountPickerSheet(
                      isDestination: _selectedType == TransactionType.transfer,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            (_selectedType == TransactionType.transfer
                                    ? selectedToAccount?.name
                                    : selectedAccount?.name) ??
                                'Seleziona conto',
                            style: const TextStyle(fontSize: 15),
                          ),
                          const Icon(
                            Icons.keyboard_arrow_down,
                            size: 18,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                // RIGA 5: Nota (con icona [!] a destra e suggerimenti automatici)
                _MoneyManagerFormRow(
                  label: 'Nota',
                  lineColor: subtleLineColor,
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _noteController,
                          style: const TextStyle(fontSize: 15),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      Container(
                        width: 24,
                        height: 24,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.grey.withValues(alpha: 0.5),
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          '!',
                          style: TextStyle(
                            color: Colors.grey,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Suggerimenti automatici delle Note già scritte
                if (matchingNotes.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: matchingNotes.map((suggestion) {
                        return ActionChip(
                          visualDensity: VisualDensity.compact,
                          label: Text(
                            suggestion,
                            style: const TextStyle(fontSize: 12),
                          ),
                          onPressed: () {
                            setState(() {
                              _noteController.text = suggestion;
                              _noteController.selection =
                                  TextSelection.fromPosition(
                                TextPosition(offset: suggestion.length),
                              );
                            });
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 12),
          Divider(
            height: 1,
            thickness: 1,
            color: subtleLineColor,
          ),
          const SizedBox(height: 12),

          // 3. Sezione inferiore: "+ Etichetta" e "Descrizione" con icona fotocamera (come nella 3a immagine)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InkWell(
                  onTap: _promptTagDialog,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color:
                          Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add, size: 15, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          _selectedTag != null && _selectedTag!.isNotEmpty
                              ? '#$_selectedTag'
                              : 'Etichetta',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: subtleLineColor, width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _descriptionController,
                          style: const TextStyle(fontSize: 15),
                          decoration: const InputDecoration(
                            hintText: 'Descrizione',
                            hintStyle: TextStyle(color: Colors.grey),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.camera_alt_outlined,
                        color: Colors.grey,
                        size: 22,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // 4. I 2 Pulsanti in basso affiancati: [ Salva ] (70%) e [ Continua ] (30%)
                Row(
                  children: [
                    Expanded(
                      flex: 7,
                      child: SizedBox(
                        height: 48,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor:
                                _selectedType == TransactionType.income
                                    ? provider.secondaryColor
                                    : const Color(0xFFFF6B6B),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () => _saveTransaction(closeOnSave: true),
                          child: const Text(
                            'Salva',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 3,
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            foregroundColor:
                                Theme.of(context).colorScheme.onSurface,
                            side: BorderSide(
                              color: Colors.grey.withValues(alpha: 0.45),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () => _saveTransaction(closeOnSave: false),
                          child: const Text(
                            'Continua',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeTabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color activeColor;
  final VoidCallback onTap;

  const _TypeTabButton({
    required this.label,
    required this.isSelected,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = Theme.of(context)
        .colorScheme
        .surfaceContainerHighest
        .withValues(alpha: 0.45);

    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 38,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? activeColor
                  : Colors.grey.withValues(alpha: 0.2),
              width: isSelected ? 1.5 : 1.0,
            ),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              color: isSelected ? activeColor : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }
}

class _MoneyManagerFormRow extends StatelessWidget {
  final String label;
  final Widget child;
  final Color lineColor;

  const _MoneyManagerFormRow({
    required this.label,
    required this.child,
    required this.lineColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 86,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 14.5,
              ),
            ),
          ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: lineColor, width: 1),
                ),
              ),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
