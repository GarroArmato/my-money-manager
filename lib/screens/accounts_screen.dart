import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/account.dart';
import '../providers/money_provider.dart';

class AccountsScreen extends StatelessWidget {
  const AccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MoneyProvider>();
    final currencyFormat = NumberFormat.currency(locale: 'it_IT', symbol: '€');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Conti & Open Banking'),
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
                    currencyFormat.format(provider.totalNetWorth),
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
            'I TUOI CONTI',
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
                            : 'Gestione manuale offline',
                      ),
                      trailing: Text(
                        currencyFormat.format(balance),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    if (isBank) ...[
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.verified_user_outlined,
                                  size: 16, color: Colors.green),
                              SizedBox(width: 6),
                              Text(
                                'Open Banking PSD2 (GoCardless)',
                                style: TextStyle(fontSize: 12),
                              ),
                            ],
                          ),
                          FilledButton.tonalIcon(
                            onPressed: provider.isSyncingBank
                                ? null
                                : () async {
                                    final count = await provider
                                        .syncBankAccount(account.id);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            count > 0
                                                ? 'Importati e categorizzati $count nuovi movimenti bancari!'
                                                : 'Tutti i movimenti bancari sono già sincronizzati.',
                                          ),
                                        ),
                                      );
                                    }
                                  },
                            icon: provider.isSyncingBank
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.sync, size: 18),
                            label: const Text('Sincronizza'),
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
