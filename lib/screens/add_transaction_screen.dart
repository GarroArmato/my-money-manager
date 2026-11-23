import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../providers/money_provider.dart';
import '../utils/formatters.dart';
import '../utils/money_scope.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  TransactionType _selectedType = TransactionType.expense;
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
        _selectedAccountId = provider.accounts.first.id;
        if (provider.accounts.length > 1) {
          _selectedToAccountId = provider.accounts[1].id;
        }
      }
      _resetCategorySelection(provider);
      _initialized = true;
    }
  }

  void _resetCategorySelection(MoneyProvider provider) {
    final matching = provider.categories.where((c) {
      return _selectedType == TransactionType.income
          ? c.kind == CategoryKind.income
          : c.kind == CategoryKind.expense;
    }).toList();

    if (matching.isNotEmpty) {
      _selectedCategoryId = matching.first.id;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedAccountId == null) return;

    final rawAmount = _amountController.text.replaceAll(',', '.');
    final amount = double.parse(rawAmount);

    final tx = MoneyTransaction(
      id: AppFormatters.generateId(),
      amount: amount,
      date: DateTime.now(),
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
    final availableCategories = provider.categories.where((c) {
      return _selectedType == TransactionType.income
          ? c.kind == CategoryKind.income
          : c.kind == CategoryKind.expense;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuovo Movimento'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Selettore Tipo (Uscita / Entrata / Trasferimento) in stile Money Manager
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
            const SizedBox(height: 24),

            // Importo
            TextFormField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
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

            // Conto di origine
            DropdownButtonFormField<String>(
              value: _selectedAccountId,
              decoration: InputDecoration(
                labelText: _selectedType == TransactionType.transfer
                    ? 'Dal Conto'
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
              onChanged: (val) => setState(() => _selectedAccountId = val),
            ),
            const SizedBox(height: 16),

            // Se è un trasferimento mostra "Al Conto", altrimenti mostra la Categoria
            if (_selectedType == TransactionType.transfer)
              DropdownButtonFormField<String>(
                value: _selectedToAccountId,
                decoration: const InputDecoration(
                  labelText: 'Al Conto',
                  prefixIcon: Icon(Icons.account_balance),
                  border: OutlineInputBorder(),
                ),
                items: provider.accounts
                    .map((a) => DropdownMenuItem(
                          value: a.id,
                          child: Text(a.name),
                        ))
                    .toList(),
                onChanged: (val) => setState(() => _selectedToAccountId = val),
              )
            else
              DropdownButtonFormField<String>(
                value: _selectedCategoryId,
                decoration: const InputDecoration(
                  labelText: 'Categoria',
                  prefixIcon: Icon(Icons.category),
                  border: OutlineInputBorder(),
                ),
                items: availableCategories
                    .map((c) => DropdownMenuItem(
                          value: c.id,
                          child: Row(
                            children: [
                              Icon(c.icon, color: c.color, size: 20),
                              const SizedBox(width: 8),
                              Text(c.name),
                            ],
                          ),
                        ))
                    .toList(),
                onChanged: (val) => setState(() => _selectedCategoryId = val),
              ),
            const SizedBox(height: 16),

            // Nota / Descrizione
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: 'Nota / Descrizione (es. Spesa settimanale)',
                prefixIcon: Icon(Icons.notes),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 28),

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
