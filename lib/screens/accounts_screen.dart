import 'package:flutter/material.dart';
import '../models/account.dart';
import '../services/csv_import_service.dart';
import '../utils/formatters.dart';
import '../utils/money_scope.dart';

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
        title: const Text('I Miei Conti'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Card Patrimonio Totale
          Card(
            elevation: 0,
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Patrimonio Totale',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppFormatters.formatCurrency(provider.totalNetWorth),
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          Text(
            'CONTI ATTIVI',
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: 8),

          ...provider.accounts.map((account) {
            final balance = provider.getAccountBalance(account.id);
            final isBank = account.type == AccountType.bankAccount;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        child: Icon(
                          isBank
                              ? Icons.account_balance
                              : Icons.account_balance_wallet,
                        ),
                      ),
                      title: Text(
                        account.name,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        account.iban != null
                            ? 'IBAN: ${account.iban}'
                            : 'Gestione contanti',
                      ),
                      trailing: Text(
                        AppFormatters.formatCurrency(balance),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),

                    // Mostra il pulsante Importa CSV solo se il flag in Impostazioni è attivo
                    if (isBank && provider.enableCsvImport) ...[
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.table_chart_outlined,
                                size: 16,
                                color: Colors.teal,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Importazione rapida CSV / Excel',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                          FilledButton.tonalIcon(
                            onPressed: () =>
                                _showCsvImportDialog(context, account),
                            icon: const Icon(Icons.upload_file, size: 18),
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
        ],
      ),
    );
  }
}
