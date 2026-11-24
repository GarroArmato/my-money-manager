import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../utils/formatters.dart';
import '../utils/money_scope.dart';
import 'category_stats_detail_screen.dart';

class _CategoryStatItem {
  final String categoryId;
  final String name;
  final double amount;
  final double percentage; // 0.0 .. 1.0
  final Color color;

  const _CategoryStatItem({
    required this.categoryId,
    required this.name,
    required this.amount,
    required this.percentage,
    required this.color,
  });
}

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  TransactionType _selectedTab = TransactionType.expense;
  bool _isYearly = false; // M = Mensile, A = Annuale

  static const List<Color> _chartPalette = [
    Color(0xFFFF6B6B), // Rosso corallo (es. 30%)
    Color(0xFFFF9F43), // Arancione (es. 16%)
    Color(0xFFFECA57), // Giallo ambra (es. 16%)
    Color(0xFFF9CA24), // Giallo vivo (es. 12%)
    Color(0xFFBAD758), // Verde lime (es. 7%)
    Color(0xFF6AB04C), // Verde prato (es. 7%)
    Color(0xFF48DBFB), // Azzurro
    Color(0xFF54A0FF), // Blu
    Color(0xFF9B59B6), // Viola
    Color(0xFFE056FD), // Rosa/Fucsia
  ];

  @override
  Widget build(BuildContext context) {
    final provider = MoneyScope.of(context);
    final selectedDate = provider.selectedMonth;

    // Filtra i movimenti per Mese (M) o Anno (A)
    final periodTransactions = provider.allTransactions.where((tx) {
      if (_isYearly) {
        return tx.date.year == selectedDate.year;
      }
      return tx.date.year == selectedDate.year &&
          tx.date.month == selectedDate.month;
    }).toList();

    final totalIncome = periodTransactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);

    final totalExpense = periodTransactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);

    final activeTotal =
        _selectedTab == TransactionType.expense ? totalExpense : totalIncome;

    // Raggruppa per categoria
    final Map<String, double> totalsByCategory = {};
    for (final tx in periodTransactions) {
      if (tx.type == _selectedTab) {
        final key = tx.categoryId ?? 'other';
        totalsByCategory[key] = (totalsByCategory[key] ?? 0.0) + tx.amount;
      }
    }

    final sortedEntries = totalsByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final List<_CategoryStatItem> items = [];
    for (int i = 0; i < sortedEntries.length; i++) {
      final entry = sortedEntries[i];
      final cat = provider.getCategoryById(entry.key);
      final pct = activeTotal > 0 ? (entry.value / activeTotal) : 0.0;
      final sliceColor = _chartPalette[i % _chartPalette.length];

      items.add(
        _CategoryStatItem(
          categoryId: entry.key,
          name: cat?.name ?? 'Altro',
          amount: entry.value,
          percentage: pct,
          color: sliceColor,
        ),
      );
    }

    final activeAccentColor = _selectedTab == TransactionType.expense
        ? const Color(0xFFFF6B6B)
        : provider.secondaryColor;

    final periodLabel = _isYearly
        ? '${selectedDate.year}'
        : AppFormatters.formatMonthYear(selectedDate).toLowerCase();

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 1. Barra superiore in stile Money Manager: [Statistiche | Budget | Nota] e [M v]
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 36,
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Container(
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: activeAccentColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Text(
                                'Statistiche',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Center(
                              child: Text(
                                'Budget',
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Center(
                              child: Text(
                                'Nota',
                                style: TextStyle(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Selettore Periodo: M (Mensile) / A (Annuale)
                  InkWell(
                    onTap: () {
                      setState(() {
                        _isYearly = !_isYearly;
                      });
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      height: 36,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.grey.withValues(alpha: 0.5),
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Text(
                            _isYearly ? 'A' : 'M',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.keyboard_arrow_down, size: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // 2. Selettore Mese/Anno:  <   nov 2026   >
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 26),
                    onPressed: () =>
                        provider.changeMonth(_isYearly ? -12 : -1),
                  ),
                  Text(
                    periodLabel,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, size: 26),
                    onPressed: () =>
                        provider.changeMonth(_isYearly ? 12 : 1),
                  ),
                ],
              ),
            ),

            // 3. Tab "In € ..." | "Spese € ..." con linea colorata sotto il tab selezionato
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedTab = TransactionType.income;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _selectedTab == TransactionType.income
                                ? provider.secondaryColor
                                : Colors.grey.withValues(alpha: 0.25),
                            width:
                                _selectedTab == TransactionType.income ? 3 : 1,
                          ),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'In ${AppFormatters.formatCurrency(totalIncome)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: _selectedTab == TransactionType.income
                                ? Theme.of(context).colorScheme.onSurface
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _selectedTab = TransactionType.expense;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(
                          bottom: BorderSide(
                            color: _selectedTab == TransactionType.expense
                                ? const Color(0xFFFF6B6B)
                                : Colors.grey.withValues(alpha: 0.25),
                            width:
                                _selectedTab == TransactionType.expense ? 3 : 1,
                          ),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Spese ${AppFormatters.formatCurrency(totalExpense)}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: _selectedTab == TransactionType.expense
                                ? Theme.of(context).colorScheme.onSurface
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // 4. Grafico a Torta con etichette esterne + Lista percentuali cliccabile in basso
            Expanded(
              child: items.isEmpty
                  ? Center(
                      child: Text(
                        _selectedTab == TransactionType.expense
                            ? 'Nessuna spesa registrata in questo periodo.'
                            : 'Nessuna entrata registrata in questo periodo.',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    )
                  : Column(
                      children: [
                        // Area Grafico a Torta con linee guida ed etichette
                        SizedBox(
                          height: 290,
                          width: double.infinity,
                          child: CustomPaint(
                            painter: _MoneyManagerPieChartPainter(
                              items: items,
                              textColor:
                                  Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                        const Divider(height: 1),

                        // Lista Categorie cliccabile (apre il Dettaglio Categoria con grafico lineare!)
                        Expanded(
                          child: ListView.separated(
                            padding: const EdgeInsets.only(bottom: 88),
                            itemCount: items.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final item = items[index];
                              final roundedPct =
                                  (item.percentage * 100).round();

                              return InkWell(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => CategoryStatsDetailScreen(
                                        categoryId: item.categoryId,
                                        transactionType: _selectedTab,
                                        accentColor: item.color,
                                      ),
                                    ),
                                  );
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    children: [
                                      // Badge percentuale colorato (es. [30%], [16%])
                                      Container(
                                        width: 48,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 5,
                                        ),
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: item.color,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          '$roundedPct%',
                                          style: const TextStyle(
                                            color: Colors.black87,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 14),

                                      // Nome Categoria
                                      Expanded(
                                        child: Text(
                                          item.name,
                                          style: const TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),

                                      // Importo formattato
                                      Text(
                                        AppFormatters.formatCurrency(
                                            item.amount),
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Disegna il grafico a torta in stile Money Manager con linee guida esterne, nome categoria e percentuale
class _MoneyManagerPieChartPainter extends CustomPainter {
  final List<_CategoryStatItem> items;
  final Color textColor;

  _MoneyManagerPieChartPainter({
    required this.items,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (items.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) * 0.30;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final fillPaint = Paint()..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..color = Colors.black87
      ..strokeWidth = 1.4;

    double startAngle = -math.pi / 2;

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final sweepAngle = item.percentage * 2 * math.pi;
      if (sweepAngle <= 0) continue;

      fillPaint.color = item.color;
      canvas.drawArc(rect, startAngle, sweepAngle, true, fillPaint);
      // Se c'è una sola categoria al 100%, disegna solo il bordo circolare esterno senza il raggio interno
      if (items.length == 1) {
        canvas.drawCircle(center, radius, borderPaint);
      } else {
        canvas.drawArc(rect, startAngle, sweepAngle, true, borderPaint);
      }

      if (i < 8 && item.percentage >= 0.012) {
        final midAngle = startAngle + (sweepAngle / 2);
        final cosA = math.cos(midAngle);
        final sinA = math.sin(midAngle);

        final p1 = Offset(
          center.dx + radius * cosA,
          center.dy + radius * sinA,
        );
        final p2 = Offset(
          center.dx + (radius + 18) * cosA,
          center.dy + (radius + 18) * sinA,
        );
        final isRightSide = cosA >= 0;
        final p3 = Offset(
          p2.dx + (isRightSide ? 14 : -14),
          p2.dy,
        );

        final linePaint = Paint()
          ..color = item.color
          ..strokeWidth = 1.5
          ..style = PaintingStyle.stroke;

        final path = Path()
          ..moveTo(p1.dx, p1.dy)
          ..lineTo(p2.dx, p2.dy)
          ..lineTo(p3.dx, p3.dy);
        canvas.drawPath(path, linePaint);

        final shortName = item.name.length > 12
            ? '${item.name.substring(0, 10)}...'
            : item.name;
        final pctText = '${(item.percentage * 100).toStringAsFixed(1)} %';

        final textSpan = TextSpan(
          children: [
            TextSpan(
              text: '$shortName\n',
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 11.5,
              ),
            ),
            TextSpan(
              text: pctText,
              style: TextStyle(
                color: textColor.withValues(alpha: 0.8),
                fontSize: 11,
              ),
            ),
          ],
        );

        final tp = TextPainter(
          text: textSpan,
          textAlign: isRightSide ? TextAlign.left : TextAlign.right,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: 110);

        final textOffset = Offset(
          isRightSide ? p3.dx + 5 : p3.dx - tp.width - 5,
          p3.dy - (tp.height / 2),
        );
        tp.paint(canvas, textOffset);
      }

      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant _MoneyManagerPieChartPainter oldDelegate) {
    return oldDelegate.items != items || oldDelegate.textColor != textColor;
  }
}
