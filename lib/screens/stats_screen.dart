import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../utils/formatters.dart';
import '../utils/money_scope.dart';
import '../widgets/app_top_bar.dart';
import 'category_stats_detail_screen.dart';

enum _StatsTopSection {
  statistiche,
  budget,
  nota,
}

enum _StatsPeriodMode {
  weekly,  // Settimanale (S)
  monthly, // Mensile (M)
  yearly,  // Ogni Anno (A)
  custom,  // Periodo personalizzato (P)
  allList, // Elenco completo (E)
}

extension _StatsPeriodModeExt on _StatsPeriodMode {
  String get shortCode {
    switch (this) {
      case _StatsPeriodMode.weekly:
        return 'S';
      case _StatsPeriodMode.monthly:
        return 'M';
      case _StatsPeriodMode.yearly:
        return 'A';
      case _StatsPeriodMode.custom:
        return 'P';
      case _StatsPeriodMode.allList:
        return 'E';
    }
  }

  String get label {
    switch (this) {
      case _StatsPeriodMode.weekly:
        return 'Settimanale';
      case _StatsPeriodMode.monthly:
        return 'Mensile';
      case _StatsPeriodMode.yearly:
        return 'Ogni Anno';
      case _StatsPeriodMode.custom:
        return 'Periodo';
      case _StatsPeriodMode.allList:
        return 'Elenco';
    }
  }
}

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

class _NoteGroupItem {
  final String noteTitle;
  final double totalAmount;
  final double percentage;
  final int count;
  final Color color;
  final List<MoneyTransaction> transactions;

