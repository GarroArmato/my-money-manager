import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../utils/formatters.dart';
import '../utils/money_scope.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = MoneyScope.of(context);
    final totalExpenses = provider.monthlyExpenses;

    // Raggruppa le uscite del mese per categoria
    final Map<String, double> totalsByCategory = {};
    for (final tx in provider.monthlyTransactions) {
      if (tx.type == TransactionType.expense && tx.categoryId != null) {
        totalsByCategory[tx.categoryId!] =
            (totalsByCategory[tx.categoryId!] ?? 0.0) + tx.amount;
      }
    }

    final sortedEntries = totalsByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiche Spese Mensili'),
      ),
      body: totalExpenses <= 0
          ? const Center(
              child: Text('Nessuna spesa registrata per il mese selezionato.'),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sortedEntries.length,
              itemBuilder: (context, index) {
                final entry = sortedEntries[index];
                final category = provider.getCategoryById(entry.key);
                final percentage = (entry.value / totalExpenses);

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              category?.icon ?? Icons.help_outline,
                              color: category?.color ?? Colors.grey,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                category?.name ?? 'Altro',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Text(
                              '${(percentage * 100).toStringAsFixed(1)}%',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              AppFormatters.formatCurrency(entry.value),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: percentage,
                            minHeight: 8,
                            color: category?.color ?? Colors.teal,
                            backgroundColor: (category?.color ?? Colors.teal)
                                .withValues(alpha: 0.15),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
