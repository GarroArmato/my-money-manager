import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../providers/money_provider.dart';

class TransactionsScreen extends StatelessWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MoneyProvider>();
    final currencyFormat = NumberFormat.currency(locale: 'it_IT', symbol: '€');
    final monthFormat = DateFormat('MMMM yyyy', 'it_IT');

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
              monthFormat.format(provider.selectedMonth).toUpperCase(),
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
                  amount: currencyFormat.format(provider.monthlyIncome),
                  color: Colors.green.shade700,
                ),
                _SummaryColumn(
                  label: 'Uscite',
                  amount: currencyFormat.format(provider.monthlyExpenses),
                  color: Colors.red.shade700,
                ),
                _SummaryColumn(
                  label: 'Bilancio',
                  amount: currencyFormat.format(provider.monthlyBalance),
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
                      'Nessun movimento in questo mese.\nPremi "+ Movimento" o sincronizza la tua banca!',
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
    final provider = context.read<MoneyProvider>();
    final category = provider.getCategoryById(transaction.categoryId);
    final account = provider.getAccountById(transaction.accountId);
    final currencyFormat = NumberFormat.currency(locale: 'it_IT', symbol: '€');
    final dateFormat = DateFormat('dd/MM HH:mm');

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
          if (transaction.isBankSynced)
            Tooltip(
              message: 'Sincronizzato via Open Banking PSD2',
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.sync, size: 12, color: Colors.blue),
                    SizedBox(width: 3),
                    Text(
                      'PSD2',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      subtitle: Text(
        '${account?.name ?? ''} • ${dateFormat.format(transaction.date)}'
        '${transaction.note.isNotEmpty ? '\n${transaction.note}' : ''}',
      ),
      isThreeLine: transaction.note.isNotEmpty,
      trailing: Text(
        '$prefix${currencyFormat.format(transaction.amount)}',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 15,
          color: amountColor,
        ),
      ),
    );
  }
}
