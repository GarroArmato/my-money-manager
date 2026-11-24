import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../utils/formatters.dart';
import '../utils/money_scope.dart';
import '../widgets/app_top_bar.dart';

class _SubcategoryStatRow {
  final String name;
  final double amount;
  final double percentage; // 0.0 .. 1.0
  final Color badgeColor;
  final List<MoneyTransaction> transactions;

  const _SubcategoryStatRow({
    required this.name,
    required this.amount,
    required this.percentage,
    required this.badgeColor,
    required this.transactions,
  });
}

class _MonthPoint {
  final DateTime monthDate;
  final double total;
  final bool isSelected;

  const _MonthPoint({
    required this.monthDate,
    required this.total,
    required this.isSelected,
  });
}

class CategoryStatsDetailScreen extends StatelessWidget {
  final String categoryId;
  final TransactionType transactionType;
  final Color accentColor;

  const CategoryStatsDetailScreen({
    super.key,
    required this.categoryId,
    required this.transactionType,
    required this.accentColor,
  });

  static const List<String> _shortMonths = [
    'gen',
    'feb',
    'mar',
    'apr',
    'mag',
    'giu',
    'lug',
    'ago',
    'set',
    'ott',
    'nov',
    'dic',
  ];

  static const List<Color> _badgePalette = [
    Color(0xFFFF6B6B), // Rosso corallo (78%)
    Color(0xFFFF9F43), // Arancione (13%)
    Color(0xFFFECA57), // Giallo ambra (8%)
    Color(0xFFF9CA24), // Giallo vivo (0%)
    Color(0xFFBAD758), // Verde lime (0%)
    Color(0xFF6AB04C), // Verde prato (0%)
    Color(0xFF48DBFB), // Ciano/Turchese (0%)
    Color(0xFF54A0FF), // Blu
    Color(0xFF9B59B6), // Viola
  ];

