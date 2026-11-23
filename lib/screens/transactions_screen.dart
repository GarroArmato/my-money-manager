import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../utils/formatters.dart';
import '../utils/money_scope.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = MoneyScope.of(context);
    final transactions = provider.monthlyTransactions;

    // Raggruppa i movimenti per giorno del mese (in stile Money Manager "Giornaliero")
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
        title: const Text('My Money Manager'),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'Mese precedente',
            icon: const Icon(Icons.chevron_left),
            onPressed: () => provider.changeMonth(-1),
          ),
          Center(
            child: Text(
              AppFormatters.formatMonthYear(provider.selectedMonth),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
          IconButton(
            tooltip: 'Mese successivo',
            icon: const Icon(Icons.chevron_right),
            onPressed: () => provider.changeMonth(1),
          ),
        ],
      ),
      body: Column(
        children: [
          // Barra riepilogo mensile in stile Money Manager (Entrate / Uscite / Totale)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _SummaryColumn(
                  label: 'Entrate',
                  amount: AppFormatters.formatCurrency(provider.monthlyIncome),
                  color: Colors.green.shade700,
                ),
                _SummaryColumn(
                  label: 'Uscite',
                  amount:
                      AppFormatters.formatCurrency(provider.monthlyExpenses),
                  color: Colors.red.shade700,
                ),
                _SummaryColumn(
                  label: 'Totale',
                  amount: AppFormatters.formatCurrency(provider.monthlyBalance),
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ],
            ),
          ),

          // Lista movimenti raggruppata per giorno (stile Money Manager)
          Expanded(
            child: sortedDayKeys.isEmpty
                ? const Center(
                    child: Text(
                      'Nessun movimento in questo mese.\nPremi "+ Movimento" o importa un CSV dai Conti!',
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                    itemCount: sortedDayKeys.length,
                    itemBuilder: (context, index) {
                      final dayKey = sortedDayKeys[index];
                      final dayTransactions = groupedByDay[dayKey]!;
                      return _DailyTransactionGroup(
                        dayTransactions: dayTransactions,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _DailyTransactionGroup extends StatelessWidget {
  final List<MoneyTransaction> dayTransactions;

  const _DailyTransactionGroup({required this.dayTransactions});

  @override
  Widget build(BuildContext context) {
    final firstDate = dayTransactions.first.date;

    final dayIncome = dayTransactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
    final dayExpense = dayTransactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          // Intestazione del giorno in stile Money Manager: [23] [Lun] 11.2026 | +Entrate -Uscite
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
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                const Spacer(),
                if (dayIncome > 0)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Text(
                      '+ ${AppFormatters.formatCurrency(dayIncome)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
                if (dayExpense > 0)
                  Text(
                    '- ${AppFormatters.formatCurrency(dayExpense)}',
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
          ...dayTransactions.map((tx) => _TransactionTile(transaction: tx)),
        ],
      ),
    );
  }
}

class _SummaryColumn extends StatelessWidget {
  final String label;
  final String amount;
  final Color color;

  const _SummaryColumn({
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
            fontSize: 15,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final MoneyTransaction transaction;

  const _TransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final provider = MoneyScope.read(context);
    final category = provider.getCategoryById(transaction.categoryId);
    final account = provider.getAccountById(transaction.accountId);
    final toAccount = transaction.toAccountId != null
        ? provider.getAccountById(transaction.toAccountId!)
        : null;

    final isExpense = transaction.type == TransactionType.expense;
    final isTransfer = transaction.type == TransactionType.transfer;

    final Color amountColor = isTransfer
        ? Colors.blueGrey
        : (isExpense ? Colors.red.shade700 : Colors.green.shade700);

    final String prefix = isTransfer ? '⇄ ' : (isExpense ? '- ' : '+ ');

    final String accountLabel = isTransfer
        ? '${account?.name ?? ''} → ${toAccount?.name ?? ''}'
        : (account?.name ?? '');

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 12),
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
      title: Row(
        children: [
          Expanded(
            child: Text(
              isTransfer
                  ? 'Trasferimento'
                  : (category?.name ?? 'Senza categoria'),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          if (transaction.source != TransactionSource.manual)
            _SourceBadge(source: transaction.source),
        ],
      ),
      subtitle: Text(
        '$accountLabel'
        '${transaction.note.isNotEmpty ? ' • ${transaction.note}' : ''}',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$prefix${AppFormatters.formatCurrency(transaction.amount)}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: amountColor,
            ),
          ),
          IconButton(
            tooltip: 'Elimina movimento',
            icon: const Icon(Icons.close, size: 16, color: Colors.grey),
            onPressed: () => provider.deleteTransaction(transaction.id),
          ),
        ],
      ),
    );
  }
}

class _SourceBadge extends StatelessWidget {
  final TransactionSource source;

  const _SourceBadge({required this.source});

  @override
  Widget build(BuildContext context) {
    final isCsv = source == TransactionSource.csv;
    final color = isCsv ? Colors.teal : Colors.deepOrange;
    final label = isCsv ? 'CSV' : 'NOTIFICA';
    final icon =
        isCsv ? Icons.table_chart_outlined : Icons.notifications_active;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
