import 'package:flutter/material.dart';
import '../models/account.dart';
import '../services/csv_import_service.dart';
import '../utils/formatters.dart';
import '../utils/money_scope.dart';
import 'account_detail_screen.dart';

/// Mostra il dialog per Creare o Modificare un Gruppo di Conti (es. Contanti, Conti Bancari, Crypto, Buoni Pasto...)
Future<AccountGroup?> showAccountGroupEditorDialog(
  BuildContext context, {
  AccountGroup? existingGroup,
}) async {
  final nameController = TextEditingController(
    text: existingGroup?.name ?? '',
  );
  String selectedIconKey = existingGroup?.iconKey ??
      AccountGroup.availableGroupIcons.keys.first;
  bool supportsCsv = existingGroup?.supportsCsvImport ?? true;

  return showDialog<AccountGroup>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: Text(
              existingGroup == null
                  ? 'Nuovo Gruppo di Conti'
                  : 'Modifica Gruppo di Conti',
            ),
            content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      autofocus: true,
                      decoration: InputDecoration(
                        labelText:
                            'Nome Gruppo (es. Crypto, Buoni Pasto, Prestiti...)',
                        prefixIcon: Icon(
                          AccountGroup.availableGroupIcons[selectedIconKey] ??
                              Icons.folder_outlined,
                        ),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Icona del Gruppo',
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
                          AccountGroup.availableGroupIcons.entries.map((e) {
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
                                  ? Theme.of(ctx).colorScheme.primaryContainer
                                  : Theme.of(ctx)
                                      .colorScheme
                                      .surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(10),
                              border: isSelected
                                  ? Border.all(
                                      color: Theme.of(ctx).colorScheme.primary,
                                      width: 2,
                                    )
                                  : null,
                            ),
                            child: Icon(
                              e.value,
                              color: isSelected
                                  ? Theme.of(ctx).colorScheme.primary
                                  : Theme.of(ctx).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Abilita importazione CSV per questo gruppo',
                        style: TextStyle(fontSize: 13),
                      ),
                      value: supportsCsv,
                      onChanged: (val) {
                        setDialogState(() {
                          supportsCsv = val;
                        });
                      },
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

                  final grp = AccountGroup(
                    id: existingGroup?.id ?? AppFormatters.generateId('grp'),
                    name: name,
                    iconKey: selectedIconKey,
                    supportsCsvImport: supportsCsv,
                  );

                  await MoneyScope.read(context).saveAccountGroup(grp);
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop(grp);
                  }
                },
                icon: const Icon(Icons.check),
                label: const Text('Salva Gruppo'),
              ),
            ],
          );
        },
      );
    },
  );
}