  Future<void> _showAddSubcategoryDialog(
    BuildContext context,
    String catId,
  ) async {
    final provider = MoneyScope.read(context);
    final category = provider.getCategoryById(catId);
    if (category == null) return;

    final controller = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Nuova Sottocategoria in ${category.name}'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Nome Sottocategoria (es. Assicurazione, Bollo...)',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Annulla'),
            ),
            FilledButton.icon(
              onPressed: () async {
                final text = controller.text.trim();
                if (text.isEmpty) return;
                if (!category.subcategories.contains(text)) {
                  final updated = category.copyWith(
                    subcategories: [...category.subcategories, text],
                  );
                  await provider.saveCategory(updated);
                }
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('Aggiungi'),
            ),
          ],
        );
      },
    );
  }

  void _showSubcategoryTransactionsSheet(
    BuildContext context,
    String categoryName,
    _SubcategoryStatRow row,
  ) {
    if (row.transactions.isEmpty) return;

    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) {
        final provider = MoneyScope.of(sheetContext);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$categoryName • ${row.name}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      AppFormatters.formatCurrency(row.amount),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: row.transactions.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, idx) {
                      final tx = row.transactions[idx];
                      final acc = provider.getAccountById(tx.accountId);
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          tx.note.isNotEmpty ? tx.note : row.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Text(
                          '${acc?.name ?? ''} • ${AppFormatters.formatShortDateTime(tx.date)}',
                        ),
                        trailing: Text(
                          AppFormatters.formatCurrency(tx.amount),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = MoneyScope.of(context);
    final category = provider.getCategoryById(categoryId);
    final categoryName = category?.name ?? 'Dettaglio Categoria';
    final selectedMonth = provider.selectedMonth;

    // 1. Costruiamo i 7 punti mensili per il grafico lineare (da Mese-4 a Mese+2, come nello screenshot: lug..gen)
    final List<_MonthPoint> monthPoints = [];
    for (int offset = -4; offset <= 2; offset++) {
      final mDate = DateTime(selectedMonth.year, selectedMonth.month + offset);
      final mTotal = provider.allTransactions.where((tx) {
        return tx.type == transactionType &&
            (tx.categoryId ?? 'other') == categoryId &&
            tx.date.year == mDate.year &&
            tx.date.month == mDate.month;
      }).fold(0.0, (sum, tx) => sum + tx.amount);

      monthPoints.add(
        _MonthPoint(
          monthDate: mDate,
          total: mTotal,
          isSelected: offset == 0,
        ),
      );
    }

    // 2. Movimenti del mese attualmente selezionato per questa categoria
    final currentMonthTx = provider.allTransactions.where((tx) {
      return tx.type == transactionType &&
          (tx.categoryId ?? 'other') == categoryId &&
          tx.date.year == selectedMonth.year &&
          tx.date.month == selectedMonth.month;
    }).toList();

    final currentMonthTotal =
        currentMonthTx.fold(0.0, (sum, tx) => sum + tx.amount);

    // 3. Raggruppamento per Sottocategoria (includendo anche le sottocategorie a 0,00 € come nella seconda foto!)
    final Map<String, List<MoneyTransaction>> groupedBySub = {};
    if (category != null) {
      for (final sub in category.subcategories) {
        groupedBySub[sub] = [];
      }
    }

    for (final tx in currentMonthTx) {
      String subKey = (tx.subcategory != null && tx.subcategory!.isNotEmpty)
          ? tx.subcategory!
          : (tx.note.isNotEmpty ? tx.note : 'Altro');

      // Se la nota contiene il nome di una sottocategoria configurata, la abbina automaticamente
      if (tx.subcategory == null && category != null) {
        for (final configuredSub in category.subcategories) {
          if (tx.note.toLowerCase().contains(configuredSub.toLowerCase())) {
            subKey = configuredSub;
            break;
          }
        }
      }

      groupedBySub.putIfAbsent(subKey, () => []).add(tx);
    }

    final sortedSubEntries = groupedBySub.entries.toList()
      ..sort((a, b) {
        final sumA = a.value.fold(0.0, (s, t) => s + t.amount);
        final sumB = b.value.fold(0.0, (s, t) => s + t.amount);
        return sumB.compareTo(sumA);
      });

    final List<_SubcategoryStatRow> subRows = [];
    for (int i = 0; i < sortedSubEntries.length; i++) {
      final entry = sortedSubEntries[i];
      final sum = entry.value.fold(0.0, (s, t) => s + t.amount);
      final pct = currentMonthTotal > 0 ? (sum / currentMonthTotal) : 0.0;

      subRows.add(
        _SubcategoryStatRow(
          name: entry.key,
          amount: sum,
          percentage: pct,
          badgeColor: _badgePalette[i % _badgePalette.length],
          transactions: entry.value,
        ),
      );
    }

    final monthLabel =
        '${_shortMonths[selectedMonth.month - 1]} ${selectedMonth.year}';

    return Scaffold(
      appBar: AppTopBar(
        title: categoryName,
        icon: category?.icon ?? Icons.pie_chart_outline,
        actions: [
          if (category != null)
            IconButton(
              tooltip: 'Aggiungi sottocategoria',
              icon: const Icon(Icons.playlist_add, color: Colors.white),
              onPressed: () => _showAddSubcategoryDialog(context, categoryId),
            ),
        ],
      ),
      body: Column(
        children: [
          // 1. Selettore Mese:  <   nov 2026   >
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, size: 26),
                  onPressed: () => provider.changeMonth(-1),
                ),
                Text(
                  monthLabel,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, size: 26),
                  onPressed: () => provider.changeMonth(1),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // 2. Grafico Lineare Andamento Mensile (cliccabile sui singoli mesi!)
          SizedBox(
            height: 230,
            width: double.infinity,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return GestureDetector(
                  onTapUp: (details) {
                    final colWidth =
                        constraints.maxWidth / monthPoints.length;
                    final tappedIndex =
                        (details.localPosition.dx / colWidth).floor().clamp(
                              0,
                              monthPoints.length - 1,
                            );
                    final offset = tappedIndex - 4;
                    if (offset != 0) {
                      provider.changeMonth(offset);
                    }
                  },
                  child: CustomPaint(
                    painter: _CategoryTrendLineChartPainter(
                      points: monthPoints,
                      lineColor: const Color(0xFFFF6B6B),
                      textColor: Theme.of(context).colorScheme.onSurface,
                      shortMonths: _shortMonths,
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),

          // 3. Riga Intestazione Categoria e Totale del Mese (es. "Macchina     € 600,70")
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            color: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withValues(alpha: 0.35),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  categoryName,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  AppFormatters.formatCurrency(currentMonthTotal),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // 4. Lista Sottocategorie / Voci con badge percentuale colorato e importo
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.only(bottom: 32),
              itemCount: subRows.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final row = subRows[index];
                final roundedPct = (row.percentage * 100).round();

                return InkWell(
                  onTap: row.transactions.isEmpty
                      ? null
                      : () => _showSubcategoryTransactionsSheet(
                            context,
                            categoryName,
                            row,
                          ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        // Badge percentuale colorato (es. [78%], [13%], [8%], [0%])
                        Container(
                          width: 48,
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: row.badgeColor,
                            borderRadius: BorderRadius.circular(6),
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

                        // Nome Sottocategoria
                        Expanded(
                          child: Text(
                            row.name,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                        // Importo formattato
                        Text(
                          AppFormatters.formatCurrency(row.amount),
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
    );
  }
}

/// Disegna il grafico lineare mensile in stile Money Manager con griglia, pallini, importi e mesi
class _CategoryTrendLineChartPainter extends CustomPainter {
  final List<_MonthPoint> points;
  final Color lineColor;
  final Color textColor;
  final List<String> shortMonths;

  _CategoryTrendLineChartPainter({
    required this.points,
    required this.lineColor,
    required this.textColor,
    required this.shortMonths,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    const double topPad = 36.0;
    const double bottomPad = 48.0;
    const double sidePad = 28.0;
    final double chartWidth = size.width - (sidePad * 2);
    final double chartHeight = size.height - topPad - bottomPad;

    // 1. Disegna una griglia sottile sullo sfondo come nello screenshot
    final gridPaint = Paint()
      ..color = textColor.withValues(alpha: 0.06)
      ..strokeWidth = 1.0;

    const int gridRows = 6;
    for (int r = 0; r <= gridRows; r++) {
      final y = topPad + (chartHeight / gridRows) * r;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    const int gridCols = 14;
    for (int c = 0; c <= gridCols; c++) {
      final x = (size.width / gridCols) * c;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height - bottomPad + 8),
        gridPaint,
      );
    }

    // Linea di separazione asse X
    final axisPaint = Paint()
      ..color = textColor.withValues(alpha: 0.15)
      ..strokeWidth = 1.0;
    canvas.drawLine(
      Offset(0, topPad + chartHeight + 8),
      Offset(size.width, topPad + chartHeight + 8),
      axisPaint,
    );

    final double maxVal =
        points.map((p) => p.total).fold(0.0, (m, v) => math.max(m, v));

    // Calcola le coordinate (X, Y) di ciascuno dei 7 mesi
    final List<Offset> coords = [];
    final double stepX =
        points.length > 1 ? chartWidth / (points.length - 1) : 0.0;

    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      final x = sidePad + (i * stepX);
      final normalized = maxVal > 0 ? (p.total / maxVal) : 0.0;
      final y = topPad + chartHeight - (normalized * chartHeight);
      coords.add(Offset(x, y));
    }

    // 2. Disegna la linea spezzata che unisce i mesi
    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 3.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final linePath = Path();
    for (int i = 0; i < coords.length; i++) {
      if (i == 0) {
        linePath.moveTo(coords[i].dx, coords[i].dy);
      } else {
        linePath.lineTo(coords[i].dx, coords[i].dy);
      }
    }
    canvas.drawPath(linePath, linePaint);

    // 3. Disegna pallini, etichette importo sopra i pallini e nomi dei mesi in basso
    final dotPaint = Paint()
      ..color = lineColor
      ..style = PaintingStyle.fill;
    final whiteDotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      final pt = coords[i];

      // Pallino sul punto dati
      canvas.drawCircle(pt, p.isSelected ? 6.5 : 5.0, dotPaint);
      if (p.isSelected) {
        canvas.drawCircle(pt, 2.8, whiteDotPaint);
      }

      // Valore numerico sopra il pallino (es. "600,70", "0,00")
      final valString = p.total.toStringAsFixed(2).replaceAll('.', ',');
      final valTp = TextPainter(
        text: TextSpan(
          text: valString,
          style: TextStyle(
            color: p.isSelected
                ? textColor
                : textColor.withValues(alpha: 0.65),
            fontSize: 10.5,
            fontWeight: p.isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      valTp.paint(
        canvas,
        Offset(pt.dx - (valTp.width / 2), pt.dy - valTp.height - 8),
      );

      // Etichetta mese sull'asse X (es. "lug", "ago", "set", "ott", "nov", "dic", "gen 2027")
      final mName = shortMonths[p.monthDate.month - 1];
      final showYear = p.monthDate.month == 1 || i == 0;
      final labelText = showYear ? '$mName\n${p.monthDate.year}' : mName;

      final monthTp = TextPainter(
        text: TextSpan(
          text: labelText,
          style: TextStyle(
            color: p.isSelected
                ? lineColor
                : textColor.withValues(alpha: 0.65),
            fontSize: 11.5,
            fontWeight: p.isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout();

      monthTp.paint(
        canvas,
        Offset(pt.dx - (monthTp.width / 2), topPad + chartHeight + 14),
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CategoryTrendLineChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.textColor != textColor;
  }
}
