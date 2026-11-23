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
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  TransactionType _selectedType = TransactionType.expense;
  DateTime _selectedDate = DateTime.now();
  String? _selectedAccountId;
  String? _selectedToAccountId;
  String? _selectedCategoryId;
  bool _initialized = false;

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
          final other = provider.accounts
              .firstWhere((a) => a.id != _selectedAccountId,
                  orElse: () => provider.accounts.first);
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
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAccountId == null) return;

    final rawAmount = _amountController.text.replaceAll(',', '.');
    final amount = double.parse(rawAmount);

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
      note: _noteController.text.trim(),
    );

    await MoneyScope.read(context).addTransaction(tx);
    if (mounted) Navigator.of(context).pop();
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuovo Movimento'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 1. Selettore Tipo (Uscita / Entrata / Trasferimento) in stile Money Manager
            SegmentedButton<TransactionType>(
              segments: const [
                ButtonSegment(
                  value: TransactionType.expense,
                  label: Text('Uscita'),
                  icon: Icon(Icons.arrow_upward),
                ),
                ButtonSegment(
                  value: TransactionType.income,
                  label: Text('Entrata'),
                  icon: Icon(Icons.arrow_downward),
                ),
                ButtonSegment(
                  value: TransactionType.transfer,
                  label: Text('Trasferimento'),
                  icon: Icon(Icons.swap_horiz),
                ),
              ],
              selected: {_selectedType},
              onSelectionChanged: (newSelection) {
                setState(() {
                  _selectedType = newSelection.first;
                  _resetCategorySelection(provider);
                });
              },
            ),
            const SizedBox(height: 16),

            // 2. Riga Data (con frecce giorno prima/dopo e calendario in stile Money Manager)
            InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Data',
                prefixIcon: Icon(Icons.calendar_today_outlined),
                border: OutlineInputBorder(),
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: _pickDate,
                    child: Text(
                      '${AppFormatters.formatShortWeekday(_selectedDate)} ${AppFormatters.formatDate(_selectedDate)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Giorno precedente',
                        icon: const Icon(Icons.chevron_left),
                        onPressed: () {
                          setState(() {
                            _selectedDate = _selectedDate
                                .subtract(const Duration(days: 1));
                          });
                        },
                      ),
                      IconButton(
                        tooltip: 'Giorno successivo',
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () {
                          setState(() {
                            _selectedDate =
                                _selectedDate.add(const Duration(days: 1));
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 3. Importo
            TextFormField(
              controller: _amountController,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                labelText: 'Importo (€)',
                prefixIcon: Icon(Icons.euro),
                border: OutlineInputBorder(),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return 'Inserisci un importo';
                }
                final parsed = double.tryParse(val.replaceAll(',', '.'));
                if (parsed == null || parsed <= 0) {
                  return 'Inserisci un valore valido maggiore di zero';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // 4. Scelta Conto + pulsante rapido "+ Nuovo Conto"
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedAccountId,
                    decoration: InputDecoration(
                      labelText: _selectedType == TransactionType.transfer
                          ? 'Dal Conto (Origine)'
                          : 'Conto',
                      prefixIcon: const Icon(Icons.account_balance_wallet),
                      border: const OutlineInputBorder(),
                    ),
                    items: provider.accounts
                        .map((a) => DropdownMenuItem(
                              value: a.id,
                              child: Text(a.name),
                            ))
                        .toList(),
                    onChanged: (val) =>
                        setState(() => _selectedAccountId = val),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  tooltip: 'Crea Nuovo Conto',
                  onPressed: () async {
                    final created = await showAccountEditorDialog(context);
                    if (created != null) {
                      setState(() {
                        _selectedAccountId = created.id;
                      });
                    }
                  },
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 5. Se è un Trasferimento mostra "Al Conto", altrimenti mostra la Griglia Categorie in stile Money Manager
            if (_selectedType == TransactionType.transfer)
              DropdownButtonFormField<String>(
                value: _selectedToAccountId,
                decoration: const InputDecoration(
                  labelText: 'Al Conto (Destinazione)',
                  prefixIcon: Icon(Icons.account_balance),
                  border: OutlineInputBorder(),
                ),
                items: provider.accounts
                    .map((a) => DropdownMenuItem(
                          value: a.id,
                          child: Text(a.name),
                        ))
                    .toList(),
                onChanged: (val) =>
                    setState(() => _selectedToAccountId = val),
              )
            else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedType == TransactionType.income
                        ? 'CATEGORIA ENTRATA'
                        : 'CATEGORIA USCITA',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => CategoriesScreen(
                            initialKind: currentKind,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit_note, size: 18),
                    label: const Text('Modifica / Gestisci'),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ...availableCategories.map((cat) {
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
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      showCheckmark: false,
                      onSelected: (_) {
                        setState(() {
                          _selectedCategoryId = cat.id;
                        });
                      },
                    );
                  }),
                  ActionChip(
                    avatar: const Icon(Icons.add_circle_outline, size: 18),
                    label: const Text('+ Nuova Categoria'),
                    onPressed: () async {
                      final created = await showCategoryEditorDialog(
                        context,
                        initialKind: currentKind,
                      );
                      if (created != null) {
                        setState(() {
                          if (created.kind == CategoryKind.income) {
                            _selectedType = TransactionType.income;
                          } else {
                            _selectedType = TransactionType.expense;
                          }
                          _selectedCategoryId = created.id;
                        });
                      }
                    },
                  ),
                ],
              ),
            ],
            const SizedBox(height: 18),

            // 6. Nota / Descrizione
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Nota / Descrizione (es. Spesa settimanale)',
                prefixIcon: Icon(Icons.notes),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            FilledButton.icon(
              onPressed: _submit,
              icon: const Icon(Icons.check),
              label: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Text('Salva Movimento', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
