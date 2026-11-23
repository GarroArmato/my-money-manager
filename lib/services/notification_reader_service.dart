import '../models/transaction.dart';
import '../utils/formatters.dart';
import 'smart_categorizer.dart';

class NotificationReaderService {
  /// Esempi realistici di notifiche push inviate da app bancarie italiane e Google Wallet
  static const List<String> sampleBankNotifications = [
    'Intesa Sanpaolo: Hai effettuato un pagamento POS di 18,50 € presso PIZZERIA DA MICHELE',
    'Google Wallet: Pagamento di 64,20 € con carta *4812 presso ESSELUNGA',
    'Revolut: Hai speso EUR 40,00 presso DISTRIBUTORE Q8 CARBURANTI',
    'UniCredit: Accredito bonifico di 250,00 € - Rimborso spese trasferta',
  ];

  /// Analizza il testo di una notifica push bancaria ed estrae Importo, Tipo ed Esercente
  MoneyTransaction? parseNotificationText({
    required String notificationText,
    required String targetAccountId,
  }) {
    final text = notificationText.trim();
    if (text.isEmpty) return null;

    final upper = text.toUpperCase();
    final isIncome = upper.contains('ACCREDITO') ||
        upper.contains('RICEVUTO') ||
        upper.contains('ENTRATA') ||
        upper.contains('STIPENDIO') ||
        upper.contains('RIMBORSO');

    final amountRegex = RegExp(
      r'(?:(?:EUR|€)\s*(\d+(?:[.,]\d{1,2})?))|(?:(\d+(?:\.\d{3})*(?:[.,]\d{1,2}))\s*(?:EUR|€))',
      caseSensitive: false,
    );

    final match = amountRegex.firstMatch(text);
    if (match == null) return null;

    final rawNumber = (match.group(1) ?? match.group(2) ?? '')
        .replaceAll('.', '')
        .replaceAll(',', '.');

    final amount = double.tryParse(rawNumber);
    if (amount == null || amount <= 0) return null;

    String merchantOrNote = text;
    final pressoMatch =
        RegExp(r'presso\s+(.+)$', caseSensitive: false).firstMatch(text);
    if (pressoMatch != null && pressoMatch.group(1) != null) {
      merchantOrNote = pressoMatch.group(1)!.trim();
    }

    return MoneyTransaction(
      id: AppFormatters.generateId(),
      amount: amount,
      date: DateTime.now(),
      type: isIncome ? TransactionType.income : TransactionType.expense,
      accountId: targetAccountId,
      categoryId: SmartCategorizer.guessCategory(text, isIncome),
      note: '$merchantOrNote (da Notifica)',
      merchantName: merchantOrNote,
      source: TransactionSource.notification,
    );
  }
}
