import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../utils/formatters.dart';
import '../utils/money_scope.dart';
import 'accounts_screen.dart';
import 'add_transaction_screen.dart';

class AccountDetailScreen extends StatelessWidget {
  final String accountId;

  const AccountDetailScreen({
    super.key,
    required this.accountId,
  });

  @override
  Widget build(BuildContext context) {
    final provider = MoneyScope.of(context);
    final account = provider.getAccountById(accountId);

    if (account == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Conto')),
        body: const Center(child: Text('Conto non trovato.')),
      );
    }

    final group = provider.getAccountGroupById(account.groupId);
    final currentBalance = provider.getAccountBalance(account.id);
    final monthlyDeposits = provider.getAccountMonthlyDeposits(account.id);
    final monthlyWithdrawals =
        provider.getAccountMonthlyWithdrawals(account.id);
    final monthlyNet = monthlyDeposits - monthlyWithdrawals;
    final transactions = provider.getAccountMonthlyTransactions(account.id);

    // Raggruppa i movimenti di questo conto per giorno del mese
    final Map<String, List<MoneyTransaction>> groupedByDay = {};
    for (final tx in transactions) {
      final key =
          '${tx.date.year}-${tx.date.month.toString().padLeft(2, '0')}-${tx.date.day.toString().padLeft(2, '0')}';
      groupedByDay.putIfAbsent(key, () => []).add(tx);
    }
    final sortedDayKeys = groupedByDay.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              account.name,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            if (group != null)
              Text(
                group.name,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Mese precedente',
            icon: const Icon(Icons.chevron_left),
            onPressed: () => provider.changeMonth(-1),
          ),
          Center(
            child: Text(
              AppFormatters.formatMonthYear(provider.selectedMonth),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          IconButton(
            tooltip: 'Mese successivo',
            icon: const Icon(Icons.chevron_right),
            onPressed: () => provider.changeMonth(1),
          ),
          IconButton(
            tooltip: 'Modifica Conto',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () {
              showAccountEditorDialog(
                context,
                existingAccount: account,
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => AddTransactionScreen(
                initialAccountId: account.id,
              ),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: Text('Movimento (${account.name})'),
      ),
      body: Column(
        children: [
          // Header Riepilogo Conto in stile Money Manager (Deposito | Prelievo | Totale Mese | Saldo)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'SALDO ATTUALE CONTO',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      AppFormatters.formatCurrency(currentBalance),
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: currentBalance < 0
                            ? Colors.red.shade700
                            : Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _AccountSummaryMetric(
                      label: 'Deposito',
                      amount: AppFormatters.formatCurrency(monthlyDeposits),
                      color: Colors.blue.shade700,
                    ),
                    _AccountSummaryMetric(
                      label: 'Prelievo',
                      amount: AppFormatters.formatCurrency(monthlyWithdrawals),
                      color: Colors.red.shade700,
                    ),
                    _AccountSummaryMetric(
                      label: 'Totale Mese',
                      amount: AppFormatters.formatCurrency(monthlyNet),
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Lista movimenti del conto raggruppati per giorno
          Expanded(
            child: sortedDayKeys.isEmpty
                ? Center(
                    child: Text(
                      'Nessun movimento per "${account.name}" in ${AppFormatters.formatMonthYear(provider.selectedMonth)}.\n'
                      'Premi il pulsante in basso per registrarne uno!',
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                    itemCount: sortedDayKeys.length,
                    itemBuilder: (context, index) {
                      final dayKey = sortedDayKeys[index];
                      final dayTx = groupedByDay[dayKey]!;
                      return _AccountDailyGroup(
                        accountId: account.id,
                        dayTransactions: dayTx,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _AccountSummaryMetric extends StatelessWidget {
  final String label;
  final String amount;
  final Color color;

  const _AccountSummaryMetric({
    required this.label,
    required this.amount,
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
          amount,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _AccountDailyGroup extends StatelessWidget {
  final String accountId;
  final List<MoneyTransaction> dayTransactions;

  const _AccountDailyGroup({
    required this.accountId,
    required this.dayTransactions,
  });

  @override
  Widget build(BuildContext context) {
    final provider = MoneyScope.read(context);
    final firstDate = dayTransactions.first.date;

    double dayIn = 0.0;
    double dayOut = 0.0;
    for (final tx in dayTransactions) {
      if (tx.type == TransactionType.income && tx.accountId == accountId) {
        dayIn += tx.amount;
      } else if (tx.type == TransactionType.transfer &&
          tx.toAccountId == accountId) {
        dayIn += tx.amount;
      } else if (tx.type == TransactionType.expense &&
          tx.accountId == accountId) {
        dayOut += tx.amount;
      } else if (tx.type == TransactionType.transfer &&
          tx.accountId == accountId) {
        dayOut += tx.amount;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withValues(alpha: 0.5),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Text(
                  firstDate.day.toString().padLeft(2, '0'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    AppFormatters.formatShortWeekday(firstDate),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${firstDate.month.toString().padLeft(2, '0')}.${firstDate.year}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const Spacer(),
                if (dayIn > 0)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Text(
                      '+ ${AppFormatters.formatCurrency(dayIn)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                if (dayOut > 0)
                  Text(
                    '- ${AppFormatters.formatCurrency(dayOut)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.red.shade700,
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...dayTransactions.map((tx) {
            final category = provider.getCategoryById(tx.categoryId);
            final isTransfer = tx.type == TransactionType.transfer;
            final isIncomingTransfer =
                isTransfer && tx.toAccountId == accountId;
            final isPositive =
                tx.type == TransactionType.income || isIncomingTransfer;

            final otherAccount = isTransfer
                ? provider.getAccountById(
                    isIncomingTransfer ? tx.accountId : (tx.toAccountId ?? ''),
                  )
                : null;

            final String titleText = isTransfer
                ? (isIncomingTransfer
                    ? 'Trasferimento da ${otherAccount?.name ?? ''}'
                    : 'Trasferimento a ${otherAccount?.name ?? ''}')
                : (category?.name ?? 'Senza categoria');

            final Color amountColor =
                isPositive ? Colors.blue.shade700 : Colors.red.shade700;
            final String prefix = isPositive ? '+ ' : '- ';

            return ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
              leading: CircleAvatar(
                backgroundColor:
                    (category?.color ?? Colors.blueGrey).withValues(alpha: 0.15),
                child: Icon(
                  isTransfer
                      ? Icons.swap_horiz
                      : (category?.icon ?? Icons.help_outline),
                  color: category?.color ?? Colors.blueGrey,
                ),
              ),
              title: Text(
                titleText,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: tx.note.isNotEmpty ? Text(tx.note) : null,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$prefix${AppFormatters.formatCurrency(tx.amount)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: amountColor,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Elimina movimento',
                    icon: const Icon(Icons.close, size: 16, color: Colors.grey),
                    onPressed: () => provider.deleteTransaction(tx.id),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
