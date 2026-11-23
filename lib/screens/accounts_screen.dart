import 'package:flutter/material.dart';
import '../models/account.dart';
import '../services/csv_import_service.dart';
import '../utils/formatters.dart';
import '../utils/money_scope.dart';

/// Mostra il dialog modale per Creare o Modificare un Conto (Contanti, Banca, Carta, Risparmi)
Future<Account?> showAccountEditorDialog(
  BuildContext context, {
  Account? existingAccount,
}) async {
  final nameController = TextEditingController(
    text: existingAccount?.name ?? '',
  );
  final balanceController = TextEditingController(
    text: existingAccount != null
        ? existingAccount.initialBalance.toStringAsFixed(2)
        : '0.00',
  );
  final ibanController = TextEditingController(
    text: existingAccount?.iban ?? '',
  );
  AccountType selectedType = existingAccount?.type ?? AccountType.bankAccount;

  return showDialog<Account>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: Text(
              existingAccount == null ? 'Nuovo Conto' : 'Modifica Conto',
            ),
            content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Gruppo di Conto (Contanti, Conti Bancari, Carte, Risparmi)
                    DropdownButtonFormField<AccountType>(
                      value: selectedType,
                      decoration: const InputDecoration(
                        labelText: 'Gruppo Conto',
                        prefixIcon: Icon(Icons.folder_outlined),
                        border: OutlineInputBorder(),
                      ),
                      items: AccountType.values
                          .map((t) => DropdownMenuItem(
                                value: t,
                                child: Row(
                                  children: [
                                    Icon(t.icon, size: 20),
                                    const SizedBox(width: 8),
                                    Text(t.label),
                                  ],
                                ),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setDialogState(() {
                            selectedType = val;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 14),

                    // Nome Conto
                    TextField(
                      controller: nameController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText:
                            'Nome Conto (es. Intesa, PostePay, Contanti...)',
                        prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Saldo Iniziale
                    TextField(
                      controller: balanceController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Saldo Iniziale (€)',
                        prefixIcon: Icon(Icons.euro),
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // IBAN / Note (opzionale)
                    TextField(
                      controller: ibanController,
                      decoration: const InputDecoration(
                        labelText: 'IBAN o Note (opzionale)',
                        prefixIcon: Icon(Icons.notes),
                        border: OutlineInputBorder(),
                      ),
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

                  final initialBalance = double.tryParse(
                        balanceController.text.replaceAll(',', '.'),
                      ) ??
                      0.0;

                  final ibanText = ibanController.text.trim();

                  final acc = Account(
                    id: existingAccount?.id ?? AppFormatters.generateId('acc'),
                    name: name,
                    type: selectedType,
                    initialBalance: initialBalance,
                    iban: ibanText.isEmpty ? null : ibanText,
                  );

                  await MoneyScope.read(context).saveAccount(acc);
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop(acc);
                  }
                },
                icon: const Icon(Icons.check),
                label: const Text('Salva Conto'),
              ),
            ],
          );
        },
      );
    },
  );
}

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  Future<void> _showCsvImportDialog(
    BuildContext context,
    Account account,
  ) async {
    final csvController = TextEditingController(
      text: CsvImportService.sampleBankCsv,
    );

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Importa CSV in ${account.name}'),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Incolla le righe del file CSV della tua banca (formato Data;Descrizione;Importo). '
                  'I movimenti già importati verranno ignorati automaticamente:',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: csvController,
                  maxLines: 8,
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Contenuto CSV (Data;Descrizione;Importo)',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Annulla'),
            ),
            FilledButton.icon(
              onPressed: () async {
                final count = await MoneyScope.read(context).importBankCsv(
                  csvContent: csvController.text,
                  accountId: account.id,
                );
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        count > 0
                            ? 'Importati e categorizzati $count nuovi movimenti da CSV!'
                            : 'Nessun nuovo movimento da importare (già presenti).',
                      ),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.file_download_done),
              label: const Text('Importa e Categorizza'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = MoneyScope.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Conti & Patrimonio'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.tonalIcon(
              onPressed: () => showAccountEditorDialog(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Nuovo Conto'),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
        children: [
          // Barra superiore a 3 colonne in stile Money Manager: Attività | Passività | Totale
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _HeaderMetric(
                  label: 'Attività',
                  value: AppFormatters.formatCurrency(provider.totalAssets),
                  color: Colors.blue.shade700,
                ),
                _HeaderMetric(
                  label: 'Passività',
                  value:
                      AppFormatters.formatCurrency(provider.totalLiabilities),
                  color: Colors.red.shade700,
                ),
                _HeaderMetric(
                  label: 'Totale',
                  value: AppFormatters.formatCurrency(provider.totalNetWorth),
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Raggruppamento dei conti per Gruppo (Contanti, Conti Bancari, Carte, Risparmi)
          ...AccountType.values.map((groupType) {
            final groupAccounts = provider.accounts
                .where((a) => a.type == groupType)
                .toList();
            if (groupAccounts.isEmpty) return const SizedBox.shrink();

            final groupSubtotal = groupAccounts.fold(
              0.0,
              (sum, a) => sum + provider.getAccountBalance(a.id),
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(groupType.icon, size: 18, color: Colors.grey),
                          const SizedBox(width: 6),
                          Text(
                            groupType.label.toUpperCase(),
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      Text(
                        AppFormatters.formatCurrency(groupSubtotal),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                ...groupAccounts.map((account) {
                  final balance = provider.getAccountBalance(account.id);
                  final supportsCsv =
                      account.type == AccountType.bankAccount ||
                          account.type == AccountType.creditCard;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              child: Icon(account.type.icon),
                            ),
                            title: Text(
                              account.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              account.iban != null && account.iban!.isNotEmpty
                                  ? account.iban!
                                  : account.type.label,
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  AppFormatters.formatCurrency(balance),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: balance < 0
                                        ? Colors.red.shade700
                                        : null,
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  onSelected: (action) {
                                    if (action == 'edit') {
                                      showAccountEditorDialog(
                                        context,
                                        existingAccount: account,
                                      );
                                    } else if (action == 'delete') {
                                      provider.deleteAccount(account.id);
                                    }
                                  },
                                  itemBuilder: (_) => [
                                    const PopupMenuItem(
                                      value: 'edit',
                                      child: Row(
                                        children: [
                                          Icon(Icons.edit_outlined, size: 18),
                                          SizedBox(width: 8),
                                          Text('Modifica Conto'),
                                        ],
                                      ),
                                    ),
                                    if (provider.accounts.length > 1)
                                      const PopupMenuItem(
                                        value: 'delete',
                                        child: Row(
                                          children: [
                                            Icon(Icons.delete_outline,
                                                size: 18, color: Colors.red),
                                            SizedBox(width: 8),
                                            Text('Elimina Conto',
                                                style: TextStyle(
                                                    color: Colors.red)),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          if (supportsCsv && provider.enableCsvImport) ...[
                            const Divider(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.table_chart_outlined,
                                      size: 15,
                                      color: Colors.teal,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'Importazione movimenti da CSV / Excel',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                                TextButton.icon(
                                  onPressed: () =>
                                      _showCsvImportDialog(context, account),
                                  icon: const Icon(Icons.upload_file, size: 16),
                                  label: const Text('Importa CSV'),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 12),
              ],
            );
          }),
        ],
      ),
    );
  }
}

class _HeaderMetric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _HeaderMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: color,
          ),
        ),
      ],
    );
  }
}