  const _NoteGroupItem({
    required this.noteTitle,
    required this.totalAmount,
    required this.percentage,
    required this.count,
    required this.color,
    required this.transactions,
  });
}

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  _StatsTopSection _topSection = _StatsTopSection.statistiche;
  _StatsPeriodMode _periodMode = _StatsPeriodMode.monthly;
  TransactionType _selectedTab = TransactionType.expense;

  // Offset per la navigazione settimanale e range personalizzato per "Periodo"
  int _weekOffset = 0;
  DateTimeRange _customRange = DateTimeRange(
    start: DateTime(DateTime.now().year, DateTime.now().month, 1),
    end: DateTime.now(),
  );

  static const List<Color> _chartPalette = [
    Color(0xFFFF6B6B), // Rosso corallo
    Color(0xFFFF9F43), // Arancione
    Color(0xFFFECA57), // Giallo ambra
    Color(0xFFF9CA24), // Giallo vivo
    Color(0xFFBAD758), // Verde lime
    Color(0xFF6AB04C), // Verde prato
    Color(0xFF48DBFB), // Azzurro
    Color(0xFF54A0FF), // Blu
    Color(0xFF9B59B6), // Viola
    Color(0xFFE056FD), // Rosa/Fucsia
  ];

  /// Apre il menu dal basso identico allo screenshot quando clicchi su "M v"
  Future<void> _showPeriodSelectorBottomSheet(
    BuildContext context,
    Color activeAccentColor,
  ) async {
    final chosen = await showModalBottomSheet<_StatsPeriodMode>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final surfaceColor =
            Theme.of(sheetContext).colorScheme.surfaceContainerHighest;

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Blocco opzioni (Settimanale, Mensile, Ogni Anno, Periodo, Elenco)
                Container(
                  decoration: BoxDecoration(
                    color: surfaceColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (int i = 0;
                          i < _StatsPeriodMode.values.length;
                          i++) ...[
                        if (i > 0)
                          Divider(
                            height: 1,
                            color: Colors.grey.withValues(alpha: 0.2),
                          ),
                        Builder(
                          builder: (_) {
                            final mode = _StatsPeriodMode.values[i];
                            final isSelected = mode == _periodMode;
                            return ListTile(
                              title: Text(
                                mode.label,
                                style: TextStyle(
                                  color: isSelected ? activeAccentColor : null,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                              ),
                              trailing: isSelected
                                  ? Icon(Icons.check, color: activeAccentColor)
                                  : null,
                              onTap: () =>
                                  Navigator.of(sheetContext).pop(mode),
                            );
                          },
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                // Pulsante separato "Annulla" in basso come nello screenshot
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: surfaceColor,
                      foregroundColor:
                          Theme.of(sheetContext).colorScheme.onSurface,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    child: const Text(
                      'Annulla',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (chosen == null || !mounted) return;

    if (chosen == _StatsPeriodMode.custom) {
      final picked = await showDateRangePicker(
        context: context,
        initialDateRange: _customRange,
        firstDate: DateTime(2020),
        lastDate: DateTime(2035),
      );
      if (picked != null && mounted) {
        setState(() {
          _periodMode = _StatsPeriodMode.custom;
          _customRange = picked;
        });
      }
    } else {
      setState(() {
        _periodMode = chosen;
      });
    }
  }

  /// Dialog per impostare o modificare il Budget mensile di una Categoria
  Future<void> _showEditBudgetDialog(
    BuildContext context,
    TransactionCategory category,
    double currentBudget,
  ) async {
    final controller = TextEditingController(
      text: currentBudget > 0 ? currentBudget.toStringAsFixed(2) : '',
    );

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Row(
            children: [
              Icon(category.icon, color: category.color),
              const SizedBox(width: 10),
              Expanded(child: Text('Budget: ${category.name}')),
            ],
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Limite Budget Mensile (€) (0 per rimuovere)',
              prefixIcon: Icon(Icons.euro),
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            if (currentBudget > 0)
              TextButton(
                onPressed: () async {
                  await MoneyScope.read(context)
                      .setCategoryBudget(category.id, 0);
                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                  }
                },
                child: const Text(
                  'Rimuovi Budget',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Annulla'),
            ),
            FilledButton.icon(
              onPressed: () async {
                final val = double.tryParse(
                      controller.text.replaceAll(',', '.'),
                    ) ??
                    0.0;
                await MoneyScope.read(context)
                    .setCategoryBudget(category.id, val);
                if (dialogContext.mounted) {
                  Navigator.of(dialogContext).pop();
                }
              },
              icon: const Icon(Icons.check),
              label: const Text('Salva Budget'),
            ),
          ],
        );
      },
    );
  }

  void _showNoteTransactionsSheet(
    BuildContext context,
    _NoteGroupItem item,
  ) {
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
                    Expanded(
                      child: Text(
                        'Nota: "${item.noteTitle}" (${item.count})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Text(
                      AppFormatters.formatCurrency(item.totalAmount),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: item.color,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: item.transactions.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, idx) {
                      final tx = item.transactions[idx];
                      final cat = provider.getCategoryById(tx.categoryId);
                      final acc = provider.getAccountById(tx.accountId);
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: (cat?.color ?? Colors.grey)
                              .withValues(alpha: 0.15),
                          child: Icon(
                            cat?.icon ?? Icons.receipt_long,
                            color: cat?.color ?? Colors.grey,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          cat?.name ?? 'Altro',
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

  DateTimeRange _getCurrentWeeklyRange() {
    final now = DateTime.now().add(Duration(days: _weekOffset * 7));
    final monday = now.subtract(Duration(days: now.weekday - 1));
    final start = DateTime(monday.year, monday.month, monday.day);
    final end = start.add(const Duration(days: 6, hours: 23, minutes: 59));
    return DateTimeRange(start: start, end: end);
  }

  @override
  Widget build(BuildContext context) {
    final provider = MoneyScope.of(context);
    final selectedDate = provider.selectedMonth;
    final weekRange = _getCurrentWeeklyRange();

    // Filtra i movimenti in base alla modalità di periodo selezionata (S, M, A, P, E)
    final periodTransactions = provider.allTransactions.where((tx) {
      switch (_periodMode) {
        case _StatsPeriodMode.weekly:
          return !tx.date.isBefore(weekRange.start) &&
              !tx.date.isAfter(weekRange.end);
        case _StatsPeriodMode.monthly:
          return tx.date.year == selectedDate.year &&
              tx.date.month == selectedDate.month;
        case _StatsPeriodMode.yearly:
          return tx.date.year == selectedDate.year;
        case _StatsPeriodMode.custom:
          final endInclusive = DateTime(
            _customRange.end.year,
            _customRange.end.month,
            _customRange.end.day,
            23,
            59,
            59,
          );
          return !tx.date.isBefore(_customRange.start) &&
              !tx.date.isAfter(endInclusive);
        case _StatsPeriodMode.allList:
          return true;
      }
    }).toList();

    final totalIncome = periodTransactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);

    final totalExpense = periodTransactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);

    final activeTotal =
        _selectedTab == TransactionType.expense ? totalExpense : totalIncome;

    final activeAccentColor = _selectedTab == TransactionType.expense
        ? const Color(0xFFFF6B6B)
        : provider.secondaryColor;

    // Etichetta del periodo centrale
    String periodLabel;
    switch (_periodMode) {
      case _StatsPeriodMode.weekly:
        periodLabel =
            '${AppFormatters.formatDate(weekRange.start)} ~ ${AppFormatters.formatDate(weekRange.end)}';
        break;
      case _StatsPeriodMode.monthly:
        periodLabel = AppFormatters.formatMonthYear(selectedDate).toLowerCase();
        break;
      case _StatsPeriodMode.yearly:
        periodLabel = '${selectedDate.year}';
        break;
      case _StatsPeriodMode.custom:
        periodLabel =
            '${AppFormatters.formatDate(_customRange.start)} ~ ${AppFormatters.formatDate(_customRange.end)}';
        break;
      case _StatsPeriodMode.allList:
        periodLabel = 'Tutti i movimenti';
        break;
    }

    return Scaffold(
      appBar: const AppTopBar(
        title: 'Statistiche & Budget',
        icon: Icons.pie_chart_outline,
      ),
      body: Column(
        children: [
          // 1. Barra superiore: [Statistiche | Budget | Nota] e pulsante Periodo [M v]
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
                        _TopSectionSegment(
                          label: 'Statistiche',
                          isSelected:
                              _topSection == _StatsTopSection.statistiche,
                          activeColor: activeAccentColor,
                          onTap: () => setState(
                            () => _topSection = _StatsTopSection.statistiche,
                          ),
                        ),
                        _TopSectionSegment(
                          label: 'Budget',
                          isSelected: _topSection == _StatsTopSection.budget,
                          activeColor: activeAccentColor,
                          onTap: () => setState(
                            () => _topSection = _StatsTopSection.budget,
                          ),
                        ),
                        _TopSectionSegment(
                          label: 'Nota',
                          isSelected: _topSection == _StatsTopSection.nota,
                          activeColor: activeAccentColor,
                          onTap: () => setState(
                            () => _topSection = _StatsTopSection.nota,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Pulsante [M v] che apre il Bottom Sheet come nella foto!
                InkWell(
                  onTap: () => _showPeriodSelectorBottomSheet(
                    context,
                    activeAccentColor,
                  ),
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
                          _periodMode.shortCode,
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

          // 2. Selettore Mese/Periodo:  <   nov 2026   >
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, size: 26),
                  onPressed: (_periodMode == _StatsPeriodMode.allList ||
                          _periodMode == _StatsPeriodMode.custom)
                      ? null
                      : () {
                          if (_periodMode == _StatsPeriodMode.weekly) {
                            setState(() => _weekOffset--);
                          } else if (_periodMode == _StatsPeriodMode.yearly) {
                            provider.changeMonth(-12);
                          } else {
                            provider.changeMonth(-1);
                          }
                        },
                ),
                InkWell(
                  onTap: _periodMode == _StatsPeriodMode.custom
                      ? () => _showPeriodSelectorBottomSheet(
                            context,
                            activeAccentColor,
                          )
                      : null,
                  child: Text(
                    periodLabel,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right, size: 26),
                  onPressed: (_periodMode == _StatsPeriodMode.allList ||
                          _periodMode == _StatsPeriodMode.custom)
                      ? null
                      : () {
                          if (_periodMode == _StatsPeriodMode.weekly) {
                            setState(() => _weekOffset++);
                          } else if (_periodMode == _StatsPeriodMode.yearly) {
                            provider.changeMonth(12);
                          } else {
                            provider.changeMonth(1);
                          }
                        },
                ),
              ],
            ),
          ),

          // 3. Tab "In € ..." | "Spese € ..."
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
                          width: _selectedTab == TransactionType.income ? 3 : 1,
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

          // 4. Contenuto dinamico in base alla scheda scelta: Statistiche | Budget | Nota
          Expanded(
            child: _buildActiveSectionBody(
              context: context,
              periodTransactions: periodTransactions,
              activeTotal: activeTotal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveSectionBody({
    required BuildContext context,
    required List<MoneyTransaction> periodTransactions,
    required double activeTotal,
  }) {
    switch (_topSection) {
      case _StatsTopSection.statistiche:
        return _buildPieAndCategoryList(
          context: context,
          periodTransactions: periodTransactions,
          activeTotal: activeTotal,
        );
      case _StatsTopSection.budget:
        return _buildBudgetSection(
          context: context,
          periodTransactions: periodTransactions,
        );
      case _StatsTopSection.nota:
        return _buildNoteGroupedSection(
          context: context,
          periodTransactions: periodTransactions,
          activeTotal: activeTotal,
        );
    }
  }

  /// VISTA 1: GRAFICO A TORTA + LISTA CATEGORIE
  Widget _buildPieAndCategoryList({
    required BuildContext context,
    required List<MoneyTransaction> periodTransactions,
    required double activeTotal,
  }) {
    final provider = MoneyScope.of(context);
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

    if (items.isEmpty) {
      return Center(
        child: Text(
          _selectedTab == TransactionType.expense
              ? 'Nessuna spesa registrata in questo periodo.'
              : 'Nessuna entrata registrata in questo periodo.',
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 280,
          width: double.infinity,
          child: CustomPaint(
            painter: _MoneyManagerPieChartPainter(
              items: items,
              textColor: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.only(bottom: 88),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = items[index];
              final roundedPct = (item.percentage * 100).round();

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
                      Container(
                        width: 48,
                        padding: const EdgeInsets.symmetric(vertical: 5),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: item.color,
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
                      Expanded(
                        child: Text(
                          item.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Text(
                        AppFormatters.formatCurrency(item.amount),
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
    );
  }

  /// VISTA 2: SEZIONE BUDGET (Logica completa Budget Mensile per Categoria + Riepilogo Totale)
  Widget _buildBudgetSection({
    required BuildContext context,
    required List<MoneyTransaction> periodTransactions,
  }) {
    final provider = MoneyScope.of(context);
    final budgets = provider.categoryBudgets;

    // Moltiplicatore del budget se siamo in modalità Annuale (x12) o Settimanale (/4.33)
    double periodMultiplier = 1.0;
    if (_periodMode == _StatsPeriodMode.yearly) {
      periodMultiplier = 12.0;
    } else if (_periodMode == _StatsPeriodMode.weekly) {
      periodMultiplier = 1.0 / 4.33;
    }

    // Calcola quanto speso per ogni categoria nel periodo
    final Map<String, double> spentByCategory = {};
    for (final tx in periodTransactions) {
      if (tx.type == TransactionType.expense && tx.categoryId != null) {
        spentByCategory[tx.categoryId!] =
            (spentByCategory[tx.categoryId!] ?? 0.0) + tx.amount;
      }
    }

    double totalBudget = 0.0;
    double totalSpentOnBudgeted = 0.0;
    for (final entry in budgets.entries) {
      final scaledBudget = entry.value * periodMultiplier;
      totalBudget += scaledBudget;
      totalSpentOnBudgeted += spentByCategory[entry.key] ?? 0.0;
    }

    final remainingTotal = totalBudget - totalSpentOnBudgeted;
    final overallRatio =
        totalBudget > 0 ? (totalSpentOnBudgeted / totalBudget) : 0.0;
    final isOverTotal = remainingTotal < 0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 88),
      children: [
        // Card Riepilogo Budget Totale in stile Money Manager
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isOverTotal
                        ? 'BUDGET TOTALE SFORATO'
                        : 'BUDGET RIMANENTE (${_periodMode.label.toUpperCase()})',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: isOverTotal
                          ? provider.expenseColor.withValues(alpha: 0.2)
                          : provider.secondaryColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${(overallRatio * 100).round()}% usato',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isOverTotal
                            ? provider.expenseColor
                            : provider.secondaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                AppFormatters.formatCurrency(remainingTotal),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: isOverTotal
                      ? provider.expenseColor
                      : provider.secondaryColor,
                ),
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: overallRatio.clamp(0.0, 1.0),
                  minHeight: 10,
                  color: isOverTotal
                      ? provider.expenseColor
                      : (overallRatio > 0.80
                          ? Colors.orange
                          : provider.secondaryColor),
                  backgroundColor: Colors.grey.withValues(alpha: 0.2),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Speso: ${AppFormatters.formatCurrency(totalSpentOnBudgeted)}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  Text(
                    'Budget: ${AppFormatters.formatCurrency(totalBudget)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),

        Text(
          'BUDGET PER CATEGORIA (TOCCA PER MODIFICARE)',
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),

        ...provider.expenseCategories.map((cat) {
          final baseMonthlyBudget = budgets[cat.id] ?? 0.0;
          final hasBudget = baseMonthlyBudget > 0;
          final scaledBudget = baseMonthlyBudget * periodMultiplier;
          final spent = spentByCategory[cat.id] ?? 0.0;
          final ratio = scaledBudget > 0 ? (spent / scaledBudget) : 0.0;
          final remaining = scaledBudget - spent;
          final isOver = hasBudget && remaining < 0;

          final Color barColor = isOver
              ? provider.expenseColor
              : (ratio > 0.80 ? Colors.orange : provider.secondaryColor);

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () =>
                  _showEditBudgetDialog(context, cat, baseMonthlyBudget),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: cat.color.withValues(alpha: 0.15),
                          child: Icon(cat.icon, color: cat.color, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            cat.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                        if (hasBudget)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: barColor,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${(ratio * 100).round()}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          )
                        else
                          TextButton.icon(
                            onPressed: () => _showEditBudgetDialog(
                              context,
                              cat,
                              baseMonthlyBudget,
                            ),
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Imposta Budget'),
                          ),
                      ],
                    ),
                    if (hasBudget) ...[
                      const SizedBox(height: 10),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: ratio.clamp(0.0, 1.0),
                          minHeight: 8,
                          color: barColor,
                          backgroundColor: Colors.grey.withValues(alpha: 0.2),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Speso: ${AppFormatters.formatCurrency(spent)} / ${AppFormatters.formatCurrency(scaledBudget)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            isOver
                                ? 'Sforato di ${AppFormatters.formatCurrency(remaining.abs())}'
                                : 'Restano ${AppFormatters.formatCurrency(remaining)}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: barColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  /// VISTA 3: SEZIONE NOTA (Raggruppa le spese/entrate per Note / Descrizioni!)
  Widget _buildNoteGroupedSection({
    required BuildContext context,
    required List<MoneyTransaction> periodTransactions,
    required double activeTotal,
  }) {
    final Map<String, List<MoneyTransaction>> groupedByNote = {};
    final Map<String, String> displayTitleByKey = {};

    for (final tx in periodTransactions) {
      if (tx.type != _selectedTab) continue;
      final trimmed = tx.note.trim();
      final label = trimmed.isEmpty ? 'Senza nota / descrizione' : trimmed;
      final normKey = label.toLowerCase();

      displayTitleByKey.putIfAbsent(normKey, () => label);
      groupedByNote.putIfAbsent(normKey, () => []).add(tx);
    }

    final sortedKeys = groupedByNote.keys.toList()
      ..sort((a, b) {
        final sumA =
            groupedByNote[a]!.fold(0.0, (sum, tx) => sum + tx.amount);
        final sumB =
            groupedByNote[b]!.fold(0.0, (sum, tx) => sum + tx.amount);
        return sumB.compareTo(sumA);
      });

    if (sortedKeys.isEmpty) {
      return Center(
        child: Text(
          _selectedTab == TransactionType.expense
              ? 'Nessuna spesa con nota in questo periodo.'
              : 'Nessuna entrata con nota in questo periodo.',
          style: const TextStyle(color: Colors.grey),
        ),
      );
    }

    final List<_NoteGroupItem> noteItems = [];
    for (int i = 0; i < sortedKeys.length; i++) {
      final k = sortedKeys[i];
      final list = groupedByNote[k]!;
      final sum = list.fold(0.0, (s, tx) => s + tx.amount);
      final pct = activeTotal > 0 ? (sum / activeTotal) : 0.0;

      noteItems.add(
        _NoteGroupItem(
          noteTitle: displayTitleByKey[k]!,
          totalAmount: sum,
          percentage: pct,
          count: list.length,
          color: _chartPalette[i % _chartPalette.length],
          transactions: list,
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 88, top: 4),
      itemCount: noteItems.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = noteItems[index];
        final roundedPct = (item.percentage * 100).round();

        return InkWell(
          onTap: () => _showNoteTransactionsSheet(context, item),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Badge percentuale colorato
                Container(
                  width: 48,
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: item.color,
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

                // Testo della Nota + numero di pagamenti raggruppati
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.noteTitle,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.count == 1
                            ? '1 pagamento'
                            : '${item.count} pagamenti raggruppati',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),

                // Importo totale speso per quella Nota
                Text(
                  AppFormatters.formatCurrency(item.totalAmount),
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
    );
  }
}

class _TopSectionSegment extends StatelessWidget {
  final String label;
  final bool isSelected;
  final Color activeColor;
  final VoidCallback onTap;

  const _TopSectionSegment({
    required this.label,
    required this.isSelected,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          alignment: Alignment.center,
          decoration: isSelected
              ? BoxDecoration(
                  color: activeColor,
                  borderRadius: BorderRadius.circular(10),
                )
              : null,
          child: Text(
            label,
            style: TextStyle(
              color: isSelected
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
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
