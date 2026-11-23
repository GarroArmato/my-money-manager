import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../utils/formatters.dart';
import '../utils/money_scope.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = MoneyScope.of(context);

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
            margin: const EdgeInsets.all(16),
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
                  amount: AppFormatters.formatCurrency(provider.monthlyExpenses),
                  color: Colors.red.shade700,
                ),
                _SummaryColumn(
                  label: 'Bilancio',
                  amount: AppFormatters.formatCurrency(provider.monthlyBalance),
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ],
            ),
          ),

          // Lista movimenti del mese
          Expanded(
            child: provider.monthlyTransactions.isEmpty
                ? const Center(
                    child: Text(
                      'Nessun movimento in questo mese.\nPremi "+ Movimento" o importa un CSV dai Conti!',
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: provider.monthlyTransactions.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final tx = provider.monthlyTransactions[index];
                      return _TransactionTile(transaction: tx);
                    },
                  ),
          ),
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

    final isExpense = transaction.type == TransactionType.expense;
    final isTransfer = transaction.type == TransactionType.transfer;

    final Color amountColor = isTransfer
        ? Colors.blueGrey
        : (isExpense ? Colors.red.shade700 : Colors.green.shade700);

    final String prefix = isTransfer ? '⇄ ' : (isExpense ? '- ' : '+ ');

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
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
        '${account?.name ?? ''} • ${AppFormatters.formatShortDateTime(transaction.date)}'
        '${transaction.note.isNotEmpty ? '\n${transaction.note}' : ''}',
      ),
      isThreeLine: transaction.note.isNotEmpty,
      trailing: Text(
        '$prefix${AppFormatters.formatCurrency(transaction.amount)}',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
          color: amountColor,
        ),
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
    final icon = isCsv ? Icons.table_chart_outlined : Icons.notifications_active;

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
