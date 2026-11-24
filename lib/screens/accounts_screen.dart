import 'package:flutter/material.dart';
import '../models/account.dart';
import '../services/csv_import_service.dart';
import '../utils/formatters.dart';
import '../utils/money_scope.dart';
import '../widgets/app_top_bar.dart';
import 'account_detail_screen.dart';

/// Mostra il dialog per Creare o Modificare un Gruppo di Conti (es. Contanti, Conti, Carte, Risparmi...)
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
                            'Nome Gruppo (es. Conti, Risparmi, Crypto...)',
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

/// Mostra il dialog modale per Creare o Modificare un Conto (con opzione "Metti nel totale / Saldo disponibile")
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
  bool includeInTotal = existingAccount?.includeInTotal ?? true;

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
                      autofocus: existingAccount == null,
                      decoration: const InputDecoration(
                        labelText:
                            'Nome Conto (es. I.S.Paolo, Parte Fissa, Salvadanaio...)',
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

                    // Switch: Metti nel totale (Saldo disponibile vs Saldo non disponibile)
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(ctx)
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: SwitchListTile(
                        title: const Text(
                          'Includi nel Totale (Saldo disponibile)',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                          ),
                        ),
                        subtitle: Text(
                          includeInTotal
                              ? 'Disponibile: viene sommato in Saldo attivo / Totale'
                              : 'Non disponibile: mostrato in grigio e sommato a parte',
                          style: const TextStyle(fontSize: 12),
                        ),
                        value: includeInTotal,
                        onChanged: (val) {
                          setDialogState(() {
                            includeInTotal = val;
                          });
                        },
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
                    includeInTotal: includeInTotal,
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

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  // Quando clicchi sulla pennina (✎) in alto a destra entra in Modalità Modifica (come nella 2a foto!)
  bool _isEditMode = false;

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

  void _showAddAccountOrGroupSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.account_balance_wallet_outlined),
                title: const Text(
                  'Aggiungi Nuovo Conto',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  'Crea un conto disponibile o non disponibile (accantonato)',
                ),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  showAccountEditorDialog(context);
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.create_new_folder_outlined),
                title: const Text(
                  'Aggiungi Nuovo Gruppo di Conti',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  'Crea una nuova sezione (es. Conti, Risparmi, Investimenti...)',
                ),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  showAccountGroupEditorDialog(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = MoneyScope.of(context);

    return Scaffold(
      appBar: AppTopBar(
        title: 'Conto',
        icon: Icons.account_balance_outlined,
        leading: _isEditMode
            ? IconButton(
                tooltip: 'Fine modifica',
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _isEditMode = false;
                  });
                },
              )
            : null,
        actions: [
          // Pennina (✎) come nello screenshot di Money Manager
          if (!_isEditMode)
            IconButton(
              tooltip: 'Modifica conti e visibilità nel totale',
              icon: const Icon(Icons.edit_outlined, color: Colors.white),
              onPressed: () {
                setState(() {
                  _isEditMode = true;
                });
              },
            )
          else
            TextButton(
              onPressed: () {
                setState(() {
                  _isEditMode = false;
                });
              },
              child: const Text(
                'Fine',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

          // Tasto (+) come nello screenshot di Money Manager
          IconButton(
            tooltip: 'Aggiungi Conto o Gruppo',
            icon: const Icon(Icons.add, color: Colors.white, size: 26),
            onPressed: () => _showAddAccountOrGroupSheet(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra superiore a 3 colonne identica alle tue foto: Saldo attivo | Saldo passivo | Totale
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withValues(alpha: 0.35),
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _HeaderMetric(
                  label: 'Saldo attivo',
                  value: AppFormatters.formatCurrency(provider.totalAssets),
                  color: provider.secondaryColor,
                ),
                _HeaderMetric(
                  label: 'Saldo passivo',
                  value:
                      AppFormatters.formatCurrency(provider.totalLiabilities),
                  color: provider.expenseColor,
                ),
                _HeaderMetric(
                  label: 'Totale',
                  value: AppFormatters.formatCurrency(provider.totalNetWorth),
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ],
            ),
          ),

          if (_isEditMode)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: provider.primaryColor.withValues(alpha: 0.15),
              child: const Row(
                children: [
                  Icon(Icons.visibility_outlined, size: 16, color: Colors.grey),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Tocca l\'occhio 👁 per mettere/togliere un conto dal Totale (Saldo disponibile vs Non disponibile). Tocca il nome per modificarlo.',
                      style: TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

          // Lista Gruppi e Conti in stile Money Manager (come nelle 2 foto)
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 88),
              children: provider.accountGroups.map((group) {
                final groupAccounts = provider.accounts
                    .where((a) => a.groupId == group.id)
                    .toList();

                // Calcola separatamente il Saldo NON disponibile (in grigio) e il Saldo Disponibile (colorato) del gruppo!
                final unavailableAccounts =
                    groupAccounts.where((a) => !a.includeInTotal).toList();
                final availableAccounts =
                    groupAccounts.where((a) => a.includeInTotal).toList();

                final double groupUnavailableSum = unavailableAccounts.fold(
                  0.0,
                  (sum, a) => sum + provider.getAccountBalance(a.id),
                );
                final double groupAvailableSum = availableAccounts.fold(
                  0.0,
                  (sum, a) => sum + provider.getAccountBalance(a.id),
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Intestazione del Gruppo (es. "Conti      € 3.793,05    € 21,32")
                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: Colors.grey.withValues(alpha: 0.2),
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: _isEditMode
                                  ? () => showAccountGroupEditorDialog(
                                        context,
                                        existingGroup: group,
                                      )
                                  : null,
                              child: Row(
                                children: [
                                  Text(
                                    group.name,
                                    style: const TextStyle(
                                      color: Colors.grey,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  if (_isEditMode) ...[
                                    const SizedBox(width: 6),
                                    const Icon(
                                      Icons.edit_outlined,
                                      size: 14,
                                      color: Colors.grey,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),

                          // Subtotale NON disponibile del gruppo (in grigio, come "€ 3793,05" nella tua foto)
                          if (unavailableAccounts.isNotEmpty)
                            Padding(
                              padding: EdgeInsets.only(
                                right: availableAccounts.isNotEmpty ? 20 : 0,
                              ),
                              child: Text(
                                AppFormatters.formatCurrency(
                                  groupUnavailableSum,
                                ),
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),

                          // Subtotale Disponibile del gruppo (colorato, come "€ 21,32" nella tua foto)
                          if (availableAccounts.isNotEmpty ||
                              unavailableAccounts.isEmpty)
                            Text(
                              AppFormatters.formatCurrency(groupAvailableSum),
                              style: TextStyle(
                                color: groupAvailableSum < 0
                                    ? provider.expenseColor
                                    : provider.secondaryColor,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    ),

                    // Righe dei conti appartenenti al gruppo
                    ...groupAccounts.map((account) {
                      final balance = provider.getAccountBalance(account.id);
                      final isIncluded = account.includeInTotal;

                      final Color balanceColor = !isIncluded
                          ? Colors.grey
                          : (balance > 0
                              ? provider.secondaryColor
                              : (balance < 0
                                  ? provider.expenseColor
                                  : Theme.of(context).colorScheme.onSurface));

                      // --- MODALITÀ MODIFICA (2a Foto: pallino rosso '-', nome, occhio '👁', '≡') ---
                      if (_isEditMode) {
                        return Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest
                                .withValues(alpha: 0.25),
                            border: Border(
                              bottom: BorderSide(
                                color: Colors.grey.withValues(alpha: 0.18),
                              ),
                            ),
                          ),
                          child: ListTile(
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            leading: InkWell(
                              onTap: provider.accounts.length <= 1
                                  ? null
                                  : () => provider.deleteAccount(account.id),
                              borderRadius: BorderRadius.circular(14),
                              child: Container(
                                width: 26,
                                height: 26,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFF5252),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.remove,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                            title: InkWell(
                              onTap: () => showAccountEditorDialog(
                                context,
                                existingAccount: account,
                              ),
                              child: Text(
                                account.name,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: isIncluded ? null : Colors.grey,
                                ),
                              ),
                            ),
                            subtitle: Text(
                              isIncluded
                                  ? 'Incluso nel totale (Saldo disponibile)'
                                  : 'Escluso dal totale (Saldo non disponibile)',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isIncluded
                                    ? provider.secondaryColor
                                    : Colors.grey,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Icona Occhio (👁) per attivare/disattivare "Metti nel totale"
                                IconButton(
                                  tooltip: isIncluded
                                      ? 'Escludi dal totale (Rendi saldo non disponibile)'
                                      : 'Includi nel totale (Rendi saldo disponibile)',
                                  icon: Icon(
                                    isIncluded
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined,
                                    color: isIncluded
                                        ? provider.secondaryColor
                                        : Colors.grey,
                                  ),
                                  onPressed: () => provider
                                      .toggleAccountIncludeInTotal(account.id),
                                ),
                                IconButton(
                                  tooltip: 'Modifica conto',
                                  icon: const Icon(
                                    Icons.drag_handle,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () => showAccountEditorDialog(
                                    context,
                                    existingAccount: account,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }

                      // --- MODALITÀ NORMALE (1a Foto: Nome a sinistra, Importo colorato o grigio a destra) ---
                      return Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withValues(alpha: 0.25),
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey.withValues(alpha: 0.18),
                            ),
                          ),
                        ),
                        child: ListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => AccountDetailScreen(
                                  accountId: account.id,
                                ),
                              ),
                            );
                          },
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  account.name,
                                  style: const TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              if (group.supportsCsvImport &&
                                  provider.enableCsvImport)
                                IconButton(
                                  tooltip: 'Importa CSV in ${account.name}',
                                  visualDensity: VisualDensity.compact,
                                  icon: const Icon(
                                    Icons.upload_file,
                                    size: 17,
                                    color: Colors.grey,
                                  ),
                                  onPressed: () =>
                                      _showCsvImportDialog(context, account),
                                ),
                            ],
                          ),
                          trailing: Text(
                            AppFormatters.formatCurrency(balance),
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w600,
                              color: balanceColor,
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                );
              }).toList(),
            ),
          ),
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
          style: const TextStyle(
            fontSize: 12.5,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15.5,
            color: color,
          ),
        ),
      ],
    );
  }
}
