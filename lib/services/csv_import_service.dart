import '../models/transaction.dart';
import '../utils/formatters.dart';
import 'smart_categorizer.dart';

class CsvImportService {
  /// Esempio di tracciato CSV esportato da una banca italiana (Data;Descrizione;Importo)
  static String get sampleBankCsv {
    final now = DateTime.now();
    String fmt(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

    return '''Data;Descrizione;Importo
${fmt(now)};PAGAMENTO POS ESSELUNGA MILANO;-48,60
${fmt(now.subtract(const Duration(days: 1)))};DISTRIBUTORE ENI CARBURANTE;-35,00
${fmt(now.subtract(const Duration(days: 2)))};ADDEBITO SDD NETFLIX.COM;-15,99
${fmt(now.subtract(const Duration(days: 3)))};PIZZERIA DA MICHELE POS;-24,50
${fmt(now.subtract(const Duration(days: 5)))};BONIFICO ACCREDITO STIPENDIO;1850,00''';
  }

  /// Analizza un testo CSV bancario (separatore ';' o ',') e restituisce la lista di MoneyTransaction
  List<MoneyTransaction> parseBankCsv({
    required String csvContent,
    required String targetAccountId,
  }) {
    final lines = csvContent
        .split(RegExp(r'\r?\n'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final List<MoneyTransaction> parsed = [];

    for (final line in lines) {
      if (line.toLowerCase().startsWith('data;') ||
          line.toLowerCase().startsWith('data,') ||
          line.toLowerCase().startsWith('date')) {
        continue;
      }

      final parts = line.contains(';') ? line.split(';') : line.split(',');
      if (parts.length < 3) continue;

      final rawDate = parts[0].trim();
      final description = parts[1].trim();
      final rawAmount = parts[2]
          .trim()
          .replaceAll('€', '')
          .replaceAll('EUR', '')
          .replaceAll(' ', '')
          .replaceAll('.', '')
          .replaceAll(',', '.');

      final signedAmount = double.tryParse(rawAmount);
      if (signedAmount == null || signedAmount == 0) continue;

      final date = _parseItalianOrIsoDate(rawDate);
      final isIncome = signedAmount > 0;
      final absAmount = signedAmount.abs();

      final dedupKey = 'CSV_${date.toIso8601String().substring(0, 10)}_'
          '${description}_${signedAmount.toStringAsFixed(2)}';

      parsed.add(
        MoneyTransaction(
          id: AppFormatters.generateId(),
          amount: absAmount,
          date: date,
          type: isIncome ? TransactionType.income : TransactionType.expense,
          accountId: targetAccountId,
          categoryId: SmartCategorizer.guessCategory(description, isIncome),
          note: description,
          source: TransactionSource.csv,
          deduplicationKey: dedupKey,
        ),
      );
    }

    return parsed;
  }

  DateTime _parseItalianOrIsoDate(String raw) {
    if (raw.contains('/')) {
      final segments = raw.split('/');
      if (segments.length == 3) {
        final day = int.tryParse(segments[0]) ?? 1;
        final month = int.tryParse(segments[1]) ?? 1;
        final year = int.tryParse(segments[2]) ?? DateTime.now().year;
        return DateTime(year, month, day, 12, 0);
      }
    }
    return DateTime.tryParse(raw) ?? DateTime.now();
  }
}