/// Mostra il dialog modale per Creare o Modificare un Conto
Future<Account?> showAccountEditorDialog(
  BuildContext context, {
  Account? existingAccount,
  String? initialGroupId,
}) async {
  final provider = MoneyScope.read(context);
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
  String selectedGroupId = existingAccount?.groupId ??
      initialGroupId ??
      (provider.accountGroups.isNotEmpty
          ? provider.accountGroups.first.id
          : 'grp_cash');

  return showDialog<Account>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (ctx, setDialogState) {
          final currentGroups = MoneyScope.of(ctx).accountGroups;
          if (currentGroups.isNotEmpty &&
              !currentGroups.any((g) => g.id == selectedGroupId)) {
            selectedGroupId = currentGroups.first.id;
          }

          return AlertDialog(
            title: Text(
              existingAccount == null ? 'Nuovo Conto' : 'Modifica Conto',
            ),
            content: SizedBox(
              width: 430,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Scelta Gruppo di Conto + pulsante "+ Nuovo Gruppo"
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: selectedGroupId,
                            decoration: const InputDecoration(
                              labelText: 'Gruppo di Conti',
                              prefixIcon: Icon(Icons.folder_outlined),
                              border: OutlineInputBorder(),
                            ),
                            items: currentGroups
                                .map((g) => DropdownMenuItem(
                                      value: g.id,
                                      child: Row(
                                        children: [
                                          Icon(g.icon, size: 20),
                                          const SizedBox(width: 8),
                                          Text(g.name),
                                        ],
                                      ),
                                    ))
                                .toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setDialogState(() {
                                  selectedGroupId = val;
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          tooltip: 'Crea Nuovo Gruppo di Conti',
                          onPressed: () async {
                            final newGrp =
                                await showAccountGroupEditorDialog(context);
                            if (newGrp != null) {
                              setDialogState(() {
                                selectedGroupId = newGrp.id;
                              });
                            }
                          },
                          icon: const Icon(Icons.create_new_folder_outlined),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Nome Conto
                    TextField(
                      controller: nameController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText:
                            'Nome Conto (es. Intesa, PostePay, Ticket...)',
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
                    groupId: selectedGroupId,
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
        title: const Text('Conti & Gruppi'),
        actions: [
          TextButton.icon(
            onPressed: () => showAccountGroupEditorDialog(context),
            icon: const Icon(Icons.create_new_folder_outlined, size: 18),
            label: const Text('+ Gruppo'),
          ),
          const SizedBox(width: 4),
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.tonalIcon(
              onPressed: () => showAccountEditorDialog(context),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('+ Conto'),
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
          const SizedBox(height: 16),

          // Raggruppamento dei conti per Gruppo di Conti personalizzabile
          ...provider.accountGroups.map((group) {
            final groupAccounts = provider.accounts
                .where((a) => a.groupId == group.id)
                .toList();

            final groupSubtotal = groupAccounts.fold(
              0.0,
              (sum, a) => sum + provider.getAccountBalance(a.id),
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Intestazione del Gruppo di Conti con subtotale e azioni (+ Conto nel gruppo / Modifica gruppo)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Row(
                    children: [
                      Icon(group.icon, size: 18, color: Colors.grey),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          group.name.toUpperCase(),
                          style: Theme.of(context)
                              .textTheme
                              .labelLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(
                        AppFormatters.formatCurrency(groupSubtotal),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        tooltip: 'Aggiungi conto in ${group.name}',
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.add_circle_outline, size: 18),
                        onPressed: () {
                          showAccountEditorDialog(
                            context,
                            initialGroupId: group.id,
                          );
                        },
                      ),
                      PopupMenuButton<String>(
                        tooltip: 'Opzioni gruppo',
                        icon: const Icon(Icons.more_horiz,
                            size: 18, color: Colors.grey),
                        onSelected: (action) {
                          if (action == 'edit_group') {
                            showAccountGroupEditorDialog(
                              context,
                              existingGroup: group,
                            );
                          } else if (action == 'delete_group') {
                            provider.deleteAccountGroup(group.id);
                          }
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                            value: 'edit_group',
                            child: Row(
                              children: [
                                Icon(Icons.edit_outlined, size: 18),
                                SizedBox(width: 8),
                                Text('Modifica Gruppo'),
                              ],
                            ),
                          ),
                          if (provider.accountGroups.length > 1)
                            const PopupMenuItem(
                              value: 'delete_group',
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline,
                                      size: 18, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Elimina Gruppo',
                                      style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                if (groupAccounts.isEmpty)
                  Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      dense: true,
                      title: Text(
                        'Nessun conto in "${group.name}". Tocca per aggiungerne uno.',
                        style:
                            const TextStyle(color: Colors.grey, fontSize: 13),
                      ),
                      trailing: const Icon(Icons.add, size: 18),
                      onTap: () => showAccountEditorDialog(
                        context,
                        initialGroupId: group.id,
                      ),
                    ),
                  ),

                ...groupAccounts.map((account) {
                  final balance = provider.getAccountBalance(account.id);

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      // Cliccando sul conto si apre la pagina con i movimenti di quel conto (come in Money Manager!)
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => AccountDetailScreen(
                              accountId: account.id,
                            ),
                          ),
                        );
                      },
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
                                child: Icon(group.icon),
                              ),
                              title: Text(
                                account.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                account.iban != null && account.iban!.isNotEmpty
                                    ? '${account.iban!} • Tocca per vedere i movimenti'
                                    : 'Tocca per vedere i movimenti del conto',
                                style: const TextStyle(fontSize: 12),
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
                                      if (action == 'view') {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (_) => AccountDetailScreen(
                                              accountId: account.id,
                                            ),
                                          ),
                                        );
                                      } else if (action == 'edit') {
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
                                        value: 'view',
                                        child: Row(
                                          children: [
                                            Icon(Icons.receipt_long, size: 18),
                                            SizedBox(width: 8),
                                            Text('Vedi Movimenti Conto'),
                                          ],
                                        ),
                                      ),
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
                            if (group.supportsCsvImport &&
                                provider.enableCsvImport) ...[
                              const Divider(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                                    icon:
                                        const Icon(Icons.upload_file, size: 16),
                                    label: const Text('Importa CSV'),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 10),
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
